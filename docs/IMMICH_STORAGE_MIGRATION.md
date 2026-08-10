# Immich Storage Architecture and Verified Migration

A storage-engineering case study for moving a live Raspberry Pi home-cloud platform from SD-card and legacy USB storage to a tiered 2 TB NVMe and 6 TB ext4 design without trusting a copy operation alone.

The migration moved roughly 600 GB, preserved Linux metadata, verified both filesystem reconciliation and file contents, and then deployed Immich with high-I/O application data separated from large media originals.

> This public version excludes personal media, filenames, user identities, device serials, filesystem UUIDs, credentials, database contents, and private mount details.

## Constraints

The migration had to satisfy several competing requirements:

- Preserve an existing photo and video archive.
- Keep original media on a large, replaceable capacity tier.
- Place PostgreSQL, thumbnails, caches, and the operating system on fast NVMe.
- Prevent Docker from silently writing into an empty mount-point directory.
- Keep the source archive immutable until verification finished.
- Avoid treating an unhealthy legacy disk as a backup.
- Support machine-learning, thumbnail, and video-transcoding bursts on a Raspberry Pi 5.

## Final design

~~~mermaid
flowchart TD
    Clients["Phones and browsers"] --> Immich["Immich server"]
    Immich --> Originals["6 TB ext4 originals"]
    Immich --> Thumbs["NVMe thumbnails"]
    Database["PostgreSQL"] --> NVMe["2 TB NVMe"]
    ML["Machine-learning cache"] --> NVMe
    Archive["Existing archive"] -->|"Read-only"| Immich
    Guard["systemd mount guard"] --> Immich
~~~

| Tier | Workload | Reason |
| --- | --- | --- |
| 2 TB NVMe | OS, Docker data, PostgreSQL, thumbnails, application state and model cache | Low latency and high random-I/O performance |
| 6 TB ext4 media disk | Uploaded originals, generated media variants, profile data and database dumps | Capacity and clean Linux filesystem semantics |
| Read-only import area | Pre-existing photo archive | Prevent accidental mutation during import and ownership validation |
| Legacy/recovery storage | Temporary recovery access only | Excluded from trusted backup design after health problems |

## Immich placement

~~~text
/srv/immich-library/
├── immich-managed/
│   ├── library/           # Uploaded originals
│   ├── encoded-video/     # Generated video variants
│   ├── profile/
│   └── backups/           # Database dumps, not media backups
└── import-staging/        # Existing archive, mounted read-only

/srv/immich-data/
├── postgres/              # NVMe
└── thumbs/                # NVMe
~~~

The container-facing design separates three data classes:

| Host storage | Container role | Access |
| --- | --- | --- |
| Managed media directory | Primary Immich data | Read/write |
| NVMe thumbnail directory | High-I/O generated data | Read/write |
| Existing archive | External library | Read-only |

## Phase 1: prepare the media tier

The media filesystem was created as ext4 and mounted persistently with a filesystem UUID, `noatime`, `nofail`, and a bounded systemd device timeout.

The source and destination were positively identified before any formatting or copy command. Placeholder device names are used in this public example:

~~~bash
lsblk -o NAME,MODEL,SERIAL,SIZE,FSTYPE,LABEL,MOUNTPOINTS
findmnt
~~~

A mount check was performed before migration:

~~~bash
findmnt /srv/immich-library
df -hT /srv/immich-library
~~~

## Phase 2: metadata-preserving copy

The initial copy preserved permissions, ownership, hard links, ACLs, extended attributes, filesystem boundaries, and numeric IDs:

~~~bash
sudo rsync -aHAXx --numeric-ids --partial --info=progress2 \
  /source/ /srv/immich-library/import-staging/
~~~

The source remained available and unchanged while the destination was evaluated.

## Phase 3: verify twice

A successful copy command was not accepted as proof of equivalence.

### Reconciliation pass

~~~bash
sudo rsync -aHAXxi --numeric-ids --stats \
  /source/ /srv/immich-library/import-staging/
~~~

This checks metadata and size differences. The completed migration reported that no reconciliation changes were required.

### Checksum dry run

~~~bash
sudo rsync -aHAXxnc --numeric-ids --itemize-changes --stats \
  /source/ /srv/immich-library/import-staging/
~~~

This compares file contents without modifying either tree. The completed checksum pass reported no changed files.

The repository includes a reusable non-destructive wrapper: [`verify-migration.sh`](../scripts/verify-migration.sh).

