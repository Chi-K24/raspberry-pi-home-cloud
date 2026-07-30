# Raspberry Pi 5 Home Cloud

A self-hosted private cloud built on a Raspberry Pi 5 with NVMe boot, tiered
storage, private remote access, photo backup, network-wide DNS filtering, file
sharing, 3D-printer management, and living-room emulation/media tools.

The project consolidates several previously independent services into one
maintainable system while keeping large media on dedicated storage and
latency-sensitive application data on NVMe.

> This public version is intentionally sanitized. IP addresses, usernames,
> device serials, filesystem UUIDs, WireGuard keys, passwords, personal folder
> names, and other identifying values are not included.

## What it runs

| Capability | Service | Role |
| --- | --- | --- |
| Photo cloud | Immich | Automatic mobile backup, timeline, search, faces and albums |
| DNS filtering | Pi-hole | Network-wide ad and tracker blocking |
| Recursive DNS | Unbound | Private recursive resolution for Pi-hole |
| Remote access | WireGuard | Encrypted access without exposing applications publicly |
| Browser file access | File Browser | Web interface for approved storage roots |
| LAN file access | Samba | Authenticated SMB shares |
| 3D printing | OctoPrint | Remote printer monitoring and control |
| Media center | Kodi | Local media playback |
| Emulation | RetroPie / EmulationStation | Local game launcher |
| Containers | Docker Compose | Immich application stack |

## Architecture

```mermaid
flowchart TD
    Clients["Phones and computers"]
    VPN["WireGuard VPN"]
    Pi["Raspberry Pi 5"]
    NVMe["2 TB NVMe<br/>OS, database, cache, thumbnails"]
    Library["6 TB HDD<br/>photos, videos, archives"]
    Legacy["Legacy USB disk<br/>recovery or secondary copies"]

    Clients -->|"LAN"| Pi
    Clients -->|"Remote"| VPN
    VPN --> Pi
    Pi --> NVMe
    Pi --> Library
    Pi -.-> Legacy
```

The NVMe drive hosts the operating system, PostgreSQL, Docker data, machine
learning cache and generated thumbnails. Original Immich uploads live on the
larger ext4 library disk. Existing archives can be mounted read-only inside
Immich as external libraries.

## Engineering highlights

- Migrated a running Raspberry Pi OS installation from SD card to NVMe.
- Updated and validated the Raspberry Pi bootloader for direct NVMe boot.
- Migrated roughly 600 GB with metadata-preserving `rsync`, followed by both
  reconciliation and checksum verification passes.
- Designed mount dependencies so Docker cannot start Immich before the media
  filesystem is available.
- Split Immich originals and high-I/O working data across HDD and NVMe.
- Restricted File Browser to an explicit root instead of exposing `/`.
- Used read-only container mounts for archived external photo libraries.
- Diagnosed USB Attached SCSI timeouts and applied a device-specific
  `usb-storage` fallback.
- Detected and corrected a Pi 5 PWM-fan initialization issue.
- Used service, HTTP, DNS, VPN, filesystem and SMART checks for validation.
- Identified a degraded legacy disk during the final operational audit.

## Repository map

```text
.
├── configs/
│   ├── boot/
│   ├── immich/
│   ├── samba/
│   ├── storage/
│   └── systemd/
├── docs/
│   ├── ARCHITECTURE.md
│   ├── BUILD_LOG.md
│   ├── OPERATIONS.md
│   ├── PORTFOLIO_SUMMARY.md
│   ├── PUBLISHING.md
│   ├── SECURITY.md
│   └── TROUBLESHOOTING.md
└── scripts/
    ├── health-check.sh
    ├── sanitize-check.sh
    └── verify-migration.sh
```

## Quick validation

Run the non-destructive health audit:

```bash
sudo ./scripts/health-check.sh
```

Before publishing any local changes:

```bash
./scripts/sanitize-check.sh
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Build log](docs/BUILD_LOG.md)
- [Operations runbook](docs/OPERATIONS.md)
- [Security model](docs/SECURITY.md)
- [Troubleshooting notes](docs/TROUBLESHOOTING.md)
- [Portfolio summary](docs/PORTFOLIO_SUMMARY.md)
- [Publishing checklist](docs/PUBLISHING.md)

## Project status

The core platform is operational. Immich, Docker, Pi-hole, Unbound, WireGuard,
Samba, File Browser and OctoPrint have passed functional checks. Kodi and
EmulationStation launch correctly with hardware graphics acceleration.

A legacy USB disk was flagged by SMART as degraded and is excluded from the
trusted storage design pending recovery and replacement.

## Upstream projects

- [Raspberry Pi documentation](https://www.raspberrypi.com/documentation/)
- [Immich documentation](https://docs.immich.app/)
- [Docker Engine documentation](https://docs.docker.com/engine/)
- [Pi-hole documentation](https://docs.pi-hole.net/)
- [Unbound documentation](https://unbound.docs.nlnetlabs.nl/)
- [WireGuard documentation](https://www.wireguard.com/quickstart/)
- [File Browser documentation](https://filebrowser.org/)
- [OctoPrint documentation](https://docs.octoprint.org/)
- [RetroPie documentation](https://retropie.org.uk/docs/)

## License

MIT. See [LICENSE](LICENSE).
