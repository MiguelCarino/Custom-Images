# Licensing

This repository builds operating-system images. That means three different bodies of
work are involved, under three different licences, and conflating them is the usual way
a project like this gets its licensing wrong. They are separated here deliberately.

---

## 1. This repository — AGPL-3.0-or-later

Everything authored here is licensed **AGPL-3.0-or-later** (see [LICENSE](LICENSE)):
`build.sh`, `lib/`, `config/`, `files/`, `tools/`, the `Makefile`, the generated
Containerfiles, the documentation, and the website under `docs/`.

Copyright © 2026 Miguel Carino.

**Why AGPL for a build system.** The network clause (§13) has no practical effect on
build tooling — nobody interacts with `build.sh` over a network. It is used here for two
reasons that do matter: every other Carino repository uses it, so the fleet has one
answer rather than eight; and single-authorship under AGPL is what makes a **commercial
exception** possible for anyone who wants to build on this without the copyleft. A
permissive licence would give that away for nothing.

**What the copyleft does and does not reach.** Your own `.conf` purpose files, your own
layer definitions and your own forks of this tooling are derived works of it. An image
*built* by this tooling is not: it is an aggregation of Fedora packages plus a handful of
configuration files from `files/`. Those configuration files are AGPL and remain so
inside the image; the thousands of packages beside them are governed by §2.

---

## 2. The built images — Fedora, and everything Fedora ships

A `carino-*` image is **Fedora bootc plus packages**, and Fedora's content carries its
own licences: GPL-2.0, GPL-3.0, LGPL, MIT, Apache-2.0, BSD and others, package by
package. **Nothing in this repository changes, relicenses or overrides any of them.**

Components worth naming, because they are copyleft and they are deliberate choices
rather than incidental dependencies:

| Image | Component | Licence family |
|---|---|---|
| `carino-pbx` | Asterisk | GPL-family, with upstream's own linking exceptions |
| `carino-pbx` | FreePBX 17 | GPL-family (installed at first boot, not baked in) |
| `carino-pbx` | MariaDB, Apache httpd, PHP (Remi SCL) | GPL / Apache-2.0 / PHP licence |
| `carino-imagenology` | ArgyllCMS | GPL-family |
| all | Fedora kernel, systemd, COSMIC, Hyprland, … | as shipped by Fedora |

Read each component's own licence rather than this table before relying on it — the table
records intent, not a legal determination, and versions change what applies.

### ⚠ If you distribute the images, the obligations are yours

Building an image for yourself triggers nothing. **Publishing an ISO, pushing to a
registry, or shipping an appliance with one of these images on it is distribution**, and
the GPL-family components above then require you to make corresponding source available
to the recipient.

In practice this is satisfied the way every Fedora derivative satisfies it: the packages
are unmodified Fedora binaries, and the accompanying written offer points at Fedora's own
source repositories, which are public and permanent. **What is not optional is stating
it.** If you ship these images to anyone else:

1. Keep the package manifests (`research/manifest-*.json`, and the image's own RPM
   database) so the exact set is recoverable.
2. Include a written offer for source, naming Fedora's source repositories and the exact
   `fedora:*` base image digest the build used.
3. If you ever patch or rebuild a package rather than installing Fedora's, **you become
   the distributor of that modified source** and must publish it yourself.

Point 3 is the one that catches people. This project installs stock packages precisely so
that it never applies — keep it that way.

---

## 3. Third-party assets in this repository

### Fonts (`docs/fonts/`)

The website self-hosts the Carino brand fonts. They are **not** covered by the AGPL above
and never were:

| Family | Copyright | Licence |
|---|---|---|
| IBM Plex Sans, IBM Plex Mono | © 2017 IBM Corp., Reserved Font Name "Plex" | SIL OFL 1.1 |
| Red Hat Display, Red Hat Text | © 2021 Red Hat, Inc., Reserved Font Name "Red Hat" | SIL OFL 1.1 |

The full licence text is in [`docs/fonts/OFL.txt`](docs/fonts/OFL.txt). OFL 1.1 requires
that the copyright notice and licence travel with any redistribution of the font files —
which is what that file is for. The subsetted `.woff2` files here are *modified* copies of
the originals; the OFL permits that, and the Reserved Font Names above are why they are
still named after their originals only in the CSS `font-family`, never in a new font name.

### Anything else vendored later

Add it to this section with its licence, and put the licence text beside the asset. A
`NOTICES`-style record that is maintained from the first vendored file is trivial; one
reconstructed two years later is not.

---

## Summary

| You are… | Licence that governs you |
|---|---|
| Reading or forking this repo | AGPL-3.0-or-later |
| Building an image for your own machine | AGPL for this tooling; nothing else triggers |
| **Publishing an ISO or registry image** | AGPL **and** the source obligations of §2 |
| Using the fonts | SIL OFL 1.1 |
| Wanting to build a product on this without the copyleft | Ask — a commercial exception is available |
