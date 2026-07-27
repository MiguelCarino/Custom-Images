# Fedora Host + Guest Container Model

## The core idea

The ISO that boots on your hardware always runs **Fedora** as the host OS.
Ubuntu and Debian environments run as **Distrobox guest containers** on top of it.

```
┌────────────────────────────────────────────────────────────┐
│  BARE METAL  (boots the ISO)                               │
├────────────────────────────────────────────────────────────┤
│  Fedora Silverblue bootc  ← HOST OS (always Fedora)        │
│  ├── System tools: dcmtk, gdcm, podman, distrobox          │
│  └── Flatpaks: LibreOffice, browsers, etc.                 │
├──────────────────────┬─────────────────────────────────────┤
│  Distrobox guest     │  Distrobox guest                    │
│  ubuntu-medical      │  debian-medical                     │
│  (Ubuntu 24.04)      │  (Debian 13)                        │
│  + weasis .deb       │  + weasis .deb                      │
│  + ubuntu packages   │  + debian packages                  │
│                      │                                     │
│  GUI apps appear on the host Wayland desktop automatically  │
└──────────────────────┴─────────────────────────────────────┘
```

## Why this approach

| Concern | Answer |
|---------|--------|
| Only one OS to maintain | ✓ Fedora bootc — one image, atomic updates |
| Need Ubuntu/Debian-only packages | ✓ Run in a guest container |
| GUI apps still work | ✓ Distrobox shares display, audio, printers |
| Home directory | ✓ Shared with host — files are the same |
| Can run `weasis` from the desktop | ✓ `distrobox-export --app weasis` adds it to GNOME launcher |
| No VM overhead | ✓ Distrobox uses container namespaces — near-native performance |

## How to enable guest containers

In `config/profiles/medical.conf`, uncomment:

```bash
DISTROBOX_GUESTS="\
  ubuntu-24.04-medical \
  debian-13-medical \
"
```

Then build:

```bash
./build.sh fedora-silverblue medical --iso --push REGISTRY=quay.io/myorg
```

This builds:
1. `fedora-silverblue-base`
2. `fedora-silverblue-workstation`
3. `fedora-silverblue-medical`  ← bootc ISO image
4. `ubuntu-24.04-medical`       ← guest container image
5. `debian-13-medical`          ← guest container image

## Adding your own guest container

### Step 1 — create the guest Containerfile

```
images/app-containers/my-ubuntu-lab/Containerfile
```

```dockerfile
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
      my-ubuntu-package-1 \
      my-ubuntu-package-2 \
      sudo bash-completion xdg-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
```

### Step 2 — create the guest config

```
config/guests/my-ubuntu-lab.conf
```

```bash
GUEST_NAME="my-ubuntu-lab"
GUEST_DESCRIPTION="My Ubuntu lab environment"
GUEST_CONTAINERFILE="images/app-containers/my-ubuntu-lab/Containerfile"
GUEST_IMAGE_NAME="my-ubuntu-lab"
GUEST_INIT=false
```

### Step 3 — add to a profile

In `config/profiles/<your-profile>.conf`:

```bash
DISTROBOX_GUESTS="\
  my-ubuntu-lab \
"
```

### Step 4 — build

```bash
./build.sh fedora-silverblue my-profile --iso
```

## First boot experience

On first boot of the installed Fedora system:

1. `distrobox-prefetch-guests.service` runs — pulls guest images from registry
2. Users set up their containers (one-time, per user):

   ```bash
   # Create containers from the pre-pulled images
   distrobox assemble create --file /etc/distrobox/medical-guests.ini

   # Enter a guest and export apps to the host desktop
   distrobox enter ubuntu-medical
   distrobox-export --app weasis
   distrobox-export --app libreoffice
   exit
   ```

3. Weasis and LibreOffice now appear in the GNOME application launcher, running transparently inside their Ubuntu container.

## Day-to-day use

```bash
# Launch an app directly (no need to "enter" the container)
distrobox run --name ubuntu-medical -- weasis

# Or enter the container shell
distrobox enter ubuntu-medical

# Update guest packages (independent of host OS update)
distrobox enter ubuntu-medical -- sudo apt upgrade -y

# Update the host OS
sudo bootc upgrade && sudo systemctl reboot
```

## Updating guest container images

When you push a new `ubuntu-24.04-medical` image to the registry:

```bash
# On the deployed Fedora host
podman pull quay.io/myorg/ubuntu-24.04-medical:latest
distrobox rm ubuntu-medical
distrobox assemble create --file /etc/distrobox/medical-guests.ini
```

This is independent of the host OS update cycle.
