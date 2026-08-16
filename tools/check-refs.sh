#!/usr/bin/env bash
# tools/check-refs.sh — validate that the repo's cross-references still resolve.
#
#   ./tools/check-refs.sh            report and exit 0
#   ./tools/check-refs.sh --strict   exit 1 on any broken reference
#
# Docs and code refer to each other constantly — `ARCHITECTURE.md` §10, paths like
# config/purposes/, the lib/common.sh interface. Those references rot silently: a
# renamed image, a deleted layer or a resectioned spec leaves prose that still reads
# fine and is simply wrong. This checks four kinds:
#
#   SECTION   `DOC.md` §N where DOC.md has no section N
#   SELF      a bare §N inside a .md that the same file does not define
#   PATH      a repo-relative path in prose that does not exist
#   IFACE     ARCHITECTURE.md §6 vs the functions lib/common.sh actually defines
#
# legacy/ and generated/ are excluded: the first is a frozen archive whose references
# describe the world as it was, the second is regenerated output.

set -euo pipefail

# shellcheck source=../lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/common.sh"

STRICT=0
for a in "$@"; do [[ "$a" == "--strict" ]] && STRICT=1; done

cd "$REPO_ROOT"
problems=0
note() { warn "$1"; problems=$((problems + 1)); }

# Files worth scanning. -print0 would be safer, but no path in this repo has spaces
# and the readable loop is worth more here than the theoretical robustness.
mapfile -t FILES < <(find . \
  \( -path ./legacy -o -path ./generated -o -path ./output -o -path ./.git -o -path ./.claude -o -path ./docs/fonts \) -prune -o \
  \( -name '*.sh' -o -name '*.md' -o -name '*.conf' -o -name '*.html' -o -name '*.apps' -o -name 'Makefile' \) -print \
  | sed 's|^\./||' | sort)

# sections_of — $1 = markdown file -> the section numbers it defines, one per line.
# Matches "## 7." and "### 7.1" and "## 11b.".
sections_of() {
  grep -oE '^#{2,}[[:space:]]+[0-9]+[a-z]?(\.[0-9]+)?' "$1" 2>/dev/null \
    | grep -oE '[0-9]+[a-z]?(\.[0-9]+)?' || true
}

# ---------------------------------------------------------------------------
# SECTION — `DOC.md` §N must exist in DOC.md
# ---------------------------------------------------------------------------
for f in "${FILES[@]}"; do
  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    doc="${ref%%.md*}.md"
    doc="${doc##*[\`\ ]}" # strip a leading backtick or space the match may carry
    sec="${ref##*§}"
    sec="$(echo "$sec" | tr -d ' `' | sed 's/[.,);:]*$//')" # a sentence-ending period is not part of the number
    [[ -z "$sec" ]] && continue
    if [[ ! -f "$doc" ]]; then
      note "SECTION  ${f}: references ${doc} §${sec} — no such document"
    elif ! sections_of "$doc" | grep -qx "$sec"; then
      note "SECTION  ${f}: references ${doc} §${sec} — no such section"
    fi
  done < <(grep -ohE '`?[A-Z][A-Za-z]*\.md`?[[:space:],]*§[[:space:]]*[0-9]+[a-z]?(\.[0-9]+)?' "$f" 2>/dev/null || true)
done

# ---------------------------------------------------------------------------
# SELF — a bare §N inside a .md refers to that same document
# ---------------------------------------------------------------------------
for f in "${FILES[@]}"; do
  [[ "$f" == *.md ]] || continue
  while IFS= read -r sec; do
    sec="$(echo "$sec" | sed 's/[.,);:]*$//')"
    [[ -z "$sec" ]] && continue
    sections_of "$f" | grep -qx "$sec" \
      || note "SELF     ${f}: refers to §${sec}, which it does not define"
  done < <(sed -E 's/`?[A-Z][A-Za-z]*\.md`?[[:space:],]*§[[:space:]]*[0-9]+[a-z]?(\.[0-9]+)?//g' "$f" \
           | grep -ohE '§[[:space:]]*[0-9]+[a-z]?(\.[0-9]+)?' | tr -d '§ ' || true)
done

# ---------------------------------------------------------------------------
# PATH — repo-relative paths named in prose must exist
# ---------------------------------------------------------------------------
for f in "${FILES[@]}"; do
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    path="$(echo "$path" | sed 's/[.,);:`]*$//')"
    case "$path" in *'*'*|*'<'*|*'>'*|*'…'*) continue ;; esac # globs and placeholders are not claims
    # gitignored paths are user-created by design (e.g. config/iso.toml) —
    # their absence in a fresh clone is not a broken reference.
    git check-ignore -q "$path" 2>/dev/null && continue
    [[ -e "$path" ]] || note "PATH     ${f}: mentions ${path}, which does not exist"
  done < <(grep -ohE '(^|[^A-Za-z0-9_/.-])(config|lib|tools|files|research|docs|legacy)/[A-Za-z0-9._/*<>-]+' "$f" 2>/dev/null \
           | grep -oE '(config|lib|tools|files|research|docs|legacy)/[A-Za-z0-9._/*<>-]+' || true)
done

# ---------------------------------------------------------------------------
# IFACE — the §6 binding interface must match lib/common.sh
# ---------------------------------------------------------------------------
if [[ -f ARCHITECTURE.md ]]; then
  documented=$(sed -n '/^## 6\./,/^## 7\./p' ARCHITECTURE.md | grep -oE '\b[a-z_][a-z0-9_]*\(\)' | tr -d '()' | sort -u)
  defined=$(grep -oE '^[a-z_][a-z0-9_]*\(\)' lib/common.sh | tr -d '()' | sort -u)
  while IFS= read -r fn; do
    [[ -z "$fn" ]] && continue
    grep -qx "$fn" <<<"$defined" || note "IFACE    ARCHITECTURE.md §6 documents ${fn}(), which lib/common.sh does not define"
  done <<<"$documented"
  while IFS= read -r fn; do
    [[ -z "$fn" || "$fn" == _* ]] && continue # underscore-prefixed helpers are private by convention
    grep -qx "$fn" <<<"$documented" || note "IFACE    lib/common.sh defines ${fn}(), undocumented in ARCHITECTURE.md §6"
  done <<<"$defined"
fi

# ---------------------------------------------------------------------------

info "checked ${#FILES[@]} files"
if (( problems == 0 )); then
  info "all references resolve"
  exit 0
fi
warn "${problems} broken reference(s)"
(( STRICT )) && die "reference check failed (--strict)"
exit 0
