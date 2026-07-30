#!/usr/bin/env bash

set -u

IMMICH_DIR="${IMMICH_DIR:-/opt/immich}"
MEDIA_MOUNT="${MEDIA_MOUNT:-/srv/immich-library}"
FILEBROWSER_URL="${FILEBROWSER_URL:-http://127.0.0.1:8080/}"
IMMICH_URL="${IMMICH_URL:-http://127.0.0.1:2283/api/server/ping}"
OCTOPRINT_URL="${OCTOPRINT_URL:-http://127.0.0.1:5000/}"

heading() {
  printf '\n## %s\n' "$1"
}

service_status() {
  local service="$1"
  printf '%-20s active=%-10s enabled=%s\n' \
    "$service" \
    "$(systemctl is-active "$service" 2>/dev/null || true)" \
    "$(systemctl is-enabled "$service" 2>/dev/null || true)"
}

http_status() {
  local name="$1"
  local url="$2"
  local code
  code="$(curl --max-time 5 -s -o /dev/null -w '%{http_code}' "$url" || true)"
  printf '%-20s HTTP %s\n' "$name" "${code:-unreachable}"
}

heading "Failed systemd units"
systemctl --failed --no-pager || true

heading "Core services"
for service in \
  ssh \
  pihole-FTL \
  unbound \
  wg-quick@wg0 \
  smbd \
  nmbd \
  filebrowser \
  octoprint \
  docker \
  containerd
do
  service_status "$service"
done

heading "Filesystems"
findmnt / || true
findmnt /boot/firmware || true
findmnt "$MEDIA_MOUNT" || true
df -hT / "$MEDIA_MOUNT" 2>/dev/null || true

heading "Application endpoints"
http_status "Immich" "$IMMICH_URL"
http_status "File Browser" "$FILEBROWSER_URL"
http_status "OctoPrint" "$OCTOPRINT_URL"

heading "Immich containers"
if [[ -f "$IMMICH_DIR/docker-compose.yml" ]]; then
  (
    cd "$IMMICH_DIR" || exit
    docker compose ps
  )
else
  printf 'Compose file not found at %s\n' "$IMMICH_DIR"
fi

heading "DNS"
if command -v dig >/dev/null 2>&1; then
  printf 'Pi-hole: '
  dig @127.0.0.1 example.com +short | head -n 1
  printf 'Unbound: '
  dig @127.0.0.1 -p 5335 example.com +short | head -n 1
else
  printf 'dig is not installed\n'
fi

heading "Thermals"
if command -v vcgencmd >/dev/null 2>&1; then
  vcgencmd measure_temp
  vcgencmd get_throttled
fi
grep . /sys/class/thermal/cooling_device*/{type,cur_state,max_state} \
  2>/dev/null || true
grep . /sys/class/hwmon/hwmon*/{name,fan1_input,pwm1} \
  2>/dev/null || true

heading "Block devices"
lsblk -o NAME,MODEL,SIZE,FSTYPE,LABEL,MOUNTPOINTS

heading "Recent serious boot messages"
journalctl -p err -b --no-pager | tail -n 30 || true
