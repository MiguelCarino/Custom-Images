## Method
Verified on a live Fedora 44 host (`fedora`, `updates`, `rpmfusion-free{,-updates}`, `rpmfusion-nonfree{,-updates,-steam,-nvidia}`; COPR and google-chrome repos **disabled**), batched `dnf repoquery --qf '%{name}\n'` 30 names/call, set-diffed input vs. echoed output. Detection validated against known-bad controls (`liberation-fonts`, `totallyfakepkg123`). **1075 package names** checked across the 10 `packages` arrays (incl. the 9 arch-qualified `.i686` gaming entries). COPRs via `copr.fedorainfracloud.org/api_3`, Flathub IDs via `flathub.org/api/v2/appstream`, external URLs via HTTP.

---

## Bad package names (`packages[]`)

**security** — 2 bad / 179
- `nbtscan` — **does not exist**. No package, no Provides, in any enabled repo. Hard `dnf install` failure.
- `p7zip` — **not a package name in F44**. Retired; only survives as a `Provides:` of `7zip-standalone`. Resolves by accident via provides-matching, but the name is wrong — and the *same author group's* `general` and `desktop-common` manifests both explicitly state "p7zip is gone in F44, use 7zip". Internal contradiction.

**de-xfce** — 1 malformed / 100
- Entry 14's `name` field is the prose string `"xfce4-settings-manager equivalent is in xfce4-settings; xfce4-about"`. Not a package name; breaks any consumer that iterates the field. Intended value `xfce4-about` does exist.

**general, imagenology, gaming, music, llms, desktop-common, de-gnome, de-cosmic-hyprland** — 0 bad. Every name echoed back, including the traps the manifests called out (`Carla`, `Carla-vst`, `setBfree`, `lv2-setBfree-plugins`, `lv2-abGate`, `lv2-mdaEPiano`, `Add64`, `timidity++`, `rosegarden4`, `vkBasalt`, `Thunar`, `DisplayCAL`, `InsightToolkit`, `zeek-core`, `perl-Image-ExifTool`, `ewftools`, `python3-ROPGadget`, `jupyterlab`, `7zip-standalone`, `google-noto-sans-symbols-2-fonts`, `liberation-fonts-all`, `lightdm-gtk`, `gtk-xfce-engine`, `java-25-openjdk-headless`). Multilib `.i686` specs all resolve. Negative claims spot-checked and all hold (`zeek`, `lightdm-gtk-greeter`, `mesa-va-drivers`, `mesa-vdpau-drivers`, `google-noto-cjk-fonts`, `polkit-gnome`, `rofi-wayland`, `gnome-themes-extra`, `python3-transformers`, `hcxdumptool`, `nikto`, `netdiscover`, `mitmproxy`, `wfuzz`, `dirb`, `scalpel`, `bulk_extractor`, `volatility3`, `sqlmap` — all genuinely absent).

**Total bad package names: 2 nonexistent + 1 malformed = 3 / 1075 (99.7% clean).**

---

## Bad COPR entries

**security** — 3 of 4 broken. This field was not verified at all.
- `melmorabity/8812au` — **PROJECT DOES NOT EXIST** (API 404). melmorabity's project list is `misc-nagios-plugins, misc-centos-packages, ansible, python-azure-sdk-el, openvpn-auth-script, octoprint, 8821au, tbs, raspberrypi-userland`. Only `8821au` exists — a *different chipset*. This was the manifest's headline "most consistently maintained" recommendation.
- `sketchybinary/RTL8812AU` — exists, but its only chroot is `epel-7-x86_64`. Zero Fedora builds. Unusable, presented without caveat.
- `krabs/kmod-88XX` — exists, but `chroot_repos` is **empty**. Never built anything. Presented as the kernel-bump fallback.
- `ublue-os/akmods` — valid (fedora-44 x86_64 + aarch64). The only working entry.

**de-cosmic-hyprland** — factual error driving a recommendation
- Claims *"uwsm exists only in lionheartp's COPR, not solopasha's, so the answer determines which COPR you pick."* `solopasha/hyprland` ships `uwsm`. The stated tiebreaker between the two COPRs is false.

**All other COPRs verified live with fedora-44 chroots**: `mhough/neurofedora` (225 pkgs, f44 x86_64+aarch64), `ycollet/audinux` (1491 pkgs, f44 x86_64+aarch64), `patrickl/wine-tkg`, `manhdv/xone`, `theimportedking/xone`, `shdwchn10/xpadneo`, `cherepavel/xpadneo`, `coffeeicus/ProtonUp-Qt-Copr`, `apicalshark/ProtonUp-Qt`, `solopasha/hyprland`, `lionheartp/Hyprland`, `@rocm-packagers-sig/F44` (f44 x86_64 only). Correctly-flagged-as-dead entries confirmed dead: `mrceresa/orthanc_epel` (no f44), `mwprado/ollama-cuda` (f43 only), `@ai-packagers-sig/agentic` (rawhide only). imagenology's neurofedora package claims are fine — the API returns SRPM names (`python-simpleitk`, `python-highdicom`, `python-dipy`, `python-nilearn`, `python-dicomweb-client`), which produce the claimed `python3-*` binaries.

---

## Bad Flatpak IDs (same hallucination class, cheap to verify, nobody did)

