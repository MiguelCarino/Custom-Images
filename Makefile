# Makefile — thin convenience wrapper over ./build.sh (the real entry point).
#
#   make list                 # show the image catalog
#   make generate             # emit all Containerfiles
#   make build                # build every image (shared layers built once)
#   make push                 # build + push the published images
#   make iso-<image>          # e.g. make iso-gaming  or  make iso-fedora-gaming-cosmic-hyprland
#   make clean                # remove generated/
#   make drift                # compare a purpose against Carino Setup (PURPOSE=imagenology)
#   make refs                 # validate cross-references between docs and code
#
# Variables forwarded to build.sh:
#   make build REGISTRY=quay.io/me TAG=testing

REGISTRY ?=
TAG ?=

FLAGS :=
ifneq ($(strip $(REGISTRY)),)
FLAGS += --registry $(REGISTRY)
endif
ifneq ($(strip $(TAG)),)
FLAGS += --tag $(TAG)
endif

.PHONY: list generate build push clean drift refs

list:
	./build.sh list

generate:
	./build.sh generate all $(FLAGS)

build:
	./build.sh build all $(FLAGS)

push:
	./build.sh build all --push $(FLAGS)

iso-%:
	./build.sh iso $* $(FLAGS)

clean:
	./build.sh clean

PURPOSE ?= imagenology
drift:
	./tools/check-drift.sh $(PURPOSE)

refs:
	./tools/check-refs.sh
