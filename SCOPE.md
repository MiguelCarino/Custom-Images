# Project Scope

Status: **decision record** — rev 6, 2026-08-15
Backed by repo-verified research in `research/` (12 manifests, 2 adversarial audits;
1075 package names checked against live Fedora 44 repositories in the rev 3 audit, and
every manifest added since verified the same way).

This is a record of decisions and their reasoning, not a spec — `ARCHITECTURE.md` is the
binding spec. Superseded decisions are kept, struck through or marked **SUPERSEDED**, so
the reasoning survives the change. Rev 4 reconciles the document with two decisions taken
after rev 3: **GNOME was dropped** (§5, §6) and **published images were renamed**
`carino-<purpose>` (§6).

**Rev 5 adds a seventh purpose, `pbx`, and with it a second branch of the layer tree**
(§3, §4.2, §5, §6.1). It is the first *appliance* rather than a workstation: it pins
`DE="headless"`, a session layer whose parent is `base`, so it inherits no desktop at
all. Two things that read as settled were revisited to allow it — the assumption that
every purpose sits on `desktop-common`, and the decision in §4 that server purposes leave
for Carino Setup. Both are addressed rather than quietly dropped, in §4.2.

**Rev 6 adds an eighth purpose, `offline`, the second appliance on that branch**
(§2, §4, §4.3, §5, §6.1). It needed no new mechanism and no new layer: `de/headless` was
written for `pbx` but was never specific to it, and taking a second consumer with no change
to the build system is the evidence for that claim rather than a restatement of it. What
rev 6 does revisit is §4's list of purposes dropped to Carino Setup, which named *Offline* —
that entry is marked superseded below, and §4.3 sets out the system integration that puts
this version of it back on this side of the §2 boundary.

---

## 1. What this project is

A build system producing **Fedora** OS images and installable media, parameterised by
**purpose** and **desktop environment**.

```
Stage 1 — abstract              Stage 2 — Fedora-specific       Stage 3 — artifacts
┌────────────────────┐          ┌──────────────────────┐        ┌──────────────────┐
│ layer manifests    │          │ resolve + verify     │        │ OCI image        │
│  · base            │─────────▶│ against F44 repos    │───────▶│ (registry)       │
│  · desktop-common  │          │ emit per backend:    │        │                  │
│  · de/*            │          │  · Containerfile     │───────▶│ ISO              │
│  · purpose/*       │          │  · osbuild blueprint │        │ (object storage) │
└────────────────────┘          └──────────────────────┘        └──────────────────┘
```

**Target: Fedora 44 only.** The distro axis is gone — the old distro tree and the
`fedora`/`el9`/`el10` family mechanism were archived to `legacy/config/distros/`. Since rev 4 the
**desktop axis is fixed too** (§5): one DE layer, so an image is parameterised by purpose
alone.

---

## 2. Project boundary

Two **separate** projects.

| | This project (builder) | Carino Setup |
|---|---|---|
| **Job** | Produce Fedora ISOs and OS images | Configure an already-installed system |
| **Distros** | Fedora 44 | Fedora, RHEL family, Debian, Ubuntu, Arch, openSUSE |
| **Purposes** | 8 (those needing system integration) | ~19 (any package set) |
| **DEs** | 1 desktop layer (COSMIC + Hyprland) + a headless layer | 13 |
| **Delivery** | Registry + ISO downloads | `bash <(curl -s https://setup.carino.systems/setup.sh)` |

Catalogs are deliberately **not** in parity. Anything that is "just a package list"
belongs in Carino Setup.

That rule is the one every new purpose has to survive, and both appliances are argued
against it in full rather than waved past it: `pbx` in §4.2, `offline` in §4.3. The test is
not "is this a server" — §1 and §2 never said the project only makes workstations — it is
whether the decisions have to be made before first boot. A package list can be installed
later; a resolver that has to own port 53 on a machine whose only way to fetch the script
is to resolve a name cannot be.

✅ **The drift lint exists** — `tools/check-drift.sh`, `ARCHITECTURE.md` §11b. It compares
at the *application* level rather than the package-name level, because the two projects
deliver the same purpose by different and equally correct means: Setup reaches for Flatpak
wherever a name is not portable across ~40 distros, this project puts things in `/usr` as
RPMs. Comparing package names would flag good decisions as errors. Only `imagenology` has a
manifest so far; it reports four missing viewers (§4).

---

## 3. Layering model

```
base
  ├─ desktop-common          DE-agnostic infrastructure
  │    └─ de/cosmic-hyprland  the only DESKTOP layer since rev 4 (§5)
  │         └─ purpose/<name>
  └─ de/headless             no desktop at all — console + SSH (rev 5)
       └─ purpose/<name>
```

`DE` remains a required field on every purpose, and rev 5 showed it was the right shape:
adding an appliance branch needed no code change at all. A purpose's parent has always
been derived from its pin, and a layer's parent has always come from its own conf, so
`de/headless` declaring `PARENT="base"` is enough to keep PipeWire, portals, Flatpak,
fonts, Mesa and a browser off the appliance images. The field's meaning is unchanged —
"which session does this purpose run in" — and for an appliance the answer is the console.

One thing did move: **`initial-setup` was relocated from `desktop-common` to `base`**. It
is a console text UI for creating the first account, with nothing desktop about it, and
the headless branch does not inherit `desktop-common` — left where it was, an ISO install
of `carino-pbx` would have come up with no account and no greeter to make one.

