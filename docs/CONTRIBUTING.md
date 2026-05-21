# Contributing

Thanks for helping make VolC better.

## Good First Contributions

- Add AppleScript support for another app that exposes a scriptable volume API.
- Improve compatibility notes for a macOS/Xcode combination you tested.
- Improve UI polish while keeping the app small and native-feeling.
- Add focused bug fixes around CoreAudio process discovery.

## Local Checks

Before opening a pull request, run:

```zsh
swiftc -typecheck -target arm64-apple-macos13.0 -sdk "$(xcrun --sdk macosx --show-sdk-path)" $(find VolC -name '*.swift')
plutil -lint VolC.xcodeproj/project.pbxproj VolC/Info.plist VolC/VolC.entitlements
```

Also run the app from Xcode and confirm the menu bar icon appears.

## Adding App Support

Per-app system volume is not available through public CoreAudio HAL. New app support should therefore be app-specific and honest about what it controls.

Unsupported apps must remain read-only unless they expose a public/scriptable volume API.

When adding an app:

1. Add a bundle ID mapping in `AppleScriptVolumeBackend.swift`.
2. Keep the script scoped to volume only.
3. Do not use private APIs.
4. Do not add virtual audio device dependencies.
5. Update [README.md](../README.md) with limitations.

See [APP_SUPPORT_POLICY.md](APP_SUPPORT_POLICY.md) for the full app support policy.

## Safety Rules

Do not add:

- private CoreAudio APIs
- kernel extensions
- virtual audio devices unless the project direction intentionally changes
- microphone/input capture
- hidden audio processing
- unnecessary entitlements

Review every AppleScript change carefully.

Any new entitlement must be justified in the pull request.

Any new dependency should require a strong reason and should be documented in the pull request.

## Pull Requests

Please include:

- macOS version tested
- Xcode version tested
- app/audio source tested
- screenshots for UI changes
- known limitations or regressions

Use the pull request checklist and keep documentation updated when behavior or support changes.

## Community and Security

Please follow [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

Please report security issues through GitHub private vulnerability reporting instead of public issues. See [SECURITY.md](SECURITY.md).
