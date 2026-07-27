# =============================================================================
# fedora-custom-images — Makefile
# =============================================================================
#
# ── Quick start (recommended) ────────────────────────────────────────────────
#   ./build.sh fedora medical                     Build Fedora medical workstation
#   ./build.sh fedora medical --iso               Build + ISO
#   ./build.sh ubuntu workstation --iso           Build Ubuntu workstation + ISO
#   ./build.sh --list                             List distros and profiles
#
# ── Makefile targets (Fedora only, for CI / backward compatibility) ──────────
#   make build-all                  Build all Fedora images
#   make build-base                 Build fedora-base
#   make build-workstation          Build fedora-workstation
#   make build-medical              Build fedora-medical
#   make build-pacs-server          Build fedora-pacs-server
#   make push   REGISTRY=<reg>      Push all Fedora images
#   make iso    DISTRO=fedora PROFILE=medical  Build named ISO
#   make clean  [DISTRO=fedora]     Remove images
# =============================================================================

REGISTRY     ?= localhost
TAG          ?= latest
DISTRO       ?= fedora
PROFILE      ?= medical

# Fedora-specific convenience aliases
FEDORA_BASE    := $(REGISTRY)/fedora-base:$(TAG)
FEDORA_WS      := $(REGISTRY)/fedora-workstation:$(TAG)
FEDORA_MEDICAL := $(REGISTRY)/fedora-medical:$(TAG)
FEDORA_PACS    := $(REGISTRY)/fedora-pacs-server:$(TAG)

.PHONY: all help \
        build-all build-base build-workstation build-medical build-pacs-server \
        push iso clean \
        list

all: help

help:
	@echo ""
	@echo "  Custom OS Images — build targets"
	@echo "  ================================="
	@echo ""
	@echo "  Recommended: use build.sh for full multi-distro support"
	@echo "    ./build.sh fedora medical --iso"
	@echo "    ./build.sh ubuntu workstation"
	@echo "    ./build.sh --list"
	@echo ""
	@echo "  Makefile targets (Fedora, for CI / quick runs):"
	@echo "    build-base            Build fedora-base"
	@echo "    build-workstation     Build fedora-workstation"
	@echo "    build-medical         Build fedora-medical"
	@echo "    build-pacs-server     Build fedora-pacs-server"
	@echo "    build-all             Build all four above"
	@echo "    push  REGISTRY=<reg>  Push all Fedora images"
	@echo "    iso   DISTRO=<d> PROFILE=<p>  Build named ISO"
	@echo "    list                  List distros and profiles"
	@echo "    clean                 Remove local Fedora images"
	@echo ""
	@echo "  Variables (current values):"
	@echo "    REGISTRY = $(REGISTRY)"
	@echo "    TAG      = $(TAG)"
	@echo "    DISTRO   = $(DISTRO)"
	@echo "    PROFILE  = $(PROFILE)"
	@echo ""

list:
	@./build.sh --list

# ---------------------------------------------------------------------------
# Fedora build targets (use build.sh under the hood for consistency)
# ---------------------------------------------------------------------------

build-base:
	./build.sh fedora base --registry $(REGISTRY) --tag $(TAG)

build-workstation:
	./build.sh fedora workstation --registry $(REGISTRY) --tag $(TAG)

build-medical:
	./build.sh fedora medical --registry $(REGISTRY) --tag $(TAG)

build-pacs-server:
	./build.sh fedora pacs-server --registry $(REGISTRY) --tag $(TAG)

build-all: build-base build-workstation build-medical build-pacs-server
	@echo ""
	@podman images | grep -E "$(REGISTRY)/fedora-(base|workstation|medical|pacs-server)" || true

# ---------------------------------------------------------------------------
# Push to registry (builds first)
# ---------------------------------------------------------------------------

push:
	./build.sh fedora base        --registry $(REGISTRY) --tag $(TAG) --push
	./build.sh fedora workstation --registry $(REGISTRY) --tag $(TAG) --push
	./build.sh fedora medical     --registry $(REGISTRY) --tag $(TAG) --push
	./build.sh fedora pacs-server --registry $(REGISTRY) --tag $(TAG) --push

# ---------------------------------------------------------------------------
# Build a named bootable ISO
# Usage:
#   make iso                                  → fedora-medical ISO
#   make iso DISTRO=ubuntu PROFILE=workstation
# ---------------------------------------------------------------------------

iso:
	./build.sh $(DISTRO) $(PROFILE) --registry $(REGISTRY) --tag $(TAG) --iso

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

clean:
	-podman rmi $(FEDORA_PACS) $(FEDORA_MEDICAL) $(FEDORA_WS) $(FEDORA_BASE) \
	  2>/dev/null || true
