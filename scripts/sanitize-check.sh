#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

failed=0

check_pattern() {
  local description="$1"
  local pattern="$2"
  local matches

  matches="$(rg -n --hidden \
    --glob '!.git/**' \
    --glob '!scripts/sanitize-check.sh' \
    "$pattern" . 2>/dev/null \
    | grep -Ev 'CHANGE_ME|<[^>]+>' || true)"

  if [[ -n "$matches" ]]; then
    printf '\nPotential %s:\n%s\n' "$description" "$matches"
    failed=1
  fi
}

check_pattern "private key material" \
  'BEGIN (OPENSSH|RSA|EC|DSA|PRIVATE) PRIVATE KEY|private[_ -]?key[=:][[:space:]]*[^<(]'

check_pattern "WireGuard secrets" \
  '(PrivateKey|PresharedKey)[[:space:]]*=[[:space:]]*[A-Za-z0-9+/]{20,}'

check_pattern "WireGuard endpoints" \
  'Endpoint[[:space:]]*=[[:space:]]*[^<[:space:]][^[:space:]]*'

check_pattern "No-IP configuration" \
  'NOIP_(USERNAME|PASSWORD|HOSTNAMES)[[:space:]]*=[[:space:]]*[^<[:space:]][^[:space:]]*'

check_pattern "committed passwords" \
  '(DB_PASSWORD|PASSWORD|TOKEN|SECRET)[[:space:]]*=[[:space:]]*[^[:space:]]{8,}'

check_pattern "filesystem identifiers" \
  '(UUID|PARTUUID)=[0-9A-Fa-f-]{8,}'

check_pattern "likely public or private LAN addresses" \
  '\b(10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3})\b'

check_pattern "email addresses" \
  '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'

if [[ "$failed" -ne 0 ]]; then
  printf '\nSanitization check FAILED. Review every match before publishing.\n' >&2
  exit 1
fi

printf 'Sanitization check passed: no obvious secrets or personal identifiers found.\n'
