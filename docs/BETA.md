# BrewPulse beta guide

## Supported setup

BrewPulse 0.2.4 requires:

- macOS 14 Sonoma or newer
- an Apple Silicon or Intel Mac
- the current stable Homebrew release installed in `/opt/homebrew/bin/brew` or `/usr/local/bin/brew`

The beta is verified against Homebrew 6.0.18. BrewPulse relies on Homebrew's structured JSON output, so older Homebrew installations may return data the app cannot read. Update Homebrew before reporting a parsing problem.

## Install

The 0.2.4 download is unsigned by Apple and has not passed Apple's notarization service. macOS will block its first launch because it cannot verify the developer or check the app for known malicious software.

Only download BrewPulse from the [official GitHub release](https://github.com/ChrisRodStar/BrewPulse/releases/tag/v0.2.4). If you do not want to override Gatekeeper for an unsigned app, build from source.

1. Download the Apple Silicon or Intel DMG for your Mac and its matching `.sha256` file from the release.
2. In Terminal, change to the download directory and run the matching command. Use `shasum -a 256 -c BrewPulse-0.2.4-macos-arm64-unsigned.dmg.sha256` for Apple Silicon or `shasum -a 256 -c BrewPulse-0.2.4-macos-x64-unsigned.dmg.sha256` for Intel. Continue only if it reports `OK`.
3. Open the verified DMG and drag `BrewPulse.app` to the Applications shortcut.
4. Try to open BrewPulse from Applications. macOS will block it.
5. Open System Settings, choose Privacy & Security, scroll to Security, and select Open Anyway for BrewPulse. Confirm the warning and authenticate if macOS asks.
6. Open BrewPulse. Its mug appears in the menu bar.
7. If Homebrew is missing, follow the link in BrewPulse to the official Homebrew installation instructions, then refresh.

Apple documents this override in [Safely open apps on your Mac](https://support.apple.com/en-us/102445). Never disable Gatekeeper globally or remove quarantine attributes to install BrewPulse.

The checksum confirms that the downloaded DMG matches the official GitHub asset. It does not provide a Developer ID identity or replace Apple's notarization and malware checks.

## Remove

1. Turn off "Launch BrewPulse at login" in BrewPulse Settings.
2. Quit BrewPulse from its menu.
3. Move `BrewPulse.app` from Applications to Trash.

BrewPulse does not install a privileged helper, background daemon, browser extension, or kernel extension. Removing the app removes BrewPulse. Homebrew and packages managed by Homebrew are left alone.

## Updates

Versions 0.2.1 through 0.2.3 can update to 0.2.4 from inside BrewPulse. Users on 0.1.0 Beta 3 must install it manually because that preview did not include the updater. Users on the affected 0.2.0 build must also install it manually because the damaged app cannot launch its updater. BrewPulse checks for new versions when it opens and at least once per day, shows the release notes, and waits for approval before downloading or installing an update.

Apple Developer ID signing and Sparkle update signing are separate. The app has only an ad-hoc integrity signature, but BrewPulse verifies update downloads with its embedded Sparkle EdDSA public key before installing them.

## Known limitations

- The 0.2.4 installers are ad-hoc signed for bundle integrity, but they are not signed with an Apple Developer ID or notarized. Apple Developer ID signing is deferred.
- BrewPulse can review one update or all currently actionable updates. It does not include scheduling.
- Cask operations may open another installer or ask macOS for administrator approval.
- Cancelling an active action asks the entire Homebrew process group to stop, but Homebrew or an external installer may take a few seconds to exit.
- A failed refresh keeps the last complete package snapshot and labels it with its original time.
- Include copied Homebrew output when filing a reproducible issue.

See [SUPPORT.md](SUPPORT.md) for help and [PRIVACY.md](PRIVACY.md) for the data policy.
