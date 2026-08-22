# BrewPulse beta guide

## Supported setup

BrewPulse 0.1.0 requires:

- macOS 14 Sonoma or newer
- an Apple Silicon or Intel Mac
- the current stable Homebrew release installed in `/opt/homebrew/bin/brew` or `/usr/local/bin/brew`

The beta is verified against Homebrew 6.0.18. BrewPulse relies on Homebrew's structured JSON output, so older Homebrew installations may return data the app cannot read. Update Homebrew before reporting a parsing problem.

## Install

1. Download `BrewPulse-0.1.0-macos.zip` from the BrewPulse GitHub release.
2. Open the ZIP and move `BrewPulse.app` to Applications.
3. Open BrewPulse from Applications. The app adds a mug to the menu bar.
4. If Homebrew is missing, follow the link in BrewPulse to the official Homebrew installation instructions, then refresh.

The public beta package must be signed with a Developer ID certificate and notarized by Apple. Do not redistribute an artifact whose filename contains `unsigned` or `unnotarized`.

## Remove

1. Turn off "Launch BrewPulse at login" in BrewPulse Settings.
2. Quit BrewPulse from its menu.
3. Move `BrewPulse.app` from Applications to Trash.

BrewPulse does not install a privileged helper, background daemon, browser extension, or kernel extension. Removing the app removes BrewPulse. Homebrew and packages managed by Homebrew are left alone.

## Updates

The first beta does not update itself. New versions are announced on the BrewPulse website and published through GitHub Releases. Download the newer ZIP and replace the existing app in Applications.

## Known limitations

- BrewPulse works on one package at a time. It does not include Update All or scheduling.
- Cask operations may open another installer or ask macOS for administrator approval.
- Cancelling asks the entire Homebrew process group to stop, but Homebrew or an external installer may take a few seconds to exit.
- A failed refresh keeps the last complete package snapshot and labels it with its original time.
- The beta has no crash reporting or analytics. Include copied Homebrew output when filing a reproducible issue.

See [SUPPORT.md](SUPPORT.md) for help and [PRIVACY.md](PRIVACY.md) for the data policy.
