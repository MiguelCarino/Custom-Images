# Fedora Custom Images

Purpose-built **atomic Fedora** images on [bootc](https://containers.github.io/bootc/).
Each image ships a complete OS — kernel, desktop, and the integration a specific kind of
work needs — as a single OCI image, with transactional updates (`bootc upgrade`) and
one-command rollback (`bootc rollback`).

Every purpose is **pinned to exactly one session**; the pin records why the combination
works, and unpinned combinations are unsupported. Only COSMIC + Hyprland is shipped as a
desktop — both sessions come from one layer and one greeter, so the integration work is
verified once and inherited by every desktop image. Two images are appliances rather than
workstations and pin `headless`: `carino-pbx` and `carino-offline` branch off `base` and
inherit no desktop stack whatsoever.

## Image catalog

| Image | Purpose | DE pin | Why the pin |
|---|---|---|---|
| `carino-general` | general | cosmic-hyprland | single supported session: COSMIC for pointer-driven use, Hyprland when tiling is wanted |
| `carino-imagenology` | imagenology | cosmic-hyprland | calibration is applied per-display with ArgyllCMS, not by the desktop |
| `carino-security` | security | cosmic-hyprland | no desktop automounter in the session, so removable evidence is never mounted on insertion |
| `carino-gaming` | gaming | cosmic-hyprland | tearing control + bakeable per-output VRR |
| `carino-music` | music | cosmic-hyprland | no file indexer; lowest overhead |
| `carino-llms` | llms | cosmic-hyprland | leanest session; least VRAM held by the desktop |
| `carino-pbx` | pbx | headless | an appliance administered over the network: the interfaces are the web UI and SSH, so a desktop would only add attack surface, RAM and packages to patch |
| `carino-offline` | offline | headless | an appliance that has to answer on the LAN's own ports before anything else on the network is up: DNS, NTP and HTTP are its interfaces and SSH is its console, so a desktop would only add attack surface, RAM and packages to patch to the one box the network cannot lose |

The catalog is derived by scanning `config/purposes/*.conf` — there is no separate
catalog file to fall out of sync.

`carino-pbx` is Asterisk with the **FreePBX 17** web UI, MariaDB, Apache and the PHP 8.2
runtime FreePBX requires. The OS and that runtime update transactionally like every other
image; FreePBX itself is installed on first boot (it writes to `/var`, which a bootc
image cannot carry across upgrades) and updates itself with `fwconsole ma upgradeall`.
See `research/manifest-pbx.json` for what was verified and what is still untested.

`carino-offline` is an **intranet keystone appliance: authoritative and recursive DNS, LAN
time, internal-CA trust store, an RPM mirror and offline content over HTTP, and the
sneakernet media pipeline** — 18 packages around bind, chrony, Caddy and kiwix-serve, plus
the optical-media tooling a courier's disc needs. It is the box that answers names, time,
trust and packages for a LAN with no WAN. It is deliberately not a workstation: there is no
desktop, no session and no Flatpak mechanism on this branch. It is also deliberately not
the router — DHCP, routing and VLANs stay on the network's router, because a service layer is
only worth layering if one box dying does not take the network with it. What makes it an
image rather than a package list is the system integration: port 53 has to be taken away
from `systemd-resolved` by masking (it is preset-enabled on the base, so `systemctl
disable` does not survive a preset re-run), `/etc/resolv.conf` has to be re-owned in the
same breath or the appliance is left with no resolver at all, an internal CA needs a place
in the trust store where a site root actually lands, `dnf` has to be pointable at a LAN
mirror without deadlocking the box's own package tooling, and chrony has to keep serving
time with nothing upstream reachable. The plan this image serves — a whole offline site, of
which this is one box — is at <https://offline.carino.systems>. Nothing in it has been
booted; `research/manifest-offline.json` records what was verified, how, and what is
therefore still a claim.

## Quickstart

Requires bash and podman (ISO builds additionally need `sudo`).

```bash
./build.sh list                          # catalog: image, DE, description, pin reason
./build.sh generate all                  # emit Containerfiles (chain-aware)
./build.sh build gaming                  # build one image (bare purpose or full name)
./build.sh build all --push              # build everything; push the published images
./build.sh iso carino-gaming   # installer ISO → output/IMAGE/install.iso ('all' for every image)
```

Already on a Fedora bootc/Atomic install? Adopt an image in place — no reinstall:

```bash
sudo bootc switch <ref>      # registry refs coming soon; ISO is only for bare-metal first installs
```

## Documentation

- **[Website](docs/index.html)** — catalog, how it works, get started, FAQ (GitHub Pages ready from `docs/`)
- **[ARCHITECTURE.md](ARCHITECTURE.md)** — binding spec for the build flow
- **[SCOPE.md](SCOPE.md)** — project scope, research findings, open decisions
- **[SimpleSetup](https://github.com/MiguelCarino/SimpleSetup)** — companion project: post-install setup for other distros and DEs

## Licensing

**Mine — GNU Affero General Public License v3.0 or later.** The build tooling
(`build.sh`, `lib/`), the layer and purpose configuration (`config/`), the files
baked into the images (`files/`), the generated Containerfiles, `tools/` and the
website under `docs/`. Copyright © 2026 Miguel Carino. Full terms in
[LICENSE](LICENSE).

**Not mine.** This project's licence does not cover, and could not cover, the
following. Each keeps its own terms.

| Path / artefact | What it is | Licence | Notice |
| --- | --- | --- | --- |
| [`docs/fonts/`](docs/fonts/) | IBM Plex Sans, IBM Plex Mono, Red Hat Display | SIL OFL 1.1 | [`docs/fonts/OFL.txt`](docs/fonts/OFL.txt) |
| **The images this tooling builds** | Fedora bootc base + the packages each purpose installs | Per package — Fedora's licences, incl. GPL-family | [LICENSING.md](LICENSING.md) |

An image *built* by this tooling is not a derived work of it: it is an
aggregation of Fedora packages with a few configuration files. Building one for
yourself triggers no obligation at all.

**Publishing an ISO or pushing an image to a registry is distribution**, and the
GPL-family components inside the images — Asterisk and FreePBX in `carino-pbx`,
ArgyllCMS in `carino-imagenology`, kiwix-tools in `carino-offline`, plus MariaDB,
httpd and PHP — carry source
obligations that become yours at that moment. This is satisfiable the ordinary
way, and [LICENSING.md](LICENSING.md) sets out how, along with the one trap to
avoid: install Fedora's stock packages and Fedora remains the distributor of
their source; rebuild or patch a package and you do not.

**Read [LICENSING.md](LICENSING.md) before your first public release.**