Supporting fragments, added on the layering audit's recommendation (`research/audit-layering.md` §2)
because dumping shared content into `desktop-common` puts compilers and packet sniffers
on every image:

| Fragment | Contents | Consumed by |
|---|---|---|
| `dev-common` | gcc-c++, cmake, ninja, python3-devel, pip, pipx, virtualenv, git-lfs | security, llms |
| `net-diag` | tcpdump, tshark, socat, nmap-ncat | security, imagenology |
| `wine` | wine, wine-core (+ .i686), winetricks — ~2 GiB | gaming, music |
| `python-sci` | numpy, scipy, matplotlib, pandas | imagenology, llms |

**The rule:** purpose manifests contain no DE packages, fonts, codecs, or generic desktop
infrastructure. DE manifests contain nothing DE-agnostic. This is currently violated
everywhere (§7) — enforcing it is the core refactor.

---

## 4. Purposes

**Eight since rev 6** (six workstations and two appliances, §4.2, §4.3). `General` is retained by decision — the everyday image with the recommended
all-purpose apps (mpv, LibreOffice, …). The §7.1 findings still apply as *cleanup work*,
though the resolution changed: rev 3 planned to fix General's three-way DE contamination by
pinning it to GNOME and moving GNOME-native apps into `de/gnome`. With GNOME gone (§5) that
route is closed — the contamination must instead be resolved by dropping the non-wlroots
packages outright. Its "pick one" duplicates (Thunderbird vs Evolution, papers vs evince,
VLC vs mpv vs Celluloid) must still be picked in the package phase.

⚠️ **Regression created by the GNOME removal:** `file-roller`, `gnome-calculator` and
`simple-scan` lived in `de/gnome` and now have no home — nothing pulls them and COSMIC
ships no equivalent archiver, calculator or scanning front end. Recorded in
`config/purposes/general.conf`; the package phase must place them.

| Purpose | Integration that justifies an image | State |
|---|---|---|
| **General** | The default recommendation; MIME defaults, gvfs plumbing, curated app set | manifest ready (needs §7.1 cleanup) |
| **Imagenology** | DICOM MIME handlers, spool dir, audit rules, display calibration | ✅ partly built — **no viewer yet** (§4.1) |
| **Gaming** | Controller udev, GameMode governor hooks, `split_lock_detect=off`, vm.max_map_count | manifest ready |
| **Music** | Realtime limits, rtkit, `threadirqs`, low-latency PipeWire quantum, USB-audio udev | manifest ready |
| **Security & Forensics** | `setcap` dumpcap, forensic write-block udev, automount disable | manifest ready |
| **LLMs** | Ollama service + model storage, GPU device groups, ROCm/CUDA, VRAM tuning | manifest ready |
| **PBX** *(rev 5)* | Which PHP serves the UI, who owns the web root, who supervises Asterisk, where `fwconsole` may live on a read-only `/usr` | ✅ built and verified; **first-boot install untested** (§4.2) |
| **Offline** *(rev 6)* | Who owns port 53 and `/etc/resolv.conf` once `systemd-resolved` is masked, where a site CA root lands in the trust store, how `dnf` points at a LAN mirror without deadlocking the box, how chrony keeps serving time with nothing upstream | manifest verified against F44 and against the built headless layer; **nothing booted** (§4.3) |

