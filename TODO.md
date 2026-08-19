# 🍺 BrewPulse — Roadmap & Implementation Plan

> **⚡ The modern, lightweight macOS menu-bar companion for Homebrew.**  
> *Track outdated packages, preview atomic updates, and keep your development environment fast and secure.*

[![Platform: macOS 14+](https://img.shields.io/badge/macOS-14%2B%20(Sonoma%2FSequoia)-blue?logo=apple&style=flat-square)](https://apple.com)
[![Swift: 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift&style=flat-square)](https://swift.org)
[![Homebrew: Universal](https://img.shields.io/badge/Homebrew-Apple%20Silicon%20%7C%20Intel-FBB040?logo=homebrew&style=flat-square)](https://brew.sh)
[![Distribution: Direct](https://img.shields.io/badge/Distribution-Direct%20(Notarized)-brightgreen?style=flat-square)](https://developer.apple.com)
[![Phase: Active Beta Prep](https://img.shields.io/badge/Phase-Beta%20Readiness-purple?style=flat-square)](#-milestone-5-testing-and-beta-readiness)

---

### 📑 Reference & Strategy Documentation
* 📘 **Product Strategy & Architecture:** [`notes/ideas/Product.md`](notes/ideas/Product.md)
* 💰 **Monetization & Pricing Model:** [`notes/business/Monetization.md`](notes/business/Monetization.md)

---

## 📊 Milestone Execution Dashboard

| Milestone | Focus Scope | Progress | Status |
| :--- | :--- | :---: | :---: |
| [**M1: Homebrew Foundation**](#-milestone-1-homebrew-foundation) | CLI runner, safe process isolation & robust parsing | `12 / 12` | 🟢 **Completed** |
| [**M2: Outdated Detection**](#-milestone-2-outdated-package-detection) | Inventory sync, version diffing & menu bar badge | `10 / 10` | 🟢 **Completed** |
| [**M3: Safe Individual Updates**](#-milestone-3-safe-individual-updates) | Command previews, live output streaming & logs | `13 / 13` | 🟢 **Completed** |
| [**M4: BrewPulse Free Polish**](#-milestone-4-brewpulse-free-polish) | Settings scene, UI edge cases, A11y & animations | `5 / 13` | 🟡 **In Progress** |
| [**M5: Testing & Beta Readiness**](#-milestone-5-testing-and-beta-readiness) | macOS CI workflow, matrix test suite & notarization | `8 / 15` | 🟡 **In Progress** |
| [**M6: Monetization Validation**](#-milestone-6-monetization-validation) | Pricing page, feedback capture & conversion tracking | `0 / 7` | ⚪ **Planned** |
| [**M7: BrewPulse Pro**](#-milestone-7-brewpulse-pro) | Scheduled checks, notifications & bulk **Update All** | `0 / 13` | ⚪ **Planned** |

> **Overall Velocity:** **48 / 83 deliverables completed (58%)**

---

> [!IMPORTANT]
> ### 🧭 Approved Architectural Principles
> * **Free-Tier Integrity:** Build and thoroughly validate the complete free workflow before introducing payments or account walls.
> * **Pro Tier Boundaries:** Reserve **Update All** and background automation strictly for BrewPulse Pro.
> * **Direct Distribution:** Distribute directly as a hardened, Developer ID-signed, and Apple-notarized macOS app.
> * **Modern Baseline:** Target **macOS 14 (Sonoma)** as the minimum supported deployment target.
> * **Total User Agency:** Keep every software update and uninstall in BrewPulse Free explicitly user-initiated with full command transparency.

---

## 🧱 Milestone 1: Homebrew Foundation
> *Robust, non-blocking subprocess engine with Apple Silicon and Intel architecture compatibility.*

- [x] Introduce a testable Homebrew command-running abstraction.
- [x] Return structured command results containing:
  - [x] Executable and arguments
  - [x] Standard output
  - [x] Standard error
  - [x] Exit status
  - [x] Start time and duration
- [x] Read standard output and standard error safely without pipe deadlocks.
- [x] Prevent conflicting Homebrew commands from running simultaneously.
- [x] Support both Apple Silicon (`/opt/homebrew`) and Intel (`/usr/local`) Homebrew paths.
- [x] Preserve Homebrew's original output for transparency and troubleshooting.
- [x] Make package and command data models independently testable.
- [x] Add parsing fixtures and initial unit tests:
  - [x] Add focused command-runner tests.
  - [x] Add Homebrew parsing fixtures and tests.
- [x] Test installed-inventory orchestration and command failures.

---

## 🔍 Milestone 2: Outdated Package Detection
> *Accurate inventory tracking, version comparison, and glanceable menu bar metrics.*

- [x] Read Homebrew's structured outdated-package data.
- [x] Model installed and available versions separately.
- [x] Distinguish formulae from casks cleanly across the data pipeline.
- [x] Recognize pinned, ignored, or otherwise non-upgradable packages.
- [x] Merge installed inventory with update availability.
- [x] Display installed and available versions in the package list.
- [x] Visually distinguish current and outdated packages.
- [x] Show the number of available updates dynamically in the menu bar.
- [x] Preserve manual refresh with clear loading and failure states.
- [x] Show when the package information was last refreshed.

---

## ⚡ Milestone 3: Safe Individual Updates
> *Granular, transparent update execution with full stdout/stderr streaming and error handling.*

- [x] Add an **Update** action to each outdated package.
- [x] Build formula and cask update commands safely from structured arguments.
- [x] Show the exact command before asking for confirmation.
- [x] Require an explicit user confirmation before starting an update.
- [x] Show which package is currently updating in real time.
- [x] Disable conflicting actions while an update is running.
- [x] Display live or completed Homebrew output in a readable details view.
- [x] Provide a single-click way to copy command output to clipboard.
- [x] Handle successful updates clearly with responsive UI updates.
- [x] Preserve and explain Homebrew failures without hiding their original output.
- [x] Handle cancellation and interrupted commands safely.
- [x] Explain when administrator access (`sudo`) or external user interaction is required.
- [x] Refresh package inventory automatically after an update completes.

---

## ✨ Milestone 4: BrewPulse Free Polish
> *Refining the native macOS experience, settings, accessibility, and resilient edge-case handling.*

- [x] Add a native macOS **Settings** scene.
- [x] Add a launch-at-login preference (`SMAppService`).
- [x] Separate **Status**, **Casks**, and **Formulae** into distinct, tabbed navigation views.
- [x] Show the active Homebrew version and inventory summary on the Status tab.
- [x] Add safe individual package uninstall with exact-command review:
  - [x] Use standard typed formula and cask uninstall commands only.
  - [x] Require a separate destructive confirmation modal before removal.
  - [x] Preserve Homebrew output and refresh inventory after completion.
  - [x] Never add `--zap`, force, or dependency overrides implicitly.
- [ ] Refine the missing-Homebrew onboarding experience.
- [ ] Refine empty, loading, offline, and partial-failure states.
- [ ] Handle long package names and multi-line version strings gracefully.
- [ ] Add keyboard navigation and native macOS shortcuts (`⌘R`, `⌘,`, `Esc`).
- [ ] Verify VoiceOver labels, accessibility values, focus ordering, and disabled states.
- [ ] Ensure controls remain fully usable with Dynamic Type / larger accessibility text sizes.
- [ ] Add self-contained SwiftUI previews for all critical view states.
- [ ] Confirm background work remains ultra-lightweight when the menu popover is closed.

---

## 🧪 Milestone 5: Testing and Beta Readiness
> *Hardening CI validation, expanding test coverage matrix, and establishing notarized release packaging.*

- [x] Add macOS CI for pull requests that are ready for review.
- [x] Enforce CI-before-merge in the local and Codex project workflow:
  - [x] Block direct local pushes to `main` with a versioned Git pre-push hook.
  - [x] Require the current PR revision to pass `macOS Validation` before merge.
- [ ] Enable GitHub-hosted branch protection for `main`.
  - [ ] *Requires GitHub Pro while the repository remains private.*
- [x] Add unit tests for command construction:
  - [x] Add installed-inventory command coverage.
  - [x] Add formula and cask update command coverage.
- [x] Add unit tests for inventory and outdated-data parsing:
  - [x] Add installed-package list parsing coverage.
  - [x] Add structured outdated-data parsing coverage.
- [ ] Add unit tests for store state transitions.
- [x] Test missing and broken Homebrew installations.
- [x] Test Apple Silicon and Intel installation paths.
- [ ] Test formula and cask updates across varying network conditions.
- [x] Test pinned packages and packages with multiple installed versions.
- [ ] Test failed, interrupted, and long-running commands.
- [ ] Test package names and output containing unexpected / Unicode characters.
- [ ] Run full accessibility (VoiceOver) and keyboard-only QA sweeps.
- [ ] Verify memory, CPU, and battery footprint while idle in menu bar.
- [ ] Configure release signing and hardened runtime requirements.
- [ ] Notarize and package a free public beta for direct distribution.

---

## 📈 Milestone 6: Monetization Validation
> *Evaluating user demand, price sensitivity, and conversion funnels before building payment infrastructure.*

- [ ] Publish a clear **BrewPulse Free vs. BrewPulse Pro** comparison matrix.
- [ ] Present the **$14.99 lifetime early-adopter price** prominently on the website.
- [ ] Add a waitlist / purchase-interest flow without requiring a mandatory app account.
- [ ] Collect structured user feedback regarding scheduled checks, notifications, and bulk updates.
- [ ] Track beta downloads and weekly active usage with strict privacy preservation.
- [ ] Interview early users about automation features and willingness to pay.
- [ ] Review quantitative validation targets:
  - [ ] 🎯 **> 500** Total beta downloads
  - [ ] 🎯 **> 100** Weekly active users (WAU)
  - [ ] 🎯 **10–20** Users with explicit written intent to purchase
  - [ ] 🎯 Evidence supporting a **3–5%** paid conversion rate

---

## 💎 Milestone 7: BrewPulse Pro
> *Advanced automation, scheduling, and power-user tooling for developers.*

- [ ] Add a local entitlement interface before integrating a payment provider.
- [ ] Add **Update All** with complete multi-package command preview and confirmation.
- [ ] Add scheduled background update checks (configurable intervals).
- [ ] Add native macOS Notification Center update alerts.
- [ ] Add granular snooze and package ignore controls.
- [ ] Add separate, distinct formula vs. cask update policies.
- [ ] Add safe configurable automatic updates with failure rollbacks.
- [ ] Add full update history log and searchable command audit trail.
- [ ] Add proactive `brew cleanup` and `brew doctor` health reminders.
- [ ] Add package release-note links and upstream changelog summaries.
- [ ] Add `Brewfile` export and automated environment backup.
- [ ] Add app configuration and preference export / import.
- [ ] Integrate one-time licensing (e.g., Lemon Squeezy / Paddle) only after demand is validated.
- [ ] Support a personal license seat model on up to **3 Macs**.

---

## 🔮 Deferred & Enterprise Horizons
> *Long-term backlog items evaluated post-v1.0 release.*

- [ ] Team fleet inventory aggregation and remote reporting.
- [ ] Shared team update policies and compliance audit logs.
- [ ] CVE vulnerability and security advisory reporting for installed packages.
- [ ] Jamf, Kandji, or other MDM configuration profile integrations.
- [ ] Organization accounts and centralized team billing.
- [ ] Cross-Mac iCloud / CloudKit state synchronization.

---

## 🚀 Current Production Baseline
> *Verified capabilities currently running in the application codebase.*

- [x] 🟢 **Native UI:** SwiftUI menu-bar popover with status bar icon and dynamic badge count.
- [x] 🟢 **Core Engine:** Non-blocking Homebrew executable detection & environment path resolution.
- [x] 🟢 **Inventory:** Complete installed formula and cask parsing with version extraction.
- [x] 🟢 **Sync:** Manual refresh mechanism with loading spinners and robust failure alerts.
- [x] 🟢 **State Model:** Stable package identity model and baseline VoiceOver accessibility.
- [x] 🟢 **Diff Engine:** Outdated-package detection with separate installed vs. available version display.
- [x] 🟢 **Execution:** Safe individual formula & cask update runner with command preview modal.
- [x] 🟢 **Destructive Flow:** Safe individual package uninstall runner with strict confirmation safeguards.
- [x] 🟢 **Quality Assurance:** Automated test target with fixtures and unit test suite.

---

> [!NOTE]
> ### 🛠️ Developer & Environment Note
> The current command-line developer-tools selection may point to standalone **Command Line Tools** rather than the full **Xcode** app suite. Ensure you select the active Xcode developer directory prior to command-line build verification:
> ```bash
> sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
> ```
