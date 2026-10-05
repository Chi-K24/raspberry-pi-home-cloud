# LEMON Manuals on Raspberry Pi

## Project scope

Deployment of the upstream LEMON automotive manuals server on the Raspberry Pi
home-cloud host, completed October 4, 2026. The portfolio contribution is Linux
application deployment and service administration. LEMON's application code,
manuals, database engines and web interface are upstream work.

This repository contains deployment documentation only. It does not contain
manual pages, database archives, upstream source code or compiled binaries.
The repository's MIT license applies to its own material, not to LEMON or any
third-party manual content.

## What was established

- Reviewed the bundled Linux/ARM instructions and Rust source archive.
- Identified that supplied Linux executables target x86_64, while the
  Raspberry Pi requires the upstream source-build route.
- Deployed a native service named `lemon.service`.
- Confirmed systemd loaded the unit from `/etc/systemd/system/lemon.service`.
- Confirmed the unit was enabled and `active (running)`, with a
  `lemon-website` main process, in the October 4 setup status capture.

The deployment files were on mounted USB storage. These public notes omit
personal identifiers, hostnames, network addresses and original download paths.

## Source-build reference

The bundled upstream instructions specify a Rust toolchain and a C toolchain,
then the following command from the extracted source directory:

```bash
cargo build --release
```

The documented output is `target/release/lemon-website`. The source archive
contains `Cargo.toml`, `Cargo.lock`, Rust application modules, LEMON and CHARM
database-engine modules, web assets and a vendored `oxidized-mtbl` dependency.

This is the upstream build procedure, not a retained compiler log. Exact
compiler versions, package-install commands and any local build fixes were not
captured in the available record.

## Service operations

Inspect configuration and state on the Raspberry Pi:

```bash
systemctl cat lemon.service
systemctl is-enabled lemon.service
systemctl is-active lemon.service
systemctl status lemon.service --no-pager -l
journalctl -u lemon.service -b --no-pager -n 100
```

Restart after an intentional application change:

```bash
sudo systemctl restart lemon.service
systemctl status lemon.service --no-pager -l
```

If the unit file itself changes, run `sudo systemctl daemon-reload` before
restarting it. The exact deployed unit contents were not retained, so this
repository does not present a reconstructed unit as the installed configuration.

## Verification boundaries and next checks

The captured status showed the process running approximately three seconds
after startup. That confirms initial service startup, not long-term stability
or successful manual-page rendering.

Before treating the deployment as fully validated:

1. Inspect the installed unit for its executable, working directory, data-index
   arguments, service user and configured listening address/port.
2. Confirm the mounted data filesystem is available and the service user can
   read the selected indexes and database files. Check mount dependencies for
   boot-time startup when using external storage.
3. Open the configured endpoint and load a representative manual page and image.
4. Check service logs for index-loading or missing-data errors.
5. During a planned reboot, verify the service starts with its storage mounted.

Upstream documents port 8080 as its default. The deployed port, bind address,
loaded datasets, restart policy and VPN reachability were not established by
the retained status output and are not claimed here.

## Attribution

The bundled LEMON instructions and source listing are the basis of the build
notes. LEMON's included README credits Operation CHARM for advice and use of
its web design. This deployment does not claim authorship of either project.
