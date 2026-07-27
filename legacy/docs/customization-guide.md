# Customization Guide

How to modify packages, settings, languages, defaults, and create new
image variants — for any supported distro.

---

## Table of contents

1. [Project structure overview](#1-project-structure-overview)
2. [The two config files you edit](#2-the-two-config-files-you-edit)
3. [Adding and removing packages](#3-adding-and-removing-packages)
4. [Switching distro or distro version](#4-switching-distro-or-distro-version)
5. [Language and locale](#5-language-and-locale)
6. [Keyboard layout](#6-keyboard-layout)
7. [Timezone](#7-timezone)
8. [Default applications](#8-default-applications)
9. [GNOME desktop defaults (dconf)](#9-gnome-desktop-defaults-dconf)
10. [System services](#10-system-services)
11. [Baking in configuration files](#11-baking-in-configuration-files)
12. [Users and groups](#12-users-and-groups)
13. [Firewall rules](#13-firewall-rules)
14. [Creating a new profile](#14-creating-a-new-profile)
15. [Creating a new distro config](#15-creating-a-new-distro-config)
16. [Overriding settings after deployment](#16-overriding-settings-after-deployment)
17. [Rebuilding after changes](#17-rebuilding-after-changes)

---

## 1. Project structure overview

```
fedora-custom-images/
├── build.sh                   ← main entry point (run this)
│
├── config/
│   ├── distros/               ← one file per OS
│   │   ├── fedora.conf        → base image, pkg manager, repo setup
│   │   ├── ubuntu.conf
│   │   └── debian.conf
│   └── profiles/              ← one file per use case
│       ├── base.conf          → packages + services for every OS
│       ├── workstation.conf
│       ├── medical.conf       → DICOM tools, Weasis, LibreOffice
│       └── pacs-server.conf   → Orthanc, PostgreSQL, Nginx
│
├── build/
│   ├── generate.sh            ← combines distro + profile → Containerfile
│   ├── build-iso.sh           ← builds named ISO via bootc-image-builder
│   └── deploy-bootc.sh        ← switches a running bootc host
│
├── generated/                 ← auto-generated (do not edit manually)
│   └── fedora-medical/
│       └── Containerfile
│
└── images/                    ← static config files for each profile
    ├── medical-workstation/config/weasis/
    └── pacs-server/config/
```

**Workflow:**

```
edit config/profiles/medical.conf
        │
        ▼
./build.sh fedora medical --iso
        │  (calls generate.sh → creates generated/fedora-medical/Containerfile)
        │  (calls podman build)
        │  (calls build-iso.sh)
        ▼
output/fedora-43-medical-2026-03-20/bootiso/install.iso
```

---

## 2. The two config files you edit

For most changes you only need to touch **one or two files**.

| What you want to change | Edit this file |
|------------------------|---------------|
| Packages in a profile | `config/profiles/<profile>.conf` |
| Package manager, base image, OS version | `config/distros/<distro>.conf` |
| Configuration files baked into the image | `images/<profile>/` |
| Systemd units, services | `config/profiles/<profile>.conf` (SERVICES variable) |
| Locale, timezone, keyboard | `images/<profile>/files/etc/` (see section 5–7) |
| GNOME defaults | `images/<profile>/files/etc/dconf/` |

---

## 3. Adding and removing packages

Open `config/profiles/<profile>.conf`. Each profile has two package lists —
one per distro family:

```bash
# config/profiles/medical.conf

PKGS_rhel="\          ← Fedora, RHEL, CentOS
  dcmtk \
  gdcm \
  my-new-package \    ← add here for Fedora/RHEL
"

PKGS_debian="\        ← Ubuntu, Debian
  dcmtk \
  gdcm-tools \
  my-new-package \    ← add here for Ubuntu/Debian (name may differ!)
"
```

To **remove** a package: delete its line.

### Find the right package name

```bash
# Fedora
dnf search <keyword>
dnf info <package>
dnf provides '*/dcmdump'     # which package contains this file/command

# Ubuntu / Debian
apt-cache search <keyword>
apt-cache show <package>
dpkg -S $(which dcmdump)     # which package owns this command
```

### Package names that differ between families

| Purpose | Fedora (`rhel`) | Ubuntu/Debian (`debian`) |
|---------|-----------------|--------------------------|
| GDCM CLI tools | `gdcm-applications` | `gdcm-tools` |
| Java 21 headless | `java-21-openjdk-headless` | `openjdk-21-jre-headless` |
| VTK Python | `python3-vtk` | `python3-vtk9` |
| DNS utilities | `bind-utils` | `bind9-utils` |
| Vim full | `vim-enhanced` | `vim` |
| GDM | `gdm` | `gdm3` |
| Xwayland | `xorg-x11-server-Xwayland` | `xwayland` |
| NetworkManager | `NetworkManager` | `network-manager` |
| PostgreSQL server | `postgresql-server` | `postgresql` |

---

## 4. Switching distro or distro version

### Change the Fedora version

Edit `config/distros/fedora.conf`:

```bash
DISTRO_VERSION="43"           # change to 44, 45, etc.
BASE_IMAGE="quay.io/fedora/fedora-bootc:${DISTRO_VERSION}"
```

Then rebuild:

```bash
./build.sh fedora medical --iso
```

### Switch to Ubuntu

```bash
./build.sh ubuntu medical --iso
./build.sh ubuntu workstation
```

### Switch to Debian

```bash
./build.sh debian medical --iso
./build.sh debian pacs-server
```

### Change Ubuntu/Debian version

Edit the appropriate distro config:

```bash
# config/distros/ubuntu.conf
DISTRO_VERSION="24.04"         # change to 22.04 or future LTS
BASE_IMAGE="ghcr.io/nicholasdille/ubuntu-bootc:${DISTRO_VERSION}"
```

---

## 5. Language and locale

Add to any profile's `PKGS_rhel` / `PKGS_debian`, and add an
`/etc/locale.conf` via the files overlay.

### Step 1 — add the language pack

In `config/profiles/<profile>.conf`:

```bash
PKGS_rhel="\
  ...existing packages...
  glibc-langpack-es \      # Spanish
"

PKGS_debian="\
  ...existing packages...
  language-pack-es \       # Spanish (Ubuntu)
  # or:
  locales \                # Debian (then configure below)
"
```

### Step 2 — set the default locale

Create `images/<profile>/files/etc/locale.conf`:

```bash
LANG=es_ES.UTF-8
LC_ALL=es_ES.UTF-8
```

Then add this to the Containerfile for your profile (see
[section 11](#11-baking-in-configuration-files) for the `COPY files/ /` pattern).

For Debian you also need to generate the locale:

```dockerfile
RUN echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
```

### Common locale codes

| Language | Code |
|----------|------|
| English (US) | `en_US.UTF-8` |
| Spanish (Spain) | `es_ES.UTF-8` |
| Spanish (Mexico) | `es_MX.UTF-8` |
| Portuguese (Brazil) | `pt_BR.UTF-8` |
| French | `fr_FR.UTF-8` |
| German | `de_DE.UTF-8` |
| Japanese | `ja_JP.UTF-8` |
| Chinese (Simplified) | `zh_CN.UTF-8` |

---

## 6. Keyboard layout

### Console keyboard

Create `images/<profile>/files/etc/vconsole.conf`:

```bash
KEYMAP=es
```

Common keymaps: `us`, `es`, `de`, `fr`, `br-abnt2`, `pt-latin1`, `uk`

### GNOME / Wayland keyboard

Create `images/<profile>/files/etc/X11/xorg.conf.d/00-keyboard.conf`:

```
Section "InputClass"
    Identifier      "system-keyboard"
    MatchIsKeyboard "on"
    Option          "XkbLayout"  "es"
    Option          "XkbVariant" ""
EndSection
```

Multiple layouts with a toggle shortcut (`Alt+Shift`):

```
Option "XkbLayout"  "us,es"
Option "XkbOptions" "grp:alt_shift_toggle"
```

---

## 7. Timezone

Create `images/<profile>/files/etc/localtime` as a symlink (not possible
with a plain file overlay), so instead add a `RUN` command to the generate.sh
profile section, or add it in a custom profile Containerfile:

```dockerfile
RUN ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime \
    && echo 'America/New_York' > /etc/timezone
```

**For profiles generated by `generate.sh`**, add a line to the
`generate_profile_extras` section inside `build/generate.sh`:

```bash
# Example: in the medical) case block
echo "RUN ln -sf /usr/share/zoneinfo/America/Bogota /etc/localtime && echo 'America/Bogota' > /etc/timezone"
```

Find your timezone name:

```bash
timedatectl list-timezones | grep -i america
```

---

## 8. Default applications

### MIME type handler (e.g., default PDF viewer)

Add to the generated Containerfile or `build/generate.sh`:

```dockerfile
RUN xdg-mime default evince.desktop application/pdf || true
RUN xdg-mime default weasis-dicom-handler.desktop application/dicom || true
```

### Custom .desktop launcher

Create `images/<profile>/files/usr/share/applications/myapp.desktop`:

```ini
[Desktop Entry]
Name=My App
Exec=/usr/bin/myapp %f
Icon=myapp
Type=Application
Categories=Utility;
MimeType=application/x-myformat;
```

Then in the Containerfile:

```dockerfile
RUN update-desktop-database /usr/share/applications/ || true
```

---

## 9. GNOME desktop defaults (dconf)

### Step 1 — create the dconf profile

Create `images/<profile>/files/etc/dconf/profile/user`:

```
user-db:user
system-db:local
```

### Step 2 — write defaults

Create `images/<profile>/files/etc/dconf/db/local.d/00-defaults`:

```ini
[org/gnome/desktop/interface]
color-scheme='prefer-dark'
gtk-theme='Adwaita-dark'
font-name='Noto Sans 11'

[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-timeout=3600
sleep-inactive-battery-timeout=900

[org/gnome/desktop/privacy]
report-technical-problems=false
send-software-usage-stats=false
```

### Step 3 — apply in the Containerfile

```dockerfile
COPY files/ /
RUN dconf update
```

### Step 4 (optional) — lock a setting

Create `images/<profile>/files/etc/dconf/db/local.d/locks/00-locks`:

```
/org/gnome/desktop/privacy/report-technical-problems
/org/gnome/desktop/privacy/send-software-usage-stats
```

Locked keys cannot be changed by the user.

### Discover dconf keys

```bash
# Change the setting in GNOME, then read it:
dconf dump / | grep -A2 <keyword>

# Browse interactively:
dconf-editor
```

---

## 10. System services

In `config/profiles/<profile>.conf`, add to the services variable:

```bash
SERVICES_rhel="firewalld sshd auditd myservice"
SERVICES_debian="ufw ssh auditd myservice"
```

To **disable** a default service, add a `RUN systemctl disable ...` line
in `build/generate.sh` for that profile case.

### Custom systemd unit

Place the unit file in `images/<profile>/files/etc/systemd/system/`,
then reference it in the profile config or generate.sh.

---

## 11. Baking in configuration files

The cleanest way to add many config files to a profile is the **`files/`
directory overlay**:

```
images/medical-workstation/
└── files/
    ├── etc/
    │   ├── locale.conf
    │   ├── vconsole.conf
    │   ├── weasis/
    │   │   └── dicom-config.properties
    │   └── dconf/
    │       └── db/local.d/
    │           └── 00-defaults
    └── usr/
        └── share/
            └── applications/
                └── myapp.desktop
```

Then in the Containerfile (or in `build/generate.sh`):

```dockerfile
COPY images/medical-workstation/files/ /
```

This mirrors the entire tree into the root of the image. One COPY, any number
of files.

---

## 12. Users and groups

### System user (for a service)

Add in `build/generate.sh` for your profile:

```bash
echo 'RUN useradd --system --no-create-home --shell /sbin/nologin myservice'
```

### Admin user (development/lab — not for production)

```dockerfile
RUN useradd -m -G wheel,dialout admin \
    && echo 'admin:CHANGEME' | chpasswd \
    && passwd -e admin        # force change on first login
```

### SSH key at deploy time (recommended for production)

```bash
sudo bootc install to-disk /dev/sda \
  --root-ssh-authorized-keys ~/.ssh/id_ed25519.pub
```

---

## 13. Firewall rules

Add to `build/generate.sh` in the relevant profile section:

```bash
# Open a port
echo 'RUN firewall-offline-cmd --add-port=8080/tcp || true'

# Named service
echo 'RUN firewall-offline-cmd --add-service=https || true'
```

For a custom service definition, place the XML in
`images/<profile>/config/` and COPY it in:

```dockerfile
COPY images/pacs-server/config/firewalld-pacs.xml \
     /etc/firewalld/services/pacs.xml
RUN firewall-offline-cmd --add-service=pacs || true
```

---

## 14. Creating a new profile

### Step 1 — create the profile config

Create `config/profiles/my-profile.conf`:

```bash
PROFILE="my-profile"
PROFILE_DESCRIPTION="My custom workstation for lab work"
INHERITS="workstation"           # builds on top of workstation

PKGS_rhel="\
  my-rhel-package-1 \
  my-rhel-package-2 \
"

PKGS_debian="\
  my-debian-package-1 \
  my-debian-package-2 \
"

SERVICES_rhel="my-service"
SERVICES_debian="my-service"
```

### Step 2 — add extra logic (optional)

Open `build/generate.sh` and add a case for your profile inside
`generate_profile_extras()`:

```bash
my-profile)
  echo "RUN my-custom-command --setup"
  ;;
```

### Step 3 — build it

```bash
./build.sh fedora my-profile --iso
./build.sh ubuntu my-profile
```

That's it. The script handles the dependency chain automatically based on
`INHERITS`.

---

## 15. Creating a new distro config

Create `config/distros/my-distro.conf`:

```bash
DISTRO="my-distro"
DISTRO_FAMILY="rhel"              # "rhel" or "debian" — picks package lists
DISTRO_VERSION="X.Y"
DISTRO_DISPLAY="My Distro X.Y"

BASE_IMAGE="registry.example.com/my-distro-bootc:${DISTRO_VERSION}"

PKG_INSTALL="dnf install -y"      # or "DEBIAN_FRONTEND=noninteractive apt-get install -y"
PKG_CLEAN="dnf clean all"         # or "apt-get clean && rm -rf /var/lib/apt/lists/*"

EXTRA_REPOS_BLOCK='RUN my-repo-setup-command'

SECURITY_BLOCK='RUN my-security-setup'
FIREWALL_SERVICE="firewalld"

WEASIS_PKG_NAME="weasis-\${WEASIS_VERSION}-1.x86_64.rpm"
WEASIS_INSTALL_CMD="rpm -ivh"
```

Then build:

```bash
./build.sh my-distro medical
```

---

## 16. Overriding settings after deployment

Some things should differ per machine without a full image rebuild.

### `/etc` — machine-specific files

bootc merges `/etc` on upgrade. Local edits survive as long as the image
doesn't change the same file.

```bash
# Set PACS address for a specific workstation
sudo tee /etc/weasis/dicom-config.local.properties << 'EOF'
weasis.dicom.host=192.168.1.50
weasis.dicom.port=4242
EOF
```

### Systemd drop-ins

```bash
sudo mkdir -p /etc/systemd/system/orthanc.service.d/
sudo tee /etc/systemd/system/orthanc.service.d/local.conf << 'EOF'
[Service]
Environment=MY_SETTING=value
EOF
sudo systemctl daemon-reload
```

### What survives upgrades

| Path | On bootc upgrade |
|------|-----------------|
| `/usr` | Replaced from new image |
| `/etc` | Three-way merged (local edits survive) |
| `/var` | Preserved (databases, spool, home dirs) |
| `/home` | Preserved (lives under `/var/home`) |

---

## 17. Rebuilding after changes

```bash
# After editing config/profiles/medical.conf or any files/ directory:
./build.sh fedora medical

# Rebuild + new ISO
./build.sh fedora medical --iso

# Full rebuild, skip Podman layer cache
./build.sh fedora medical --iso --no-cache

# Check what ISOs you have
ls output/
```

The generated Containerfile is written to `generated/fedora-medical/Containerfile`
so you can inspect exactly what was built.

Podman caches layers, so only changed layers and those after them are rebuilt.
If you only changed a package list, only the install step onwards is re-run.