## Phase 4: migrate the operating system to NVMe

The Raspberry Pi bootloader was updated and validated for direct NVMe boot. The target received:

- A FAT32 boot partition
- An ext4 root partition
- A metadata-preserving copy of the running root filesystem
- Explicit exclusions for runtime virtual filesystems and external mounts
- Updated `cmdline.txt` and `fstab` references using the new partition identities

The final boot test was performed with the SD card removed. Both `/` and `/boot/firmware` resolved to the intended NVMe partitions.

## Phase 5: deploy Immich

Immich was deployed through Docker Compose with the following placement:

- Originals on the high-capacity ext4 media disk
- PostgreSQL on NVMe
- Thumbnails on NVMe
- Machine-learning cache in NVMe-backed Docker storage
- Existing archives exposed as read-only external libraries

This keeps large sequential media away from the latency-sensitive database and generated working set.

## Mount-order protection

An unavailable media disk must not look like an empty but valid directory to Docker. The Immich service has an explicit mount dependency:

~~~ini
[Unit]
RequiresMountsFor=/srv/immich-library
~~~

After adding or changing the dependency:

~~~bash
sudo systemctl daemon-reload
sudo systemctl restart docker
systemctl show docker -p RequiresMountsFor
~~~

The goal is to stop the application stack rather than let it write new data into the root filesystem beneath a missing mount.

## Validation matrix

| Layer | Validation |
| --- | --- |
| Filesystem | `findmnt`, `df` and expected ext4 mount |
| Migration | Metadata reconciliation plus checksum dry run |
| Boot | NVMe root and boot mounts with the SD card removed |
| Containers | Compose status for Immich, PostgreSQL, Valkey and machine learning |
| Application | Local Immich ping endpoint and phone upload test |
| Storage health | SMART attributes, kernel logs and capacity checks |
| Recovery | Compressed OS image checksum plus separate database/media backup plan |

The non-destructive [`health-check.sh`](../scripts/health-check.sh) combines mount, capacity, endpoint, container, service, temperature, and block-device checks.

## Problems uncovered

### USB Attached SCSI instability

A legacy USB-to-SATA bridge produced UAS timeouts, aborted commands, and disconnects. A device-specific quirk moved only the affected enclosure to `usb-storage` while retaining USB 3 operation. UAS remained enabled for the healthy media device.

### Unhealthy legacy storage

SMART analysis identified unreadable sectors on a legacy disk. It was removed from the trusted backup design rather than treated as a valid second copy.

### Thermal load

Initial Immich processing triggered thumbnails, metadata extraction, machine learning, and transcoding. Thermal history exposed a PWM-fan initialization problem, which was corrected and revalidated.

### Memory pressure

Compressed zram plus a file-backed fallback provide temporary breathing room for machine-learning, transcoding, container, and desktop workload spikes. Swap is a resilience layer, not a substitute for appropriate concurrency.

## Backup boundary

An Immich database dump contains metadata and relationships; it does not contain the original media. Recovery requires at least:

1. PostgreSQL dumps and relevant configuration
2. A complete independent copy of the Immich media directory
3. Untracked secrets and deployment configuration
4. A tested operating-system recovery image
5. A restore drill that verifies mounts before applications start

The production media disk and the OS image are not, by themselves, a complete backup strategy.

## Outcome

- Roughly 600 GB migrated with metadata preservation.
- Reconciliation reported no required changes.
- Checksum verification reported no changed files.
- The Pi boots directly from NVMe without the SD card.
- Immich storage is split by workload rather than placed on one disk.
- Existing archives remain read-only during import.
- Docker is mount-aware before starting Immich.
- An unhealthy legacy disk was removed from the trusted design.
- Repeatable health and migration-verification scripts document the operational checks.

## Portfolio summary

Designed and validated a tiered storage architecture for an Immich photo cloud on Raspberry Pi 5. Migrated roughly 600 GB with metadata-preserving `rsync`, reconciliation and checksum verification; moved the OS and high-I/O application data to NVMe; retained originals on a 6 TB ext4 tier; and added mount-order, health, thermal and recovery safeguards.

## Related documentation

- [Architecture](ARCHITECTURE.md)
- [Build log](BUILD_LOG.md)
- [Operations runbook](OPERATIONS.md)
- [System resilience and recovery](SYSTEM_RESILIENCE.md)
- [Troubleshooting](TROUBLESHOOTING.md)