- **general**: `io.gitlab.librewolf-community.LibreWolf` → 404. Correct: `io.gitlab.librewolf-community`. Appears twice (`unavailable` + `flatpaks`).
- **gaming**: `io.github.azahar_emu.Azahar` → 404. Correct: `org.azahar_emu.Azahar`. Appears twice.
- **de-xfce**: `net.scummvm.ScummVM` → 404. Correct: `org.scummvm.ScummVM`.
- **de-xfce**: `io.github.dosbox_staging.dosbox_staging` → 404. Correct: `io.github.dosbox-staging`.
- **de-xfce**: asserts under `unavailable` that *"org.gtk.Gtk3theme.Chicago95 (Flathub runtime extension) — Does not exist on Flathub."* **It does exist** — `{"type":"runtime","id":"org.gtk.Gtk3theme.Chicago95","name":"Chicago95 Gtk Theme",...,"bundle":"runtime/org.gtk.Gtk3theme.Chicago95/x86_64/3.22"}`. The manifest's entire `/etc/flatpak/overrides/global` bind-mount + `GTK_THEME=` workaround is built on a false negative; the supported extension is the correct answer.
- **de-cosmic-hyprland**: `org.gnome.SystemMonitor` → 404; GNOME System Monitor is not on Flathub under any ID.
- 44 other IDs verified 200 (Chrome, Brave, Edge, Vivaldi, Chromium, Firefox, Thunderbird, Signal, Bitwarden, Riot, Discord, Spotify, Zoom, Slack, Flatseal, Warehouse, Secrets, calibre, VLC, LibreOffice, Steam, Heroic, pupgui2, Bottles, PCSX2, RPCS3, DuckStation, PPSSPP, melonDS, xemu, Flycast, Cemu, Weasis, AlizaMS, InVesalius, DisplayCAL, ARX, Ghidra, ZAP, Cutter, ExtensionManager, Alpaca, PodmanDesktop, GdmSettings, Boxes, ffmpeg-full).

---

## External spot-checks (6)

| Manifest | Claim | Result |
|---|---|---|
| imagenology | `github.com/nroduit/Weasis/releases/download/v4.7.1/weasis-4.7.1-1.x86_64.rpm` | **200**, and `v4.7.1` *is* the current `releases/latest` tag. Accurate. |
| llms | `nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo` | **200**. Correct shape, project alive. |
| general | Brave `brave-browser-rpm-release.s3.brave.com/x86_64/` | Directory listing 404 (expected for S3) but `…/repodata/repomd.xml` **200**. Valid repo. |
| security | SecLists, hcxdumptool (ZerBea), openwall/john | all **200**, all alive. |
| gaming | umu-launcher, LACT GitHub releases | both **200** via `releases/latest`. |
| de-xfce | `grassmunk/Chicago95` pinned tag/commit | Repo **200**, but `releases/latest` = **v3.0.1, 2022-10-17** — no tagged release in ~3.8 years. The "pin a tag" advice is workable only against a commit SHA; the manifest doesn't note the tag staleness, and its `install_all`/`make man` dependency analysis is against an unpinned HEAD. |

---

## Per-manifest verdict

| Manifest | Names | Bad | COPR | Flatpak | Verdict |
|---|---|---|---|---|---|
| **security** | 179 | **2** | **3/4 broken** | — | **WORST. Package list nearly clean, but the COPR field is fabricated — the primary Wi-Fi driver COPR does not exist, and two of three fallbacks have zero usable chroots. `dnf copr enable melmorabity/8812au` fails outright. Do not ship.** |
| **de-xfce** | 100 | 1 malformed | none | **2 wrong IDs + 1 false "does not exist"** | Poor on non-RPM claims. Package list verified except the prose-in-name-field bug. Flathub was not checked at all; the Chicago95 GTK theme false-negative invalidates a whole integration section. |
| **de-cosmic-hyprland** | 56 | 0 | **1 false claim** | **1 bad ID** | Package list excellent (COSMIC + Fedora-side Hyprland deps all real). Both COPRs live. But the solopasha-lacks-uwsm claim is false and steers the COPR choice wrongly; `org.gnome.SystemMonitor` invented. |
| **general** | 95 | 0 | n/a (empty) | **1 bad ID (×2)** | Very good. Package verification is genuine — even `lha`, `arj`, `lzip`, `7zip-standalone`, `evince-djvu` resolve. Honest about the google-chrome build-host contamination. Only the LibreWolf Flathub ID is wrong. |
| **gaming** | 54 | 0 | 0 | **1 bad ID (×2)** | Very good. All 6 COPRs live with f44 chroots; multilib specs correct; `vkBasalt` casing right. Azahar ID wrong. |
| **music** | 149 | 0 | 0 | 0 | **Excellent.** Largest list after security/desktop-common, zero errors, including every capitalisation trap it warned about. audinux verified: all 23 claimed packages present. Verification claim is credible. |
| **imagenology** | 46 | 0 | 0 | 0 | **Excellent.** Weasis URL + version accurate, neurofedora contents confirmed, dead-COPR call correct, `java-21` absence claim correct. |
| **llms** | 77 | 0 | 0 | 0 | **Excellent.** Whole ROCm/hip name-soup verified. COPR chroot claims (incl. the "do not use" ones) all match the API exactly. |
| **desktop-common** | 208 | 0 | n/a | 0 | **Excellent.** Largest list, zero errors; the four "names that don't exist on F44" corrections it makes (`liberation-fonts`, `google-noto-cjk-fonts`, `mesa-va-drivers`, `symbols2`) are all independently confirmed. |
| **de-gnome** | 111 | 0 | n/a (empty) | 0 | **Excellent.** All GNOME 50 names, extensions and colour-management packages real. |

**Overall: 3 bad package names / 1075 (0.28%). The failure is not in package verification — it is in the fields nobody was told to verify.** COPR and Flatpak identifiers were fabricated at ~15× the rate of RPM names (5 bad COPR facts, 6 bad Flathub IDs out of ~70 checked). If the instruction was "verify with `dnf repoquery`", the agents did that; anything outside dnf's reach was written from memory.