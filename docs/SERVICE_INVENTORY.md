# Service Inventory

This inventory separates persistent services from graphical applications and
optional operating-system components.

## Project services

| Component | Runtime | Expected state | Validation |
| --- | --- | --- | --- |
| SSH | `ssh.service` | active | Remote shell connects |
| Pi-hole | `pihole-FTL.service` | active | DNS query succeeds |
| Unbound | `unbound.service` | active | Direct recursive query succeeds |
| No-IP | `noip-duc.service` | active | Update log and hostname resolution |
| WireGuard | `wg-quick@wg0` unit | active (exited) | Interface and recent peer handshake |
| Samba | `smbd.service`, `nmbd.service` | active | `testparm` and authenticated share |
| File Browser | `filebrowser.service` | active | Local HTTP response |
| OctoPrint | `octoprint.service` | active | Local HTTP redirect or page |
| Docker | `docker.service`, `containerd.service` | active | Engine and Compose respond |
| LEMON manuals | `lemon.service` | enabled; active (running) in setup capture | `systemctl status lemon.service`; page and reboot checks remain to be recorded |
| Immich | Docker Compose stack | healthy | All containers healthy and API pong |

## Supporting services

| Component | Expected state | Purpose |
| --- | --- | --- |
| `avahi-daemon` | active | Local service discovery |
| `bluetooth` | active when used | Controllers and local accessories |
| `cups` | active when used | Printing support |
| `lightdm` | active | Local graphical session |
| `smartmontools` | active | Disk-health monitoring |
| `unattended-upgrades` | active | Automated security updates |
| `winbind` | active when required | Samba identity integration |

`samba-ad-dc.service` being inactive is expected for a standalone Samba server;
the host uses `smbd` and `nmbd`, not an Active Directory domain controller.
`wayvnc-control` is optional and may be inactive when remote desktop is not in
use. Netdata was intentionally not installed; the repository provides a
lightweight read-only health script instead.

## Graphical applications

Kodi and RetroPie/EmulationStation are not required to remain active as
background daemons. Validate their installed binaries and launch them on the
connected display:

```bash
kodi --version

ldd /opt/retropie/supplementary/emulationstation/emulationstation \
  | grep 'not found' || echo "EmulationStation libraries: OK"

tail -n 80 "$HOME/.emulationstation/es_log.txt"
```

## Full audit

```bash
systemctl --failed --no-pager
systemctl list-unit-files --type=service --state=enabled --no-pager
sudo journalctl -p err -b --no-pager
sudo ./scripts/health-check.sh
```

An enabled unit is not necessarily supposed to be continuously active. Timer,
oneshot, hardware-dependent and mutually exclusive units can legitimately show
inactive after completing or when their feature is unused.
