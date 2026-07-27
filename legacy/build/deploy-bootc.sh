#!/usr/bin/env bash
# =============================================================================
# deploy-bootc.sh — Switch a running bootc host to a new image
#
# Run ON the target host (must already be running a bootc/ostree system).
#
# Usage:
#   ./deploy-bootc.sh <image-ref> [--reboot]
#
# Example:
#   ./deploy-bootc.sh quay.io/myorg/fedora-medical-workstation:latest --reboot
# =============================================================================
set -euo pipefail

IMAGE="${1:?Usage: $0 <image-ref> [--reboot]}"
REBOOT=false
[[ "${2:-}" == "--reboot" ]] && REBOOT=true

# Verify bootc is available
if ! command -v bootc &>/dev/null; then
  echo "ERROR: bootc not found. This host is not a bootc system."
  exit 1
fi

echo "==> Switching to image: ${IMAGE}"
sudo bootc switch "$IMAGE"

echo "==> Switch staged. Changes take effect on next reboot."
bootc status

if $REBOOT; then
  echo "==> Rebooting in 5 seconds (Ctrl-C to cancel)..."
  sleep 5
  sudo systemctl reboot
fi
