# Architecture Review — Fedora bootc layering audit

## 1. LAYER VIOLATIONS

### 1a. `purpose/general` is not a purpose layer — it is a second GNOME layer

**29 packages are byte-for-byte duplicated between `general` and `de/gnome`:**
`loupe`, `papers`, `sushi`, `file-roller`, `file-roller-nautilus`, `gnome-calculator`, `gnome-text-editor`, `gnome-characters`, `gnome-font-viewer`, `gnome-clocks`, `gnome-calendar`, `gnome-contacts`, `gnome-weather`, `gnome-system-monitor`, `gnome-disk-utility`, `baobab`, `gnome-logs`, `gnome-firmware`, `gnome-connections`, `seahorse`, `gnome-online-accounts`, `gnome-epub-thumbnailer`, `xdg-user-dirs-gtk`, `gvfs-mtp`, `gvfs-gphoto2`, `gvfs-smb`, `gvfs-archive`, `gvfs-fuse`, `gvfs-goa`.

Every one of these belongs in `de/gnome` (or `desktop-common` for the gvfs backends). `general` is currently unusable on any non-GNOME DE without dragging the entire GNOME dependency tail — its own `risks` field admits this and then ships the packages anyway.

**Cross-DE contamination inside `general` — it ships packages for all three DEs simultaneously:**
- `tumbler` — Thunar/XFCE thumbnailer. Already in `de/xfce` (with `tumbler-extras`). Dead weight on GNOME and COSMIC.
- `file-roller-nautilus` — no-op without Nautilus, i.e. dead on COSMIC/Hyprland/XFCE.
- `grim`, `slurp`, `swappy` — wlroots-only. Already in `de/cosmic-hyprland`. Dead on GNOME and XFCE (X11).
- `flameshot` — its own `why` says "mainly for non-GNOME DE layers", and its own `notes` say the tray icon misbehaves under Wayland. It is DE-conditional by admission and unconditional in the list.

A single purpose layer cannot contain `tumbler` **and** `file-roller-nautilus` **and** `grim/slurp` — those are three mutually exclusive DE assumptions.

**Infrastructure `general` must not own (all already in `desktop-common`):**
- Archives: `7zip`, `unzip`, `zip`, `zstd`, `cabextract`, `unrar`, `xz`
- Clipboard: `wl-clipboard`, `xclip`
- VFS: `gvfs` + all backends
- MIME/desktop plumbing: `mailcap`, `xdg-user-dirs-gtk`
- Dictionaries: `hunspell-en-US`, `hyphen-en` — DE-agnostic text infrastructure consumed by GTK/LibreOffice/Thunderbird; belongs in `desktop-common` (or a lang layer), not a purpose.
- `ImageMagick`, `ffmpegthumbnailer` — thumbnailer/codec plumbing; overlaps `de/gnome`'s `gst-thumbnailers` + `glycin-thumbnailer`.

**Mutually exclusive alternatives shipped together** (each `why` says "pick one" and then both are listed): `thunderbird` + `evolution`+`evolution-ews`; `papers` + `evince`+`evince-djvu`; `vlc` + `mpv` + `celluloid`.

### 1b. Other purpose layers

**`imagenology`:**
- `colord`, `colord-extra-profiles` — in `desktop-common` *and* `de/gnome`. Triple-claimed.
- `argyllcms`, `DisplayCAL` — also claimed by `de/gnome`. These are DE-agnostic X11 CLI/GTK tools; the purpose layer is the right home, `de/gnome` is the violator here.
- `ddcutil`, `i2c-tools` — duplicated with `gaming`.
- `samba-client`, `cifs-utils`, `nfs-utils`, `autofs`, `gnupg2`, `jq`, `policycoreutils-python-utils`, `python3-pip` — generic; base layer.
- `wireshark-cli` (93 MiB), `tcpdump`, `socat`, `nmap-ncat` — duplicated with `security`.

