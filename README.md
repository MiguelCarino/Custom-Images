# Fedora Custom Images

Purpose-built **atomic Fedora** images on [bootc](https://containers.github.io/bootc/).
Each image ships a complete OS — kernel, desktop, and the integration a specific kind of
work needs — as a single OCI image, with transactional updates (`bootc upgrade`) and
one-command rollback (`bootc rollback`).

Every purpose is **pinned to exactly one desktop environment**; the pin records why the
combination works, and unpinned combinations are unsupported. Only COSMIC + Hyprland is
shipped — both sessions come from one layer and one greeter, so the integration work is
verified once and inherited by every image.

## Image catalog

| Image | Purpose | DE pin | Why the pin |
|---|---|---|---|
| `carino-general` | general | cosmic-hyprland | single supported session: COSMIC for pointer-driven use, Hyprland when tiling is wanted |
| `carino-imagenology` | imagenology | cosmic-hyprland | calibration is applied per-display with ArgyllCMS, not by the desktop |
| `carino-security` | security | cosmic-hyprland | no desktop automounter in the session, so removable evidence is never mounted on insertion |
| `carino-gaming` | gaming | cosmic-hyprland | tearing control + bakeable per-output VRR |
| `carino-music` | music | cosmic-hyprland | no file indexer; lowest overhead |
| `carino-llms` | llms | cosmic-hyprland | leanest session; least VRAM held by the desktop |

The catalog is derived by scanning `config/purposes/*.conf` — there is no separate
catalog file to fall out of sync.

## Quickstart

Requires bash and podman (ISO builds additionally need `sudo`).

```bash
./build.sh list                          # catalog: image, DE, description, pin reason
./build.sh generate all                  # emit Containerfiles (chain-aware)
./build.sh build gaming                  # build one image (bare purpose or full name)
./build.sh build all --push              # build everything; push the six published images
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
