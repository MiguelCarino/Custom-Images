# Architecture — Build Flow Specification

Status: **binding spec** for the v1 build flow. Package manifests are deliberately
minimal starter sets; the full package/environment phase comes after the flow works.

---

## 1. Concept

Every image is a **chain of bootc layers**, each layer an OCI image built `FROM` its
parent:

```
quay.io/fedora/fedora-bootc:44          (upstream)
  └─ base                               hardening, common CLI tools
       └─ desktop-common                DE-agnostic desktop infrastructure
            └─ de/cosmic-hyprland       COSMIC + Hyprland sessions
                 └─ <purpose>           the published image
```

Each **purpose is pinned to exactly one DE** (a hard requirement — the pin encodes why
the combination works; unpinned combinations are unsupported). The published image name
is:

```
carino-<purpose>              e.g.  carino-gaming
```

Intermediate layer images are named `carino-layer-<layer-id>` and are build
infrastructure, not published artifacts.

## 2. Image catalog

| Image | Purpose | DE pin | Why the pin |
|---|---|---|---|
| `carino-general` | general | cosmic-hyprland | single supported session: COSMIC for pointer-driven use, Hyprland when tiling is wanted |
| `carino-imagenology` | imagenology | cosmic-hyprland | calibration is applied per-display with ArgyllCMS, not by the desktop |
| `carino-security` | security | cosmic-hyprland | no desktop automounter in the session, so removable evidence is never mounted on insertion |
| `carino-gaming` | gaming | cosmic-hyprland | tearing control + bakeable per-output VRR |
| `carino-music` | music | cosmic-hyprland | no file indexer; lowest overhead |
| `carino-llms` | llms | cosmic-hyprland | leanest session; least VRAM held by the desktop |

Only COSMIC + Hyprland is shipped: both sessions come from one layer and one greeter, so
the integration work is verified once and inherited by all six images. `DE` remains a
required field so adding a second desktop later stays a one-line change per purpose.

The catalog is **derived** by scanning `config/purposes/*.conf` — there is no separate
catalog file to fall out of sync.

## 3. Repository layout

```
├── build.sh                    # THE entry point (list | generate | build | iso | blueprint | clean)
├── Makefile                    # thin convenience wrapper over build.sh
├── lib/
│   └── common.sh               # shared functions (see §6)
├── tools/
│   ├── check-drift.sh          # purpose drift vs Carino Setup (see §11b)
│   └── purpose-apps/<purpose>.apps
├── config/
│   ├── build.conf              # global defaults: FEDORA_VERSION, REGISTRY, TAG, BASE_IMAGE
│   ├── layers/
│   │   ├── base.conf
│   │   ├── desktop-common.conf
│   │   └── de/
│   │       └── cosmic-hyprland.conf
│   └── purposes/
│       ├── general.conf        # each declares DE="<pin>"
│       ├── imagenology.conf
│       ├── security.conf
│       ├── gaming.conf
│       ├── music.conf
│       └── llms.conf
├── files/                      # static files COPYed into layers, mirrored by layer id
│   ├── base/                   #   layer dirs are created on demand; only desktop-common
│   │                           #   exists today. A dir maps to / — base/etc/… → /etc/…
│   ├── desktop-common/
│   ├── de/cosmic-hyprland/
│   └── purposes/<purpose>/
├── generated/                  # emitted Containerfiles + blueprints (gitignored)
│   └── <image-or-layer>/Containerfile
├── output/                     # ISOs (gitignored)
├── docs/                       # static website (GitHub Pages ready)
│   └── index.html
├── research/                   # repo-verified package research (input for the package phase)
├── legacy/                     # the pre-restructure system, kept for reference
├── ARCHITECTURE.md             # this file
└── SCOPE.md
```

## 4. Config file format

Plain bash, sourced. Every value optional unless marked required.

### Layer conf (`config/layers/**.conf`)

```bash
LAYER="desktop-common"          # required, unique id; de layers use "de/<name>"
DESCRIPTION="one line"          # required
PARENT="base"                   # required; layer id, or "" for the root layer
                                # (root layer builds FROM ${BASE_IMAGE})
PACKAGES="pkg1 pkg2 @group"     # dnf install set; @groups allowed
COPRS="owner/project ..."       # COPRs enabled before install (left enabled)
SERVICES_ENABLE="a.service ..." # systemctl enable
SERVICES_MASK="b.service ..."   # systemctl mask (how purposes silence inherited daemons)
KARGS="karg1 karg2"             # kernel args (see §7)
FLATPAKS="org.app.Id ..."       # installed on first boot, NOT at build time (see §8)
POST_SCRIPT="post.sh"           # optional, relative to files dir; runs as final RUN
```

### Purpose conf (`config/purposes/*.conf`)

Same fields, plus:

