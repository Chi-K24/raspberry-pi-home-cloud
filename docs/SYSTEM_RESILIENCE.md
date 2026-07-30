# System Resilience and Recovery

## Memory-pressure protection

The host uses compressed zram swap plus a loopback/file-backed swap fallback.
This provides breathing room during short memory spikes from containers,
machine learning, video transcoding and desktop applications.

```bash
swapon --show
free -h
zramctl
```

Swap is not a substitute for sufficient RAM. Sustained swapping is a signal to
reduce concurrency, reschedule heavy jobs or adjust service limits.

## System image

A compressed Raspberry Pi system image and checksum provide a recovery point
for the bootable OS:

```text
pi-backup-latest.img.gz
pi-backup-latest.img.gz.sha256
```

Verify the artifact before depending on it:

```bash
sha256sum -c pi-backup-latest.img.gz.sha256
```

Images and checksums containing local paths or device details are operational
artifacts and must remain outside this public repository. The `.gitignore`
excludes disk images.

## Restore approach

1. Verify the compressed image checksum.
2. Identify the replacement target by model, size and serial outside any write
   command.
3. Restore with Raspberry Pi Imager's custom-image option or another validated
   imaging workflow.
4. Boot with nonessential external disks disconnected.
5. Confirm `/` and `/boot/firmware` resolve to the intended device.
6. Reconnect storage and validate mounts before starting applications.
7. Run `scripts/health-check.sh`.

Restoration overwrites a target device. The device must be positively
identified before imaging.

## What the system image does not replace

The operating-system image is only one recovery layer. A complete recovery
also needs:

- Immich PostgreSQL dumps.
- The complete Immich media directory.
- Untracked application configuration and secrets.
- WireGuard and No-IP configuration stored securely.
- A second independent copy of irreplaceable media.

Database dumps do not contain original photos or videos. Likewise, a media copy
without the database loses application metadata and relationships.

## Recovery drill

Periodically verify:

```bash
sha256sum -c pi-backup-latest.img.gz.sha256
sudo ./scripts/health-check.sh
```

At least one restore test should be performed on a spare device or disposable
target. A backup is not proven until it can be restored.

