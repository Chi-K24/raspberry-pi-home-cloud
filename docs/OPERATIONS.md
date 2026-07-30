# Operations Runbook

## Daily health

```bash
sudo ./scripts/health-check.sh
```

The script is read-only. Review:

- Failed units.
- Core service states.
- Immich container health.
- Local HTTP checks.
- Mount presence and capacity.
- Pi temperature, throttling history and fan state.
- DDNS, VPN and swap state.

The expected state of every project and supporting component is documented in
[SERVICE_INVENTORY.md](SERVICE_INVENTORY.md).

## Immich

### Status

```bash
cd /opt/immich
sudo docker compose ps
curl -fsS http://127.0.0.1:2283/api/server/ping
```

### Logs

```bash
cd /opt/immich
sudo docker compose logs --tail=200
```

### Upgrade

Read the Immich release notes first, then:

```bash
cd /opt/immich
sudo docker compose pull
sudo docker compose up -d
sudo docker compose ps
```

### Database backup

Immich can create scheduled database dumps from the administration UI. These
dumps must be backed up together with the media directory.

## DNS

```bash
systemctl status pihole-FTL unbound --no-pager
dig @127.0.0.1 example.com +short
dig @127.0.0.1 -p 5335 example.com +short
```

The first query tests Pi-hole. The second tests Unbound directly.

After changing router DHCP DNS, renew a client lease and verify that the client
received the Pi-hole address. Router setup and IPv6 considerations are covered
in [REMOTE_ACCESS.md](REMOTE_ACCESS.md).

## No-IP and WireGuard

```bash
systemctl status noip-duc --no-pager
sudo journalctl -u noip-duc --since today --no-pager
dig +short <DDNS_HOSTNAME>
```

```bash
systemctl status wg-quick@wg0 --no-pager
sudo wg show
```

`wg-quick@wg0` normally reports `active (exited)` because setup completed and
the kernel interface remains active.

Never publish the full output of `wg show` if peer metadata must remain private.
See [REMOTE_ACCESS.md](REMOTE_ACCESS.md) for router, split-tunnel and remote
validation details.

## Samba

```bash
sudo testparm -s
systemctl status smbd nmbd --no-pager
```

After a configuration edit:

```bash
sudo testparm -s >/dev/null
sudo systemctl reload smbd nmbd
```

## File Browser

```bash
systemctl status filebrowser --no-pager
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/
```

Expected HTTP results include `200` or a redirect to a login page.

## OctoPrint

```bash
systemctl status octoprint --no-pager
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:5000/
```

An offline printer state is normal when the printer is powered off or
disconnected.

## RetroPie

RetroPie and EmulationStation are graphical applications, not background
services.

```bash
ldd /opt/retropie/supplementary/emulationstation/emulationstation \
  | grep 'not found' || echo "Libraries OK"

tail -n 80 "$HOME/.emulationstation/es_log.txt"
```

Launch tests should be observed on the connected display.

## Kodi

Kodi is a graphical application rather than a required background service:

```bash
kodi --version
```

Launch tests should be observed on the connected display.

## Thermal monitoring

```bash
vcgencmd measure_temp
vcgencmd get_throttled
grep . /sys/class/thermal/cooling_device*/{type,cur_state,max_state} 2>/dev/null
grep . /sys/class/hwmon/hwmon*/{name,fan1_input,pwm1} 2>/dev/null
```

A current `throttled=0x0` means no under-voltage or throttling flags have been
recorded since boot.

## Storage checks

```bash
lsblk -o NAME,MODEL,SIZE,FSTYPE,LABEL,MOUNTPOINTS
findmnt /srv/immich-library
df -hT / /srv/immich-library
sudo smartctl --scan-open
```

Do not rely only on SMART's high-level `PASSED` result. Review pending,
reallocated and uncorrectable sector attributes.

## Swap and recovery

```bash
swapon --show
free -h
zramctl
```

See [SYSTEM_RESILIENCE.md](SYSTEM_RESILIENCE.md) for system-image verification,
restore boundaries and the recovery drill.

## Migration verification

```bash
sudo ./scripts/verify-migration.sh /source/path /destination/path
```

The checksum dry run can take hours on large datasets.
