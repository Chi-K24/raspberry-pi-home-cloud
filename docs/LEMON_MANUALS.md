# LEMON Workspace — Responsive Manuals UI on Raspberry Pi

## Project scope

Deployed the upstream Rust-based LEMON manuals server on Raspberry Pi, then
customized its frontend for desktop and mobile use. Initial service setup was
completed October 4, 2026; the redesigned interface was compiled and confirmed
working on the Pi on October 5.

The contribution covers frontend customization, Linux deployment, browser
testing and operational documentation. LEMON supplies the server, database
engines, original interface and manual content. The Rust backend and database
files were unchanged by the UI update.

This repository documents the work; it does not distribute manual databases,
upstream source archives or compiled binaries. Its MIT license does not extend
to third-party LEMON or manual content.

## Interface improvements

| Area | Implemented behaviour |
| --- | --- |
| Desktop navigation | Workspace sidebar with vehicle breadcrumbs, saved pages and recent history |
| Mobile navigation | Responsive drawer with keyboard focus management and touch-friendly controls |
| Index filtering | Filters entries on the current page, including nested groups and an empty-results message |
| Folder navigation | Separate expand/collapse buttons, remembered expansion state and deep-link reveal |
| Personal workspace | Saved pages and recent history in browser storage, with a clear-history control |
| Reading | Light/dark themes, text sizing, focus view and print styles |
| Diagrams | Keyboard-operated image viewer with zoom and scroll-to-pan |
| Compatibility | Linked images, image maps and CHARM hotspots retain their original navigation |
| Layout | Scrollable tables and constrained images on narrow screens |

Filtering searches only the currently loaded index, not all manuals or the
server database. Saved pages and history stay in the current browser/origin.
This is a responsive website, not an installable or offline PWA.

## Implementation choices

Only `src/html/script.js` and `src/html/style.css` changed application behaviour.
The interface enhances the existing generated HTML and uses the actual
breadcrumb destinations. No frontend framework, external font, CDN, analytics
or new server dependency was added.

Storage access is guarded so blocked or malformed browser storage does not
break navigation. Folder state is restored after filtering, and malformed URL
fragments are handled without crashing initialization. The diagram viewer
preserves original image colours instead of recolouring technical diagrams
for dark mode.

No performance benchmark or database-wide search speedup is claimed.

## Build and deployment

The upstream Linux binaries target x86_64, so the Raspberry Pi uses a native
source build with Rust and C tooling. The update helper:

1. Backs up the existing CSS, JavaScript and release binary.
2. Copies only the two frontend files into the existing source tree, preserving
   any local ARM/Rust fixes.
3. Runs `cargo build --release --locked` with an explicit target directory.
4. Restores the previous frontend sources if the build fails.
5. Leaves the service restart to the operator after checking the executable path.

The October 5 build completed successfully in **24.40 seconds** as an incremental
release build on the existing installation; this is not a clean-build benchmark.
Six upstream `oxidized-mtbl` deprecation warnings were non-fatal.

The service executable was verified to point to the rebuilt
`target/release/lemon-website`. After the restart instructions, the operator
confirmed that the new interface was working.

The inspected unit also includes a storage-mount requirement and
`Restart=on-failure`. Hostnames, account names, IP addresses, listening details,
download identifiers and private filesystem paths are omitted.

## Validation and limits

**Automated Chromium tests on synthetic pages passed for:**

- Current-index filtering, nested matches, clearing and folder-state restoration.
- Saved-page persistence.
- Deep links into collapsed groups and malformed fragment handling.
- Image viewer zoom and Escape dismissal; exclusion of hotspot images.
- Theme switching and mobile drawer behaviour.
- No horizontal document overflow at 390- and 320-pixel viewport widths.
- Invalid or blocked browser storage and failed-save feedback.

Desktop and mobile screenshots were visually reviewed using synthetic content.
The native Pi build succeeded and the operator confirmed live operation.

That confirmation is not an exhaustive audit of every manual or every feature.
Real-data CHARM compatibility, generated offline ZIPs, reboot recovery and
long-term stability remain to be checked.

## Operations and rollback

Inspect the configured binary and service state:

```bash
systemctl show lemon.service --property=ExecStart --no-pager
systemctl status lemon.service --no-pager -l
journalctl -u lemon.service -b --no-pager -n 50
```

After a successful build and executable-path check:

```bash
sudo systemctl restart lemon.service
```

Hard-refresh the browser to reload the embedded CSS and JavaScript.
The UI assets are included in the compiled binary, so source edits require a
rebuild. Rollback uses the saved frontend files and previous binary; stop the
service before replacing a running executable, then start it again.
The update helper does not modify the manuals database.

## Attribution

LEMON and its contributors provide the upstream application and content.
LEMON's included README credits Operation CHARM for advice and its web design.
The responsive workspace is a frontend customization of that application.
