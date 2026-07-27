#!/usr/bin/env bash
# =============================================================================
# generate.sh — Generate a Containerfile from a distro + profile combination
#
# Usage:
#   ./build/generate.sh --distro fedora --profile medical
#   ./build/generate.sh --distro ubuntu --profile workstation
#   ./build/generate.sh --distro debian --profile pacs-server --registry quay.io/myorg
#
# Outputs:
#   generated/<distro>-<profile>/Containerfile
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# --------------------------------------------------------------------------- #
# Parse arguments
# --------------------------------------------------------------------------- #
DISTRO=""
PROFILE=""
REGISTRY="localhost"
BASE_TAG="latest"
WEASIS_VERSION_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --distro)           DISTRO="$2";                   shift 2 ;;
    --profile)          PROFILE="$2";                  shift 2 ;;
    --registry)         REGISTRY="$2";                 shift 2 ;;
    --base-tag)         BASE_TAG="$2";                 shift 2 ;;
    --weasis-version)   WEASIS_VERSION_OVERRIDE="$2";  shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$DISTRO"  ]] && { echo "ERROR: --distro required"  >&2; exit 1; }
[[ -z "$PROFILE" ]] && { echo "ERROR: --profile required" >&2; exit 1; }

# --------------------------------------------------------------------------- #
# Load configs
# --------------------------------------------------------------------------- #
DISTRO_CONF="${ROOT}/config/distros/${DISTRO}.conf"
PROFILE_CONF="${ROOT}/config/profiles/${PROFILE}.conf"

[[ -f "$DISTRO_CONF"  ]] || { echo "ERROR: unknown distro '${DISTRO}' (no ${DISTRO_CONF})"   >&2; exit 1; }
[[ -f "$PROFILE_CONF" ]] || { echo "ERROR: unknown profile '${PROFILE}' (no ${PROFILE_CONF})" >&2; exit 1; }

# shellcheck source=/dev/null
source "$DISTRO_CONF"
# shellcheck source=/dev/null
source "$PROFILE_CONF"

# Allow CLI override of Weasis version
[[ -n "$WEASIS_VERSION_OVERRIDE" ]] && WEASIS_VERSION="$WEASIS_VERSION_OVERRIDE"

# --------------------------------------------------------------------------- #
# Resolve package list for this distro family
# --------------------------------------------------------------------------- #
pkgs_var="PKGS_${DISTRO_FAMILY}"
PACKAGES="${!pkgs_var:-}"
[[ -z "$PACKAGES" ]] && {
  echo "ERROR: no package list found for family '${DISTRO_FAMILY}' in ${PROFILE_CONF}" >&2
  echo "       Define PKGS_${DISTRO_FAMILY}=\"...\" in that file." >&2
  exit 1
}

services_var="SERVICES_${DISTRO_FAMILY}"
SERVICES="${!services_var:-${SERVICES:-}}"

pgsql_init_var="PGSQL_INIT_${DISTRO_FAMILY}"
PGSQL_INIT="${!pgsql_init_var:-}"

# WEASIS_PKG and WEASIS_CMD are resolved later, only when needed (medical profile)

# --------------------------------------------------------------------------- #
# Determine parent image
# --------------------------------------------------------------------------- #
case "$PROFILE" in
  base)
    PARENT="${BASE_IMAGE}"
    ;;
  workstation)
    PARENT="${REGISTRY}/${DISTRO}-base:${BASE_TAG}"
    ;;
  medical)
    PARENT="${REGISTRY}/${DISTRO}-workstation:${BASE_TAG}"
    ;;
  pacs-server)
    PARENT="${REGISTRY}/${DISTRO}-base:${BASE_TAG}"
    ;;
  *)
    # Custom profile: try to honour INHERITS if set
    if [[ -n "${INHERITS:-}" ]]; then
      PARENT="${REGISTRY}/${DISTRO}-${INHERITS}:${BASE_TAG}"
    else
      PARENT="${BASE_IMAGE}"
    fi
    ;;
esac

# --------------------------------------------------------------------------- #
# Prepare output directory
# --------------------------------------------------------------------------- #
OUT_DIR="${ROOT}/generated/${DISTRO}-${PROFILE}"
mkdir -p "$OUT_DIR"
OUT_FILE="${OUT_DIR}/Containerfile"

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #

