#!/usr/bin/env bash
# lib/common.sh — shared functions for the fedora-custom-images build flow.
#
# Binding interface (ARCHITECTURE.md §6). Sourced by build.sh and lib/generate.sh.
# Safe to source multiple times.
#
# Conventions:
#   - A "layer id" is one of:  base | desktop-common | de/<name> | purpose:<purpose>
#   - Purposes are addressed as "purpose:<id>" wherever a layer id is expected.
#   - REPO_ROOT is derived from this file's location; all paths are absolute.

set -euo pipefail

# ---------------------------------------------------------------------------
# Repository paths
# ---------------------------------------------------------------------------

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${REPO_ROOT}/config"
LAYERS_DIR="${CONFIG_DIR}/layers"
PURPOSES_DIR="${CONFIG_DIR}/purposes"
FILES_ROOT="${REPO_ROOT}/files"
GENERATED_DIR="${REPO_ROOT}/generated"

# Every variable a layer/purpose conf may set. Unset before each load so a
# previously sourced conf can never leak values into the next one.
CONF_VARS=(
  LAYER DESCRIPTION PARENT PACKAGES COPRS
  SERVICES_ENABLE SERVICES_MASK KARGS FLATPAKS POST_SCRIPT
  PURPOSE DE PIN_REASON
)

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

