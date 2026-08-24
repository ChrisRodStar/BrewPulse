# BrewPulse beta guide

## Supported setup

BrewPulse 0.1.0 requires:

- macOS 14 Sonoma or newer
- an Apple Silicon or Intel Mac
- the current stable Homebrew release installed in `/opt/homebrew/bin/brew` or `/usr/local/bin/brew`

The beta is verified against Homebrew 6.0.18. BrewPulse relies on Homebrew's structured JSON output, so older Homebrew installations may return data the app cannot read. Update Homebrew before reporting a parsing problem.

## Install

The 0.1.0 Beta 3 download is an unsigned preview. It has no Apple Developer ID signature and has not passed Apple's notarization service. macOS will block its first launch because it cannot verify the developer or check the app for known malicious software.

Only download the preview from the [official GitHub release](https://github.com/ChrisRodStar/BrewPulse/releases/tag/v0.1.0-beta.3). If you do not want to override Gatekeeper for an unsigned app, build from source or wait for the signed beta.

1. Download the Apple Silicon or Intel DMG for your Mac and its matching `.sha256` file from the release.
2. In Terminal, change to the download directory and run the matching command. Use `shasum -a 256 -c BrewPulse-0.1.0-macos-arm64-unsigned.dmg.sha256` for Apple Silicon or `shasum -a 256 -c BrewPulse-0.1.0-macos-x64-unsigned.dmg.sha256` for Intel. Continue only if it reports `OK`.
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

The beta does not update itself. New versions are announced on the BrewPulse website and published through GitHub Releases. Download the newer DMG for your Mac and replace the existing app in Applications.

## Known limitations

- The 0.1.0 Beta 3 installers are unsigned and not notarized. A later signed beta will replace them.
- BrewPulse can review one update or all currently actionable updates. It does not include scheduling.
- Cask operations may open another installer or ask macOS for administrator approval.
- Cancelling an active action asks the entire Homebrew process group to stop, but Homebrew or an external installer may take a few seconds to exit.
- A failed refresh keeps the last complete package snapshot and labels it with its original time.
- The beta has no crash reporting or analytics. Include copied Homebrew output when filing a reproducible issue.

See [SUPPORT.md](SUPPORT.md) for help and [PRIVACY.md](PRIVACY.md) for the data policy.