**`gaming`:**
- `cabextract`, `7zip` — in `desktop-common`.
- `vulkan-tools` — in `desktop-common`.
- `ddcutil`, `i2c-tools` — dup with `imagenology`.
- `nvtop`, `radeontop` — dup with `llms`.
- `kernel-tools` — dup with `music`.
- `wine`, `wine-core`, `winetricks` — dup with `music`. ~2 GiB duplicated across two purposes.

**`music`:**
- `pipewire-jack-audio-connection-kit` — **already in `desktop-common`**. Direct duplicate, and `desktop-common` owning the JACK ABI is itself questionable (its own risks note flags the pro-audio conflict).
- `alsa-utils`, `alsa-ucm`, `alsa-firmware`, `alsa-sof-firmware` — all four in `desktop-common`. The manifest's own `notes` admit this and ship them anyway.
- `rtkit` — in `desktop-common`.
- `lame` — in `desktop-common`. Codec CLI.
- `tuned`, `kernel-tools` — generic tuning infrastructure; base layer.
- `multimedia-menus` — freedesktop menu category infrastructure; `desktop-common`.
- `picard`, `easytag`, `soundconverter` — general-purpose media tagging, not DAW-specific; `general`.

**`security`:**
- `p7zip` — **does not exist on Fedora 44.** Both `desktop-common` and `general` explicitly document the rename to `7zip`. This name fails the dnf transaction outright. Also duplicates `desktop-common`.
- `cabextract`, `unrar`, `unzip` — in `desktop-common`.
- `ntfs-3g`, `ntfsprogs`, `exfatprogs` — in `desktop-common`.
- `keepassxc` — dup with `general`.
- `gcc-c++`, `python3-devel`, `python3-pip`, `pipx`, `python3-virtualenv` — dup with `llms`; belongs in a shared dev layer.
- `usbutils`, `pciutils`, `lshw`, `dmidecode`, `smartmontools`, `lsof`, `cryptsetup`, `lvm2`, `mdadm`, `openssl`, `bind-utils`, `whois`, `mtr` — base layer hardware/system inventory.

**`llms`:** the cleanest of the six. Correctly refuses to claim `podman`/`tuned`/`git`. Remaining violation is the dev toolchain (`gcc-c++`, `cmake`, `ninja-build`, `python3-devel`, `pybind11-devel`, `python3-pip`, `pipx`, `python3-virtualenv`, `git-lfs`) duplicated with `security`.

### 1c. DE layers containing DE-agnostic infrastructure