info() { printf '\033[1;34m[info]\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[fail]\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Global build configuration
# ---------------------------------------------------------------------------

# load_build_conf — source config/build.conf, then re-apply any environment
# overrides (FEDORA_VERSION, REGISTRY, TAG, BASE_IMAGE) that were set before
# the call, so `REGISTRY=quay.io/me ./build.sh ...` works. If FEDORA_VERSION
# is overridden but BASE_IMAGE is not, the version embedded in BASE_IMAGE is
# rewritten to match.
load_build_conf() {
  local conf="${CONFIG_DIR}/build.conf"
  [[ -f "$conf" ]] || die "missing global config: $conf"

  # Snapshot pre-existing environment overrides.
  local env_fedora_version="${FEDORA_VERSION-}"
  local env_registry="${REGISTRY-}"
  local env_tag="${TAG-}"
  local env_base_image="${BASE_IMAGE-}"
  local env_rootfs="${ROOTFS-}"
  local env_firstboot="${FIRSTBOOT-}"

  # shellcheck source=../config/build.conf
  source "$conf"

  local conf_fedora_version="$FEDORA_VERSION"
  [[ -n "$env_fedora_version" ]] && FEDORA_VERSION="$env_fedora_version"
  [[ -n "$env_registry"       ]] && REGISTRY="$env_registry"
  [[ -n "$env_tag"            ]] && TAG="$env_tag"
  [[ -n "$env_rootfs"         ]] && ROOTFS="$env_rootfs"
  [[ -n "$env_firstboot"      ]] && FIRSTBOOT="$env_firstboot"
  if [[ -n "$env_base_image" ]]; then
    BASE_IMAGE="$env_base_image"
  elif [[ -n "$env_fedora_version" ]]; then
    # Keep BASE_IMAGE consistent with an overridden FEDORA_VERSION.
    BASE_IMAGE="${BASE_IMAGE//"$conf_fedora_version"/"$FEDORA_VERSION"}"
  fi

  [[ -n "${FEDORA_VERSION:-}" ]] || die "FEDORA_VERSION not set by $conf"
  [[ -n "${REGISTRY:-}"       ]] || die "REGISTRY not set by $conf"
  [[ -n "${TAG:-}"            ]] || die "TAG not set by $conf"
  [[ -n "${BASE_IMAGE:-}"     ]] || die "BASE_IMAGE not set by $conf"
}

# ---------------------------------------------------------------------------
# Catalog helpers
# ---------------------------------------------------------------------------

# list_purposes — echo purpose ids, one per line, derived from config/purposes/.
list_purposes() {
  local f
  for f in "${PURPOSES_DIR}"/*.conf; do
    [[ -e "$f" ]] || die "no purpose confs found under ${PURPOSES_DIR}"
    basename "$f" .conf
  done
}

# _conf_path — internal: echo the conf file path for a layer id.
#   base            -> config/layers/base.conf
#   de/cosmic-hyprland -> config/layers/de/cosmic-hyprland.conf
#   purpose:gaming  -> config/purposes/gaming.conf
_conf_path() {
  local id="$1"
  if [[ "$id" == purpose:* ]]; then
    echo "${PURPOSES_DIR}/${id#purpose:}.conf"
  else
    echo "${LAYERS_DIR}/${id}.conf"
  fi
}

# _reset_conf_vars — internal: unset every conf variable (sourcing-pollution guard).
_reset_conf_vars() {
  local v
  for v in "${CONF_VARS[@]}"; do
    unset "$v"
  done
}

# load_layer_conf — $1 = layer id or purpose:<id>. Sources the conf file,
# normalizes variables and sets FILES_DIR (absolute path to the layer's files
# dir; the dir may not exist — callers must check).
#
# After a call the following are always set (possibly empty where optional):
#   LAYER PARENT DESCRIPTION PACKAGES COPRS SERVICES_ENABLE SERVICES_MASK
#   KARGS FLATPAKS POST_SCRIPT FILES_DIR
# and for purposes additionally: PURPOSE DE PIN_REASON.
load_layer_conf() {
  local id="$1"
  local conf
  conf="$(_conf_path "$id")"
  [[ -f "$conf" ]] || die "no such layer config: $conf (layer id: $id)"

  _reset_conf_vars
  # shellcheck disable=SC1090
  source "$conf"

  if [[ "$id" == purpose:* ]]; then
    local want="${id#purpose:}"
    [[ -n "${PURPOSE:-}" ]]    || die "$conf: PURPOSE is required"
    [[ "$PURPOSE" == "$want" ]] || die "$conf: PURPOSE='$PURPOSE' must match filename '$want'"
    [[ -n "${DE:-}" ]]         || die "$conf: DE is required"
    [[ -f "${LAYERS_DIR}/de/${DE}.conf" ]] \
      || die "$conf: DE='$DE' has no config/layers/de/${DE}.conf"
    [[ -n "${PIN_REASON:-}" ]] || die "$conf: PIN_REASON is required"
    [[ -z "${LAYER:-}" && -z "${PARENT:-}" ]] \
      || die "$conf: LAYER/PARENT must not be set in purpose confs (derived)"
    # Normalize: a purpose behaves like a layer whose parent is its pinned DE.
    LAYER="purpose:${PURPOSE}"
    PARENT="de/${DE}"
    FILES_DIR="${FILES_ROOT}/purposes/${PURPOSE}"
  else
    [[ -n "${LAYER:-}" ]]      || die "$conf: LAYER is required"
    [[ "$LAYER" == "$id" ]]    || die "$conf: LAYER='$LAYER' must match layer id '$id'"
    [[ -n "${PARENT+x}" ]]     || die "$conf: PARENT is required (\"\" for the root layer)"
    FILES_DIR="${FILES_ROOT}/${LAYER}"
  fi

  [[ -n "${DESCRIPTION:-}" ]] || die "$conf: DESCRIPTION is required"

  # Default the optional fields so `set -u` callers can expand them freely.
  PACKAGES="${PACKAGES:-}"
  COPRS="${COPRS:-}"
  SERVICES_ENABLE="${SERVICES_ENABLE:-}"
  SERVICES_MASK="${SERVICES_MASK:-}"
  KARGS="${KARGS:-}"
  FLATPAKS="${FLATPAKS:-}"
  POST_SCRIPT="${POST_SCRIPT:-}"
}

# ---------------------------------------------------------------------------
# Image naming and chains
# ---------------------------------------------------------------------------

# resolve_image — $1 = bare purpose id or full image name -> echoes the purpose
# id; dies with the list of valid names if unknown.
resolve_image() {
  local wanted="$1" p
  for p in $(list_purposes); do
    if [[ "$wanted" == "$p" || "$wanted" == "$(image_name "$p")" ]]; then
      echo "$p"
      return 0
    fi
  done
  local valid=""
  for p in $(list_purposes); do
    valid+=$'\n'"  $p  ($(image_name "$p"))"
  done
  die "unknown image '$wanted'. Valid purposes/images:$valid"
}

# image_name — $1 = purpose id -> fedora-<purpose>-<de>
image_name() {
  local p="$1"
  load_layer_conf "purpose:$p"
  # The mark leads and Fedora is credited in the OCI base.name label instead
  # (§2): a published ref beginning "fedora-" reads as an official Fedora
  # edition, and the DE has carried no information since every purpose moved
  # to the one session.
  echo "carino-${PURPOSE}"
}

# layer_chain — $1 = purpose id -> ordered layer ids root-first on one line,
# e.g. "base desktop-common de/cosmic-hyprland purpose:general".
# Data-driven: the purpose's parent is its pinned DE layer, then PARENT links
# are walked from the conf files up to the root (PARENT="").
layer_chain() {
  local p="$1"
  load_layer_conf "purpose:$p"
  local chain="$LAYER" cur="$PARENT" guard=0
  while [[ -n "$cur" ]]; do
    chain="$cur $chain"
    load_layer_conf "$cur"
    cur="$PARENT"
    guard=$((guard + 1))
    (( guard <= 16 )) || die "layer chain too deep (PARENT cycle?) resolving purpose '$p'"
  done
  echo "$chain"
}

# layer_slug — $1 = layer id -> filesystem/image-name-safe form
#   de/cosmic-hyprland -> de-cosmic-hyprland ; purpose:gaming -> gaming (purposes use image_name).
layer_slug() {
  local id="$1"
  id="${id#purpose:}"
  echo "${id//\//-}"
}

# layer_image_ref — $1 = layer id -> full image ref usable in FROM / -t.
#   Intermediate layers: <REGISTRY>/carino-layer-<slug>:<TAG>
#   Purposes (published): <REGISTRY>/fedora-<purpose>-<de>:<TAG>
# Requires load_build_conf to have run.
layer_image_ref() {
  local id="$1"
  [[ -n "${REGISTRY:-}" && -n "${TAG:-}" ]] \
    || die "layer_image_ref: REGISTRY/TAG unset — call load_build_conf first"
  if [[ "$id" == purpose:* ]]; then
    echo "${REGISTRY}/$(image_name "${id#purpose:}"):${TAG}"
  else
    echo "${REGISTRY}/carino-layer-$(layer_slug "$id"):${TAG}"
  fi
}
