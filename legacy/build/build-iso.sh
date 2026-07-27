#!/usr/bin/env bash
# =============================================================================
# build-iso.sh — Build a named bootable ISO from a bootc container image
#
# Usage:
#   ./build/build-iso.sh <image-ref> [--name <iso-name>]
#
# Examples:
#   ./build/build-iso.sh quay.io/carino/fedora-medical:latest \
#       --name fedora-43-medical-2026-03-20
#
#   # Called automatically by build.sh --iso (name is set there)
#
# Output:
#   output/<iso-name>/bootiso/install.iso
#
# NOTE: bootc-image-builder runs as root (sudo podman) and uses root's
# container storage (/var/lib/containers/storage), which is separate from
# the current user's storage. This script copies the image there first.
# =============================================================================
set -euo pipefail

IMAGE="${1:?Usage: $0 <image-ref> [--name <iso-name>]}"
shift

ISO_NAME=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) ISO_NAME="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Default name from image ref + date
if [[ -z "$ISO_NAME" ]]; then
  ISO_NAME="$(echo "$IMAGE" | tr '/: ' '---')-$(date +%Y%m%d)"
fi

OUTPUT_DIR="$(pwd)/output/${ISO_NAME}"
mkdir -p "$OUTPUT_DIR"

echo ""
echo "==> Image:   ${IMAGE}"
echo "==> ISO name: ${ISO_NAME}"
echo "==> Output:  ${OUTPUT_DIR}/bootiso/install.iso"
echo ""

# ---------------------------------------------------------------------------
# Copy image from current user's podman storage into root's storage.
# bootc-image-builder cannot see the user store because it runs as root.
# ---------------------------------------------------------------------------
echo "==> Copying image to root container storage..."
if podman image scp "${IMAGE}" root@localhost:: 2>/dev/null; then
  echo "    (image scp succeeded)"
else
  echo "    (image scp unavailable — falling back to save/load)"
  podman save "${IMAGE}" | sudo podman load
fi

# ---------------------------------------------------------------------------
# Run bootc-image-builder
# Docs: https://github.com/osbuild/bootc-image-builder
# ---------------------------------------------------------------------------
echo ""
echo "==> Running bootc-image-builder..."
sudo podman run \
  --rm \
  --privileged \
  --pull=newer \
  --security-opt label=type:unconfined_t \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v "${OUTPUT_DIR}:/output" \
  quay.io/centos-bootc/bootc-image-builder:latest \
    --type iso \
    --rootfs xfs \
    --output /output \
    "${IMAGE}"

ISO_PATH="${OUTPUT_DIR}/bootiso/install.iso"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  ISO built successfully                              ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  Name: ${ISO_NAME}"
echo "  Path: ${ISO_PATH}"
echo "  Size: $(du -sh "${ISO_PATH}" 2>/dev/null | cut -f1 || echo 'unknown')"
echo ""
echo "  Write to USB:"
echo "    sudo dd if='${ISO_PATH}' of=/dev/sdX bs=4M status=progress && sync"
echo ""
