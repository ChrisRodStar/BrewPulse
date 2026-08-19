# BrewPulse Free roadmap

BrewPulse is the public, open-source macOS client and the shared local Homebrew engine.

This roadmap only tracks work that belongs in the public Free product. Paid Pro implementation, licensing, the website, cloud services, and company fleet management belong in their own repositories.

> **Current priority:** finish BrewPulse Free as a trustworthy public beta before building the commercial product around it.

## Product sequence

The broader BrewPulse plan should move in this order:

1. Finish and harden BrewPulse Free.
2. Ship a signed and notarized public beta.
3. Use the website and real users to validate demand for Pro.
4. Build Pro in `BrewPulse-Commercial` without moving core Homebrew logic out of this repository.
5. Add only the minimum cloud services needed for paid licensing.
6. Explore Teams and Enterprise after BrewPulse has real adoption and direct feedback from IT administrators.

Enterprise is intentionally later. When it is eventually built, the local managed-Mac client belongs in `BrewPulse-Commercial`, the admin dashboard belongs in `BrewPulse-Web`, and the server-side fleet system belongs in `BrewPulse-Cloud`.

## Status

| Milestone | Focus | Status |
| --- | --- | --- |
| F1 | Homebrew foundation | Complete |
| F2 | Update detection | Complete |
| F3 | Safe package actions | Complete |
| F4 | Free app polish | In progress |
| F5 | Beta hardening | In progress |
| F6 | Open-core integration boundary | Planned |
| F7 | Public beta and Free 1.0 | Planned |

## F1. Homebrew foundation

- [x] Introduce a testable Homebrew command-running abstraction.
- [x] Return structured command results with executable, arguments, stdout, stderr, exit status, start time, and duration.
- [x] Read stdout and stderr without pipe deadlocks.
- [x] Prevent conflicting Homebrew commands from running at the same time.
- [x] Support Apple Silicon and Intel Homebrew paths.
- [x] Preserve Homebrew output for troubleshooting.
- [x] Keep package and command models independently testable.
- [x] Add parsing fixtures and command-runner tests.
- [x] Test installed-inventory orchestration and command failures.

## F2. Update detection

- [x] Read Homebrew's structured outdated-package data.
- [x] Model installed and available versions separately.
- [x] Distinguish formulae from casks through the full data path.
- [x] Recognize pinned and otherwise non-upgradable packages.
- [x] Merge installed inventory with update availability.
- [x] Display installed and available versions.
- [x] Visually distinguish current and outdated packages.
- [x] Show the available-update count in the menu bar.
- [x] Preserve manual refresh with loading and failure states.
- [x] Show when package information was last refreshed.

## F3. Safe package actions

- [x] Add an Update action for outdated packages.
- [x] Build formula and cask update commands from structured arguments.
- [x] Show the exact command before it runs.
- [x] Require explicit confirmation before an update.
- [x] Show which package is currently updating.
- [x] Disable conflicting actions while Homebrew work is active.
- [x] Display completed Homebrew output in a readable details view.
- [x] Let users copy command output.
- [x] Preserve failures without hiding Homebrew's original output.
- [x] Handle cancellation and interrupted commands.
- [x] Explain when administrator access or external interaction may be required.
- [x] Refresh inventory after an update finishes.
- [x] Add individual package uninstall with exact-command review.
- [x] Require a separate destructive confirmation before removal.
- [x] Avoid implicit `--zap`, force, and dependency overrides.

## F4. Free app polish

This milestone is about making BrewPulse feel dependable on a normal Mac, not adding more power-user features.

- [x] Add a native macOS Settings scene.
- [x] Add a launch-at-login preference with `SMAppService`.
- [x] Separate Status, Casks, and Formulae into focused views.
- [x] Show the active Homebrew version and inventory summary.
- [ ] Refine the missing-Homebrew onboarding experience.
- [ ] Refine empty, loading, offline, and partial-failure states.
- [ ] Handle long package names and multi-line version strings gracefully.
- [ ] Add useful native shortcuts such as `⌘R`, `⌘,`, and `Esc` where appropriate.
- [ ] Verify keyboard-only navigation across the full app.
- [ ] Verify VoiceOver labels, values, focus order, and disabled states.
- [ ] Verify larger accessibility text sizes do not break important controls.
- [ ] Add self-contained SwiftUI previews for critical states.
- [ ] Confirm background work remains lightweight while the menu is closed.
- [ ] Review wording throughout the app so command, failure, and confirmation messages are clear to people who are not Terminal experts.

