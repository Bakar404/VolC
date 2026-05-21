# Local App Build

This guide is for people who want to build VolC from source and run it like a normal Mac app without keeping Xcode open.

You do not need a paid Apple Developer account for a personal local build. A free Apple ID or local signing setup is enough for running the app on your own Mac.

## Requirements

- macOS 13 Ventura or newer
- A compatible Xcode for your macOS version
- The VolC source code cloned from GitHub

If the Mac App Store only offers an Xcode version that requires a newer macOS release, use Apple's developer downloads page instead:

https://developer.apple.com/download/all/

## Build Once, Run Without Xcode

1. Clone the repo:

   ```zsh
   git clone https://github.com/Bakar404/VolC.git
   cd VolC
   ```

2. Open the project:

   ```zsh
   open -a Xcode VolC.xcodeproj
   ```

3. In Xcode, select the `VolC` scheme and `My Mac`.

4. If Xcode asks about signing, select your Apple ID or **Personal Team** under **Signing & Capabilities**.

5. If signing still fails because the bundle identifier is already taken, change the local bundle identifier to something unique, such as:

   ```text
   com.yourname.VolC
   ```

   This is only needed for your local build. You do not need to commit that personal bundle identifier change.

6. Choose **Product > Build For > Running**.

   Use **Running** for a normal app build. **Testing** and **Profiling** are for developer workflows.

7. In the Project navigator, expand **Products**.

8. Right-click **VolC.app** and choose **Show in Finder**.

9. Stop the Xcode-launched copy if it is currently running.

   In Xcode, press the stop button or use:

   ```text
   Cmd + .
   ```

10. Move the built **VolC.app** into your **Applications** folder.

11. Open VolC from **Applications**.

VolC is a menu bar app, so it does not appear in the Dock. Look for the speaker icon in the menu bar near Wi-Fi, battery, and the clock.

## First Launch

On first launch, macOS may ask for Automation permission when VolC controls apps such as Spotify, Music, Chrome, Edge, Brave, Vivaldi, Opera, or Safari.

Allow this permission if you want VolC to control supported apps. If you deny it by accident, enable it later in:

```text
System Settings > Privacy & Security > Automation
```

VolC does not request microphone access, capture audio, install a virtual audio device, or install a kernel extension.

## Start at Login

After launching the app from **Applications**, open the VolC menu bar popover and turn on **Launch at login**.

Launch at login works best when the app lives in **Applications** instead of the Xcode build folder.

If you previously enabled **Launch at login** from an Xcode build folder and then moved VolC to **Applications**, macOS may keep more than one login entry. Quit all running copies, remove duplicate VolC entries in:

```text
System Settings > General > Login Items & Extensions
```

Then open the **Applications** copy and toggle **Launch at login** off and back on.

## Updating Your Local App

1. Pull the latest source:

   ```zsh
   git pull --ff-only
   ```

2. Open the project in Xcode.
3. Choose **Product > Build For > Running**.
4. Quit the old running copy of VolC.
5. Replace the old app in **Applications** with the newly built **VolC.app**.
6. Open VolC again from **Applications**.

## If the Icon Does Not Update

macOS sometimes caches app icons.

Try these in order:

1. Quit VolC.
2. Delete the old **VolC.app** from **Applications**.
3. Copy the newly built **VolC.app** into **Applications** again.
4. Open the app.

If Finder still shows the old icon, right-click the app, choose **Get Info**, and confirm the icon at the top left. Finder may take a little while to refresh cached icons.

## Sharing Builds With Others

A local build is best for your own machine. If you want to share a downloadable `.app` with other people, prefer a signed and notarized release build. See [RELEASE.md](RELEASE.md).
