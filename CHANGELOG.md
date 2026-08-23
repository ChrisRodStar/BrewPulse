# Changelog

## 0.1.0 beta 2 - 2026-08-22

### Fixed

- Package updates and uninstalls can now prepare valid Homebrew commands in optimized Release builds.
- Release validation now runs the command-builder regression suite with optimization enabled.

### Verified

- A complete `bun` formula update succeeded through BrewPulse, including command review, preserved output, exit status, and the follow-up inventory refresh.

### Known limitations

- This preview is unsigned and not notarized. macOS blocks its first launch until the user explicitly allows it in Privacy & Security settings.
- No Update All, scheduling, background notifications, or automatic app updater.
- Cask installers may require interaction in another window or administrator approval.
- Intel runtime verification, cask testing, uninstall testing, and the full accessibility pass are not complete.
- The beta does not collect crash reports or analytics.

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
- The beta does not collect crash reports or analytics.