## F5. Beta hardening

The beta should be boring in the best way. Package actions need to be predictable, failures need to be recoverable, and BrewPulse should not leave Homebrew in a confusing state.

### Automated coverage

- [x] Add macOS CI for code pull requests.
- [x] Require the current code revision to pass macOS Validation before merge.
- [x] Test command construction for installed inventory and typed formula/cask updates.
- [x] Test installed-package and outdated-data parsing.
- [x] Test missing and broken Homebrew installations.
- [x] Test Apple Silicon and Intel paths.
- [x] Test pinned packages and multiple installed versions.
- [ ] Add focused tests for store state transitions.
- [ ] Expand tests around failed, interrupted, and long-running commands.
- [ ] Test package names and output containing Unicode and unexpected characters.
- [ ] Test refresh and package actions under slow or unreliable network conditions.
- [ ] Add real-world cancellation tests for cask installers and child processes, not only the parent `brew` process.

### Manual quality checks

- [ ] Run a complete formula update test on a clean supported macOS setup.
- [ ] Run a complete cask update test, including a cask that requires user interaction when practical.
- [ ] Run a complete formula and cask uninstall test.
- [ ] Run VoiceOver and keyboard-only QA.
- [ ] Verify idle memory, CPU, wakeups, and battery impact.
- [ ] Verify relaunch and launch-at-login behavior after macOS restart.
- [ ] Confirm failures never leave the UI showing stale success state.

### Release safety

- [ ] Enable appropriate GitHub protection for `main` now that the public repository can support it.
- [ ] Configure Developer ID signing and hardened runtime requirements.
- [ ] Notarize the app successfully in a repeatable release process.
- [ ] Package the beta so installation and removal are straightforward.
- [ ] Document the supported macOS and Homebrew baseline for each release.
- [ ] Decide how BrewPulse itself will notify users about new app versions without tying Free to a paid service.

## F6. Open-core integration boundary

This work prepares the public project to be reused by the private commercial app without weakening the open-source client.

- [ ] Make sure the public repository builds and runs completely without access to any private repository.
- [ ] Keep Homebrew discovery, parsing, command construction, safety rules, and Free package actions in the public core.
- [ ] Define narrow interfaces for commercial capabilities instead of importing private implementation into public code.
- [ ] Define an entitlement-facing seam that Free can ignore cleanly.
- [ ] Define extension points for bulk actions, scheduling, notifications, history, and managed-device behavior only where the commercial product actually needs them.
- [ ] Avoid speculative abstractions that have no real Pro implementation yet.
- [ ] Add tests proving Free behavior does not change when commercial modules are absent.
- [ ] Document compatibility expectations between BrewPulse Free/core and `BrewPulse-Commercial`.
- [ ] Keep all signing secrets, licensing secrets, payment credentials, and private service configuration out of this repository.

## F7. Public beta and Free 1.0

- [ ] Publish the first signed and notarized public beta.
- [ ] Provide clear installation instructions and system requirements.
- [ ] Publish release notes that call out known limitations honestly.
- [ ] Give users an obvious place to report bugs and provide feedback.
- [ ] Watch early reports for Homebrew parsing edge cases and installer behavior that tests missed.
- [ ] Fix beta-blocking crashes, data-loss risks, confusing command behavior, and major accessibility issues before 1.0.
- [ ] Tag BrewPulse Free 1.0 only when the basic package-maintenance workflow is stable enough to recommend to people outside the project.

## What does not belong in this repository

Do not add these implementations here simply because BrewPulse Free needs to integrate with them later:

- Pro automation and paid local features
- License activation implementation
- Payment-provider integration
- Official commercial app composition
- Enterprise device enrollment and managed-device logic
- Marketing website and pricing pages
- Account or organization dashboard
- Cloud APIs, databases, billing services, or fleet state
- Company policies, audit logs, SSO, or MDM server integrations

Those responsibilities belong in `BrewPulse-Commercial`, `BrewPulse-Web`, and `BrewPulse-Cloud`.

## Definition of done for BrewPulse Free

The public Free product is ready when a normal Homebrew user can install BrewPulse, understand what is outdated, safely update or remove an individual package, recover from common failures, and trust that the app is not doing hidden package-manager work behind their back.
