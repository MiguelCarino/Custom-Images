# Medical Imaging Workstation

The `fedora-medical-workstation` image is designed for radiology departments and medical imagenology labs. It provides a complete DICOM viewing and processing environment on an atomic, updateable OS.

## What's included

### Weasis — DICOM viewer

[Weasis](https://weasis.org) is an enterprise-grade, zero-footprint DICOM viewer.

**Capabilities:**
- DICOM (CT, MRI, PET, US, CR, DX, SC, PR, KO, SR, GSPS, AU …)
- 2D/3D/MPR/MIP rendering
- Hanging protocols
- DICOM-SR structured reports
- C-FIND / C-MOVE / WADO retrieval from any PACS
- Measurement and annotation tools

**Launch:**
```bash
weasis
# Open a DICOM file
weasis /path/to/study.dcm
# Open from PACS via WADO
weasis "dicom:get -w http://pacs-server:8042/wado?studyUID=1.2.3…"
```

**Site configuration:** `/etc/weasis/dicom-config.properties`

Add your PACS AE Title and address there so Weasis can query it on the local network:
```properties
weasis.dicom.aetitle=WEASIS_WS
weasis.dicom.host=192.168.1.50  # your PACS server IP
weasis.dicom.port=4242
```

### DCMTK — DICOM toolkit

DCMTK provides a suite of command-line DICOM tools.

| Command | Purpose |
|---------|---------|
| `dcmdump` | Print DICOM dataset as text |
| `dcmconv` | Convert between transfer syntaxes |
| `storescu` | C-STORE SCU — send DICOM files to a PACS |
| `storescp` | C-STORE SCP — receive DICOM files |
| `findscu` | C-FIND SCU — query a PACS |
| `movescu` | C-MOVE SCU — retrieve studies |
| `echoscu` | C-ECHO SCU — DICOM ping |
| `dcmj2kloss` | JPEG 2000 compression |
| `dcmdrle` | RLE compression/decompression |

**Example — send a study to the PACS:**
```bash
storescu -aec ORTHANC -aet WORKSTATION pacs-server 4242 /path/to/study/
```

**Example — query a PACS for studies:**
```bash
findscu -W -k QueryRetrieveLevel=STUDY \
  -k PatientName="DOE^JOHN" \
  -k StudyDate=20240101-20241231 \
  pacs-server 4242
```

### GDCM — Grassroots DICOM

Additional DICOM processing tools:
```bash
gdcmdump file.dcm           # dump tags
gdcminfo file.dcm           # summary info
gdcmconv -i in.dcm -o out.dcm --j2k   # convert to JPEG 2000
gdcmanon -i in.dcm -o out.dcm         # anonymise
```

### Python DICOM stack

```python
import pydicom
import pynetdicom
import SimpleITK as sitk

# Read a DICOM file
ds = pydicom.dcmread("image.dcm")
print(ds.PatientName, ds.StudyDate)

# ITK processing
image = sitk.ReadImage("image.dcm")
resampled = sitk.Resample(image, ...)
```

### LibreOffice

Used for:
- Radiology report templates (Writer)
- Dosimetry / QA spreadsheets (Calc)
- Presentations for grand rounds / teaching files (Impress)

## Using as a PACS client

The workstation is pre-configured to communicate with a PACS. Set the PACS address in `/etc/weasis/dicom-config.properties`, then:

1. **Query** — use Weasis → File → DICOM Explorer to search patients/studies
2. **Retrieve** — double-click a study to C-MOVE it to the workstation
3. **Send** — drag images to "Send" in Weasis, or use `storescu` from terminal
4. **Verify connectivity** — `echoscu -aec ORTHANC pacs-server 4242`

## DICOM spool directory

Received DICOM files are stored in `/var/spool/dicom`. It has sticky-bit permissions so multiple users can share it.

## Updating the workstation

Because this is a bootc image, updates are atomic:

```bash
# Pull and stage the latest image
sudo bootc upgrade

# Reboot to apply
sudo systemctl reboot

# If something breaks
sudo bootc rollback
```

Configuration files in `/etc/weasis/` are preserved across upgrades (bootc merges `/etc` changes).

## Security notes

- Patient data in `/var/spool/dicom` should be encrypted at rest (use LUKS on the data volume)
- SSH is key-only; no password login
- SELinux is enforcing
- Audit rules log access to `/etc/weasis` and `/var/spool/dicom`
- For multi-user environments, combine with POSIX ACLs on the spool directory
