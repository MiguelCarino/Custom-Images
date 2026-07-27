#!/usr/bin/env bash
# =============================================================================
# build-image.sh — Build a single named image
#
# Wraps the Makefile targets for convenience in CI or manual runs.
#
# Usage:
#   ./build/build-image.sh <target> [REGISTRY=...] [TAG=...] [WEASIS_VER=...]
#
# Targets: base | workstation | medical-workstation | pacs-server | all
# =============================================================================
set -euo pipefail

TARGET="${1:?Usage: $0 <target> [VAR=value …]}"
shift

# Forward remaining args as make variables
make "build-${TARGET}" "$@"