# Write a formatted dnf/apt install block
emit_pkg_install() {
  local pkgs="$1"
  # Convert to array, drop empty entries
  local pkg_array
  read -r -a pkg_array <<< "$(echo "$pkgs" | tr -s ' \n' ' ')"

  echo "RUN ${PKG_INSTALL} \\"
  for pkg in "${pkg_array[@]}"; do
    [[ -z "$pkg" ]] && continue
    echo "      ${pkg} \\"
  done
  # Replace the trailing backslash on the last line with the clean command
  echo "    && ${PKG_CLEAN}"
}

# Write a systemctl enable block
emit_services() {
  local svc_list="$1"
  [[ -z "$svc_list" ]] && return
  echo "RUN systemctl enable \\"
  local svcs
  read -r -a svcs <<< "$svc_list"
  for svc in "${svcs[@]}"; do
    echo "      ${svc} \\"
  done | sed '$ s/ \\//'  # remove trailing backslash from last line
}

# --------------------------------------------------------------------------- #
# Generate the Containerfile
# --------------------------------------------------------------------------- #
{

# ── Header ──────────────────────────────────────────────────────────────────
cat << HEADER
# =============================================================================
# ${DISTRO_DISPLAY} — ${PROFILE_DESCRIPTION}
# Generated by build/generate.sh  (do not edit manually)
# Distro: ${DISTRO}  |  Profile: ${PROFILE}  |  Family: ${DISTRO_FAMILY}
# Regenerate: ./build/generate.sh --distro ${DISTRO} --profile ${PROFILE}
# =============================================================================

FROM ${PARENT}

LABEL org.opencontainers.image.title="${DISTRO_DISPLAY} ${PROFILE^}"
LABEL org.opencontainers.image.description="${PROFILE_DESCRIPTION}"
LABEL org.opencontainers.image.source="https://github.com/your-org/fedora-custom-images"

HEADER

# ── Extra repos ──────────────────────────────────────────────────────────────
if [[ -n "${EXTRA_REPOS_BLOCK:-}" && "$PROFILE" == "base" ]]; then
  echo "# ---------------------------------------------------------------------------"
  echo "# Extra package repositories"
  echo "# ---------------------------------------------------------------------------"
  echo "${EXTRA_REPOS_BLOCK}"
  echo ""
fi

# ── Packages ─────────────────────────────────────────────────────────────────
echo "# ---------------------------------------------------------------------------"
echo "# Packages"
echo "# ---------------------------------------------------------------------------"
emit_pkg_install "$PACKAGES"
echo ""

# ── Profile-specific extras ──────────────────────────────────────────────────
case "$PROFILE" in

  # ── base extras ─────────────────────────────────────────────────────────
  base)
    echo "# ---------------------------------------------------------------------------"
    echo "# SSH hardening"
    echo "# ---------------------------------------------------------------------------"
    cat << 'SSH'
RUN sed -i \
      -e 's/^#\?PermitRootLogin.*/PermitRootLogin no/' \
      -e 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' \
      /etc/ssh/sshd_config

SSH

    if [[ -n "${SECURITY_BLOCK:-}" ]]; then
      echo "# ---------------------------------------------------------------------------"
      echo "# OS security model"
      echo "# ---------------------------------------------------------------------------"
      echo "${SECURITY_BLOCK}"
      echo ""
    fi
    ;;

  # ── workstation extras ──────────────────────────────────────────────────
  workstation)
    # Silverblue/Kinoite already has Flathub; ensure it's present for plain Fedora too
    echo "# ---------------------------------------------------------------------------"
    echo "# Ensure Flathub remote is registered (idempotent)"
    echo "# ---------------------------------------------------------------------------"
    cat << 'FLAT'
RUN flatpak remote-add --system --if-not-exists flathub \
      https://dl.flathub.org/repo/flathub.flatpakrepo || true

FLAT

    if [[ "${GRAPHICAL_TARGET:-false}" == "true" ]]; then
      echo "# ---------------------------------------------------------------------------"
      echo "# Default to graphical target"
      echo "# ---------------------------------------------------------------------------"
      echo "RUN systemctl set-default graphical.target"
      echo ""
    fi
    ;;

  # ── medical extras ──────────────────────────────────────────────────────
  medical)
    # Resolve Weasis variables here — only defined when medical.conf is loaded
    _wver="${WEASIS_VERSION:-4.3.0}"
    _wpkg_template="${WEASIS_PKG_NAME:-weasis-\${WEASIS_VERSION}-1.x86_64.rpm}"
    _wpkg="$(WEASIS_VERSION="$_wver" eval echo "$_wpkg_template")"
    _wcmd="${WEASIS_INSTALL_CMD:-rpm -ivh}"

    echo "# ---------------------------------------------------------------------------"
    echo "# Weasis DICOM viewer v${_wver} (not in distro repos)"
    echo "# ---------------------------------------------------------------------------"
    cat << WEASIS
