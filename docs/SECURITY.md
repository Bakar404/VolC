# Security Policy

## Reporting a Vulnerability

Please do not open public GitHub issues for security problems.

Use GitHub private vulnerability reporting for this repository. If private reporting is unavailable, contact the maintainer privately before publishing details.

Security-sensitive areas include:

- AppleScript automation
- Apple Events permissions
- macOS entitlements
- release binaries
- signing and notarization
- any code that could access audio input, microphone APIs, private APIs, or hidden audio processing

## Supported Versions

VolC is currently pre-1.0. Security fixes should target the latest commit on `main` unless a release branch is created later.

## Project Safety Rules

VolC should not use:

- private CoreAudio APIs
- kernel extensions
- virtual audio devices unless the project direction intentionally changes
- microphone or audio input capture
- hidden background audio processing
- unnecessary entitlements

Every new entitlement must be justified in the pull request.

Every AppleScript change should be reviewed carefully because Apple Events can affect other apps.

Every new dependency should have a strong reason and should be documented in the pull request.

## Release Binary Safety

Public binary releases should be signed and notarized when possible. Release notes should include:

- macOS versions tested
- Xcode version used
- supported app controls
- known limitations
- SHA256 checksums for downloadable archives

Unsigned builds should be described as development builds, not stable releases.

