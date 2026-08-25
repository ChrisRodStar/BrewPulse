<div align="center">

# BrewPulse

**Homebrew updates at a glance.**

A small native macOS menu bar app for checking and updating Homebrew packages without living in Terminal.

[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![SwiftUI](https://img.shields.io/badge/Swift-SwiftUI-orange?logo=swift&logoColor=white)](https://www.swift.org/)
[![Homebrew](https://img.shields.io/badge/Homebrew-Apple%20Silicon%20%7C%20Intel-FBB040?logo=homebrew&logoColor=black)](https://brew.sh/)
[![MPL 2.0](https://img.shields.io/badge/License-MPL%202.0-blue)](LICENSE)

</div>

## Why I made BrewPulse

I use Homebrew, but I am bad at remembering to check what needs updating. I also prefer a clean Mac app over opening Terminal for routine maintenance.

BrewPulse started as the tool I wanted for myself: click the menu bar, see what needs attention, update it, and move on. Homebrew still does the actual package management. BrewPulse gives it a native interface and keeps the commands visible instead of hiding what is happening.

## What works right now

BrewPulse can already:

- Find Homebrew on Apple Silicon and Intel Macs.
- Show the installed package total and Homebrew version at a glance.
- Check for outdated formulae and casks and list only actionable updates.
- Preview the exact Homebrew command before it runs.
- Require confirmation before any update.
- Update one package or review all available updates together.
- Keep Homebrew's stdout and stderr available when something goes wrong.
- Handle running, completed, failed, interrupted, and cancelled operations.

The current release is [BrewPulse 0.2.4](https://github.com/ChrisRodStar/BrewPulse/releases/tag/v0.2.4). It is unsigned by Apple and not notarized, so macOS will block it on first launch. Read the [beta guide](docs/BETA.md) before installing it. Apple Developer ID signing and notarization remain deferred; the current checklist is in [TODO.md](TODO.md).

Version 0.2.4 sends anonymous product analytics directly to BrewPulse Cloud instead of TelemetryDeck. The in-app opt-out remains available in Settings. Versions 0.2.1 through 0.2.3 can update to this release from inside BrewPulse. Users on 0.1.0 Beta 3 or the affected 0.2.0 build must install it manually because those versions cannot complete the update.

## Safety and transparency

A package manager UI should not make it harder to understand what changed on your computer.

Before BrewPulse updates a package, it shows the command and waits for confirmation. Homebrew's original output is kept for troubleshooting, and the app does not try to turn package management into an opaque one-click process.

The client is open source partly for this reason. You can inspect how BrewPulse finds Homebrew, builds commands, validates package names, runs approved actions, and handles failures.

## Free and Pro

This repository contains BrewPulse Free and the shared open-source Homebrew core.

Free is meant to be useful on its own. The planned Pro version is mostly about saving time: scheduled checks, notifications, history, and more control over automation. Those commercial pieces are kept outside this public repository.

I want someone to be able to use the free app without feeling like the useful part was intentionally removed just to force an upgrade.

## Requirements

- macOS 14 Sonoma or newer
- Homebrew installed locally
- Apple Silicon or Intel Mac

## Download 0.2.4

This build has an ad-hoc signature for bundle integrity, but it is not signed with an Apple Developer ID or notarized. Gatekeeper will block the first launch because macOS cannot verify the developer or check the app through Apple's notarization service. The [beta guide](docs/BETA.md) explains the warning, checksum verification, installation, and removal steps. If you do not want to override Gatekeeper for an unsigned app, build from source.

- [Download for Apple Silicon](https://github.com/ChrisRodStar/BrewPulse/releases/download/v0.2.4/BrewPulse-0.2.4-macos-arm64-unsigned.dmg)
- [Apple Silicon SHA-256 checksum](https://github.com/ChrisRodStar/BrewPulse/releases/download/v0.2.4/BrewPulse-0.2.4-macos-arm64-unsigned.dmg.sha256)
- [Download for Intel](https://github.com/ChrisRodStar/BrewPulse/releases/download/v0.2.4/BrewPulse-0.2.4-macos-x64-unsigned.dmg)
- [Intel SHA-256 checksum](https://github.com/ChrisRodStar/BrewPulse/releases/download/v0.2.4/BrewPulse-0.2.4-macos-x64-unsigned.dmg.sha256)
- [Read the complete release notes](https://github.com/ChrisRodStar/BrewPulse/releases/tag/v0.2.4)

## Building from source

The macOS app lives in `macOS/` and is written in Swift and SwiftUI.

Open `macOS/BrewPulse.xcodeproj` in Xcode and build the `BrewPulse` scheme.

For a command-line build that does not require the maintainer's signing identity:

```text
./scripts/build-local.sh
```

```text
BrewPulse/
├── macOS/
│   ├── BrewPulse/       Native macOS app
│   └── BrewPulseTests/  Tests, support types, and fixtures
├── docs/                Public project documentation
├── TODO.md              Roadmap and implementation status
├── LICENSE              Mozilla Public License 2.0
└── NOTICE               Copyright and branding notice
```

## Roadmap

[TODO.md](TODO.md) is the working roadmap.

Right now the focus is finishing the free app properly before spending time on payments or Pro-only automation. The unsigned 0.2.4 release lets early testers use the BrewPulse Cloud analytics and in-app updater while accessibility and real-package testing continue. Developer ID signing and notarization are deferred.

Supporting product and release documentation lives in [`docs/`](docs/README.md):

- [Design system](docs/DESIGN_SYSTEM.md)
- [Beta guide](docs/BETA.md)
- [Privacy](docs/PRIVACY.md)
- [Product analytics](docs/ANALYTICS.md)
- [Support](docs/SUPPORT.md)
- [Release process](docs/RELEASING.md)
- [Release notes](CHANGELOG.md)

## Contributing

Contributions to the open-source core are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request so you know how the repo is organized and what checks are expected.

Security problems should be reported through [SECURITY.md](SECURITY.md), not a public issue.

## License

BrewPulse source code in this repository is licensed under the [Mozilla Public License 2.0](LICENSE).

Copyright © 2026 Christopher Rodriguez.

The BrewPulse name, logo, branding, and other project identifiers are not granted for unrestricted use by the MPL 2.0. See [NOTICE](NOTICE) for details.
