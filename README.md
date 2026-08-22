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
- Show installed formulae and casks with their current versions.
- Check for outdated packages and show the available version.
- Put the number of available updates in the menu bar.
- Preview the exact Homebrew command before it runs.
- Require confirmation before an update or uninstall.
- Update or uninstall individual formulae and casks.
- Keep Homebrew's stdout and stderr available when something goes wrong.
- Handle running, completed, failed, interrupted, and cancelled operations.

An [unsigned 0.1.0 preview](https://github.com/ChrisRodStar/BrewPulse/releases/tag/v0.1.0-beta.1) is available for early testing. macOS will block it on first launch because it has no Apple Developer ID signature or notarization ticket. Read the [beta guide](docs/BETA.md) before installing it. Signing, notarization, and the hands-on beta matrix still gate the ordinary public beta. The current checklist is in [TODO.md](TODO.md).

## Safety and transparency

A package manager UI should not make it harder to understand what changed on your computer.

Before BrewPulse updates or removes a package, it shows the command and waits for confirmation. Homebrew's original output is kept for troubleshooting, and the app does not try to turn package management into an opaque one-click process.

The client is open source partly for this reason. You can inspect how BrewPulse finds Homebrew, builds commands, validates package names, runs approved actions, and handles failures.

## Free and Pro

This repository contains BrewPulse Free and the shared open-source Homebrew core.

Free is meant to be useful on its own. The planned Pro version is mostly about saving time: scheduled checks, notifications, Update All, history, and more control over automation. Those commercial pieces are kept outside this public repository.

I want someone to be able to use the free app without feeling like the useful part was intentionally removed just to force an upgrade.

## Requirements

- macOS 14 Sonoma or newer
- Homebrew installed locally
- Apple Silicon or Intel Mac

## Download the unsigned preview

This build is intentionally unsigned. macOS cannot verify its developer or check it through Apple's notarization service, so Gatekeeper will block the first launch. The [beta guide](docs/BETA.md) explains the warning, checksum verification, installation, and removal steps. If you do not want to override Gatekeeper for an unsigned app, build from source or wait for the signed beta.

- [Download `BrewPulse-0.1.0-macos-unsigned.zip`](https://github.com/ChrisRodStar/BrewPulse/releases/download/v0.1.0-beta.1/BrewPulse-0.1.0-macos-unsigned.zip)
- [Download the SHA-256 checksum](https://github.com/ChrisRodStar/BrewPulse/releases/download/v0.1.0-beta.1/BrewPulse-0.1.0-macos-unsigned.zip.sha256)
- [Read the complete release notes](https://github.com/ChrisRodStar/BrewPulse/releases/tag/v0.1.0-beta.1)

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

Right now the focus is finishing the free app properly before spending time on payments or Pro-only automation. The unsigned preview lets early testers try the current build, while accessibility, real-package testing, Developer ID signing, and notarization remain on the path to the ordinary public beta.

Beta installation, privacy, support, and release details live in [`docs/`](docs/):

- [Beta guide](docs/BETA.md)
- [Privacy](docs/PRIVACY.md)
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
