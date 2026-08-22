# Changelog

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
