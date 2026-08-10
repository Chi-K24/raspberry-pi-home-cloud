# Kodi and RetroPie Media Console

A living-room media and emulation layer running on the same Raspberry Pi 5 as the broader home-cloud platform. Kodi provides local media playback, while RetroPie and EmulationStation provide a controller-friendly launcher for the installed emulator stack.

> This public documentation contains no ROMs, BIOS files, game images, personal media paths, library databases, controller identifiers, or copyrighted media.

## Architecture

~~~mermaid
flowchart TD
    Display["TV or attached display"] --> Pi["Raspberry Pi 5 graphical session"]
    Pi --> Kodi["Kodi media center"]
    Pi --> ES["RetroPie and EmulationStation"]
    Kodi --> Media["Approved local media sources"]
    ES --> Emulators["Installed emulator stack"]
    Services["Background home-cloud services"] -.-> Pi
~~~

Kodi and EmulationStation run as graphical applications only when requested. The Pi's DNS, VPN, file-sharing, photo, monitoring, and other server workloads remain independently managed in the background.

## Implementation profile

| Area | Implementation |
| --- | --- |
| Hardware | Raspberry Pi 5 |
| Media frontend | Kodi |
| Emulation frontend | RetroPie / EmulationStation |
| Graphics | Broadcom V3D hardware-accelerated OpenGL rendering |
| Launch model | Local graphical session on the attached display |
| Service model | On-demand applications, not persistent daemons |
| Diagnostics | Binary, dynamic-library, renderer, and application-log checks |

## Why this belongs on the server

The Raspberry Pi is physically connected to the living-room display, so the same hardware can provide an appliance-like local interface without moving the infrastructure services into Kodi or RetroPie.

This separation keeps the roles clear:

- Kodi and EmulationStation own the local display while in use.
- Home-cloud applications continue under their normal service managers.
- Media and emulation frontends can be restarted without rebooting the whole server stack.
- Application failure is diagnosed independently from network and storage services.

## Validation

### Kodi

Confirm the package and executable are available:

~~~bash
command -v kodi
kodi --version
~~~

Launch testing must be observed on the attached display because Kodi is a graphical application rather than a background HTTP service.

### RetroPie and EmulationStation

Check that the frontend has no unresolved shared libraries:

~~~bash
ldd /opt/retropie/supplementary/emulationstation/emulationstation \
  | grep 'not found' || echo "EmulationStation libraries: OK"
~~~

Inspect the application log after a launch test:

~~~bash
tail -n 80 "¤HOME/.emulationstation/es_log.txt"
~~~

Successful window creation, Broadcom V3D/OpenGL renderer initialization, and a clean shutdown indicate that the graphical path is healthy.

## SSH launch behavior

Starting EmulationStation from SSH can look like a hang because the process renders on the attached display while retaining the terminal session. Check the physical display and the EmulationStation log before treating the process as failed.

## Operational boundaries

- Kodi and EmulationStation are not required to start at boot.
- No public web port is opened for either graphical application.
- ROMs, BIOS files, save data, scraped artwork, and personal media remain outside this public repository.
- Bluetooth is managed by the host when local controllers or accessories are used.
- A broken frontend should not require changing DNS, VPN, Docker, or storage configuration.

## Maintenance checks

After operating-system, graphics-library, or frontend updates:

1. Confirm Kodi still reports its version.
2. Re-run the EmulationStation library check.
3. Launch each frontend on the attached display.
4. Inspect the EmulationStation log for renderer or window errors.
5. Confirm critical background services remain healthy.
6. Test one legally owned local media item and one authorized emulator workload.

## Troubleshooting principle

Treat display-session issues separately from service failures. A process holding an SSH terminal can still be functioning normally on the TV. Conversely, an installed binary does not prove that graphics, input, audio, or content paths are working; each layer should be validated explicitly.

## Portfolio summary

Built a dual-purpose Raspberry Pi 5 platform that combines always-on home infrastructure with an on-demand living-room interface. Kodi handles local media playback, while RetroPie and EmulationStation provide an emulation launcher using hardware-accelerated Broadcom V3D graphics.

## Upstream documentation

- [Kodi Wiki](https://kodi.wiki/)
- [RetroPie documentation](https://retropie.org.uk/docs/)
- [Raspberry Pi graphics documentation](https://www.raspberrypi.com/documentation/computers/configuration.html)
