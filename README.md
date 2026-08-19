<div align="center">

# 🍺 BrewPulse

### Homebrew updates at a glance.

A native macOS menu-bar companion for people who use Homebrew but do not want to live in Terminal.

[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-SwiftUI-orange?logo=swift&logoColor=white)](https://www.swift.org/)
[![Homebrew](https://img.shields.io/badge/Homebrew-Apple%20Silicon%20%7C%20Intel-FBB040?logo=homebrew&logoColor=black)](https://brew.sh/)
[![License: MPL 2.0](https://img.shields.io/badge/License-MPL%202.0-blue)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Beta%20Prep-purple)](TODO.md)

</div>

---

## What is BrewPulse?

Homebrew is excellent, but package maintenance is easy to forget and routine checks still tend to pull you back into Terminal.

BrewPulse brings that workflow into a focused native macOS interface. It shows what is installed, what is outdated, what command will run, and what Homebrew actually returned — without trying to hide or replace Homebrew itself.

The goal is simple: **make Homebrew maintenance easier to remember, easier to understand, and safer to perform.**

## ✨ What BrewPulse can do today

- Detect Homebrew on both Apple Silicon and Intel Macs.
- Show installed formulae and casks with their versions.
- Detect outdated packages and show available versions.
- Display the number of available updates from the menu bar.
- Refresh Homebrew inventory manually.
- Preview the exact Homebrew command before anything runs.
- Require explicit confirmation before package updates or removals.
- Update individual formulae and casks safely.
- Uninstall individual packages with a separate destructive confirmation flow.
- Preserve Homebrew stdout and stderr for troubleshooting and transparency.
- Handle running, completed, failed, interrupted, and cancelled operations.
- Keep formulae, casks, and status information organized in a native SwiftUI experience.

BrewPulse is currently in **beta-preparation / polish**, not a finished public release. See the [roadmap](TODO.md) for current progress.

## 🧭 Product philosophy

BrewPulse is built around five principles:

**Native** — feel like a real macOS app, not a web page wrapped in a window.  
**Simple** — make common Homebrew maintenance obvious and approachable.  
**Transparent** — show users exactly what BrewPulse is asking Homebrew to do.  
**Safe** — require clear user intent before changing installed software.  
**Lightweight** — stay out of the way when there is nothing to do.

## 🆓 Free and open-source core

This repository is the open-source BrewPulse Free application and shared Homebrew core.

BrewPulse Free is intended to remain genuinely useful on its own. Paid BrewPulse Pro features are planned around convenience and automation — things such as scheduled checks, notifications, bulk updates, history, and advanced policies — rather than locking basic Homebrew information behind a paywall.

Commercial Pro modules, cloud services, and future organization-management infrastructure are intentionally maintained separately from this public repository.

## 🔐 Trust and safety

BrewPulse interacts with software installed on your Mac, so transparency matters.

The open-source client lets anyone inspect how BrewPulse:

- discovers Homebrew,
- reads package inventory,
- constructs commands,
- validates package names,
- executes approved actions,
- handles cancellation and failures,
- and preserves Homebrew's original output.

BrewPulse does not aim to become a generic remote shell or hide package-manager behavior behind opaque actions.

## 🖥️ Requirements

- macOS 14 Sonoma or newer
- Homebrew installed locally
- Apple Silicon or Intel Mac

## 🛠️ Development

The native application lives under `macOS/` and is built with Swift and SwiftUI.

```text
BrewPulse/
├── macOS/       Native macOS application
├── tests/       Test support and fixtures
├── docs/        Public project documentation
├── TODO.md      Roadmap and implementation status
├── LICENSE      Mozilla Public License 2.0
└── NOTICE       Copyright and branding notice
```

Open `macOS/BrewPulse.xcodeproj` in Xcode and use the `BrewPulse` scheme to build the app locally.

## 🤝 Contributing

Contributions that improve the open-source BrewPulse core are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

If you discover a security issue, please follow [SECURITY.md](SECURITY.md) instead of filing a public issue.

## 🗺️ Roadmap

The current roadmap is tracked in [TODO.md](TODO.md).

The near-term focus is polishing BrewPulse Free, improving accessibility and failure states, expanding testing, and preparing a properly signed and notarized public beta before building the commercial Pro layer.

## 📄 License

BrewPulse's open-source source code is licensed under the [Mozilla Public License 2.0](LICENSE).

Copyright © 2026 Christopher Rodriguez.

The BrewPulse name, logo, branding, and other project identifiers are not granted for unrestricted use by the MPL-2.0. See [NOTICE](NOTICE) for details.
