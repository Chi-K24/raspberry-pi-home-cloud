# Security Model

## Public-repository policy

Never commit:

- `.env` files.
- Database passwords.
- WireGuard private or preshared keys.
- Full `wg showconf` output.
- Real LAN or WAN addresses.
- Filesystem UUIDs or PARTUUIDs.
- Disk serial numbers.
- Personal usernames, emails or folder labels.
- Application databases.
- Photo, video, backup or recovery data.

Use `scripts/sanitize-check.sh` before every public push.

## Network exposure

The intended design keeps application ports private:

- Immich, File Browser, OctoPrint and SMB are available only on the trusted LAN
  and through WireGuard.
- No application is directly port-forwarded from the internet.
- WireGuard is the single remote-access entry point.
- Pi-hole and Unbound are not configured as public resolvers.

## File Browser

File Browser must not use `/` as its root. Its root is an allow-listed
directory:

```text
/srv/filebrowser
```

The application database is stored outside that root so it cannot be downloaded
through the web interface.

## Immich

- Existing archives are mounted read-only.
- Each person receives a separate Immich account and storage label.
- Database credentials live only in the untracked `.env` file.
- Docker requires the media mount before startup.
- Remote access uses VPN rather than direct exposure.

## Backups

The database and media are separate backup concerns. Database dumps alone
cannot restore photos or videos.

A disk with pending or uncorrectable sectors is not a valid backup target even
if its SMART summary says `PASSED`.

## Incident checklist

If a secret is committed:

1. Treat it as exposed.
2. Rotate the password or key immediately.
3. Remove it from the current tree.
4. Rewrite Git history before publishing.
5. Re-run the sanitization check.

Removing a secret in a later commit does not remove it from earlier Git history.