ARG WEASIS_VERSION=${_wver}
RUN WEASIS_PKG="${_wpkg}" && \\
    curl -fsSL -o "/tmp/\${WEASIS_PKG}" \\
      "https://github.com/nroduit/Weasis/releases/download/v\${WEASIS_VERSION}/\${WEASIS_PKG}" && \\
    ${_wcmd} "/tmp/\${WEASIS_PKG}" && \\
    rm -f "/tmp/\${WEASIS_PKG}"

WEASIS

    cat << 'WEASIS_CFG'
# ---------------------------------------------------------------------------
# Weasis configuration
# ---------------------------------------------------------------------------
COPY ../../images/medical-workstation/config/weasis/dicom-config.properties \
     /etc/weasis/dicom-config.properties
COPY ../../images/medical-workstation/systemd/weasis-dicom-handler.desktop \
     /usr/share/applications/weasis-dicom-handler.desktop
RUN update-desktop-database /usr/share/applications/ || true && \
    xdg-mime default weasis-dicom-handler.desktop application/dicom || true

WEASIS_CFG

    if [[ -n "${PIP_PACKAGES:-}" ]]; then
      echo "# ---------------------------------------------------------------------------"
      echo "# Python medical imaging extras (pip)"
      echo "# ---------------------------------------------------------------------------"
      echo "RUN pip3 install --no-cache-dir \\"
      for pkg in ${PIP_PACKAGES}; do
        echo "      ${pkg} \\"
      done | sed '$ s/ \\//'
      echo ""
    fi

    cat << 'SPOOL'
# ---------------------------------------------------------------------------
# DICOM spool directory
# ---------------------------------------------------------------------------
RUN mkdir -p /var/spool/dicom && chmod 1777 /var/spool/dicom && \
    echo '-w /var/spool/dicom -p rwa -k dicom_spool' \
      >> /etc/audit/rules.d/medical.rules || true

SPOOL

    # ── Distrobox guest containers ──────────────────────────────────────
    _guests="${DISTROBOX_GUESTS:-}"
    _guests="$(echo "$_guests" | tr -s ' \n' ' ' | xargs)"

    if [[ -n "$_guests" ]]; then
      echo "# ---------------------------------------------------------------------------"
      echo "# Distrobox guest containers"
      echo "# Fedora is the host OS. Ubuntu/Debian run as Distrobox guests."
      echo "# Users launch guest apps via: distrobox enter <name>"
      echo "# GUI apps appear on the host Wayland desktop automatically."
      echo "# ---------------------------------------------------------------------------"

      # Build the distrobox assemble INI file content
      _ini_content=""
      for _guest_conf in $_guests; do
        _gcf="${ROOT}/config/guests/${_guest_conf}.conf"
        if [[ -f "$_gcf" ]]; then
          # shellcheck source=/dev/null
          source "$_gcf"
          _image_ref="${REGISTRY}/${GUEST_IMAGE_NAME}:${BASE_TAG}"
          _ini_content+="[${GUEST_NAME}]\nimage=${_image_ref}\ninit=${GUEST_INIT:-false}\npull_image=false\n\n"
          echo "# Guest: ${GUEST_NAME} — ${GUEST_DESCRIPTION}"
          echo "# Image: ${_image_ref}"
          # Unset guest vars to avoid pollution
          unset GUEST_NAME GUEST_DESCRIPTION GUEST_CONTAINERFILE GUEST_IMAGE_NAME GUEST_INIT
        else
          echo "# WARNING: guest config not found: ${_gcf}" >&2
        fi
      done

      # Emit the assemble config + prefetch service
      cat << DBOX_HEADER
RUN mkdir -p /etc/distrobox
DBOX_HEADER

      echo "RUN printf '${_ini_content}' > /etc/distrobox/medical-guests.ini"
      echo ""

      cat << 'DBOX_SVC'
