# Changelog

## 0.2.3 - 2026-08-24

### Added

- Anonymous product analytics now measure first-observed installations, activation, engagement, package-action conversion, retention, and operation reliability through TelemetryDeck.
- Settings includes a Privacy control for turning anonymous usage statistics on or off.
- The website records installer selection and download intent through Vercel Analytics.

### Changed

- Published builds verify that the production TelemetryDeck application identifier is embedded in the packaged app.
- Privacy and release documentation now describe the analytics event contract and investor-facing metric definitions.

### Known limitations

- This release is not signed with an Apple Developer ID and is not notarized. macOS still requires the user to allow its first launch in Privacy & Security.
- Users on 0.1.0 Beta 3 or the affected 0.2.0 build must install 0.2.3 manually. Versions 0.2.1 and 0.2.2 can update to this release from inside BrewPulse.
- Scheduling and background Homebrew update notifications are not included.
- Cask installers may require interaction in another window or administrator approval.

## 0.2.2 - 2026-08-24

### Changed

- Refresh failures and package-operation details now share one selectable, scrollable output view, which keeps very large Homebrew logs responsive.
- Launch-at-login settings now use direct state bindings and clear failed registration alerts through the same presentation state used by the settings window.

### Known limitations

- This release is not signed with an Apple Developer ID and is not notarized. macOS still requires the user to allow its first launch in Privacy & Security.
- Users on 0.1.0 Beta 3 or the affected 0.2.0 build must install 0.2.2 manually. Version 0.2.1 can update to this release from inside BrewPulse.
- Scheduling and background Homebrew update notifications are not included.
- Cask installers may require interaction in another window or administrator approval.

## 0.2.1 - 2026-08-24

### Fixed

- Unsigned release apps now receive a complete ad-hoc bundle signature after Sparkle is embedded, so macOS no longer reports a verified download as damaged.
- The release process now checks the full signature and resource seal in both the archive and the finished DMG before publishing any artifact.

### Known limitations

- This release is not signed with an Apple Developer ID and is not notarized. macOS still requires the user to allow its first launch in Privacy & Security.
- Anyone who downloaded the affected 0.2.0 installer must replace it with 0.2.1 manually because the damaged app cannot run its updater.

## 0.2.0 - 2026-08-24

### Added

- BrewPulse checks for app updates when it opens and at least once per day, then asks before downloading or installing anything.
- Settings includes a manual "Check for Updates…" action and shows the installed BrewPulse version.
- Update archives and the appcast feed are signed with a dedicated EdDSA key. The release process produces a universal update archive for Apple Silicon and Intel Macs.
- Disk images now open as a compact BrewPulse-branded install window with a clear drag-to-Applications layout.

### Known limitations

- This release is unsigned and not notarized. macOS blocks its first launch until the user explicitly allows it in Privacy & Security settings.
- Users on 0.1.0 Beta 3 must install 0.2.0 manually once. BrewPulse can offer later releases from inside the app.
- Scheduling and background Homebrew update notifications are not included.
- Cask installers may require interaction in another window or administrator approval.
- Intel packaging is verified, but hands-on Intel runtime testing and the full keyboard, VoiceOver, and larger-text passes are not complete.

## 0.1.0 beta 3 - 2026-08-23

### Added

- A new Overview screen shows the installed package total, Homebrew version, update status, and last refresh time without exposing the full inventory by default.
- The Updates screen lists only actionable updates and supports reviewing one update or all available updates before anything runs.
- Separate Apple Silicon and Intel DMG installers include an Applications shortcut and individual SHA-256 checksums.

### Changed

- Replaced the previous interface and branding with the new BrewPulse mug, compact section switcher, clearer status treatment, and footer refresh indicator.
- The package-action review window now closes when no action is selected.
- The menu bar shows only the correctly sized mug. Update counts remain inside the app.

### Known limitations

- This preview is unsigned and not notarized. macOS blocks its first launch until the user explicitly allows it in Privacy & Security settings.
- Scheduling, background notifications, and automatic app updates are not included.
- Cask installers may require interaction in another window or administrator approval.
- Intel packaging is verified, but hands-on Intel runtime testing and the full keyboard, VoiceOver, and larger-text passes are not complete.

## 0.1.0 beta 2 - 2026-08-22

### Fixed

- Package updates and uninstalls can now prepare valid Homebrew commands in optimized Release builds.
- Release validation now runs the command-builder regression suite with optimization enabled.

### Verified

- Complete `bun` formula and `font-caskaydia-cove-nerd-font` cask updates succeeded through BrewPulse, including command review, preserved output, exit status, and the follow-up inventory refresh.

### Known limitations

- This preview is unsigned and not notarized. macOS blocks its first launch until the user explicitly allows it in Privacy & Security settings.
- No Update All, scheduling, background notifications, or automatic app updater.
- Cask installers may require interaction in another window or administrator approval.
- Intel runtime verification, installer-driven cask testing, uninstall testing, and the full accessibility pass are not complete.

## 0.1.0 beta 1 - 2026-08-22

### Included

- Native menu-bar inventory for Homebrew formulae and casks.
- Installed and available versions with per-package update status.
- Exact command review before individual updates or standard uninstalls.
- Cancellation that stops the Homebrew process group and preserves partial output.
- Recoverable missing-Homebrew, timeout, command, connectivity, and parsing failures.
- Retained last-known-good inventory after a failed refresh.
- Launch-at-login setting.

### Known limitations

- This preview is unsigned and not notarized. macOS blocks its first launch until the user explicitly allows it in Privacy & Security settings.
- No Update All, scheduling, background notifications, or automatic app updater.
- Cask installers may require interaction in another window or administrator approval.
- Intel runtime verification, real-package testing, and the full accessibility pass are not complete.
