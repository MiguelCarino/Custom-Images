# bootc — Image-Based OS Updates

## What is bootc?

**bootc** (Bootable Containers) extends the OCI container model to cover the entire operating system. Instead of managing packages with `dnf upgrade`, you build a new container image and deploy it atomically.

```
Traditional OS update:          bootc update:
  dnf upgrade                     podman build → push → bootc upgrade → reboot
  (partial, un-rollbackable)       (atomic, rollbackable, reproducible)
```

## Key concepts

### The image IS the OS

A bootc host runs an OS defined entirely by a `Containerfile`. The running system is a materialised view of that image on real hardware.

### Atomic upgrades

Updates are staged in a parallel deployment slot. The running OS is untouched until reboot. If the new image fails to boot, the previous deployment is still intact.

### `/etc` is mutable

bootc performs a **three-way merge** of `/etc`:
- Base image `/etc`
- Previous deployment `/etc` (your local changes)
- New image `/etc`

Your site-specific configs survive upgrades.

### `/var` is persistent

`/var` is never touched by bootc — it persists across all deployments. This is where databases, spool directories, and user data live.

### `/usr` is read-only

`/usr` is bind-mounted read-only from the image. Package managers cannot modify it on a running system (use `rpm-ostree` layering for emergency patches, or rebuild the image).

## Workflow

```
1. Edit Containerfile
        │
        ▼
2. podman build -t registry/image:tag .
        │
        ▼
3. podman push registry/image:tag
        │
        ▼
4. bootc switch registry/image:tag   (or bootc upgrade)
        │
        ▼
5. systemctl reboot
        │
        ▼
6. Running new image ✓
```

## Commands

```bash
bootc status                    # show current and pending deployments
bootc upgrade                   # pull latest tag, stage for next reboot
bootc switch <image-ref>        # switch to a different image entirely
bootc rollback                  # swap back to the previous deployment
bootc install <image-ref>       # install onto bare metal from a live environment
```

## bootc-image-builder

`bootc-image-builder` converts a bootc container image into bootable artifacts:

| Output type | Use case |
|------------|---------|
| `iso`      | USB installer / PXE |
| `disk`     | Raw disk image for VMs |
| `vmdk`     | VMware |
| `qcow2`    | QEMU/KVM |
| `ami`      | AWS |

```bash
sudo podman run --rm --privileged \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v $(pwd)/output:/output \
  quay.io/centos-bootc/bootc-image-builder:latest \
    --type iso \
    --output /output \
    quay.io/myorg/fedora-medical-workstation:latest
```

## Fedora-specific notes

- Base image: `quay.io/fedora/fedora-bootc:41`
- Fedora 41 ships bootc natively; no extra setup needed
- `rpm-ostree` is still available for emergency in-place layering, but rebuilding the image is the preferred workflow
- Flathub apps update independently of the OS (via `flatpak update`)

## References

- https://containers.github.io/bootc/
- https://docs.fedoraproject.org/en-US/bootc/
- https://github.com/osbuild/bootc-image-builder
