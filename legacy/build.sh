#!/usr/bin/env bash
# =============================================================================
# build.sh — Easy entry point for building custom OS images
#
# Usage:
#   ./build.sh <distro> <profile> [OPTIONS]
#
# Examples:
#   ./build.sh fedora medical
#   ./build.sh fedora medical --iso
#   ./build.sh ubuntu workstation --registry quay.io/myorg
#   ./build.sh debian pacs-server --iso --push
#   ./build.sh --list
#
# Options:
#   --registry  <reg>   Container registry prefix  (default: localhost)
#   --tag       <tag>   Image tag                  (default: latest)
#   --iso               Generate a bootable ISO after build
#   --push              Push images to registry after build
#   --no-cache          Force full rebuild (skip Podman layer cache)
#   --weasis-version <v> Override Weasis version   (default: from profile)
#   --list              List available distros and profiles
#   -h, --help          Show this help
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --------------------------------------------------------------------------- #
# Defaults
# --------------------------------------------------------------------------- #
DISTRO=""
PROFILE=""
REGISTRY="localhost"
TAG="latest"
BUILD_ISO=false
PUSH=false
NO_CACHE=false
WEASIS_VER_OVERRIDE=""

# --------------------------------------------------------------------------- #
# Parse arguments
# --------------------------------------------------------------------------- #
if [[ $# -eq 0 ]]; then
  "$0" --help
  exit 0
fi

# First two positional args are distro and profile (if not flags)
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --registry)        REGISTRY="$2";          shift 2 ;;
    --tag)             TAG="$2";               shift 2 ;;
    --iso)             BUILD_ISO=true;          shift   ;;
    --push)            PUSH=true;              shift   ;;
    --no-cache)        NO_CACHE=true;          shift   ;;
    --weasis-version)  WEASIS_VER_OVERRIDE="$2"; shift 2 ;;
    --list)
      echo ""
      echo "Available distros:"
      for f in "${SCRIPT_DIR}/config/distros/"*.conf; do
        name=$(basename "$f" .conf)
        # shellcheck source=/dev/null
        source "$f"
        echo "  ${name}  (${DISTRO_DISPLAY})"
        # Re-declare empty after sourcing to avoid pollution
        unset DISTRO DISTRO_FAMILY DISTRO_VERSION DISTRO_DISPLAY BASE_IMAGE \
              PKG_INSTALL PKG_CLEAN EXTRA_REPOS_BLOCK SECURITY_BLOCK \
              FIREWALL_SERVICE WEASIS_PKG_NAME WEASIS_INSTALL_CMD 2>/dev/null || true
      done
      echo ""
      echo "Available profiles:"
      for f in "${SCRIPT_DIR}/config/profiles/"*.conf; do
        name=$(basename "$f" .conf)
        # shellcheck source=/dev/null
        source "$f"
        inherits_str="${INHERITS:-none}"
        echo "  ${name}  — ${PROFILE_DESCRIPTION}  (inherits: ${inherits_str})"
        unset PROFILE PROFILE_DESCRIPTION INHERITS 2>/dev/null || true
      done
      echo ""
      exit 0
      ;;
    -h|--help)
      sed -n '2,/^# ===/p' "$0" | grep '^#' | sed 's/^# \?//'
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

