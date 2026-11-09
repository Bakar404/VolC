# Release Guide

This project can be distributed in two ways:

1. Source-first: users clone the repo and run it in Xcode.
2. App bundle: the release workflow automatically publishes an ad-hoc signed `VolC-adhoc.zip` under GitHub Releases. A maintainer can optionally upload a Developer ID signed and notarized `VolC.zip` separately.

For semi-technical users, source-first is acceptable. For non-technical users, a notarized app bundle is much better.

For users who want to build a personal copy and move it to **Applications**, see [LOCAL_APP_BUILD.md](LOCAL_APP_BUILD.md).

## Source-First Release

1. Make sure `main` builds locally.
2. Run local checks:

   ```zsh
   swiftc -typecheck -target arm64-apple-macos13.0 -sdk "$(xcrun --sdk macosx --show-sdk-path)" $(find VolC -name '*.swift')
   plutil -lint VolC.xcodeproj/project.pbxproj VolC/Info.plist VolC/VolC.entitlements
   ```

3. Update `README.md` and `docs/COMPATIBILITY.md` if support changed.
4. Create and push a tag matching `v*`, such as `v0.1.0`. The [release workflow](../.github/workflows/release.yml) builds the Release app with ad-hoc signing, verifies its signature, and automatically attaches `VolC-adhoc.zip` to the GitHub release.
5. In the release notes, include:
   - tested macOS version
   - tested Xcode version
   - supported apps
   - known limitations

## App Bundle Release

The automated `VolC-adhoc.zip` is ad-hoc signed, not Developer ID signed or notarized. Gatekeeper may block it on first open; the [README installation steps](../README.md#install-from-releases) explain **Open Anyway** and the quarantine-removal fallback.

### Optional Developer ID Signing and Notarization

This is a manual step requiring a Developer ID certificate. It does not replace the automated ad-hoc asset.

Recommended flow:

1. In Xcode, set a Developer ID signing team for the `VolC` target.
2. Select **Product > Archive**.
3. In Organizer, export a Developer ID signed app.
4. Notarize the exported app with Apple.
5. Staple notarization to the app.
6. Zip the `.app` as `VolC.zip` and upload it to the same GitHub release. Keep `VolC-adhoc.zip` as the separate automated asset so workflow reruns cannot overwrite the Developer ID signed build.

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
