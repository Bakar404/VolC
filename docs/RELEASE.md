# Release Guide

This project can be distributed in two ways:

1. Source-first: users clone the repo and run it in Xcode.
2. App bundle: maintainer publishes a signed and preferably notarized `.zip` under GitHub Releases.

For semi-technical users, source-first is acceptable. For non-technical users, a notarized app bundle is much better.

## Source-First Release

1. Make sure `main` builds locally.
2. Run local checks:

   ```zsh
   swiftc -typecheck -target arm64-apple-macos13.0 -sdk "$(xcrun --sdk macosx --show-sdk-path)" $(find VolC -name '*.swift')
   plutil -lint VolC.xcodeproj/project.pbxproj VolC/Info.plist VolC/VolC.entitlements
   ```

3. Update `README.md` and `docs/COMPATIBILITY.md` if support changed.
4. Create a GitHub release tag such as `v0.1.0`.
5. In the release notes, include:
   - tested macOS version
   - tested Xcode version
   - supported apps
   - known limitations

## App Bundle Release

Use this only if you have a Developer ID certificate. Unsigned apps work poorly for public distribution because Gatekeeper will warn users.

Recommended flow:

1. In Xcode, set a Developer ID signing team for the `VolC` target.
2. Select **Product > Archive**.
3. In Organizer, export a Developer ID signed app.
4. Notarize the exported app with Apple.
5. Staple notarization to the app.
6. Zip the `.app` and upload it to GitHub Releases.

Example release note text:

```text
VolC v0.1.0

Tested on macOS 15.7.1.
Requires macOS 13 or newer.

Supported app controls:
- Spotify
- Music
- Google Chrome tabs with JavaScript from Apple Events enabled

Known limitation:
macOS public CoreAudio can enumerate app audio processes but does not provide public writable per-app gain. Unsupported apps appear as read-only.
```

## Versioning

Use simple semantic versions:

- `0.x`: early public builds
- `1.0`: stable source build instructions, stable UI, clear compatibility docs, and at least one signed/notarized release if distributing binaries