Dropped along the way, all to Carino Setup: Coding, Corporate, Astronomy, Comp-Neuro,
Design, Scientific, Robotics (ROS 2 targets Ubuntu — better as a Distrobox guest),
~~Offline~~ (**SUPERSEDED (rev 6)** — see §4.3. The dropped entry is read as an offline
*workstation* package set, the kind of thing Setup installs on a machine that will lose its
connection; the purpose added in rev 6 is the server such machines ask. The original list
recorded no detail, so that distinction is drawn now rather than recovered),
~~PACS server~~ (see §4.2 — the *reason* it went still stands, but "it is a
server" was never the reason).

### 4.1 Imagenology ships a toolchain but nothing to look at a study with

Found by the drift check (§2). The image has DCMTK, GDCM, pydicom, pynetdicom, dcm2niix
and nibabel — a study can be parsed but not viewed. Carino Setup's equivalent profile
installs three viewers plus `xmedcon`, none of which the image carries:

| Missing | Delivery in Setup |
|---|---|
| Weasis | `io.github.nroduit.Weasis` (Flathub) |
| Aliza MS | `com.github.AlizaMedicalImaging.AlizaMS` |
| InVesalius | `br.gov.cti.invesalius` |
| xmedcon | RPM |

Scheduled §11 Phase 2 work, not an oversight — but it is the gap that most undermines the
purpose, so `tools/check-drift.sh` is deliberately left reporting it rather than exempting
it.

**PACS server: resolved by archiving.** The full pre-restructure system — pacs-server
included — lives in the baseline git commit and under `legacy/`.

### 4.2 PBX — the first appliance (rev 5)

`carino-pbx` is Asterisk with the FreePBX 17 web UI, MariaDB, Apache and PHP 8.2. Adding
it crossed two lines this document had drawn, so both are argued here rather than left
for a reader to notice.

**"Anything that is just a package list belongs in Carino Setup" (§2) — it holds.** A PBX
is the opposite of a package list. Four decisions have to be made before first boot and
cannot be made afterwards without taking the phone system down:

| Decision | Why an image and not a script |
|---|---|
| Which PHP serves the UI | FreePBX 17 requires **8.2** and upstream says 8.3+ must not be installed. Fedora 44 ships **8.5**. The runtime comes from Remi's SCL packages under `/opt/remi/php82`, parallel to Fedora's, and Fedora's PHP is deliberately not installed at all |
| Who owns the web root | Apache runs as `asterisk:asterisk`, matching `fwconsole chown`. As `apache:apache` FreePBX cannot install its own modules |
| Who supervises Asterisk | `fwconsole`. `asterisk.service` is **masked**, because two supervisors racing for `asterisk.ctl` is the classic failure of FreePBX on a distro Asterisk package |
| Where `fwconsole` lives | FreePBX installs it to `/usr/sbin`, which is read-only on bootc. `--ampsbin=/usr/local/sbin` puts it on the `/var/usrlocal` symlink instead |

**"PACS server was dropped" (§4) is not a precedent against it.** That decision archived a
half-built subsystem of the pre-restructure tree; it was about *that code*, not about a
rule that servers are out of scope. Nothing in §1 or §2 says the project only makes
workstations, and the boundary that does exist — system integration vs package lists —
puts a PBX firmly on this side. What the PACS episode does contribute is the shape of the
risk: server purposes are where half-finished work hides longest, because nobody notices a
feature that was never wired up until the day it is needed.

**What is verified and what is not.** Verified 2026-08-06 per §7.2: every package name
against live Fedora 44, `remi-release-44` and `php82-php-*` 8.2.33 against Remi's F44
repo, the FreePBX tarball URL, and a full `./build.sh build pbx` including
`bootc container lint`, `httpd -t` and `php-fpm -t` inside the built image.
**Not verified: the first-boot installation itself** — `/usr/libexec/freepbx-setup` needs
a booted machine, and it has not had one. It is left as a known-unverified step rather
than described as working; `research/manifest-pbx.json` names the three places it is most
likely to break first.

**FreePBX escapes the transactional-update promise, and that is stated rather than
hidden.** The OS and the runtime under it upgrade with `bootc upgrade` and roll back with
`bootc rollback`. FreePBX itself lives in `/var`, updates through `fwconsole ma
upgradeall`, and migrates a database schema that no image rollback will undo. Backups come
from FreePBX's own backup module, not from the image.

### 4.3 Offline — the intranet keystone, and the second appliance (rev 6)

`carino-offline` is, in its own conf's words, an *"intranet keystone appliance:
authoritative and recursive DNS, LAN time, internal-CA trust store, an RPM mirror and
offline content over HTTP, and the sneakernet media pipeline"* — 18 packages around bind,
chrony, Caddy and kiwix-serve. It is the box a LAN with no working WAN still gets names,
time, trust, packages and content from. It pins `DE="headless"` for the reason its
`PIN_REASON` records: *"an appliance that has to answer on the LAN's own ports before
anything else on the network is up: DNS, NTP and HTTP are its interfaces and SSH is its
console, so a desktop would only add attack surface, RAM and packages to patch to the one
box the network cannot lose."* The chain is `base → de/headless → offline`, with the same
three consequences `pbx` documents: no desktop, no session, and no first-boot Flatpak
mechanism, because the installer lives in `desktop-common` and this branch never touches it.

**"Anything that is just a package list belongs in Carino Setup" (§2) — it holds, and this
is the purpose that had to prove it,** because a name server and a web server are exactly
the shape of thing a script could install. Five decisions cannot be made after the fact:

| Decision | Why an image and not a script |
|---|---|
| Who owns port 53 | `systemd-resolved` is installed **and preset-enabled** on the bootc base — verified in the built `carino-layer-de-headless`: 259.7, `is-enabled` returns enabled, and `enable systemd-resolved.service` appears in both `90-default.preset` and `90-systemd.preset`. `systemctl disable` does not survive a preset re-run; masking does. The usual workstation answer, `DNSStubListener=no`, leaves resolved as the host's resolution path, so the appliance keeps a second cache that can answer an internal name differently from the answer it is giving the building |
| Who owns `/etc/resolv.conf` | On that same base it is a symlink into `/run/systemd/resolve/`. Mask resolved without re-owning the path and the box has no resolver at all — which is not something a post-install script can repair, because it runs after the machine has lost the ability to resolve the name of the script's own source |
| Where a site CA root lands | An internal CA needs an anchor directory that exists and an `update-ca-trust extract` run where it takes effect. No root is baked and none can be: a private key inside an image is the same private key on every machine that installs it |
| Where packages come from | `dnf` has to be pointable at a LAN mirror without deadlocking the box's own package tooling on a hostname that may not resolve — which is why the repo file ships in `/usr/share` and is deliberately *not* installed into `/etc/yum.repos.d` |
| Whether the clock may serve | chrony is inherited from `de/headless`, but serving time with nothing upstream reachable takes one directive nothing installs for you, and the failure is silent for weeks: without it every NTP answer carries leap indicator 3 and every client correctly rejects it |

**Not a router, deliberately.** DHCP, routing and VLANs stay on the MikroTik. Putting them
here would make the keystone the router too, which is the single point of failure the
layered design exists to avoid — a service layer that survives one box dying cannot be one
box. The consequence is recorded rather than hidden: a fresh `carino-offline` on a network
with no other infrastructure serves nobody, because nothing tells clients to ask it.

**What is verified and what is not.** Verified 2026-08-15 per §7.2, two ways: package names
and versions against live Fedora 44 with `dnf repoquery`, and the system facts this purpose
depends on — the preset state, the `resolv.conf` symlink, the contents of `/etc/chrony.conf`,
the absence of a chrony drop-in directory, the `gpsd.socket` preset line — inside the
already-built `localhost/carino-layer-de-headless`, which is this purpose's actual parent.
**Nothing has been booted**, and no image has been built: no ISO, no started unit. The piece
most likely to bite first is the port-53 arbitration (§8.3). Two substitutions are recorded
as real losses rather than smoothed over: step-ca is not packaged for Fedora 44, so a
LAN-wide internal ACME server is not delivered, and Technitium — the plan's actual choice of
DNS server — is a .NET tarball, so anyone expecting its GUI gets `named.conf` and a text
editor. `research/manifest-offline.json` carries both, along with ten recorded risks.

**The image is not the plan.** The reasoning for a whole offline site — what it is for, what
else is in it, what the bill of materials looks like — lives at
<https://offline.carino.systems> (section *00 - Start*), and that page points back at this
repository. Neither document is the other's summary: the site is the plan, this is one box
in it.

---

## 5. Desktop environments

**One desktop layer**, Wayland-only — the project has no X11 session, which is acceptable
only because imagenology resolved to hardware-LUT calibration (§8.1). Rev 5 adds a second
layer under `config/layers/de/` that is not a desktop at all.

| Layer | Notes |
|---|---|
| `de/cosmic-hyprland` | COSMIC + Hyprland co-installed; `cosmic-greeter` enumerates both sessions — **verified working**, the one end-to-end-confirmed claim in the manifest set |
| `de/headless` *(rev 5)* | No desktop: `openssh-server`, `firewalld`, `chrony`, `cronie`, `logrotate`, `tuned`, `policycoreutils-python-utils`, `bash-completion`, `tmux`. `PARENT="base"`, so it skips `desktop-common` entirely — and with it the first-boot Flatpak mechanism, which purposes on this branch must do without. Built for `pbx`; since rev 6 `offline` sits on it too, and taking a second purpose with no change to the layer or to the build system is the evidence that it was never `pbx`-specific |
| ~~`de/gnome`~~ | **SUPERSEDED (rev 4) — removed.** Mature, and the only DE whose dconf automount lock works. Its layer conf was deleted; no purpose pins to it. |

**Why GNOME went.** Every desktop shipped is a desktop that has to be verified against
every purpose, and unverified combinations are how integration work rots. One session,
built once, means tearing control, per-output VRR, no file indexer and no automounter are
each decided once and inherited by all six desktop images.

**What it cost, recorded so the reasoning survives:**

- **Colour management.** GNOME's `colord` integration applied ICC/VCGT at session start;
  `de/cosmic-hyprland` ships no ICC applier at all (§7.4). Imagenology is the purpose that
  cared, and it lost its fallback — see §8.1, whose "with 100%/200% integer scaling on
  GNOME" advice no longer has a desktop to run on.
- **Forensic automount.** The rev 3 pin rested on GNOME's dconf `media-handling` lock.
  The replacement argument is stronger, not weaker: neither `desktop-common` nor
  `de/cosmic-hyprland` pulls a desktop automounter at all, so there is nothing to lock —
  verified against both layer manifests.
- **Three everyday apps lost their home** (§4).

**XFCE and Chicago95 were dropped earlier.** Consequences, recorded so the reasoning survives:

- Music and LLMs re-pin from XFCE to Hyprland, which the audit rates `OK` for both (no file
  indexer; least VRAM held by the desktop).
- The project loses its only X11 session. Safe **only** because §8.1 chose hardware-LUT
  calibration; the software-calibration option would have required XFCE.
- Chicago95 was XFCE-only, so it goes too. It was already headed for demotion to an optional
  fragment (forced antialiasing off and 8 pt bitmap fonts, ignored entirely by GTK4/libadwaita
  apps, no upstream release since Oct 2022).
- `de/xfce` also carried the most defects of any manifest — 18+ layer violations, build-time
  packages (`make`, `git-core`) shipped into the runtime image, and a malformed package entry.

Research retained in `research/manifest-de-xfce.json` should this ever be revisited.

---

## 6. The matrix does not multiply — purposes pin to DEs

The layering audit's conclusion: *"expect 4–6 real image tags, not 18."* Purposes have
hard DE requirements, so the cross product is fiction.

**SUPERSEDED (rev 4).** The matrix collapsed to a single column when GNOME was removed
(§5). Six purposes, one DE, six images — and since rev 5 a second column that is not a
desktop at all, carrying `pbx` (§4.2) and, since rev 6, `offline` (§4.3). Eight purposes,
two columns, still one pin each and still no cross product: the second column grew a row
without the first one changing. The rev 3 analysis below is retained because three
of its rows recorded *why* a purpose needed GNOME specifically, and those costs did not
disappear when the column did — they are now carried, unmitigated, by the images that
inherited them. §5 records what each one cost.

### 6.1 Current pins

| Purpose | Pin | Reason recorded in the conf |
|---|---|---|
| **General** | cosmic-hyprland | single supported session: COSMIC for pointer-driven use, Hyprland when tiling is wanted |
| **Imagenology** | cosmic-hyprland | calibration is applied per-display with ArgyllCMS, not by the desktop |
| **Security & Forensics** | cosmic-hyprland | no desktop automounter in the session, so removable evidence is never mounted on insertion |
| **Gaming** | cosmic-hyprland | tearing control + bakeable per-output VRR |
| **Music** | cosmic-hyprland | no file indexer; lowest overhead |
| **LLMs** | cosmic-hyprland | leanest session; least VRAM held by the desktop |
| **PBX** *(rev 5)* | headless | an appliance administered over the network: the interfaces are the web UI and SSH, so a desktop would only add attack surface, RAM and packages to patch |
| **Offline** *(rev 6)* | headless | an appliance that has to answer on the LAN's own ports before anything else on the network is up: DNS, NTP and HTTP are its interfaces and SSH is its console, so a desktop would only add attack surface, RAM and packages to patch to the one box the network cannot lose |

Published image names follow **`carino-<purpose>`**: `carino-general`,
`carino-imagenology`, `carino-security`, `carino-gaming`, `carino-music`, `carino-llms`,
`carino-pbx`, `carino-offline`. Intermediate layers are `carino-layer-<slug>`.

**Why the mark leads and Fedora does not.** `fedora-<purpose>-<de>` was the rev 3 scheme.
The DE suffix stopped carrying information the moment every purpose shared one session, and
a published ref beginning `fedora-` reads as an official Fedora edition — a form Fedora
reserves for its own products (Workstation, Server, Silverblue, Kinoite) and which no
third-party derivative in the ecosystem uses. Upstream credit moved to where machines can
read it: `org.opencontainers.image.base.name` on every generated image, plus the visible
"Based on Fedora 44" attribution on the site.

Eight images, one backend. With the osbuild backend (§9) it would be **16 image tags total**,
though that backend produces no artifacts today (§9b).

<details>
<summary><strong>Rev 3 pin analysis (superseded — retained for the reasoning)</strong></summary>

The layering audit's conclusion: *"expect 4–6 real image tags, not 18."* Purposes have
hard DE requirements, so the cross product is fiction.

| Purpose | GNOME | COSMIC+Hyprland | Pin |
|---|---|---|---|
| **General** | **OK — mainstream default**; the curated app set assumes a conventional desktop | workable, but not what a general user expects at first boot | **gnome** |
| **Imagenology** | OK with hardware-LUT calibration (§8.1) | **BAD** — zero colour management; the DE manifest itself says do not read studies on it | **gnome** |
| **Security & Forensics** | **OK — only viable** — the dconf `media-handling` lock is load-bearing for write-blocking | **BAD** — `udiskie` automounts evidence from `hyprland.conf`; `cosmic-files` automounts with no documented disable | **gnome** |
| **Gaming** | MIXED — VRR unbakeable (lives in per-user `monitors.xml` keyed by monitor serial), no tearing control | **OK — best** — tearing control + per-output VRR, bakeable via `/etc/skel` | **cosmic-hyprland** |
| **Music** | MIXED — `localsearch` indexes sample libraries mid-take; heaviest DE against a 256-frame quantum | **OK** — no indexer, lowest overhead | **cosmic-hyprland** |
| **LLMs** | MIXED — `gnome-shell` holds a GPU context competing for VRAM with a large model | **OK** — Hyprland session is the leanest | **cosmic-hyprland** |

**Result: 6 pinned combinations, cleanly split two ways.**

- `de/gnome` → general, imagenology, security
- `de/cosmic-hyprland` → gaming, music, llms

Published image names follow **`fedora-<purpose>-<de>`**: `fedora-general-gnome`,
`fedora-imagenology-gnome`, `fedora-security-gnome`, `fedora-gaming-cosmic-hyprland`,
`fedora-music-cosmic-hyprland`, `fedora-llms-cosmic-hyprland`.

Build only the pinned combination per purpose. Everything else is Tier 3 — on-demand and
unsupported. With both backends (§9) that is **12 image tags total**.

</details>

---

## 7. What the research found

Full detail in `research/audit-layering.md` and `research/audit-package-existence.md`.

### 7.1 `General` is not a purpose — it is a second GNOME layer

> **Read as history.** The GNOME layer this compares against was removed in rev 4 (§5), so
> the duplication described here no longer exists — but the *contamination* it found does,
> and its resolution changed with it (§4).

29 packages byte-for-byte duplicated with the then-current `de/gnome` (`loupe`, `papers`, `sushi`,
`gnome-calculator`, `gnome-text-editor`, `seahorse`, all the `gvfs-*` backends, …). Worse,
it simultaneously ships packages for all three DEs — `tumbler` (XFCE), `file-roller-nautilus`
(GNOME), `grim`/`slurp` (wlroots) — which are three mutually exclusive assumptions in one
layer. And it ships mutually exclusive alternatives together: Thunderbird *and* Evolution,
papers *and* evince, VLC *and* mpv *and* Celluloid.

Everyday apps belong in the DE layer (each DE ships its native set) or `desktop-common`.
**Recommendation: drop `General`.** *(Decision pending.)*

### 7.2 Verification worked; everything unverified was fabricated

- **Package names: 3 bad / 1075 (99.7% clean).** The `dnf repoquery` instruction worked.
- **COPR and Flatpak IDs: fabricated at ~15× that rate** — 5 bad COPR facts, 6 bad Flathub
  IDs out of ~70 checked, because nothing forced verification of those fields.

The worst case: `security`'s headline Wi-Fi driver COPR `melmorabity/8812au` **does not
exist**, and two of three fallbacks have zero usable chroots. `dnf copr enable` fails outright.

**Process rule going forward: every external identifier gets verified, not just RPM names.**
COPR via the `copr.fedorainfracloud.org` API, Flathub via `flathub.org/api/v2/appstream`,
upstream URLs via HTTP. This is the single most valuable lesson from the run.

### 7.3 XFCE / Chicago95 — dropped (findings retained)

The XFCE layer was cut (§5). The findings are recorded because they informed that decision:

- Chicago95 as specified forced **antialiasing off and 8 pt bitmap Helvetica** — indefensible
  on the imaging and DAW workstations XFCE was pinned to serve.
- Every GTK4/libadwaita app ignores it entirely, so half the desktop rendered Adwaita anyway.
- It mandated `use_compositing=false`, removing the vsync path.
- The manifest claimed `org.gtk.Gtk3theme.Chicago95` "does not exist on Flathub". **It does** —
  the entire bind-mount workaround was built on a false negative.
- No upstream release since **v3.0.1 (Oct 2022)**; any pin would have to be a commit SHA.
- The layer shipped `make`, `git-core`, `bzip2` and `txt2man` into the runtime image — a
  build stage leaking into a published desktop.

### 7.4 Conflicts needing an assigned owner before anything ships

| Conflict | Detail |
|---|---|
| **`kargs.d` numbering** | `desktop-common` (`10-desktop`), `music` (`20-audio`), plus gaming/security/llms all want kernel args with no assigned numbers. Files merge by filename — two layers picking `20-` silently clobber each other. **Assign the convention first.** |
| **CPU governor** | `power-profiles-daemon` (desktop-common), `tuned` (music, llms), GameMode (gaming) — three consumers, one knob. All three purposes are pinned to the same DE layer, so this fires on every cosmic-hyprland image. Purposes touching CPU policy must mask `ppd`; that masking is specified nowhere. |
| **PipeWire low-latency** | `music`'s `99-*` drop-ins sort last and win **globally**, not just for Ardour — forcing 256-frame quantum on Firefox, blocking runtime PM, and `headroom=0` causes continuous xruns on internal HDA codecs. Must live under `/usr/share/daw/` behind the toggle the manifest describes but never implements. |
| **`mimeapps.list`** | `general`, `imagenology` and `security` all write the *same path*; last layer wins and silently discards the others. No layer should ship it — contribute numbered fragments merged at build. |
| **Colour management** | `colord` was triple-claimed by desktop-common, de/gnome and imagenology. `de/cosmic-hyprland` ships **no ICC applier at all**. Rev 3 called this acceptable *because imagenology was pinned to GNOME* — **that premise is void since rev 4** (§5). Imagenology now runs on the session with no applier, so §8.1's hardware-LUT route is not one option of two, it is the only one. |
| **Steam twice** | `desktop-common` pre-seeds Flatpak Steam; `gaming` installs the RPM. The gaming manifest itself calls this "a real failure mode". Shared layer must not pre-seed purpose apps. |

### 7.5 Concrete defects to fix in the manifests

- `p7zip` (security) — **does not exist on F44**; hard `dnf` transaction failure.
- `nbtscan` (security) — does not exist.
- `music`'s realtime limits sort-order reasoning is **inverted** — `95-daw-realtime.conf`
  parses *before* `realtime.conf`, so rtprio 99 wins and the claimed safety margin does not exist.
- `music` grants `LimitRTPRIO=95` / `LimitMEMLOCK=infinity` to **every user session**, from a purpose layer.
- `python3-torch` (llms) hard-requires `libmagma.so.2.9.0`, which the same manifest says is
  COPR-only — **may be unsatisfiable from Fedora repos**. Verify before it ships.
- `gaming` never adds the user to the `gamemode` group — identified as "the one step nothing
  does for you", then not done. Silently inert limits and governor switching.
- `security` never adds `util-linux` (for `blockdev`), on which the entire write-block rule
  depends — and it fails **silently**, the worst mode for that feature.
- `wine-core.i686` described in prose but not listed → 32-bit VST bridging silently broken.
- `llms` sets `vm.overcommit_memory=1` system-wide from a purpose layer.

---

## 8. Open decisions

### 8.1 Imagenology calibration — **RESOLVED: hardware LUT only**

Software calibration works only through X11 gamma ramps; on Wayland `argyllcms`/`dispwin`
**silently does nothing**. Calibration is done against the **monitor's internal LUT** —
`ddcutil`, Eizo RadiCS, Barco QAWeb.

**Reinforced by rev 4.** Rev 3 hedged by keeping GNOME, whose `colord` integration applied
VCGT at session start; that hedge is gone (§5), so the hardware LUT is now the only path
rather than the preferred one. That is arguably the more defensible position for the
FDA-submission goal — calibration state lives in the device, not in a session that may not
have started — but it is now load-bearing, and the "100%/200% integer scaling on GNOME"
advice below no longer has a desktop to run on.

**Consequences to design around:**
- Requires calibration-capable diagnostic monitors. Consumer panels cannot be calibrated
  on this image. State this in the image documentation.
- `argyllcms` / `DisplayCAL` should be **dropped** from the imagenology manifest, or shipped
  only as measurement tools with an explicit note that profile *application* is the
  monitor's job. Shipping them as-is implies a workflow that does not function.
  ⚠️ **Still unresolved:** `argyllcms` and `colord-extra-profiles` are both still in
  `config/purposes/imagenology.conf`, and the purpose's `PIN_REASON` now cites ArgyllCMS
  by name. Either the packages go or the note gets written — currently neither.
- Weasis is Java/Swing and runs through XWayland — verify DPI and greyscale rendering there
  during acceptance testing.

### 8.1a Hyprland COPR — **RESOLVED: `lionheartp/Hyprland`**

The manifest offered `solopasha/hyprland` and `lionheartp/Hyprland` and leaned toward the
latter — it is what the Fedora 44 research host actually runs, it ships `uwsm` /
`hyprland-uwsm` for systemd user-session scoping consistent with COSMIC, and its own COPR
description states it is forked from solopasha.

The one objection on record was a **`hyprland-git` snapshot trap**: the repo carries dozens
of git snapshot builds alongside stable, and the manifest warned `dnf` might resolve to one.
**Verified 2026-07-27 and retired** — checked per §7.2 against the COPR API and then in a
`fedora` container:

- project exists, chroots `fedora-44-x86_64` and `fedora-44-aarch64`
- `hyprland` resolves to stable **0.56.0-1.fc44**
- **nothing other than `hyprland` Provides `hyprland`** — the snapshots are separate package
  names (`hyprland-git`, `hyprland-plugins-git`, …), not higher-EVR builds of the same name
- `hyprland-git` obsoletes only the historical `hyprland-aquamarine-git` /
  `hyprland-nvidia-git` renames, never `hyprland`

So a plain `dnf install hyprland` cannot land on a snapshot. The repo still tracks upstream
aggressively, so the pin recommendation stands — that is a churn concern, not a correctness one.

**Not adopted:** the manifest's `uwsm` lean. The layer keeps the in-Fedora substitutes
(`swaylock`/`swayidle`/`swaybg` rather than `hyprlock`/`hypridle`/`hyprpaper`) to keep COPR
surface minimal. Revisit in the package phase if session scoping consistency matters.

### 8.2 Resolved since rev 3

- **`General`: kept** (user decision). Pinned to GNOME in rev 3; re-pinned to
  cosmic-hyprland in rev 4 (§5). §7.1 findings become package-phase cleanup.
- **pacs-server: archived** — baseline git commit + `legacy/`.
- **`kargs.d` convention: assigned** — slots by layer kind (10 base / 20 desktop-common /
  30 DE / 40 purpose), see `ARCHITECTURE.md` §7. Collisions are structurally impossible.

### 8.3 Still open

1. Installer ISO or live ISO for the osbuild backend?
2. What is *n* in "every n days"?
3. ~~New project name~~ **RESOLVED (rev 4).** Brand is *Carino Custom Images*; images are
   `carino-<purpose>`. The project is **not** a distribution and does not claim to be —
   it builds no packages, patches nothing, and hosts no repository, so "Carino Linux" was
   rejected as claiming work the project does not do. Repository directory rename and the
   `linux`/`images` subdomain remain the owner's call.
4. **Where do published artifacts live?** Registry choice (§10) fixes the `bootc switch`
   ref shape and the site's `RELEASES` map; nothing is published yet.
5. **Image signing.** If people `bootc switch` to the registry, unsigned images are a
   supply-chain question. Unaddressed.
6. **Boot `carino-pbx` and run the first-boot install** (rev 5, §4.2). The image builds
   and everything in it is verified, but `/usr/libexec/freepbx-setup` has never executed
   on a real machine. Until it has, the FreePBX half of that image is a claim, not a
   result — and it is the half a user meets first.
7. **Pin the Remi repository** (rev 5). `REPO_RPMS` fixes no version, so a rebuild takes
   whatever `php82-php-*` is current that day. Same class of problem as the Hyprland COPR
   pin (§8.1a), same place to solve it: the package phase.
8. **Build and boot `carino-offline`, and read the resolver state first** (rev 6, §4.3).
   Nothing in that purpose has been built or started. The specific thing to check before
   believing any of it is whether NetworkManager's `dns=none` / `rc-manager=unmanaged`
   drop-in actually takes: if it does not, the first carrier event writes a DHCP-supplied
   resolver over the tmpfiles symlink and the appliance starts answering from an upstream
   cache — on the machine whose entire job is to be the authority. `resolvectl status`,
   `nmcli dev show | grep DNS` and `ls -l /etc/resolv.conf`, in that order.

---

## 9. Backends

Both are retained. Every manifest must therefore be expressible twice.

### 9a. bootc (primary)

Proven. `Containerfile` → `podman build` → registry → `bootc-image-builder` → ISO.
Atomic updates, `bootc switch` / `bootc rollback`.

### 9b. osbuild blueprints — traditional Fedora Workstation

Serves the one remaining axis: **atomic vs traditional**. Manifests map closely onto
blueprint `[[packages]]` / `[customizations]`, which is a better fit than hand-written
Kickstart + Lorax.

**Built since rev 3, and narrower than hoped.** `./build.sh blueprint` emits
`generated/<image>/blueprint.toml` (`ARCHITECTURE.md` §10). It is an **export, not a build
path** — nothing depsolves or builds it, so the TOML is handed to `composer-cli` by hand,
and that route has not been executed end to end. The blueprint is also a **lossy** copy,
never an equivalent: COPRs, Flatpaks, static files and `POST_SCRIPT` have no representation,
and a service whose unit ships only in a layer's own file tree is *omitted* from `enabled`
because osbuild runs `systemctl enable` during the build and a missing unit fails it. Every
omission is printed in the TOML header and warned about on the terminal, so a thin blueprint
cannot pass as a clean generate.

**Risks specific to this backend, given the DE choices:**
- **COPR dependency.** Hyprland comes from a COPR (`lionheartp/Hyprland`, §8.1a), and COSMIC
  may need one. Blueprints support custom repos, but this is more fragile than a Containerfile
  `dnf copr enable` and needs proving early.
- `/etc/skel` Hyprland config must be delivered through blueprint file customizations rather
  than a `COPY`.
- **Open:** installer ISO or live ISO (§8.2). `image-installer` produces bare-metal installer
  media only; live media needs Lorax/`livemedia-creator` — a third toolchain.

---

## 10. Automation and hosting

- **Runner:** self-hosted. GitHub-hosted runners have ~14 GB free disk and cannot build
  multi-GB ISOs; `bootc-image-builder` needs privileged podman.
- **Images:** GHCR or Quay.io. Primary artifact — what `bootc upgrade`/`switch` consume.
- **ISOs:** S3-compatible storage; Cloudflare R2 (zero egress). GitHub Releases is out — 2 GB cap.
- **Schedule:** every *n* days + manual trigger.

---

## 11. Work breakdown

**Phase 1 — build flow (current):** see `ARCHITECTURE.md`, the binding spec.
✅ git init + baseline archive · ✅ legacy system moved to `legacy/` · ✅ layered config
model (base → desktop-common → de → purpose) with data-driven inheritance ·
✅ per-layer build contexts (fixes the legacy `COPY ../../` bug) · ✅ `kargs.d` slots ·
✅ first-boot Flatpak mechanism · ✅ `carino-<purpose>` naming + `base.name` attribution ·
✅ docs website · ✅ osbuild blueprint export (§9b) · ✅ purpose drift check (§2) ·
starter package sets only.

**Phase 2 — packages & environments (next):**
1. Land the full 6 purpose manifests from `research/`, applying §7.5 fixes and §7.1
   General cleanup.
2. Add the `dev-common` / `net-diag` / `wine` / `python-sci` fragments.
3. Single-owner each §7.4 conflict (governor masking, PipeWire toggle, mimeapps fragments).
4. Re-verify all COPR IDs, Flathub IDs and upstream URLs (§7.2).
5. Integration files: udev rules, limits, PipeWire drop-ins, DICOM MIME, write-block rules.

**Phase 3 — automation:** self-hosted runner + scheduled workflow + R2 upload; osbuild
ISO production.

### Carino Setup (separate track)

Status re-checked against `setup.sh` on 2026-07-27.

1. ✅ **Menu/dispatch desync fixed.** Was a live bug: item 4 "Development" ran Corporate,
   item 12 "Offline" ran Forensics, items 13–15 unreachable, all 8 translations carrying the
   same wrong list. `test.sh` now asserts menu-to-dispatch parity per language; the purpose
   menu prints 16 items and dispatches the same 16.
2. ◐ **Partly wired.** `astronomyPackages` and `compneuroPackages` are now referenced
   (4 expansions each). `carinoPackages`, `corporateFlatpak` and `multimediaFlatpak` are
   still defined and never expanded — 0 uses each.
3. Fill the remaining stub purpose branches.
4. ✅ **imagenology added as a purpose** — and is the one purpose with a drift manifest (§2).
5. Fill or formally drop the empty `rhel*Packages` / `centos*Packages` DE entries. The
   CentOS/EPEL hyprland, sway, budgie and niri lists are populated with names EPEL does not
   carry, so `--skip-broken` drops them silently and reports success.

---

## 12. Risks

| Risk | Impact |
|---|---|
| **Imagenology needs calibration-capable monitors** | Hardware-LUT-only (§8.1) means consumer panels cannot be calibrated on this image. Since rev 4 removed GNOME's `colord` applier there is no software fallback at all, so this moved from an expectation-setting issue to a hard requirement. |
| **Unverified external identifiers** | COPR/Flathub/URL hallucination at ~15× the RPM rate (§7.2). Mitigated only by an explicit verification step. |
| **Single-maintainer COPR in the trusted base** | Hyprland comes from `lionheartp/Hyprland` (rev 4; previously `solopasha/hyprland`, from which lionheartp is forked). **Escalated in rev 4:** with one DE layer this COPR sits under **six of the eight** purposes — every desktop image depends on it, and it is the only COPR in the project. *(Rev 6: the two appliances on the headless branch do not touch it, which narrows the blast radius from "everything published" to "everything with a desktop" — a real reduction, and not one anybody designed for.)* Pin it (versionlock or dated snapshot) in the package phase. |
| **One Wayland-only DE, no X11 escape hatch** | Narrowed further in rev 4 (§5): a future purpose needing X11, or needing GNOME specifically, has nowhere to go. The `DE` field survives precisely so re-adding a layer stays cheap. |
| **COSMIC maturity** | Young on an immutable base; expect breakage across Fedora releases. |
| **NVIDIA on atomic** | Kernel modules and image-based OS mix poorly; container-based GPU access (CDI) is the realistic path for LLMs. |
| **Baking Flatpaks at build time** | `RUN flatpak install --system` is unreliable in a container build (no session bus). Needs a first-boot systemd unit. |
| **osbuild + COPR** | The traditional-Workstation backend must pull Hyprland from a COPR through a blueprint — prove this early (§9b). |
| **ISO size** | Existing medical ISO is 5.4 GB; `llms` alone is an 8–9 GB layer before a desktop. |
| **`carino-offline` is unbuilt and unbooted** | Every claim in §4.3 comes from repository queries and from inspecting the built `carino-layer-de-headless`, not from a running machine. The port-53 arbitration is the part that fails silently if it fails (§8.3). Separately, the appliance's *content* is not in the image and never will be — roughly 180 GB of Kiwix and up to 600 GB of package mirror arrive by rsync or by courier — so a correctly built box does nothing useful until they land, and that gap is measured in terabytes and weeks rather than in packages. |
| **Nothing is published or signed** | No registry, no ISO, no image signatures, and the `composer-cli` path in §9b has never been run end to end. Every download control on the site is a deliberate placeholder (`RELEASES` map) rather than a dead link. |