```bash
PURPOSE="gaming"                # required; must match filename
DE="cosmic-hyprland"            # required; must match a config/layers/de/<DE>.conf
PIN_REASON="one line"           # required; why this DE
```

`LAYER`/`PARENT` are **not** set in purpose confs — the parent is always the pinned DE
layer, derived. Files dir is `files/purposes/<PURPOSE>/`.

## 5. `build.sh` CLI

```
./build.sh list                          # catalog: image, DE, description, pin reason
./build.sh generate [IMAGE|all]          # emit Containerfiles (chain-aware)
./build.sh build    [IMAGE|all] [--push] # generate + podman build in dependency order
./build.sh iso      IMAGE                # bootc-image-builder → output/IMAGE/install.iso
./build.sh blueprint [IMAGE|all]         # emit osbuild blueprint TOML (experimental)
./build.sh clean                         # rm -rf generated/
```

Global flags (before or after the subcommand): `--registry R` `--tag T` `--no-cache`.
Defaults from `config/build.conf`. `IMAGE` accepts the full name
(`carino-gaming`) or the bare purpose (`gaming`).

Behavior requirements:
- `set -euo pipefail` everywhere; helpful errors (unknown image lists valid ones).
- `build all` builds each layer **once** in topological order (base → desktop-common →
  each needed DE → purposes); shared layers are never rebuilt per-purpose within a run.
- `--push` pushes only the six published images, not `carino-layer-*` intermediates.
- `iso` runs bootc-image-builder via `sudo podman run --privileged --rm
  -v ./output:/output -v /var/lib/containers/storage:/var/lib/containers/storage
  quay.io/centos-bootc/bootc-image-builder:latest --type iso --local <image-ref>`.

## 6. `lib/common.sh` interface (binding for all scripts)

```bash
info(), warn(), die()                    # logging; die exits 1
load_build_conf()                        # sources config/build.conf, applies env overrides
list_purposes()                          # -> purpose ids, one per line (from config/purposes/)
resolve_image()                          # $1 purpose-or-image-name -> echoes purpose id, dies if unknown
image_name()                             # $1 purpose id -> fedora-<purpose>-<de>
layer_chain()                            # $1 purpose id -> ordered layer ids root-first,
                                         #   e.g. "base desktop-common de/cosmic-hyprland purpose:general"
layer_slug()                             # $1 layer id -> filesystem/image-name-safe form
                                         #   e.g. de/cosmic-hyprland -> de-cosmic-hyprland
layer_image_ref()                        # $1 layer id -> full image ref for FROM/-t
load_layer_conf()                        # $1 layer id or purpose:<id> -> sources the conf,
                                         #   normalizes vars, sets FILES_DIR
```

## 7. Kernel arguments

Emitted as `/usr/lib/bootc/kargs.d/<slot>-<name>.toml` containing `kargs = [...]`.
Slots are **assigned by layer kind** so two layers can never collide:

| Slot | Layer kind |
|---|---|
| 10 | base |
| 20 | desktop-common |
| 30 | DE layers |
| 40 | purpose layers |

## 8. Flatpaks — first boot, never build time

`RUN flatpak install` inside a container build is unreliable (no session bus, no
network guarantees). Instead:

- The generator writes each layer's `FLATPAKS` to
  `/usr/share/fedora-images/flatpaks.d/<slot>-<name>.list` (one app id per line).
- `desktop-common` ships (via its `files/` dir) a oneshot
  `flatpak-setup.service` + script: on first boot with network, add Flathub and install
  every id under `flatpaks.d/`, then stamp `/var/lib/fedora-images/.flatpaks-done`.

## 9. Generated Containerfile shape

One per layer, `generated/<layer-or-image-name>/Containerfile`:

```
# header comment: generated-by, layer, chain position, regen command
FROM <parent ref>
LABEL org.opencontainers.image.title=... description=...
# COPRs (if any):        RUN dnf -y copr enable ...
# Packages (if any):     RUN dnf -y install ... && dnf clean all
# Files (if files dir):  COPY files-root/ /      (build context trick, see below)
# Services:              RUN systemctl enable ...  / systemctl mask ...
# Kargs:                 written via COPY or heredoc into /usr/lib/bootc/kargs.d/
# Flatpak list:          written into /usr/share/fedora-images/flatpaks.d/
# Post script:           RUN /tmp/post.sh (copied, run, removed)
# Final line:            RUN bootc container lint
```

**Build context rule (fixes the legacy bug):** every layer builds with its **own
files dir as context** — `podman build -f generated/<x>/Containerfile files/<x>/`
(or an empty stub context when the layer has no files). `COPY` paths are always
context-relative; `../../` escapes are forbidden.

## 10. osbuild blueprint emitter (experimental)

