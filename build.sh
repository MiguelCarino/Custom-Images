#!/usr/bin/env bash
# build.sh — THE entry point for the fedora-custom-images build flow.
#
# CLI (ARCHITECTURE.md §5):
#   ./build.sh list                          # catalog: image, DE, description, pin reason
#   ./build.sh generate [IMAGE|all]          # emit Containerfiles (chain-aware)
#   ./build.sh build    [IMAGE|all] [--push] # generate + podman build in dependency order
#   ./build.sh iso      IMAGE|all            # bootc-image-builder → output/IMAGE/install.iso
#   ./build.sh blueprint [IMAGE|all]         # emit osbuild blueprint TOML (experimental)
#   ./build.sh clean                         # rm -rf generated/
#
# Global flags (before or after the subcommand): --registry R  --tag T  --no-cache
# IMAGE accepts the full name (carino-gaming) or the bare
# purpose (gaming).

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/generate.sh
source "${SCRIPT_DIR}/lib/generate.sh"
# shellcheck source=lib/blueprint.sh
source "${SCRIPT_DIR}/lib/blueprint.sh"

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
  cat <<'EOF'
Usage: ./build.sh COMMAND [ARGS] [FLAGS]

Commands:
  list                          Show the image catalog (image, DE, description, pin reason)
  generate  [IMAGE|all]         Emit Containerfiles for the image's layer chain (default: all)
  build     [IMAGE|all] [--push]
                                Generate + podman build in dependency order; --push
                                publishes the final images (never carino-layer-* intermediates)
  iso       IMAGE|all           Build installer ISOs via bootc-image-builder
                                into output/<image>/install.iso (needs sudo + built images)
  blueprint [IMAGE|all]         Emit an osbuild blueprint TOML (experimental, default: all)
  clean                         Remove the generated/ directory

Flags (accepted before or after the command):
  --registry R                  Override REGISTRY from config/build.conf
  --tag T                       Override TAG from config/build.conf
  --no-cache                    Pass --no-cache to podman build
  -h, --help                    Show this help

IMAGE is a full image name (carino-gaming) or a bare purpose (gaming).
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing — flags may appear anywhere relative to the subcommand.
# ---------------------------------------------------------------------------

PUSH=0
NO_CACHE=0
POSITIONAL=()

while (($#)); do
  case "$1" in
    --registry)
      [[ $# -ge 2 ]] || die "--registry requires a value"
      REGISTRY="$2"; shift 2 ;;
    --tag)
      [[ $# -ge 2 ]] || die "--tag requires a value"
      TAG="$2"; shift 2 ;;
    --no-cache)
      NO_CACHE=1; shift ;;
    --push)
      PUSH=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    -*)
      die "unknown flag '$1' (see ./build.sh --help)" ;;
    *)
      POSITIONAL+=("$1"); shift ;;
  esac
done

