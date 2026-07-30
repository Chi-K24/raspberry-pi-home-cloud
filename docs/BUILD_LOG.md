# Build Log

This is a sanitized reconstruction of the implementation. Values that identify
the original system are replaced with placeholders.

## 1. Prepare the high-capacity media disk

The external media disk was repartitioned as GPT and formatted ext4:

```bash
sudo parted -s /dev/sdX mklabel gpt
sudo parted -s -a optimal /dev/sdX mkpart primary ext4 1MiB 100%
sudo partprobe /dev/sdX
sudo mkfs.ext4 -L IMMICH_LIBRARY -m 0 /dev/sdX1
```

It was mounted persistently at `/srv/immich-library` by UUID with `noatime`,
`nofail`, and a bounded systemd device timeout.

## 2. Migrate and verify the existing archive

The archive was copied with Linux metadata preservation:

```bash
sudo rsync -aHAXx --numeric-ids --partial --info=progress2 \
  /source/ /srv/immich-library/import-staging/
```

Two verification passes followed:

```bash
sudo rsync -aHAXxi --numeric-ids --stats \
  /source/ /srv/immich-library/import-staging/

sudo rsync -aHAXxnc --numeric-ids --itemize-changes --stats \
  /source/ /srv/immich-library/import-staging/
```

The first confirmed no metadata/size reconciliation was required. The second
performed a checksum dry run and reported no changed files.

## 3. Update firmware and migrate Raspberry Pi OS to NVMe

The bootloader EEPROM was updated before the system migration:

```bash
sudo rpi-eeprom-update -a
```

The NVMe was partitioned with a FAT32 boot partition and an ext4 root
partition. The existing root filesystem and boot partition were copied using
`rsync`, excluding runtime virtual filesystems and external mounts.

The cloned `cmdline.txt` and `fstab` were updated to reference the new NVMe
PARTUUIDs. Boot was validated with the SD card removed:

```bash
findmnt /
findmnt /boot/firmware
```

Both mount points resolved to NVMe partitions.

## 4. Stabilize a problematic USB-to-SATA bridge

A legacy USB disk showed UAS timeouts, aborted commands and disconnects. The
device remained at USB 3 speed but was moved from `uas` to `usb-storage` using
a targeted quirk:

```text
usb-storage.quirks=<VID>:<PID>:u
```

The quirk was added to the single-line kernel command line. After reboot:

```bash
cat /proc/cmdline
lsusb -t
```

confirmed the affected enclosure used `usb-storage` while the healthy media
disk continued using UAS.

## 5. Restrict File Browser

File Browser originally used `/` as its root. It was changed to:

```text
/srv/filebrowser
```

Its database was moved outside the browsable root to:

```text
/var/lib/filebrowser/filebrowser.db
```

Approved storage was exposed with bind mounts. The NVMe received a dedicated
storage directory rather than exposing the operating-system root.

## 6. Install Docker and deploy Immich

Docker Engine and the Compose plugin were installed from Docker's official
Debian repository. The installation was validated with `hello-world`.

Immich was deployed in `/opt/immich` using the official Compose release.
Storage was split as follows:

- Originals: high-capacity media disk.
- PostgreSQL: NVMe.
- Thumbnails: NVMe.
- Model cache: Docker named volume on NVMe.
- Existing archive: read-only external mount.

The stack was validated with:

```bash
sudo docker compose ps
curl -fsS http://127.0.0.1:2283/api/server/ping
```

All four containers reported healthy.

## 7. Configure multi-user mobile backup

Separate users and storage labels were created. The storage template used a
human-readable date hierarchy:

```text
{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}
```

Mobile uploads were tested with a few selected assets before automatic album
backup was enabled. The resulting files were verified directly on the media
disk.

## 8. Validate existing applications

The operational audit covered:

- Pi-hole and Unbound service state plus live DNS queries.
- WireGuard interface state and recent peer handshake.
- Samba configuration and active daemons.
- File Browser and OctoPrint HTTP responses.
- Immich container health.
- RetroPie/EmulationStation binary, libraries, logs and OpenGL renderer.
- Kodi package and executable.
- Failed systemd units and boot-level error logs.

The audit found and corrected a stale Samba share that still referenced the
NVMe's former mount point.

## 9. Repair Pi 5 fan detection

The system had recorded thermal throttling while Immich processed its initial
queue. The installed four-wire PWM fan spun at boot but did not register as a
Linux cooling device.

The built-in Pi 5 fan node was forced on:

```ini
[all]
dtparam=cooling_fan=on
```

After reboot, Linux reported `pwm-fan`, RPM feedback was available, and the
system completed a full-CPU Immich workload without new throttling.

## 10. Detect degraded legacy storage

The final boot audit reported unreadable pending sectors on a legacy disk.
SMART confirmed media degradation despite its high-level result still reading
`PASSED`. The disk was removed from the trusted backup plan and marked for
recovery/replacement.