**`de/gnome` — 15 violations, all already present in `desktop-common`:**
`xorg-x11-server-Xwayland`, `xdg-desktop-portal-gtk`, `at-spi2-core`, `polkit`, `power-profiles-daemon`, `switcheroo-control`, `iio-sensor-proxy`, `adwaita-icon-theme`, `gnome-keyring`, `xdg-user-dirs-gtk`, `colord`, `gvfs-fuse`, `gvfs-smb`, `gvfs-mtp`, `gvfs-gphoto2`.
Additionally DE-agnostic and not in `desktop-common` (so promote, don't keep): `fprintd`, `fprintd-pam`, `libwacom`, `speech-dispatcher`, `accountsservice`, `argyllcms`, `DisplayCAL`, `icc-profiles-openicc`.
`adw-gtk3-theme` is also in `de/cosmic-hyprland` → promote to `desktop-common`.

**`de/cosmic-hyprland` — 6 violations:** `xorg-x11-server-Xwayland`, `qt6-qtwayland`, `gnome-keyring`, `gnome-keyring-pam`, `wl-clipboard`, `xdg-user-dirs-gtk` — all in `desktop-common`. `blueman` and `network-manager-applet` are duplicated with `de/xfce` → both are DE-agnostic GTK tray apps, promote.

**`de/xfce` — worst offender, 18+ violations:**
`gvfs`, `gvfs-mtp`, `gvfs-gphoto2`, `gvfs-smb`, `gvfs-archive`, `gvfs-fuse`, `xdg-desktop-portal-gtk`, `xdg-user-dirs-gtk`, `xdg-utils`, `desktop-file-utils`, `shared-mime-info`, `hicolor-icon-theme`, `adwaita-icon-theme`, `adwaita-cursor-theme`, `gnome-keyring`, `gnome-keyring-pam`, `upower`, `udisks2`, `polkit`, `at-spi2-core`, `fontconfig` — every one is in `desktop-common`.
**`fontconfig` and the `xorg-x11-fonts-*` bitmap sets are a direct violation of the no-fonts-in-DE rule.** The bitmap PCFs are arguably theme assets, but `fontconfig` itself is unambiguously `desktop-common`'s.
**Build-time-only packages shipped into the runtime image:** `make`, `git-core`, `bzip2`, `txt2man`. These belong in a build stage, not the DE package list. Shipping `make` + `git-core` into an immutable desktop is a footprint and attack-surface defect.
**Malformed package entry — build breaker:** the packages array contains a name field of `"xfce4-settings-manager equivalent is in xfce4-settings; xfce4-about"`. That literal string will be passed to dnf.

### 1d. `desktop-common` contains purpose content

Its `flatpaks` list ships `com.valvesoftware.Steam` (gaming), `org.libreoffice.LibreOffice`, `org.mozilla.firefox`, `com.brave.Browser`, `com.google.Chrome`, `com.microsoft.Edge`, `com.spotify.Client`, `org.videolan.VLC` (all `general`). Purpose apps pre-seeded from the shared layer onto every image including the DFIR and DAW builds.

`unrar` is in `desktop-common` — the RPM Fusion nonfree redistribution exposure is thereby attached to *every* published image rather than to the one or two purposes that need it.

**Multi-layer claim counts (packages claimed by 4 layers each):** `gnome-keyring` (desktop-common, gnome, cosmic-hyprland, xfce); `xdg-user-dirs-gtk` (desktop-common, gnome, xfce, general).

---

## 2. PROMOTION CANDIDATES

Packages appearing in 2+ purpose manifests. Note: a strict reading of the rule ("promote into desktop-common") produces a bad outcome for several of these — `wine`, `tcpdump`, `wireshark-cli` do not belong on a general desktop. Correct home is annotated.

| Package | Count | Purposes | Correct home |
|---|---|---|---|
| `cabextract` | 3 | general, gaming, security | **already in desktop-common** — delete from all 3 |
| `python3-pip` | 3 | imagenology, security, llms | shared `dev-common` |
| `7zip` | 2 | general, gaming | **already in desktop-common** |
| `unrar` | 2 | general, security | **already in desktop-common** (and should move out of it) |
| `unzip` | 2 | general, security | **already in desktop-common** |
| `gcc-c++` | 2 | security, llms | shared `dev-common` |
| `python3-devel` | 2 | security, llms | shared `dev-common` |
| `pipx` | 2 | security, llms | shared `dev-common` |
| `python3-virtualenv` | 2 | security, llms | shared `dev-common` |
| `python3-numpy` | 2 | imagenology, llms | shared `python-sci` fragment |
| `python3-scipy` | 2 | imagenology, llms | shared `python-sci` fragment |
| `python3-matplotlib` | 2 | imagenology, llms | shared `python-sci` fragment |
| `python3-pandas` | 2 | imagenology, llms | shared `python-sci` fragment |
| `python3-cryptography` | 2 | imagenology, security | base |
| `gnupg2` | 2 | imagenology, security | base |
| `jq` | 2 | imagenology, security | base |
| `wine` | 2 | gaming, music | **separate `wine` layer** — ~2 GiB, never desktop-common |
| `wine-core` (+`.i686`) | 2 | gaming, music | same |
| `winetricks` | 2 | gaming, music | same |
| `ddcutil` | 2 | imagenology, gaming | desktop-common (display control is generic) |
| `i2c-tools` | 2 | imagenology, gaming | desktop-common |
| `nvtop` | 2 | gaming, llms | desktop-common or hardware layer |
| `radeontop` | 2 | gaming, llms | hardware layer (AMD-only) |
| `kernel-tools` | 2 | gaming, music | base |
| `keepassxc` | 2 | general, security | general only; security should consume it |
| `tcpdump` | 2 | imagenology, security | **net-diag fragment**, not desktop-common |
| `wireshark-cli` | 2 | imagenology, security | net-diag fragment — 93 MiB, and PHI-capture risk |
| `socat` | 2 | imagenology, security | base |
| `nmap-ncat` | 2 | imagenology, security | net-diag fragment |

**Recommendation:** introduce two intermediate fragments rather than dumping all of this into `desktop-common` — `dev-common` (compilers, python packaging, git-lfs) and `net-diag` (tcpdump/tshark/socat/ncat). Neither belongs on a stock general desktop.

---

## 3. CONFLICTS

### 3a. Low-latency PipeWire vs. default desktop audio — the config wins globally, not just for the DAW

`music` ships:
- `/usr/share/pipewire/pipewire.conf.d/99-daw-lowlatency.conf` → `default.clock.quantum=256`, `min-quantum=32`
- `/usr/share/pipewire/jack.conf.d/99-daw.conf` → `node.lock-quantum=true`, `node.force-quantum=256`
- `/usr/share/wireplumber/wireplumber.conf.d/99-daw-alsa.conf` → `api.alsa.period-size=128`, `periods=2`, `headroom=0`, `session.suspend-timeout-seconds=0`

`desktop-common` ships stock `pipewire` + `pipewire-pulseaudio` + `wireplumber` with Fedora defaults (~1024 quantum, 5 s suspend, non-zero headroom). Both sets land in the same `conf.d` search path; the `99-` prefix sorts last and **wins for every client on the machine**, not just Ardour. Concrete consequences:

1. `node.lock-quantum=true` + `force-quantum=256` denies Firefox, notifications and video players the large quantum they request for power saving → measurable idle-power and wakeup-count regression on a machine that is also someone's desktop.
2. `session.suspend-timeout-seconds=0` pins the codec on forever → runtime PM blocked, and no other app can take exclusive access.
3. `api.alsa.headroom=0` is only safe on a dedicated interface. On an internal HDA codec (i.e. every laptop) it produces continuous xruns. The `music` manifest admits this in its own risks and still ships it unconditionally.

**Fix:** `music` must ship these under `/usr/share/daw/lowlatency/` and symlink them into `/etc/pipewire/pipewire.conf.d` via the `daw-mode` toggle its own integration section proposes. As written, "toggleable" is described but not implemented.

**Related, and an outright bug:** `music` claims its `/etc/security/limits.d/95-daw-realtime.conf` (rtprio 95) "must sort after" `realtime-setup`'s `realtime.conf` (rtprio 99), asserting *"95- prefix beats its default name"*. That is inverted. `pam_limits` walks `limits.d/*.conf` in C-collation order and later files win; ASCII digits sort **before** letters, so `95-daw-realtime.conf` is parsed **first** and `realtime.conf`'s `rtprio 99` overrides it. The stated safety margin (keeping userspace below the migration/watchdog/RCU threads at 99) does not exist as configured. Rename to something sorting after `realtime.conf`, or drop `realtime-setup`'s file.

**Also:** `music`'s `/usr/lib/systemd/system/user@.service.d/10-daw-limits.conf` sets `LimitRTPRIO=95`, `LimitMEMLOCK=infinity` for **every user session on the image**, not just the DAW operator. That is a system-wide privilege grant from a purpose layer.

**Duplicate rtkit ownership:** `desktop-common` installs `rtkit` and documents "prefer rtkit, only add limits.conf if a purpose layer does pro-audio". `music` then installs `rtkit` again *and* adds limits.conf *and* overrides `rtkit-daemon.service` with `--max-realtime-priority=95 --rttime-usec-max=2000000`. Three overlapping RT mechanisms; pick one owner.

### 3b. Greeter / display-manager conflict across the three DE layers

| Layer | Enables | Claims `display-manager.service` |
|---|---|---|
| `de/gnome` | `gdm.service` | yes |
| `de/cosmic-hyprland` | `cosmic-greeter.service` (`Alias=display-manager.service`) | yes |
| `de/xfce` | `lightdm.service` | yes |

By the stated composition model only one DE layer ships per image, so this does not fire *today*. What does fire:

1. **`de/cosmic-hyprland` already breaks the one-DE-per-layer rule** — it ships two full desktops (COSMIC + Hyprland), two notification daemons (`cosmic-notifications` + `mako`), two idle daemons (`cosmic-idle` + `swayidle`), two wallpaper daemons (`cosmic-bg` + `swaybg`) in one layer. Its own risks acknowledge that if any of the Hyprland-side daemons are ever started via a systemd user unit instead of `exec-once`, they will also run inside the COSMIC session and duplicate notifications/fight over the wallpaper. It handles the greeter correctly (`cosmic-greeter` is a greetd greeter and enumerates both `wayland-sessions` entries) — that part is the one thing in this manifest set that is verified end-to-end.
2. **`graphical.target` is set by two layers.** `desktop-common` integration says `systemctl set-default graphical.target` belongs there; `de/gnome` sets it again. Harmless but signals unclear ownership.
3. **Plymouth has two owners.** `desktop-common` ships `plymouth` + `plymouth-system-theme` and bakes `rhgb quiet` via `/usr/lib/bootc/kargs.d/10-desktop.toml`. `de/xfce` wants `plymouth-set-default-theme Chicago95` plus an initramfs regeneration in the same layer. Two layers writing `/etc/plymouth/plymouthd.conf`.
4. **`fprintd` is inconsistent across DEs.** `de/gnome` lists it; `de/cosmic-hyprland` pulls it transitively (hard `Requires` of `cosmic-greeter`); `de/xfce` has no fingerprint path at all. Promote `fprintd`/`fprintd-pam` to `desktop-common`.
5. **`kargs.d` numbering collision, unresolved.** `desktop-common` uses `10-desktop.toml` and explicitly raises the numbering-convention question. `music` then claims `20-audio.toml` while `desktop-common`'s own suggested convention reserves `20-` for hardware. `gaming` (`split_lock_detect=off`), `security` (`systemd.gpt_auto=0`, `iomem=relaxed`), and `llms` (`amdgpu.gttsize`, `nvidia-drm.modeset=1`) all want kargs with no assigned number. Files merge by filename — two layers picking `20-` silently clobber each other. Assign the convention before anything else ships.

### 3c. Governor contention — three daemons, one knob

- `desktop-common` **enables** `power-profiles-daemon.service`.
- `music` **enables** `tuned.service` with `active_profile=latency-performance` (governor=performance, `force_latency=cstate.id:1`).
- `gaming` relies on GameMode's `desiredgov=performance`, and its own integration note says GameMode and ppd "fight over the same knob. Pick one."
- `de/xfce` adds `xfce4-power-manager`, a third consumer.
- `llms` requests `tuned` from the base layer.

On a `music` image you get **ppd and tuned both enabled and both writing the governor**. `music` only warns about `tuned-ppd`, not plain `tuned` vs `power-profiles-daemon` — that is the actual conflict and it is unhandled. Every purpose that touches CPU policy (`music`, `gaming`, `llms`) must mask `power-profiles-daemon.service` inherited from `desktop-common`, and that masking is currently specified nowhere.

Second-order: `desktop-common` enables `systemd-oomd.service`; `gaming`'s notes state systemd-oomd "has historically killed games under memory pressure". Shared layer enabling it, purpose layer objecting, no resolution.

### 3d. Colour management — three-way ownership collision

`colord` is claimed by `desktop-common`, `de/gnome`, and `imagenology`. `argyllcms` + `DisplayCAL` + `colord-extra-profiles` are claimed by **both** `de/gnome` and `imagenology`. `imagenology`'s notes correctly assert that only the DE-specific applier (`gnome-color-manager`) belongs in the DE layer — `de/gnome` took the DE-agnostic engine as well.

Worse: `de/cosmic-hyprland` and `de/xfce` ship **no colour management at all**. So on a COSMIC or XFCE imaging workstation there is a `colord` daemon with an ICC database and **nothing that applies the profile at session start**. Neither manifest ships an equivalent of `gnome-color-manager`, `colord-kde`, or an `xcalib`/`dispwin` login hook.

### 3e. Four layers write `mimeapps.list`

- `general` → `/usr/share/applications/mimeapps.list` (browser, PDF, image, video, archive, magnet, text defaults)
- `de/gnome` → `/usr/share/applications/gnome-mimeapps.list`
- `imagenology` → `/usr/share/applications/mimeapps.list` (`application/dicom`)
- `security` → `/usr/share/applications/mimeapps.list` (`.pcap`, `.E01`, `.dd`, `.raw`, `.img`)

Three of them write the *same path*. Last layer in the build wins and silently discards the others. `general` raises this as an "open question" and then ships the file anyway. Compounding it, `general` ships both `papers` and `evince` competing for `application/pdf`, and `de/gnome` ships `papers` again.

**Fix:** no layer ships `mimeapps.list`. Each contributes a numbered fragment merged at build time; only `de/gnome` may use the desktop-prefixed `gnome-mimeapps.list`.

### 3f. Steam and Firefox shipped twice, by policy

- `desktop-common` pre-seeds Flatpak `com.valvesoftware.Steam`. `gaming` installs the `steam` RPM and its own risks state: *"Flatpak Steam and RPM Steam both installed is a real failure mode: two `steam://` handlers, two library locations, and Proton prefixes that do not transfer."* The shared layer creates exactly that condition on every gaming image.
- `desktop-common` pre-seeds `org.mozilla.firefox` and recommends Flatpak over RPM; `general` installs the `firefox` RPM specifically so `policies.json` works. Two Firefoxes, two `http(s)` handlers.

### 3g. Forensic write-block vs. desktop automount — only works on GNOME

`security`'s `60-forensic-writeblock.rules` + `UDISKS_IGNORE` covers udisks. Its second line of defence is a **dconf lock** on `org/gnome/desktop/media-handling` — GNOME-only, and inert on the other two DEs:
- `de/xfce` ships `thunar-volman`, an explicit removable-media auto-handling daemon with no dconf equivalent.
- `de/cosmic-hyprland` ships `udiskie` (an automount daemon started from `hyprland.conf`) plus `cosmic-files`.

On XFCE or COSMIC/Hyprland, `security`'s defence-in-depth is one udev rule deep and its `forensics-verify.service` will assert a dconf key that does not apply. `security` flags this as an open question; it is a hard blocker for those two combinations.

### 3h. Smaller conflicts

- `pipewire-jack-audio-connection-kit` `Provides`/`Obsoletes` `jack-audio-connection-kit`; installed by both `desktop-common` and `music`.
- `llms` ships `vm.overcommit_memory=1` system-wide in `/usr/lib/sysctl.d/60-llm.conf` — a global allocator policy change from a purpose layer that affects every process on the image.
- `desktop-common` enables `avahi-daemon` + `cups-browsed` (mDNS chatter) on the `security` image, which is meant to be quiet on a client network.
- `desktop-common` ships `ibus` + the full IME set, but **neither `de/cosmic-hyprland` nor `de/xfce` wires `GTK_IM_MODULE`/`QT_IM_MODULE`/`XMODIFIERS` or an `exec-once`/autostart for `ibus-daemon`**. CJK input is silently dead on both, despite the fonts and engines being installed.
- `gnome-keyring` installed by four layers; if a KDE/kwallet layer is ever added, double Secret Service → double password prompts (`desktop-common` flags this).
- `llms`: `python3-torch` hard-requires `libmagma.so.2.9.0`, and the same manifest states `magma` "is not in Fedora proper" (COPR only). If accurate, `python3-torch` is **unsatisfiable from Fedora repos** and the manifest's central package cannot depsolve. Verify before this ships.

---

## 4. GAPS

**`general`**
- `mozilla-openh264` is missing everywhere. `general` flags it as codec-layer work; `desktop-common` ships `gstreamer1-plugin-openh264` but **not** the Firefox-specific `mozilla-openh264`. Result: WebRTC video calls fail in Firefox and users blame the browser. Nobody owns it.
- No dictionaries beyond `en`; no `libreoffice-langpack-*` beyond `en`. A non-English user gets a partial LibreOffice UI with no spellcheck and cannot fix it on an immutable image.
- No `unrar-free` decision, despite `general`'s own risk about publishing `unrar`.

**`imagenology`**
- **No time synchronisation hardening.** A PACS client whose study timestamps and PHI audit log are legally relevant ships no `chrony` configuration. Nothing in any layer addresses it.
- No `audit`/`audit-rules` package listed, yet the manifest enables `auditd.service` and ships audit rules. Same gap in `security`.
- No optical-media import path (`xorriso`, `dvd+rw-tools`) despite explicitly citing "CD/DVD import stations" as a workflow.
- No session-side ICC applier for non-GNOME DEs (see 3d).

**`gaming`**
- **No shipped mechanism to add the user to the `gamemode` group.** The manifest correctly identifies this as "the one step nothing does for you" and then does not do it. Without it, `10-gamemode.conf` limits and the polkit rules are inert and the governor switch silently fails. This is the single highest-frequency support ticket the image will generate, and it is a known unfixed gap.
- No StatusNotifier host guaranteed for the Steam/Discord tray on XFCE (see matrix).

**`music`**
- `wine-core.i686` is described in the `why` text of the `wine-core` entry ("Pull both … (wine-core.i686)") but **is not a package entry**. dnf will not select the 32-bit build; 32-bit VST2 bridging silently does not work.
- No default SoundFont pointer (`/usr/share/soundfonts/default.sf2` or equivalent) despite shipping `fluidsynth`, `timidity++` and 200 MB of banks.

**`security`**
- `p7zip` does not exist → transaction failure (see 1b).
- `util-linux` (for `/usr/sbin/blockdev`, on which the entire write-block `RUN+=` depends) is raised as an open question and never added to `packages`. If the base only ships `util-linux-core`, the write-block rule is a no-op — and it fails *silently*, which is the worst possible failure mode for this specific feature.

**`llms`** — no `podman` anywhere in its chain except via `desktop-common`; correctly flagged, and `desktop-common` does provide it. This one is fine.

**`desktop-common`**
- No `gtk2` — `de/xfce` needs it for the Chicago95 pixmap/xfce GTK2 engines and adds it locally.
- No `pavucontrol` (only `pulseaudio-utils` CLI); `de/xfce` adds it, the other two rely on native DE panels.
- No X.org server. Correct for a Wayland-first shared layer, but it means **any purpose needing X11 (imagenology calibration) is silently dependent on choosing XFCE**.
- No app-store frontend. `de/gnome` has `gnome-software`, `de/cosmic-hyprland` has `cosmic-store`, **`de/xfce` has none** (and deliberately excludes `dnfdragora`). The XFCE image has no graphical way to install a Flatpak.
- `de/xfce` notes that many modern apps dropped XEmbed tray support and that `xfce4-statusnotifier-plugin` exists — and then does not list it. Steam, Discord, Nextcloud and Syncthing tray icons are dead on XFCE as shipped.
- No `NetworkManager-openconnect`/`-wireguard`; only `-openvpn`.

---

## 5. DE-SUITABILITY MATRIX

`OK` = ship it · `MIXED` = works with named mitigations · `BAD` = do not ship this combination

| Purpose | `de/gnome` (Wayland-only) | `de/cosmic-hyprland` (Wayland-only) | `de/xfce` (X11-only, Win95) |
|---|---|---|---|
| **general** | **OK** — but delete the 29 duplicated packages; `general` is currently a second GNOME layer | **MIXED** — GNOME app tail drags a large foreign dependency set; `file-roller-nautilus` + `sushi` + `tumbler` are dead weight; `flameshot` tray misbehaves on Wayland | **BAD** — every GTK4/libadwaita app (`loupe`, `papers`, `gnome-text-editor`, `gnome-calculator`) ignores Chicago95 entirely; half the desktop renders in Adwaita. `grim`/`slurp` dead on X11 |
| **imagenology** | **MIXED** — no X11 session on F44, so `argyllcms`/`dispwin` gamma-ramp calibration **silently does not apply**; Weasis is Swing→XWayland; mutter applies VCGT only, not a colour transform. Viable **only** with hardware LUT via `ddcutil`/vendor tool, and 100%/200% integer scale | **BAD** — Hyprland has no colour management and wlroots-style fractional scaling resamples fine structure; the DE manifest itself says do not read studies on it. COSMIC session ships **zero** colour-management components. Software calibration broken (Wayland), no ICC applier | **MIXED (best substrate, wrong skin)** — the **only** X11 session, so `dispwin` gamma ramps actually land. But: no ICC session applier shipped, no per-monitor scaling for a 5MP panel, and the layer force-installs Chicago95 with **antialiasing off and 8 pt bitmap Helvetica** — indefensible on a reading workstation. Usable only if the theming is made optional |
| **gaming** | **MIXED** — VRR works in mutter 50.3 but **cannot be baked** (lives in per-user `~/.config/monitors.xml` keyed by monitor serial, not dconf). **Zero tearing-control support** (no `wp_tearing_control_v1`); gamescope is the only mitigation. Highest compositor overhead of the three | **OK — best choice** — Hyprland supports tearing control and per-output VRR, both bakeable via `/etc/skel/.config/hypr/hyprland.conf`; lowest overhead. Cost: single-maintainer COPR in the trusted base, and `hyprland-git` snapshot trap in the lionheartp repo | **BAD** — X11: no per-monitor VRR, no modern presentation path, gamescope degraded. The Chicago95 theme mandates `use_compositing=false`, so no vsync path either. Only plus is XEmbed tray for Steam |
| **music** | **MIXED** — `localsearch`/`tinysparql` will index sample libraries and cause disk churn mid-take; must be masked. Heaviest DE = most non-audio wakeups against a 256-frame quantum. `power-profiles-daemon` vs `tuned` conflict (3c) | **OK** — lowest overhead, no file indexer, tiling suits patchbay + DAW. Caveat: bare Hyprland gets no systemd user session scope, so ordering of PipeWire vs `exec-once` clients is manual (use `uwsm`) | **OK — best latency** — lightest, X11, no indexer, no compositing. But `xfce4-power-manager` becomes a **third** governor/DPMS consumer alongside `tuned` and `ppd`; must disable its power policy and mask `ppd` |
| **security** | **OK — best for forensics** — the **only** DE where the dconf `media-handling` automount lock actually functions, which is a load-bearing part of the write-block posture | **BAD for forensics** — `udiskie` is an explicit automount daemon started from the Hyprland config, directly hostile to write-blocking; `cosmic-files` automounts with no documented disable. Must strip `udiskie`. Offensive half is fine | **BAD for forensics** — `thunar-volman` is an explicit auto-mount/auto-run daemon with no lockable system default; the dconf lock is inert. Must drop `thunar-volman`. Offensive half is fine and XFCE is the lightest for a long-running capture box |
| **llms** | **MIXED** — GNOME + Mesa/LLVM is the largest desktop footprint stacked on an already 8–9 GB layer, and `gnome-shell` holds a GPU context competing for VRAM with a 70B model on a single-GPU box | **OK** — COSMIC is also GPU-accelerated (Iced); the Hyprland session is the leanest of the two and the right pick | **OK — least VRAM held by the desktop** (X11, no compositing), which is the metric that actually matters here. Also the easiest NVIDIA path. The Win95 theming is irrelevant to a mostly-headless workload |

**Two cross-cutting conclusions from the matrix:**

1. `imagenology` has **no good DE**. The one requirement that constrains everything — software display calibration through X11 gamma ramps — is satisfiable only by `de/xfce`, which is simultaneously the least appropriate desktop for diagnostic reading as configured. Either commit to hardware-LUT-only calibration (`ddcutil`/Eizo RadiCS/Barco QAWeb) and use GNOME, or fork an unthemed XFCE variant. Decide this before acceptance testing, not during.
2. `gaming` and `security` want opposite DEs (`cosmic-hyprland` vs `gnome`), and `music` and `llms` both want the lightest thing available. The purpose set does not collapse cleanly onto three DE layers — expect 4–6 real image tags, not 18 combinations.