# Systemd service: pre-pull guest images on first boot so users don't wait
COPY images/app-containers/prefetch-guests.service \
     /etc/systemd/system/distrobox-prefetch-guests.service
RUN systemctl enable distrobox-prefetch-guests.service

DBOX_SVC
    fi
    ;;

  # ── pacs-server extras ──────────────────────────────────────────────────
  pacs-server)
    if [[ -n "$PGSQL_INIT" ]]; then
      echo "# ---------------------------------------------------------------------------"
      echo "# PostgreSQL initial cluster"
      echo "# ---------------------------------------------------------------------------"
      echo "RUN ${PGSQL_INIT}"
      echo ""
    fi

    ORTHANC_IMAGE_VAL="${ORTHANC_IMAGE:-docker.io/orthancteam/orthanc:latest}"
    echo "# ---------------------------------------------------------------------------"
    echo "# Orthanc quadlet (systemd-managed Podman container)"
    echo "# ---------------------------------------------------------------------------"
    cat << QUADLET
RUN mkdir -p /etc/containers/systemd /etc/orthanc
COPY ../../images/pacs-server/config/orthanc.container \
     /etc/containers/systemd/orthanc.container
COPY ../../images/pacs-server/config/orthanc.json       /etc/orthanc/orthanc.json
COPY ../../images/pacs-server/config/orthanc-dicomweb.json /etc/orthanc/dicomweb.json

QUADLET

    cat << 'PACS_REST'
# ---------------------------------------------------------------------------
# Nginx TLS reverse proxy
# ---------------------------------------------------------------------------
COPY ../../images/pacs-server/config/nginx-orthanc.conf \
     /etc/nginx/conf.d/orthanc.conf

# ---------------------------------------------------------------------------
# Firewall service definition
# ---------------------------------------------------------------------------
COPY ../../images/pacs-server/config/firewalld-pacs.xml \
     /etc/firewalld/services/pacs.xml
RUN firewall-offline-cmd --add-service=pacs || true

# ---------------------------------------------------------------------------
# DICOM storage directory
# ---------------------------------------------------------------------------
RUN mkdir -p /var/lib/orthanc && chmod 750 /var/lib/orthanc

# ---------------------------------------------------------------------------
# First-boot DB init (oneshot service)
# ---------------------------------------------------------------------------
COPY ../../images/pacs-server/config/orthanc-db-init.sh \
     /usr/local/bin/orthanc-db-init.sh
RUN chmod +x /usr/local/bin/orthanc-db-init.sh
COPY ../../images/pacs-server/config/orthanc-db-init.service \
     /etc/systemd/system/orthanc-db-init.service
RUN systemctl enable orthanc-db-init.service

PACS_REST
    ;;
esac

# ── Flatpak apps ─────────────────────────────────────────────────────────────
FLATPAKS="${FLATPAKS:-}"
if [[ -n "$FLATPAKS" ]]; then
  # Flatten to a clean space-separated list
  flatpak_list="$(echo "$FLATPAKS" | tr -s ' \n' ' ' | xargs)"

  echo "# ---------------------------------------------------------------------------"
  echo "# Flatpak apps (system-wide from Flathub)"
  echo "# Update independently of the OS: flatpak update"
  echo "# ---------------------------------------------------------------------------"
  echo "RUN flatpak remote-add --system --if-not-exists flathub \\"
  echo "      https://dl.flathub.org/repo/flathub.flatpakrepo || true \\"
  echo "    && flatpak install -y --system flathub \\"
  for app in $flatpak_list; do
    echo "         ${app} \\"
  done | sed '$ s/ \\//'
  echo ""
fi

# ── Services ─────────────────────────────────────────────────────────────────
if [[ -n "$SERVICES" ]]; then
  echo "# ---------------------------------------------------------------------------"
  echo "# Enable services"
  echo "# ---------------------------------------------------------------------------"
  emit_services "$SERVICES"
  echo ""
fi

} > "$OUT_FILE"

# --------------------------------------------------------------------------- #
# Done
# --------------------------------------------------------------------------- #
_npkgs="$(echo "$PACKAGES" | wc -w | tr -d ' ')"
_nflats="$(echo "${FLATPAKS:-}" | wc -w | tr -d ' ')"
echo "Generated: ${OUT_FILE}"
echo "Parent:    ${PARENT}"
echo "Packages:  ${DISTRO_FAMILY} (${_npkgs} rpm/deb  +  ${_nflats} flatpaks)"
