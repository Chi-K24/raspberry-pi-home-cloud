# Troubleshooting

## USB disk slows to a few MB/s

Check real device activity:

```bash
iostat -dx 2 /dev/sdX
```

Large write latency, a growing queue and bursty throughput can indicate cache
flushes, SMR behavior or media problems. Kernel USB resets point toward the
bridge, cable, power or UAS compatibility.

Exit `iostat` with `Ctrl+C`.

## UAS timeouts and USB disconnects

Inspect:

```bash
sudo journalctl -k --since "30 minutes ago" --no-pager
lsusb -t
```

If a specific bridge is unstable under UAS, a targeted kernel quirk can retain
USB 3 speed while changing only that device to `usb-storage`:

```text
usb-storage.quirks=<VID>:<PID>:u
```

Do not apply a global UAS disable. Verify after reboot with `lsusb -t`.

## SMART unavailable through a USB enclosure

Try the device type reported by:

```bash
sudo smartctl --scan-open
```

Common attempts include:

```bash
sudo smartctl -a -d sat /dev/sdX
sudo smartctl -a -d scsi /dev/sdX
```

Some USB bridges do not pass ATA SMART commands. Lack of SMART visibility does
not prove the disk is healthy.

## NTFS I/O errors

Stop writing immediately and inspect SMART before attempting filesystem repair.
For valuable data, clone or rescue first.

`ntfsfix` is not a Linux implementation of Windows CHKDSK. A Windows
`chkdsk /r` pass may repair logical NTFS damage and identify unreadable clusters,
but it cannot restore physical reliability.

## Duplicate mount points

Check:

```bash
findmnt -S /dev/sdX1
sudo nl -ba /etc/fstab
```

Avoid using both a generic USB auto-mounter and explicit `fstab` entries for the
same disk. Resolve exact targets before unmounting.

## Samba share points to an old mount

Validate all configured paths after a storage migration:

```bash
sudo testparm -s
```

Update only the affected `path`, validate again, and reload the daemons.

## File Browser returns 404 for an old folder

Old bookmarks can survive a root-directory change. Confirm the service root:

```bash
systemctl cat filebrowser
```

Remove or update the client bookmark. A `403` for an ext4 `lost+found`
directory is expected.

## Pi 5 fan spins at boot but stops under load

Inspect cooling-device registration:

```bash
grep . /sys/class/thermal/cooling_device*/{type,cur_state,max_state} 2>/dev/null
```

If a compatible four-wire fan is installed but no `pwm-fan` device appears,
force-enable the built-in Pi 5 fan node:

```ini
[all]
dtparam=cooling_fan=on
```

Reboot and verify RPM:

```bash
grep . /sys/class/hwmon/hwmon*/{name,fan1_input,pwm1} 2>/dev/null
```

Always power down and disconnect power before reseating a fan connector.

## Immich causes sustained high CPU usage

Initial uploads trigger thumbnails, metadata extraction, machine learning and
video transcoding. Inspect:

```bash
top -b -n 1 -o %CPU | head -n 20
sudo docker stats --no-stream
```

If temperatures remain excessive with a working fan, reduce concurrency in
Immich under **Administration → Settings → Job Settings**.

## EmulationStation appears to hang over SSH

The executable may be running normally and rendering on the attached display
while holding the SSH terminal. Check:

```bash
tail -n 80 "$HOME/.emulationstation/es_log.txt"
```

Successful window creation, Broadcom V3D rendering and a clean shutdown indicate
that EmulationStation itself is healthy.
