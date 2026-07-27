#!/usr/bin/env bash
# tools/check-drift.sh — compare a purpose against the same purpose in Carino
# Setup, at the application level rather than the package-name level.
#
#   ./tools/check-drift.sh [PURPOSE]        report and exit 0
#   ./tools/check-drift.sh [PURPOSE] --strict   exit 1 on any violation
#
# The two projects deliver the same purposes by deliberately different means
# (see tools/purpose-apps/<purpose>.apps for why), so the comparison runs over
# an explicit app manifest. Three things are reported:
#
#   MISSING    an app the manifest says belongs on both sides, absent from one
#   UNEXPECTED an app declared one-sided that turned up on the other side too
#   UNMAPPED   a package or flatpak either project ships that no manifest row
#              claims — the guard that stops the manifest going quietly stale
#
# Setup lives outside this repo. Point CARINO_SETUP at it, or leave it beside
# this checkout as ../SimpleSetup. If it is not found the check SKIPS loudly
# and exits 2: a comparison that could not run must never read as a pass.

set -euo pipefail

# shellcheck source=../lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/common.sh"

PURPOSE="${1:-imagenology}"
[[ "${PURPOSE}" == --* ]] && { PURPOSE=imagenology; set -- imagenology "$@"; } # so `--strict` alone still works
STRICT=0
for a in "$@"; do [[ "$a" == "--strict" ]] && STRICT=1; done

MANIFEST="${REPO_ROOT}/tools/purpose-apps/${PURPOSE}.apps"
[[ -f "$MANIFEST" ]] || die "no app manifest for '${PURPOSE}' (expected ${MANIFEST#"${REPO_ROOT}"/})"

SETUP_DIR="${CARINO_SETUP:-${REPO_ROOT}/../SimpleSetup}"
SETUP_SH="${SETUP_DIR}/setup.sh"
if [[ ! -f "$SETUP_SH" ]]; then
  warn "SKIPPED — Carino Setup not found at ${SETUP_DIR}"
  warn "  set CARINO_SETUP=/path/to/setup-checkout to enable the comparison"
  exit 2
fi

# ---------------------------------------------------------------------------
# Collect what each side actually ships
# ---------------------------------------------------------------------------

# setup_tokens — every package and flatpak Setup installs for this purpose,
# across all package-manager families. Trailing #comments are stripped first:
# Setup annotates these lists heavily and prose words are not package names.
setup_tokens() {
  sed -n -E "s/^${PURPOSE}(Packages(RPM|Debian|Arch|SUSE)?|Flatpak)=\"([^\"]*)\".*/\3/p" "$SETUP_SH" \
    | sed 's/#.*$//' | tr ' ' '\n' | sed '/^$/d' | sort -u
}

# image_tokens — PACKAGES + FLATPAKS from this repo's purpose conf, read through
# load_layer_conf so the field defaulting in §6 applies rather than a second parser.
image_tokens() {
  load_layer_conf "purpose:${PURPOSE}"
  # shellcheck disable=SC2086 # conf fields are space-separated words by design
  printf '%s\n' $PACKAGES $FLATPAKS | sed '/^$/d' | sort -u
}

mapfile -t SETUP_HAS < <(setup_tokens)
mapfile -t IMAGE_HAS < <(image_tokens)
setup_set=" ${SETUP_HAS[*]} "
image_set=" ${IMAGE_HAS[*]} "

has() { [[ "$1" == *" $2 "* ]]; }

# any_of — is ANY of the space-separated tokens in $2 present in set $1?
any_of() {
  local set="$1" tok
  for tok in $2; do has "$set" "$tok" && return 0; done
  return 1
}

# ---------------------------------------------------------------------------
# Walk the manifest
# ---------------------------------------------------------------------------

violations=0
claimed=" "
rows=0

while IFS='|' read -r app s_tok i_tok policy why; do
  app="$(echo "$app" | xargs)" # xargs trims; the manifest is column-aligned for reading, not parsing
  [[ -z "$app" || "$app" == \#* ]] && continue
  s_tok="$(echo "${s_tok:-}" | xargs)"; i_tok="$(echo "${i_tok:-}" | xargs)"
  policy="$(echo "${policy:-}" | xargs)"; why="$(echo "${why:-}" | xargs)"
  rows=$((rows + 1))
  claimed+="${s_tok} ${i_tok} "

  local_in_setup=0; local_in_image=0
  any_of "$setup_set" "$s_tok" && local_in_setup=1
  any_of "$image_set" "$i_tok" && local_in_image=1

  case "$policy" in
    both)
      if (( local_in_setup && ! local_in_image )); then
        warn "MISSING    ${app} — Setup ships it, the image does not"
        violations=$((violations + 1))
      elif (( local_in_image && ! local_in_setup )); then
        warn "MISSING    ${app} — the image ships it, Setup does not"
        violations=$((violations + 1))
      fi
      ;;
    setup-only)
      [[ -n "$why" ]] || { warn "MANIFEST   ${app} — setup-only needs a why"; violations=$((violations + 1)); }
      if (( local_in_image )); then
        warn "UNEXPECTED ${app} — declared setup-only but the image ships it now"
        violations=$((violations + 1))
      fi
      ;;
    image-only)
      [[ -n "$why" ]] || { warn "MANIFEST   ${app} — image-only needs a why"; violations=$((violations + 1)); }
      if (( local_in_setup )); then
        warn "UNEXPECTED ${app} — declared image-only but Setup ships it now"
        violations=$((violations + 1))
      fi
      ;;
    *) die "${MANIFEST##*/}: app '${app}' has unknown policy '${policy}'" ;;
  esac
done < <(grep -v '^[[:space:]]*#' "$MANIFEST" | grep -v '^[[:space:]]*$')

# ---------------------------------------------------------------------------
# Nothing either side ships may go unclaimed
# ---------------------------------------------------------------------------

for tok in "${SETUP_HAS[@]}"; do
  has "$claimed" "$tok" || { warn "UNMAPPED   ${tok} — Setup ships it, no manifest row claims it"; violations=$((violations + 1)); }
done
for tok in "${IMAGE_HAS[@]}"; do
  has "$claimed" "$tok" || { warn "UNMAPPED   ${tok} — the image ships it, no manifest row claims it"; violations=$((violations + 1)); }
done

# ---------------------------------------------------------------------------

info "${PURPOSE}: ${rows} apps declared, ${#SETUP_HAS[@]} Setup tokens, ${#IMAGE_HAS[@]} image tokens"
if (( violations == 0 )); then
  info "${PURPOSE}: no drift"
  exit 0
fi

warn "${PURPOSE}: ${violations} violation(s)"
if (( STRICT )); then
  die "drift check failed (--strict)"
fi
info "reporting only — pass --strict to fail on drift once the package phase (ARCHITECTURE.md §11) lands"
exit 0
