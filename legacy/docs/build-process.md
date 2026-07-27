# Build Process — Ordered Command Reference

Step-by-step commands to build, push, and deploy every image.
Run these **on a machine with Podman installed** (does not need to be a bootc host).

---

## 0. Prerequisites

```bash
# Confirm Podman is installed and working
podman --version

# Log in to your registry (do this once)
podman login quay.io

# Set your registry — used in every step below
export REGISTRY=quay.io/carino
export TAG=latest
export FEDORA_VER=43
export WEASIS_VER=4.3.0
```

---

## 1. Build the base image

Every other image derives from this one. Build it first.

```bash
podman build --pull=newer \
  --build-arg FEDORA_VERSION=${FEDORA_VER} \
  -t ${REGISTRY}/fedora-base:${TAG} \
  images/base/
```

---

## 2. Build the workstation image

Depends on: `fedora-base`

```bash
podman build --pull=newer \
  --build-arg REGISTRY=${REGISTRY} \
  --build-arg BASE_TAG=${TAG} \
  -t ${REGISTRY}/fedora-workstation:${TAG} \
  images/workstation/
```

---

## 3a. Build the medical workstation image

Depends on: `fedora-workstation`

```bash
podman build --pull=newer \
  --build-arg REGISTRY=${REGISTRY} \
  --build-arg BASE_TAG=${TAG} \
  --build-arg WEASIS_VERSION=${WEASIS_VER} \
  -t ${REGISTRY}/fedora-medical-workstation:${TAG} \
  images/medical-workstation/
```

---

## 3b. Build the PACS server image

Depends on: `fedora-base` (independent of the workstation branch)

```bash
podman build --pull=newer \
  --build-arg REGISTRY=${REGISTRY} \
  --build-arg BASE_TAG=${TAG} \
  -t ${REGISTRY}/fedora-pacs-server:${TAG} \
  images/pacs-server/
```

---

## 4. Push all images to the registry

```bash
podman push ${REGISTRY}/fedora-base:${TAG}
podman push ${REGISTRY}/fedora-workstation:${TAG}
podman push ${REGISTRY}/fedora-medical-workstation:${TAG}
podman push ${REGISTRY}/fedora-pacs-server:${TAG}
```

Or with Make (runs steps 1–4 in one command):

```bash
make push REGISTRY=quay.io/carino
```

---

## 5. Build a bootable ISO (optional)

Requires `bootc-image-builder`. Produces a USB-installable ISO.

```bash
# Medical workstation ISO
make iso IMAGE=fedora-medical-workstation REGISTRY=quay.io/carino

# PACS server ISO
make iso IMAGE=fedora-pacs-server REGISTRY=quay.io/carino

# Write to USB (replace /dev/sdX with your device)
# bootc-image-builder places the ISO at output/bootiso/install.iso
sudo dd if=output/bootiso/install.iso of=/dev/sdX bs=4M status=progress && sync
```

---

## 6. Deploy to a running bootc host

Run these **on the target host** after it is already running a bootc image.

```bash
# Switch to a new image (staged — takes effect after reboot)
sudo bootc switch quay.io/carino/fedora-medical-workstation:latest

# Apply the staged update
sudo systemctl reboot

# --- OR --- pull the latest tag of the current image
sudo bootc upgrade
sudo systemctl reboot

# Roll back if something is wrong (before the old deployment is garbage collected)
sudo bootc rollback

# Check current and pending deployments
bootc status
```

---

## 7. PACS server first-boot setup

Run these **once on the PACS server** after first boot:

```bash
# 1. Set the PostgreSQL password for Orthanc
sudo sh -c 'echo "CHANGE_THIS_PASSWORD" > /etc/orthanc/db.secret'
sudo chmod 600 /etc/orthanc/db.secret

# 2. The orthanc-db-init.service runs automatically and creates the DB.
#    Check its status:
sudo systemctl status orthanc-db-init.service
sudo journalctl -u orthanc-db-init.service

# 3. Verify Orthanc started (quadlet → orthanc.service)
sudo systemctl status orthanc.service
curl -s http://localhost:8042/system | python3 -m json.tool

# 4. Configure TLS (replace with your real domain)
sudo certbot --nginx -d pacs.example.com
```

---

## Dependency tree (build order)

```
fedora-bootc:43  (upstream, pulled automatically)
    │
    └─► 1. fedora-base
              │
              ├─► 2. fedora-workstation
              │           │
              │           └─► 3a. fedora-medical-workstation
              │
              └─► 3b. fedora-pacs-server
```

Steps 3a and 3b are **independent** — they can be built in parallel after step 2 / step 1 complete respectively.
