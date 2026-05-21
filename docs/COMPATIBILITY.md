# Compatibility

VolC targets macOS 13 Ventura and newer. The code avoids private APIs, virtual audio devices, loopback drivers, kernel extensions, and third-party dependencies.

## Runtime Support

| macOS version | Expected status | Notes |
| --- | --- | --- |
| macOS 13 Ventura | Supported | Minimum deployment target. Uses `SMAppService`, which is available on macOS 13+. |
| macOS 14 Sonoma | Supported | Same public API surface used by VolC. |
| macOS 15 Sequoia | Supported | Maintainer development/testing has been on macOS 15.7.1. |
| macOS 26 Tahoe and newer | Expected | Public APIs should continue to work, but release builds should be tested before claiming support. |

## Xcode Guidance

Use an Xcode version that your installed macOS can run. Apple maintains the current compatibility table here:

https://developer.apple.com/support/xcode/

Useful starting points:

| Your macOS | Practical Xcode choice |
| --- | --- |
| macOS 13 Ventura | Xcode 14.3.1, or Xcode 15.0.x on macOS 13.5+ |
| macOS 14 Sonoma | Xcode 15.4, or Xcode 16.x where supported |
| macOS 15 Sequoia | Xcode 16.4 is a good stable choice; Xcode 26.0-26.3 also supports macOS 15.6+ according to Apple's table |
| macOS 26 Tahoe | Current Xcode from the Mac App Store is usually fine |

If the Mac App Store only offers an Xcode that requires a newer macOS version, download an older compatible `.xip` from:

https://developer.apple.com/download/all/

## Feature Compatibility

| Feature | API | macOS notes |
| --- | --- | --- |
| Menu bar icon | `NSStatusItem` | Longstanding AppKit API |
| Popover UI | SwiftUI + `NSPopover` | macOS 13+ target |
| Active audio process discovery | CoreAudio HAL process objects | Public process enumeration exists, but not public per-process gain |
| Master volume | CoreAudio default output device volume | Depends on output device exposing writable volume |
| Launch at login | `SMAppService` | macOS 13+ |
| Spotify/Music/Chrome controls | AppleScript / Apple Events | Requires user automation permission |
| Edge/Brave/Vivaldi/Opera/Safari controls | AppleScript / JavaScript from Apple Events | Limited to reachable web media elements |
| Zoom, Firefox, games, Discord, most Electron apps | CoreAudio discovery only | Shown read-only without a virtual audio device or private API |

## Testing Before a Release

GitHub Actions validates the source on the current `macos-latest` runner. That is a useful guardrail, but it is not a substitute for manually testing older macOS versions before claiming a polished binary release.

For a GitHub release, test at least:

- Fresh clone and build in Xcode
- First launch permission prompts
- Menu bar icon appears
- Master volume changes the current output device, if the device supports software volume
- Spotify volume, if Spotify is installed
- Music volume, if Music is installed
- Chrome tab media after enabling JavaScript from Apple Events
- Read-only behavior for unsupported apps
