# PACS Server

The `fedora-pacs-server` image provides a full-featured PACS (Picture Archiving and Communication System) based on **Orthanc**.

## Architecture

```
  DICOM devices          PACS Server                  Clients
  (modalities)           ──────────────────────        ──────────────────
  CT scanner ──C-STORE──▶ Orthanc :4242             ◀── Weasis workstation
  MRI scanner ─────────▶ │  │                       ◀── Web browser (REST)
  X-ray DR ────────────▶ │  └─ PostgreSQL :5432     ◀── HL7 / EHR (WADO-RS)
                          │
                          └─ Nginx :443 (TLS)
                                └─ DICOMweb REST API
                                └─ Orthanc Explorer UI
```

## First-boot setup

1. **Deploy the image** (via ISO installer or `bootc switch`)

2. **Create the database password secret:**
   ```bash
   sudo sh -c 'echo "CHANGE_THIS_PASSWORD" > /etc/orthanc/db.secret'
   sudo chmod 600 /etc/orthanc/db.secret
   ```

3. **Set Orthanc credentials** — create a systemd drop-in:
   ```bash
   sudo mkdir -p /etc/systemd/system/orthanc.service.d/
   sudo tee /etc/systemd/system/orthanc.service.d/credentials.conf << 'EOF'
   [Service]
   Environment=ORTHANC_USER=admin
   Environment=ORTHANC_PASSWORD=CHANGE_THIS_PASSWORD
   EOF
   sudo systemctl daemon-reload
   ```

4. **Configure TLS with Certbot:**
   ```bash
   # Replace pacs.example.com with your real domain
   sudo certbot --nginx -d pacs.example.com
   ```
   Update `/etc/nginx/conf.d/orthanc.conf` with your FQDN.

5. **Reboot** — orthanc-db-init.service runs automatically on first boot.

6. **Verify:**
   ```bash
   systemctl status orthanc
   curl -u admin:PASSWORD http://localhost:8042/system | python3 -m json.tool
   ```

## DICOM storage

DICOM files are stored in `/var/lib/orthanc/db`. Mount a large volume there at deploy time:

**Systemd mount unit** (`/etc/systemd/system/var-lib-orthanc.mount`):
```ini
[Unit]
Description=Orthanc DICOM storage
After=local-fs.target

[Mount]
What=/dev/disk/by-label/DICOM_STORAGE
Where=/var/lib/orthanc
Type=xfs
Options=defaults,noatime

[Install]
WantedBy=multi-user.target
```

## Registering DICOM modalities

Edit `/etc/orthanc/orthanc.json` (or create `/etc/orthanc/modalities.json`):

```json
{
  "DicomModalities": {
    "CT_ROOM1": {
      "AET": "CT_ROOM1",
      "Host": "192.168.1.20",
      "Port": 104,
      "Manufacturer": "Generic"
    },
    "WEASIS_WS1": {
      "AET": "WEASIS_WS",
      "Host": "192.168.1.10",
      "Port": 11112
    }
  }
}
```

Then `sudo systemctl restart orthanc`.

## DICOMweb API

The DICOMweb plugin exposes:

| Endpoint | Protocol |
|---------|---------|
| `https://pacs.example.com/dicom-web/studies` | WADO-RS / STOW-RS / QIDO-RS |
| `https://pacs.example.com/wado` | WADO-URI |

**Configure Weasis to use DICOMweb:**
```properties
# /etc/weasis/dicom-config.properties
weasis.dicom.wado.url=https://pacs.example.com/dicom-web
```

## Orthanc Explorer

The built-in web UI is available at `https://pacs.example.com/`.

## Backup

```bash
# Backup Orthanc database + config
sudo -u postgres pg_dump orthanc | gzip > orthanc-$(date +%Y%m%d).sql.gz

# Sync DICOM files to offsite storage (example with rclone)
rclone sync /var/lib/orthanc/db remote:pacs-backup/dicom/
```

## Updating the server

```bash
# Stage the latest PACS image
sudo bootc upgrade
# Reboot to apply
sudo systemctl reboot
```

PostgreSQL data in `/var/lib/pgsql` and DICOM files in `/var/lib/orthanc` are untouched by bootc upgrades (they live in `/var`).
