# Fedora Custom Images

Purpose-built **atomic Fedora** images on [bootc](https://containers.github.io/bootc/).
Each image ships a complete OS — kernel, desktop, and the integration a specific kind of
work needs — as a single OCI image, with transactional updates (`bootc upgrade`) and
one-command rollback (`bootc rollback`).

Every purpose is **pinned to exactly one session**; the pin records why the combination
works, and unpinned combinations are unsupported. Only COSMIC + Hyprland is shipped as a
desktop — both sessions come from one layer and one greeter, so the integration work is
verified once and inherited by every desktop image. `carino-pbx` is an appliance and pins
`headless`: it branches off `base` and inherits no desktop stack whatsoever.

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

The catalog is derived by scanning `config/purposes/*.conf` — there is no separate
catalog file to fall out of sync.

`carino-pbx` is Asterisk with the **FreePBX 17** web UI, MariaDB, Apache and the PHP 8.2
runtime FreePBX requires. The OS and that runtime update transactionally like every other
image; FreePBX itself is installed on first boot (it writes to `/var`, which a bootc
image cannot carry across upgrades) and updates itself with `fwconsole ma upgradeall`.
See `research/manifest-pbx.json` for what was verified and what is still untested.

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

## License

Not yet chosen.
