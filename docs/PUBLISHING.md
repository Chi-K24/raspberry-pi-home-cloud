# Publishing Checklist

## 1. Review placeholders

Search for values that must be replaced or intentionally left generic:

```bash
rg -n 'YOUR_|<[^>]+>|CHANGE_ME' .
```

Placeholders in example configuration files are expected.

## 2. Run the sanitization check

```bash
./scripts/sanitize-check.sh
```

Manually review every match before publishing.

## 3. Review the Git tree

```bash
git status --short
git ls-files
```

Confirm there are no databases, images, archives, `.env` files or local logs.

## 4. Review committed history

```bash
git log --stat --oneline
```

Secrets removed in a later commit still exist in earlier commits.

## 5. Create a remote repository

Create an empty repository on the hosting provider without automatically adding
a README or license. Then:

```bash
git remote add origin <REMOTE_REPOSITORY_URL>
git branch -M main
git push -u origin main
```

Do not paste access tokens into shell commands that will be saved in history.

## Suggested repository description

> Raspberry Pi 5 private cloud with NVMe boot, tiered storage, Immich, Pi-hole,
> Unbound, No-IP, WireGuard, File Browser, Samba, OctoPrint, Kodi and RetroPie.

## Suggested topics

```text
raspberry-pi
self-hosted
homelab
immich
docker-compose
wireguard
dynamic-dns
pihole
unbound
nas
octoprint
retropie
```