# Assign positional args
[[ ${#POSITIONAL[@]} -ge 1 ]] && DISTRO="${POSITIONAL[0]}"
[[ ${#POSITIONAL[@]} -ge 2 ]] && PROFILE="${POSITIONAL[1]}"

# Validate
[[ -z "$DISTRO"  ]] && { echo "ERROR: distro is required. Run ./build.sh --list" >&2; exit 1; }
[[ -z "$PROFILE" ]] && { echo "ERROR: profile is required. Run ./build.sh --list" >&2; exit 1; }

DISTRO_CONF="${SCRIPT_DIR}/config/distros/${DISTRO}.conf"
PROFILE_CONF="${SCRIPT_DIR}/config/profiles/${PROFILE}.conf"
[[ -f "$DISTRO_CONF"  ]] || { echo "ERROR: unknown distro '${DISTRO}'" >&2; exit 1; }
[[ -f "$PROFILE_CONF" ]] || { echo "ERROR: unknown profile '${PROFILE}'" >&2; exit 1; }

# --------------------------------------------------------------------------- #
# Load configs to know the build chain
# --------------------------------------------------------------------------- #
# shellcheck source=/dev/null
source "$DISTRO_CONF"
# shellcheck source=/dev/null
source "$PROFILE_CONF"

PODMAN_FLAGS="--pull=newer"
$NO_CACHE && PODMAN_FLAGS="${PODMAN_FLAGS} --no-cache"

DATE_STAMP="$(date +%Y%m%d)"
IMAGE_NAME="${DISTRO}-${PROFILE}"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

# --------------------------------------------------------------------------- #
# Helper: build one image from a generated Containerfile
# --------------------------------------------------------------------------- #
build_image() {
  local distro="$1"
  local profile="$2"
  local image_ref="$3"

  echo ""
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║  Building: ${distro}-${profile}"
  echo "║  Image:    ${image_ref}"
  echo "╚══════════════════════════════════════════════════════╝"

  # Generate Containerfile
  gen_args=("--distro" "$distro" "--profile" "$profile"
            "--registry" "$REGISTRY" "--base-tag" "$TAG")
  [[ -n "$WEASIS_VER_OVERRIDE" ]] && gen_args+=("--weasis-version" "$WEASIS_VER_OVERRIDE")

  "${SCRIPT_DIR}/build/generate.sh" "${gen_args[@]}"

  local ctx="${SCRIPT_DIR}/generated/${distro}-${profile}"

  # podman build context is the generated dir; config files are referenced
  # via relative ../../images/... paths inside the Containerfile
  podman build ${PODMAN_FLAGS} \
    -t "${image_ref}" \
    -f "${ctx}/Containerfile" \
    "${SCRIPT_DIR}"

  echo "  ✓ Built ${image_ref}"
}

# --------------------------------------------------------------------------- #
# Determine which images to build (full dependency chain)
# --------------------------------------------------------------------------- #
declare -a BUILD_CHAIN=()

case "$PROFILE" in
  base)
    BUILD_CHAIN=("base")
    ;;
  workstation)
    BUILD_CHAIN=("base" "workstation")
    ;;
  medical)
    BUILD_CHAIN=("base" "workstation" "medical")
    ;;
  pacs-server)
    BUILD_CHAIN=("base" "pacs-server")
    ;;
  *)
    # Custom profile with INHERITS chain
    if [[ -n "${INHERITS:-}" ]]; then
      # Simple one-level inherit
      BUILD_CHAIN=("${INHERITS}" "$PROFILE")
    else
      BUILD_CHAIN=("$PROFILE")
    fi
    ;;
esac

# --------------------------------------------------------------------------- #
# Build bootstrap base image (if this distro needs one)
# --------------------------------------------------------------------------- #
if [[ -n "${BOOTSTRAP_CONTAINERFILE:-}" ]]; then
  BOOTSTRAP_TAG="${BASE_IMAGE}"   # e.g. localhost/ubuntu-bootc:24.04

  if podman image exists "$BOOTSTRAP_TAG" 2>/dev/null; then
    echo "==> Bootstrap image already present: ${BOOTSTRAP_TAG}"
  else
    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║  Building bootstrap bootc base"
    echo "║  From:  ${SCRIPT_DIR}/${BOOTSTRAP_CONTAINERFILE}"
    echo "║  Tag:   ${BOOTSTRAP_TAG}"
    echo "╚══════════════════════════════════════════════════════╝"
    podman build --pull=newer \
      -t "${BOOTSTRAP_TAG}" \
      "${SCRIPT_DIR}/$(dirname "$BOOTSTRAP_CONTAINERFILE")/"
    echo "  ✓ Bootstrap built: ${BOOTSTRAP_TAG}"
  fi
fi

# --------------------------------------------------------------------------- #
# Build the chain
# --------------------------------------------------------------------------- #
echo ""
echo "Build chain for ${DISTRO}/${PROFILE}:"
for step in "${BUILD_CHAIN[@]}"; do
  echo "  → ${REGISTRY}/${DISTRO}-${step}:${TAG}"
done
echo ""

for step in "${BUILD_CHAIN[@]}"; do
  build_image "$DISTRO" "$step" "${REGISTRY}/${DISTRO}-${step}:${TAG}"
done

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Host OS images built successfully                   ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# --------------------------------------------------------------------------- #
# Build Distrobox guest container images (if profile declares any)
# --------------------------------------------------------------------------- #
DISTROBOX_GUESTS="${DISTROBOX_GUESTS:-}"
_guest_list="$(echo "$DISTROBOX_GUESTS" | tr -s ' \n' ' ' | xargs)"

if [[ -n "$_guest_list" ]]; then
  echo "==> Building Distrobox guest container images..."
  for _guest_conf in $_guest_list; do
    _gcf="${SCRIPT_DIR}/config/guests/${_guest_conf}.conf"
    if [[ ! -f "$_gcf" ]]; then
      echo "WARNING: guest config not found: ${_gcf}" >&2
      continue
    fi
    # shellcheck source=/dev/null
    source "$_gcf"
    _guest_tag="${REGISTRY}/${GUEST_IMAGE_NAME}:${TAG}"

    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║  Guest container: ${GUEST_NAME}"
    echo "║  Image: ${_guest_tag}"
    echo "╚══════════════════════════════════════════════════════╝"

    podman build ${PODMAN_FLAGS} \
      -t "${_guest_tag}" \
      "${SCRIPT_DIR}/$(dirname "$GUEST_CONTAINERFILE")/"

    echo "  ✓ Guest built: ${_guest_tag}"
    unset GUEST_NAME GUEST_DESCRIPTION GUEST_CONTAINERFILE GUEST_IMAGE_NAME GUEST_INIT
  done
  echo ""
fi

# --------------------------------------------------------------------------- #
# Push
# --------------------------------------------------------------------------- #
if $PUSH; then
  echo "==> Pushing host OS images..."
  for step in "${BUILD_CHAIN[@]}"; do
    echo "    podman push ${REGISTRY}/${DISTRO}-${step}:${TAG}"
    podman push "${REGISTRY}/${DISTRO}-${step}:${TAG}"
  done

  # Also push guest images if any
  if [[ -n "$_guest_list" ]]; then
    echo "==> Pushing guest container images..."
    for _guest_conf in $_guest_list; do
      _gcf="${SCRIPT_DIR}/config/guests/${_guest_conf}.conf"
      [[ -f "$_gcf" ]] || continue
      source "$_gcf"
      podman push "${REGISTRY}/${GUEST_IMAGE_NAME}:${TAG}"
      unset GUEST_NAME GUEST_DESCRIPTION GUEST_CONTAINERFILE GUEST_IMAGE_NAME GUEST_INIT
    done
  fi

  echo "  ✓ All images pushed"
  echo ""
fi

# --------------------------------------------------------------------------- #
# ISO
# --------------------------------------------------------------------------- #
if $BUILD_ISO; then
  ISO_NAME="${DISTRO}-${DISTRO_VERSION}-${PROFILE}-${DATE_STAMP}"
  echo "==> Generating ISO: ${ISO_NAME}"
  "${SCRIPT_DIR}/build/build-iso.sh" \
    "$FULL_IMAGE" \
    --name "$ISO_NAME"
fi
