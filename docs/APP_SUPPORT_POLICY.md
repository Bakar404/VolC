# App Support Policy

VolC supports per-app controls only when there is a public, safe way to control that app's volume.

Public CoreAudio HAL can enumerate many apps that produce audio, but it does not expose public writable per-process gain. That means unsupported apps must remain read-only unless they expose a public/scriptable volume API.

## Allowed Control Paths

Allowed:

- public AppleScript APIs
- public browser JavaScript automation through Apple Events
- public macOS APIs
- public app-specific APIs that do not require private entitlements or background capture

Not allowed:

- private CoreAudio APIs
- kernel extensions
- virtual audio devices unless the project direction intentionally changes
- microphone or audio input capture
- hidden audio recording
- dependencies that intercept system audio without clear user consent

## Supported Apps

Currently supported:

- Spotify
- Music
- Google Chrome
- Microsoft Edge
- Brave
- Vivaldi
- Opera / Opera GX
- Safari

## Read-Only Apps

These are usually read-only because macOS public APIs can detect them but cannot set their per-app output gain:

- Zoom
- Firefox
- Discord
- games
- most Electron apps
- apps without scriptable volume APIs

## Adding New App Support

A pull request adding app support should include:

- app name
- bundle ID
- public API or AppleScript command used
- macOS version tested
- app version tested
- known limitations
- whether automation permissions are required

App support should be scoped to volume control only. Avoid broad automation that changes playback state, reads user data, captures audio, or controls unrelated app behavior.

