# Fedora Custom Images

Modular, atomic, bootc-based Fedora OS images for any purpose.

## Overview

This project produces bootable Fedora OS images using **[bootc](https://containers.github.io/bootc/)** — a technology that treats the operating system like a container image. The result is a system that is:

- **Atomic** — updates apply completely or not at all (no partial upgrades)
- **Image-based** — the OS is a versioned OCI container image stored in a registry
- **Rollback-capable** — `bootc rollback` reverts to the previous deployment
- **Declarative** — everything is defined in a `Containerfile`

## Image hierarchy

```
quay.io/fedora/fedora-bootc:41   ← upstream base
        │
        ▼
  fedora-base          (security hardening, SSH, common tools, RPM Fusion)
        │
        ├──▶ fedora-workstation           (GNOME, Flatpak, Podman, fonts)
        │           │
        │           └──▶ fedora-medical-workstation   (Weasis, DCMTK, LibreOffice, GDCM)
        │
        └──▶ fedora-pacs-server           (Orthanc, PostgreSQL, Nginx TLS)
```

## Quick start

### Requirements

- Podman ≥ 4.9
- GNU make
- A container registry (Quay.io, GHCR, local registry, …)

### Build all images

```bash
# Build locally
make build-all

# Build and push to a registry
make push REGISTRY=quay.io/myorg TAG=latest
```

### Build a single image

```bash
./build/build-image.sh medical-workstation REGISTRY=quay.io/myorg
```

### Generate a bootable ISO

```bash
make iso IMAGE=fedora-medical-workstation REGISTRY=quay.io/myorg
# output: ./output/quay.io---myorg---fedora-medical-workstation---latest.iso
```

Write the ISO to USB:
```bash
sudo dd if=output/*.iso of=/dev/sdX bs=4M status=progress && sync
```

### Update a running host

On a host already running a bootc image:
```bash
# Stage the update (applied on next reboot)
sudo bootc upgrade

# Or switch to a different image
sudo bootc switch quay.io/myorg/fedora-medical-workstation:latest

# Then reboot
sudo systemctl reboot

# Rollback if something goes wrong (before next reboot clears the old deployment)
sudo bootc rollback
```

## Images

### `fedora-base`

Minimal hardened foundation:
- RPM Fusion free + nonfree
- SSH daemon (key auth only, root login disabled)
- SELinux enforcing
- firewalld
- bootc auto-update timer

### `fedora-workstation`

General-purpose GNOME desktop:
- GNOME on Wayland
- Flatpak + Flathub
- Podman, Buildah, Distrobox
- Multimedia codecs (FFmpeg, GStreamer)
- Full font stack including CJK

### `fedora-medical-workstation`

Radiology / medical imagenology workstation — see [docs/medical-workstation.md](docs/medical-workstation.md).

| Package | Purpose |
|---------|---------|
| [Weasis](https://weasis.org) | DICOM viewer (2D/3D, multi-format) |
| [DCMTK](https://dicom.offis.de/dcmtk) | DICOM toolkit (C-STORE, C-FIND, C-MOVE …) |
| [GDCM](http://gdcm.sourceforge.net) | Grassroots DICOM library + CLI |
| LibreOffice | Reports and office documents |
| python3-pydicom | DICOM scripting |
| SimpleITK | Medical image analysis |
| pynetdicom | Pure-Python DICOM networking |

### `fedora-pacs-server`

Headless PACS server:
- [Orthanc](https://www.orthanc-server.com/) DICOM server with DICOMweb plugin
- PostgreSQL for the Orthanc index
- Nginx TLS reverse proxy
- Certbot for Let's Encrypt certificates
- DCMTK for diagnostics

## Customisation

### Add packages to an image

Edit the relevant `Containerfile` and add packages to the `dnf install` block. Then rebuild:

```bash
make build-medical-workstation REGISTRY=quay.io/myorg
```

### Override configuration at deploy time

Configuration files in `/etc` are part of the image but can be overridden by placing files in `/etc` on the running host before updating. bootc uses a three-way merge between the base image, the previous deployment, and the new image.

### Add a new image variant

1. Create `images/<my-variant>/Containerfile` based on any existing image.
2. Add a `build-<my-variant>` target to the `Makefile`.
3. Build with `make build-<my-variant>`.

## Bootc concepts

| Concept | Explanation |
|---------|------------|
| `bootc switch <ref>` | Replace the OS image (staged, needs reboot) |
| `bootc upgrade` | Pull and stage the latest tag of the current image |
| `bootc rollback` | Revert to the previous deployment |
| `bootc status` | Show current and pending deployments |
| `bootc install` | Install bootc onto bare metal from inside a container |

## References

- [Fedora bootc documentation](https://docs.fedoraproject.org/en-US/bootc/)
- [bootc project](https://containers.github.io/bootc/)
- [bootc-image-builder](https://github.com/osbuild/bootc-image-builder)
- [Weasis DICOM viewer](https://weasis.org)
- [Orthanc PACS server](https://www.orthanc-server.com/)
- [DCMTK](https://dicom.offis.de/dcmtk)
