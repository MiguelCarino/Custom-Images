#!/usr/bin/env bash
# lib/blueprint.sh — EXPERIMENTAL osbuild blueprint emitter (ARCHITECTURE.md §10).
#
# Provides:
#   emit_blueprint  $1 purpose id -> writes generated/<image>/blueprint.toml
#
# Flattens the image's full layer chain (packages, services, kargs) into a
# single blueprint TOML for the traditional-Workstation osbuild backend.
# COPRs cannot be enabled from a blueprint, so packages coming from layers
# that declare COPRS are flagged in a header comment as unresolved — the COPR
# repo must be configured host-side for the depsolve to succeed. REPO_RPMS
# (Remi, RPM Fusion …) are flagged the same way and for the same reason.
# Flatpaks are
# a first-boot mechanism (§8) and are not representable in a blueprint; they
# are noted in the header for transparency.
#
# A layer's static files (FILES_DIR, mirrored into / by the Containerfile
# path) and its POST_SCRIPT have no blueprint equivalent either. Both are
# reported in the header AND on the terminal, because a silently thinner
# blueprint reads as a clean generate. Where SERVICES_ENABLE names a unit that
# only ships in FILES_DIR, the enable is omitted rather than emitted: osbuild
# runs `systemctl enable` during the build and a missing unit fails it, so
# emitting it would produce a blueprint that cannot build at all. The omitted
# names are listed in the header so they can be re-added once the unit is
# provisioned host-side.
#
# Requires lib/common.sh sourced and load_build_conf already called.

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# _bp_toml_string_array — $* = items -> a TOML inline array of strings,
# e.g. `"a", "b"` (caller supplies the brackets).
_bp_toml_string_array() {
  local item out=""
  for item in "$@"; do
    out+="${out:+, }\"${item}\""
  done
  echo "$out"
}

# ---------------------------------------------------------------------------
# Blueprint emission
# ---------------------------------------------------------------------------