COMMAND="${POSITIONAL[0]:-}"
TARGET="${POSITIONAL[1]:-}"
[[ ${#POSITIONAL[@]} -le 2 ]] \
  || die "too many arguments: '${POSITIONAL[*]}' (see ./build.sh --help)"

if [[ -z "$COMMAND" ]]; then
  usage >&2
  exit 1
fi

if (( PUSH )) && [[ "$COMMAND" != build ]]; then
  die "--push is only valid with the 'build' command"
fi

# REGISTRY/TAG assignments above act as environment overrides here (§6).
load_build_conf

# ---------------------------------------------------------------------------
# Target helpers
# ---------------------------------------------------------------------------

# resolve_targets — $1 = IMAGE | all | "" -> purpose ids, one per line.
# An empty target means "all". Unknown images die with the valid list.
resolve_targets() {
  local t="${1:-all}"
  if [[ "$t" == all ]]; then
    list_purposes
  else
    resolve_image "$t"
  fi
}

# build_order — $* = purpose ids -> every layer needed, one per line, in
# topological order (root-first) with each shared layer listed exactly once.
# Chains are root-first, so first-seen order across chains is already valid.
build_order() {
  local p layer seen=" "
  for p in "$@"; do
    # shellcheck disable=SC2046 # layer ids never contain whitespace
    for layer in $(layer_chain "$p"); do
      if [[ "$seen" != *" ${layer} "* ]]; then
        seen+="${layer} "
        echo "$layer"
      fi
    done
  done
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

cmd_list() {
  local p name
  printf '%-30s %-16s %s\n' "IMAGE" "DE" "DESCRIPTION"
  printf '%-30s %-16s %s\n' "-----" "--" "-----------"
  for p in $(list_purposes); do
    name="$(image_name "$p")"           # subshell — does not clobber conf vars
    load_layer_conf "purpose:$p"
    printf '%-30s %-16s %s\n' "$name" "$DE" "$DESCRIPTION"
    printf '%-30s %-16s pin: %s\n' "" "" "$PIN_REASON"
  done
}

cmd_generate() {
  local p targets
  # Plain assignment so resolve_targets' die() propagates under set -e
  # (a `for p in $(...)` substitution would swallow the failure).
  targets="$(resolve_targets "$TARGET")"
  for p in $targets; do
    generate_image "$p"
  done
}

cmd_build() {
  local -a purposes=()
  local p layer ref out ctx targets
  # Plain assignment so resolve_targets' die() propagates under set -e
  # (`mapfile < <(...)` would discard the process substitution's status).
  targets="$(resolve_targets "$TARGET")"
  mapfile -t purposes <<<"$targets"
  [[ -n "$targets" && ${#purposes[@]} -gt 0 ]] || die "no targets resolved"

  # ---- Build every needed layer once, in dependency order ----------------
  for layer in $(build_order "${purposes[@]}"); do
    emit_layer_containerfile "$layer"
    ref="$(layer_image_ref "$layer")"
    out="$(layer_output_name "$layer")"
    ctx="$(layer_context_dir "$layer")"

    local -a args=(build -f "${GENERATED_DIR}/${out}/Containerfile" -t "$ref")
    if (( NO_CACHE )); then
      args+=(--no-cache)
    fi
    info "building ${ref}  (layer: ${layer})"
    podman "${args[@]}" "$ctx"
  done

  # ---- Push only the published images, never the intermediates -----------
  if (( PUSH )); then
    for p in "${purposes[@]}"; do
      ref="$(layer_image_ref "purpose:$p")"
      info "pushing ${ref}"
      podman push "$ref"
    done
  fi
}

# _iso_one — $1 = purpose id -> installer ISO at output/<image>/install.iso.
_iso_one() {
  local p="$1" name ref out_dir
  name="$(image_name "$p")"
  ref="$(layer_image_ref "purpose:$p")"
  out_dir="${REPO_ROOT}/output/${name}"

  # bootc-image-builder reads root's container storage, but build.sh builds
  # rootless — sync the image across when root's copy is missing or stale.
  local uid rid
  uid="$(podman image inspect --format '{{.Id}}' "$ref" 2>/dev/null || true)"
  rid="$(sudo podman image inspect --format '{{.Id}}' "$ref" 2>/dev/null || true)"
  [[ -n "$uid" || -n "$rid" ]] \
    || die "image ${ref} not found locally — run: ./build.sh build $p"
  if [[ -n "$uid" && "$uid" != "$rid" ]]; then
    info "copying ${ref} into root container storage (needed by bootc-image-builder)"
    podman save "$ref" | sudo podman load
  fi

  # User accounts — the bootc base images ship none and the unattended
  # installer creates none. FIRSTBOOT=interactive images prompt on first boot;
  # otherwise config/iso.toml credentials are the only way in.
  local -a cfg_mount=() cfg_flag=()
  if [[ -f "${CONFIG_DIR}/iso.toml" ]]; then
    cfg_mount=(-v "${CONFIG_DIR}/iso.toml:/config.toml:ro")
    cfg_flag=(--config /config.toml)
    info "using config/iso.toml (users etc.)"
  elif [[ "${FIRSTBOOT:-interactive}" == "interactive" ]]; then
    # Anaconda disables initial-setup by default on kickstart installs, which
    # would silently undo the enablement baked into the image — the kickstart
    # must say firstboot --enable for the first-boot prompt to survive.
    local gen_cfg="${GENERATED_DIR}/iso-firstboot.toml"
    mkdir -p "${GENERATED_DIR}"
    printf '[customizations.installer.kickstart]\ncontents = """\nfirstboot --enable\n"""\n' > "$gen_cfg"
    cfg_mount=(-v "${gen_cfg}:/config.toml:ro")
    cfg_flag=(--config /config.toml)
    info "no config/iso.toml — injecting 'firstboot --enable'; first boot prompts for the initial user"
  else
    warn "no config/iso.toml and FIRSTBOOT=none — the installed system will have NO user accounts;"
    warn "copy config/iso.toml.example to config/iso.toml and set a user first."
  fi

  mkdir -p "$out_dir"
  info "building ISO for ${ref} → output/${name}/install.iso (privileged, needs sudo)"
  sudo podman run --privileged --rm \
    -v "${out_dir}:/output" \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    "${cfg_mount[@]}" \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type iso --rootfs "${ROOTFS:-ext4}" "${cfg_flag[@]}" --local "$ref"

  # bootc-image-builder emits bootiso/install.iso; surface it at the §5 path.
  if [[ -f "${out_dir}/bootiso/install.iso" ]]; then
    mv -f "${out_dir}/bootiso/install.iso" "${out_dir}/install.iso"
    info "ISO ready: output/${name}/install.iso"
  else
    warn "expected ${out_dir}/bootiso/install.iso not found — check builder output above"
  fi
}

cmd_iso() {
  [[ -n "$TARGET" ]] \
    || die "iso requires an IMAGE argument or 'all' (see ./build.sh list)"
  local p targets
  # Plain assignment so resolve_targets' die() propagates under set -e.
  targets="$(resolve_targets "$TARGET")"
  for p in $targets; do
    _iso_one "$p"
  done
}

cmd_blueprint() {
  local p targets
  # Plain assignment so resolve_targets' die() propagates under set -e.
  targets="$(resolve_targets "$TARGET")"
  for p in $targets; do
    emit_blueprint "$p"
  done
}

cmd_clean() {
  rm -rf "${GENERATED_DIR}"
  info "removed ${GENERATED_DIR#"${REPO_ROOT}"/}/"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

case "$COMMAND" in
  list)      cmd_list ;;
  generate)  cmd_generate ;;
  build)     cmd_build ;;
  iso)       cmd_iso ;;
  blueprint) cmd_blueprint ;;
  clean)     cmd_clean ;;
  *)
    die "unknown command '$COMMAND' (valid: list generate build iso blueprint clean)" ;;
esac
