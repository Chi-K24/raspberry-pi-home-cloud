# Portfolio Summary

## Short description

Designed and deployed a multi-service Raspberry Pi 5 home-cloud platform with
NVMe boot, tiered storage, private VPN access, automated photo backup, network
DNS filtering, web/SMB file access, 3D-printer management and media/emulation
applications.

## Resume bullets

- Architected a Raspberry Pi 5 private-cloud platform combining Immich,
  Pi-hole, Unbound, WireGuard, Samba, File Browser, OctoPrint, Kodi and RetroPie.
- Migrated the operating system from SD to a 2 TB NVMe drive and validated
  direct NVMe boot, mount integrity and bootloader configuration.
- Migrated approximately 600 GB of archived data to a 6 TB ext4 storage tier
  using metadata-preserving `rsync` and checksum-based verification.
- Deployed Immich with Docker Compose and separated originals, PostgreSQL,
  thumbnails, model cache and read-only external archives across appropriate
  storage tiers.
- Hardened access by restricting File Browser to allow-listed paths, keeping
  application ports private and using WireGuard for encrypted remote access.
- Diagnosed USB/UAS instability, stale Samba paths, Raspberry Pi PWM-fan
  initialization and degraded-disk SMART indicators through Linux service,
  kernel, storage and network tooling.
- Built a repeatable operational runbook and automated health checks covering
  systemd, HTTP endpoints, containers, DNS, VPN, mounts and thermals.

## Skills demonstrated

- Linux administration and systemd
- Storage planning, GPT, ext4, NTFS and mount management
- Data migration and integrity verification
- Docker and Docker Compose
- Network services, DNS and VPNs
- Security hardening and secrets management
- Hardware and kernel troubleshooting
- Operational documentation and incident detection

## Interview talking points

### Why split storage?

PostgreSQL, cache and thumbnails benefit from NVMe latency, while large original
media files need capacity more than random-I/O performance. Separating them
improved responsiveness without wasting expensive flash capacity.

### How was data integrity protected?

The migration used a metadata-preserving copy, a no-change reconciliation pass
and a checksum dry run. The source was retained until both checks succeeded.

### What failure modes were addressed?

- Missing media disk at Docker startup.
- USB bridge instability under UAS.
- Accidental exposure of the Linux root through File Browser.
- Mixed ownership in multi-user external photo libraries.
- Thermal throttling caused by an undetected PWM fan.
- A failing legacy backup disk that still reported a high-level SMART pass.

### What would come next?

- Replace the degraded legacy disk.
- Add a second independent media backup.
- Automate encrypted off-site backup for critical data.
- Add metrics and alerting.
- Document recovery drills and regularly test restores.