# emit_blueprint — $1 = purpose id. Writes generated/<image>/blueprint.toml.
emit_blueprint() {
  local purpose="$1"
  local img chain layer
  img="$(image_name "$purpose")"
  chain="$(layer_chain "$purpose")"

  # ---- Flatten the chain -------------------------------------------------
  # Accumulators (order-preserving, deduplicated where it matters).
  local -a packages=() enabled=() masked=() kargs=() flatpaks=() copr_notes=()
  local -a file_notes=() dropped_enabled=() masked_uncompensated=()
  local seen_pkgs=" " seen_enabled=" " seen_masked=" " layer_drops=0
  local shipped_units=" " # unit filenames a FILES_DIR mirrors into /, accumulated parent-first so a child layer's enable sees them
  local description=""

  local item unit note
  # shellcheck disable=SC2086 # layer ids never contain whitespace
  for layer in $chain; do
    load_layer_conf "$layer"
    layer_drops=0 # set below if THIS layer's static files / POST_SCRIPT are dropped

    # The published image describes itself with the purpose's DESCRIPTION.
    description="$DESCRIPTION"

    # COPR-declaring layers: their PACKAGES may resolve only from the COPR.
    # A conf does not say which individual package needs the COPR, so the
    # whole layer's set is flagged (see file header for the rationale).
    if [[ -n "$COPRS" ]]; then
      copr_notes+=("layer ${layer} enables COPR(s): ${COPRS}")
      copr_notes+=("  affected packages: ${PACKAGES:-<none>}")
    fi

    # Repo-definition RPMs (Remi, RPM Fusion …) are the same problem as a COPR:
    # a blueprint cannot install one, so the repo must exist host-side before
    # the depsolve. Reported through the same channel.
    if [[ -n "$REPO_RPMS" ]]; then
      copr_notes+=("layer ${layer} installs repo-definition RPM(s): ${REPO_RPMS}")
      copr_notes+=("  affected packages: ${PACKAGES:-<none>}")
    fi

    # Static files and POST_SCRIPT: Containerfile-only mechanisms (§7). Record
    # what is being left behind, and remember any systemd units the tree ships
    # so the SERVICES_ENABLE pass below can tell "enable a stock unit" from
    # "enable a unit that arrives only via FILES_DIR".
    if [[ -d "$FILES_DIR" ]] && [[ -n "$(find "$FILES_DIR" -type f -print -quit 2>/dev/null)" ]]; then
      layer_drops=1
      file_notes+=("layer ${layer} mirrors ${FILES_DIR#"${REPO_ROOT}"/} into / — not representable:")
      while IFS= read -r item; do
        file_notes+=("  /${item#"${FILES_DIR}"/}")
      done < <(find "$FILES_DIR" -type f | sort)
      while IFS= read -r unit; do
        shipped_units+="$(basename "$unit") "
      done < <(find "$FILES_DIR" -type f -path '*/systemd/system/*' 2>/dev/null)
    fi
    if [[ -n "$POST_SCRIPT" ]]; then
      layer_drops=1
      file_notes+=("layer ${layer} runs POST_SCRIPT '${POST_SCRIPT}' — not representable")
    fi

    # shellcheck disable=SC2086 # conf fields are space-separated words
    for item in $PACKAGES; do
      if [[ "$seen_pkgs" != *" ${item} "* ]]; then
        seen_pkgs+="${item} "
        packages+=("$item")
      fi
    done
    # shellcheck disable=SC2086
    for item in $SERVICES_ENABLE; do
      if [[ "$seen_enabled" != *" ${item} "* ]]; then
        seen_enabled+="${item} "
        if [[ "$shipped_units" == *" ${item} "* ]]; then
          dropped_enabled+=("${item} (unit ships only in a FILES_DIR, layer ${layer})")
        else
          enabled+=("$item")
        fi
      fi
    done
    # shellcheck disable=SC2086
    for item in $SERVICES_MASK; do
      if [[ "$seen_masked" != *" ${item} "* ]]; then
        seen_masked+="${item} "
        masked+=("$item")
        # A mask carries into the blueprint verbatim, but whatever re-owned the
        # path the masked unit used to own does not, if it arrived as a static
        # file or a POST_SCRIPT in the same layer. That asymmetry is how
        # `offline` ends up masking systemd-resolved in a classic image that no
        # longer gets the tmpfiles.d line pointing /etc/resolv.conf at 127.0.0.1.
        (( layer_drops )) && masked_uncompensated+=("${item} (layer ${layer}, whose static files / POST_SCRIPT are dropped)")
      fi
    done
    # shellcheck disable=SC2086
    for item in $KARGS; do
      kargs+=("$item")
    done
    # shellcheck disable=SC2086
    for item in $FLATPAKS; do
      flatpaks+=("$item")
    done
  done

  # ---- Output location ---------------------------------------------------
  local out_dir="${GENERATED_DIR}/${img}"
  local bp="${out_dir}/blueprint.toml"
  mkdir -p "$out_dir"

  # ---- Write -------------------------------------------------------------
  {
    printf '# Generated by lib/blueprint.sh — DO NOT EDIT (regen: ./build.sh blueprint %s)\n' "$img"
    printf '# EXPERIMENTAL osbuild blueprint (ARCHITECTURE.md §10) — traditional-Workstation backend.\n'
    printf '# Image: %s\n' "$img"
    printf '# Chain: %s\n' "$chain"
    if [[ ${#copr_notes[@]} -gt 0 ]]; then
      printf '#\n'
      printf '# UNRESOLVED — packages from repositories a blueprint cannot add for\n'
      printf '# itself (COPRs, repo-definition RPMs). Configure the repo host-side or\n'
      printf '# these packages will fail to depsolve:\n'
      local note
      for note in "${copr_notes[@]}"; do
        printf '#   %s\n' "$note"
      done
    fi
    if [[ ${#flatpaks[@]} -gt 0 ]]; then
      printf '#\n'
      printf '# NOTE: flatpaks are installed on first boot (§8), not representable here:\n'
      printf '#   %s\n' "${flatpaks[*]}"
    fi
    if [[ ${#file_notes[@]} -gt 0 ]]; then
      printf '#\n'
      printf '# DROPPED — static files and post-install scripts. The Containerfile path\n'
      printf '# mirrors these into the image; a blueprint has no equivalent, so the\n'
      printf '# classic image will NOT contain them:\n'
      for note in "${file_notes[@]}"; do
        printf '#   %s\n' "$note"
      done
    fi
    if [[ ${#dropped_enabled[@]} -gt 0 ]]; then
      printf '#\n'
      printf '# OMITTED from [customizations.services].enabled — osbuild runs\n'
      printf '# `systemctl enable` during the build and a missing unit fails it.\n'
      printf '# Re-add each once its unit is provisioned host-side:\n'
      for note in "${dropped_enabled[@]}"; do
        printf '#   %s\n' "$note"
      done
    fi
    if [[ ${#masked_uncompensated[@]} -gt 0 ]]; then
      printf '#\n'
      printf '# MASKS KEPT, COMPENSATING FILES DROPPED — these masks DO carry into the\n'
      printf '# blueprint, but the static files that made each one survivable do not\n'
      printf '# (see DROPPED above). Masking a unit without whatever re-owned the path\n'
      printf '# it held, or whatever took over the job it was doing, leaves the classic\n'
      printf '# image with that function simply missing rather than replaced. Provision\n'
      printf '# the equivalent host-side, or drop the mask too:\n'
      for note in "${masked_uncompensated[@]}"; do
        printf '#   %s\n' "$note"
      done
    fi
    printf '\n'
    printf 'name = "%s"\n' "$img"
    printf 'description = "%s"\n' "$description"
    printf 'version = "0.0.1"\n'
    printf 'distro = "fedora-%s"\n' "$FEDORA_VERSION"

    if [[ ${#packages[@]} -gt 0 ]]; then
      printf '\n'
      local pkg
      for pkg in "${packages[@]}"; do
        printf '[[packages]]\nname = "%s"\n\n' "$pkg"
      done
    fi

    if [[ ${#kargs[@]} -gt 0 ]]; then
      printf '[customizations.kernel]\n'
      printf 'append = "%s"\n\n' "${kargs[*]}"
    fi

    if [[ ${#enabled[@]} -gt 0 || ${#masked[@]} -gt 0 ]]; then
      printf '[customizations.services]\n'
      if [[ ${#enabled[@]} -gt 0 ]]; then
        printf 'enabled = [%s]\n' "$(_bp_toml_string_array "${enabled[@]}")"
      fi
      if [[ ${#masked[@]} -gt 0 ]]; then
        printf 'masked = [%s]\n' "$(_bp_toml_string_array "${masked[@]}")"
      fi
    fi
  } > "$bp"

  info "generated ${bp#"${REPO_ROOT}"/} (experimental)"

  # Surface the lossy parts on the terminal too — the header comment is only
  # read by whoever opens the TOML, and this is what makes the blueprint an
  # incomplete copy of the image rather than an equivalent one.
  if [[ ${#copr_notes[@]} -gt 0 || ${#flatpaks[@]} -gt 0 || ${#file_notes[@]} -gt 0 || ${#dropped_enabled[@]} -gt 0 || ${#masked_uncompensated[@]} -gt 0 ]]; then
    warn "${img}: blueprint is a LOSSY export of the image — see the header of ${bp#"${REPO_ROOT}"/}"
    [[ ${#copr_notes[@]}      -gt 0 ]] && warn "  COPR / third-party-repo packages need the repo configured host-side or the depsolve fails"
    [[ ${#flatpaks[@]}        -gt 0 ]] && warn "  ${#flatpaks[@]} flatpak(s) dropped (first-boot mechanism, §8)"
    [[ ${#file_notes[@]}      -gt 0 ]] && warn "  static files / POST_SCRIPT dropped — the classic image will not contain them"
    [[ ${#dropped_enabled[@]} -gt 0 ]] && warn "  ${#dropped_enabled[@]} service enable(s) omitted so the build does not fail on a missing unit"
    [[ ${#masked_uncompensated[@]} -gt 0 ]] && warn "  ${#masked_uncompensated[@]} mask(s) KEPT whose compensating files were dropped — the masked function is simply gone in the classic image"
  fi
  return 0 # the [[ ]] chain above leaves a false status when the last test misses, and the caller runs under set -e
}