`build.sh blueprint IMAGE` flattens the image's full chain (packages, services, kargs)
into a single osbuild blueprint TOML at `generated/<image>/blueprint.toml` — the
traditional-Workstation backend. Marked experimental; ISO production for this backend is
a later phase, so the blueprint is currently an **export**, not a build path: hand it to
`composer-cli` yourself.

A blueprint is a **lossy** copy of the image, never an equivalent. Everything it cannot
carry is reported twice — in the TOML header and as a `warn` on the terminal — so a
thinner blueprint is never mistaken for a clean generate:

| Mechanism | Blueprint behaviour |
|---|---|
| `COPRS` | listed as unresolved; the repo must be configured host-side or the depsolve fails |
| `FLATPAKS` | dropped (first-boot mechanism, §8) |
| `FILES_DIR` static files | dropped — the classic image will not contain them |
| `POST_SCRIPT` | dropped |
| `SERVICES_ENABLE` naming a unit that only ships in `FILES_DIR` | **omitted** from `enabled` |

That last row is a correctness requirement, not a preference: osbuild runs
`systemctl enable` during the build, and a missing unit fails the whole build. Emitting
the enable would produce a blueprint that cannot build at all, so the name is omitted and
listed in the header for re-adding once the unit is provisioned host-side. Units that
come from packages (`gdm.service`, `tuned.service`, `ollama.service`, …) are unaffected —
only units the layer mirrors in itself are omitted.

## 11. Starter package sets (this phase only)

Purpose and layer confs ship a **small starter set** (roughly 5–15 packages) drawn only
from names already verified in `research/manifest-*.json`. Full manifests, integration
files, udev rules, PipeWire configs etc. land in the package phase. Two integration
examples are wired now to prove the mechanisms end to end:

- `gaming`: `KARGS="split_lock_detect=off"`
- `music`: `KARGS="threadirqs"` and `SERVICES_MASK="power-profiles-daemon.service"`

## 11b. Purpose drift check (against Carino Setup)

Several purposes exist in both this project and [Carino Setup](https://setup.carino.systems/),
which configures an already-installed system across ~40 distros plus Windows and macOS. The
two deliver the same purpose by deliberately different means — Setup reaches for Flatpak
wherever a package name is not portable, this project puts things in `/usr` as RPMs — so
comparing package names would flag correct decisions as errors.

`tools/check-drift.sh PURPOSE` compares at the **application** level instead, against an
explicit manifest in `tools/purpose-apps/<purpose>.apps`. "Medical Imaging includes a DICOM
viewer" is a fact about the purpose; "it arrives as `io.github.nroduit.Weasis`" is a fact
about the delivery target. Only the first is shared.

| Report | Meaning |
|---|---|
| `MISSING` | an app the manifest marks `both`, present on one side only |
| `UNEXPECTED` | an app declared one-sided that has turned up on the other side |
| `UNMAPPED` | a package or flatpak either project ships that no manifest row claims |

`UNMAPPED` is what stops the manifest going stale: adding a package to either side without
recording it in the manifest is itself a violation. Each manifest row carries the token each
side *would* use even when that side does not ship it yet, so a row flips to clean the moment
the gap is closed rather than reporting forever.

Setup lives outside this repo; point `CARINO_SETUP` at it, or leave it beside this checkout
as `../SimpleSetup`. If it is not found the check **skips loudly and exits 2** — a comparison
that could not run must never read as a pass. Default output is a report (exit 0); `--strict`
exits non-zero, which is how it should be wired once the package phase in §11 lands.

Only `imagenology` has a manifest today. It currently reports four missing viewers
(Weasis, Aliza MS, InVesalius, xmedcon): the image ships the DICOM toolchain but nothing to
look at a study with. That is scheduled §11 work, not an oversight, and it is left as a
visible violation on purpose.

## 11c. Reference check

`tools/check-refs.sh` validates that the repo's cross-references still resolve. Docs and code
point at each other constantly — `ARCHITECTURE.md` §10, `config/purposes/`, the §6 interface —
and those references rot silently: a renamed image or a resectioned spec leaves prose that
still reads fine and is simply wrong.

| Report | Meaning |
|---|---|
| `SECTION` | `DOC.md` §N where DOC.md defines no section N |
| `SELF` | a bare §N inside a `.md` that the same file does not define |
| `PATH` | a repo-relative path named in prose that does not exist |
| `IFACE` | §6's documented interface vs the functions `lib/common.sh` defines, both directions |

`legacy/` and `generated/` are excluded — the first is a frozen archive whose references
describe the world as it was, the second is regenerated output. Default output is a report
(exit 0); `--strict` exits non-zero. Run with `make refs`.

## 12. Update model (what users get)

- Installed systems track their image: `bootc upgrade` (staged, applied on reboot),
  `bootc switch <ref>` to move between purposes, `bootc rollback` to revert.
- Any existing Fedora bootc/Atomic install can adopt an image with `bootc switch` —
  the ISO is only for bare-metal first installs.
```
