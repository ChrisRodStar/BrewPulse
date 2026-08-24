# BrewPulse Free roadmap

BrewPulse is the public macOS client and the shared Homebrew implementation used by every future BrewPulse product.

> **Current priority:** publish and collect feedback on the unsigned 0.2.2 updater release, then continue the remaining manual quality matrix. Apple Developer ID signing and notarization are deferred. Do not start Pro, licensing, accounts, or fleet management to make the workspace look complete.

## Current state

The core workflow is implemented and locally verified. On August 24, 2026, all 87 tests passed with Xcode 27.0, the optimized command-builder regression suite passed, the Release build passed, and static analysis passed.

| Area | Status |
| --- | --- |
| Homebrew discovery and inventory | Complete |
| Update detection | Complete |
| Individual update and uninstall | Complete |
| Store and command-runner coverage | Complete for current behavior |
| Failure recovery and command lifecycle | In progress |
| Accessibility and UI edge cases | In progress |
| Signed in-app updates | Complete |
| Unsigned 0.2.2 release | Complete |

Only the **Now** section should drive the next code task. The later sections record release gates and boundaries without pretending they are active work.

## Now

Work through these areas in order. Keep each code change small enough to review and verify on its own.

### 1. Missing Homebrew and refresh failures

- [x] Give a missing Homebrew installation its own state instead of presenting it as a generic load failure.
- [x] Explain where BrewPulse looked for Homebrew and provide a safe link to installation information without running an install command.
- [x] Keep Refresh available as the retry action after Homebrew is installed or repaired.
- [x] Distinguish command failure, unreadable Homebrew output, and likely connectivity failure in user-facing copy.
- [x] Let users inspect and copy preserved stdout, stderr, exit status, and the exact command from a failed refresh.
- [x] Keep the last complete snapshot after a later refresh fails rather than applying partial inventory, and label the retained snapshot with its timestamp.
- [x] Add focused tests and self-contained previews for missing Homebrew, initial failure, retained-data failure, and empty inventory.

### 2. Command lifecycle and recovery

- [x] Apply a five-minute timeout to each read-only refresh command. Do not time out update or uninstall automatically.
- [x] Test stalled refresh commands and likely connectivity failures with deterministic runners.
- [ ] Remove the in-progress Cancel action from package updates and uninstalls. Keep Cancel in command review, before anything runs.
- [ ] Once confirmed, let a package action run to completion and preserve Homebrew output if it fails or the app exits unexpectedly.
- [x] Run read-only refresh commands in their own process groups so a timeout stops child work before returning.
- [x] Show a successful package action and a failed follow-up refresh as separate outcomes so stale inventory is never mistaken for current state.
- [ ] Verify relaunch behavior after an operation is interrupted by a crash or forced quit.
- [x] Keep very large command output usable without constructing one unbounded SwiftUI `Text` view.

### 3. UI and accessibility finish work

- [x] Make long and multi-line installed or available versions readable without breaking row actions.
- [x] Add `Command-R` for refresh. Keep the existing default, cancel, and Settings shortcuts working.
- [ ] Verify keyboard-only navigation through section selection, package actions, command review, output details, and Settings.
- [ ] Verify VoiceOver labels, values, focus order, grouping, and disabled states for the same workflow.
- [ ] Verify larger accessibility text sizes do not hide commands, versions, warnings, or destructive confirmations.
- [x] Add previews for loading, failure, empty inventory, and failed operation states.
- [ ] Review copy with someone who uses Homebrew but does not work in Terminal every day.

### 4. Remaining quality matrix

These checks improve the preview and remain required for the later signed beta. They do not block the explicitly unsigned download.

- [x] Test a complete formula update on a clean supported Mac.
- [x] Test a complete cask update.
- [ ] Test a cask that opens an installer or requests administrator approval when practical.
- [ ] Test formula and cask uninstall without `--zap`, force, or dependency overrides.
- [ ] Test Apple Silicon and Intel Homebrew installations on supported macOS versions.
- [ ] Verify launch at login and ordinary relaunch after a macOS restart.
- [ ] Measure idle and refresh CPU, memory, wakeups, and battery impact with the menu closed and open.
- [ ] Repeat the keyboard, VoiceOver, and larger-text checks on the archived Release build.

### 5. Distribution and public beta

- [x] Add and validate a production Icon Composer app icon with light, dark, and tinted appearances.
- [x] Enable hardened runtime in Debug and Release configurations.
- [x] Add a repeatable credential-free Apple Silicon and Intel DMG packaging dry run.
- [x] Document an explicitly labeled unsigned preview without presenting it as the signed public beta.
- [x] Add a release mode that requires a clean tagged commit and dated changelog for a published unsigned preview.
- [ ] Verify the Developer ID archive and signing process with the production identity.
- [ ] Notarize and staple a release artifact successfully.
- [x] Choose a simple beta package format and document installation and removal.
- [x] Make contributor builds work without requiring the maintainer's signing identity.
- [x] Protect `main` against force pushes and deletion, keep pull-request validation for outside contributions, and validate maintainer pushes locally and on GitHub.
- [x] Document the supported macOS, Homebrew, and BrewPulse versions for the release.
- [x] Decide how Free users learn about BrewPulse updates without requiring a paid account or service.
- [x] Add signed in-app updates with automatic checks, an approval prompt, and a manual check in Settings.
- [x] Publish honest release notes, known limitations, support instructions, and a feedback path.

## Unsigned preview gate

The 0.1.0 beta preview is ready when:

- [x] Version-checked Apple Silicon and Intel DMGs with SHA-256 checksums are published in a GitHub prerelease.
- [x] The unsigned and unnotarized status appears before every download link.
- [x] The install guide explains Apple's Open Anyway flow without disabling Gatekeeper or removing quarantine.
- [x] The GitHub prerelease and website point to the exact artifact and checksum.
- [x] Source, license, security, support, privacy, release notes, and known limitations remain accessible.

## Signed beta gate

The later signed beta is ready when:

- [ ] Apple Silicon and Intel DMGs are published, and the website selects the matching installer with a manual fallback.
- [ ] A new user can install, open, and remove the signed app using the published instructions.
- [ ] Missing Homebrew, a healthy installation, no packages, current packages, outdated packages, and refresh failures are understandable.
- [ ] An individual formula or cask update and Update All can be reviewed without hidden commands.
- [ ] Failures and cancellations preserve enough original Homebrew output to troubleshoot them.
- [ ] The archived build passes automated checks and the manual beta matrix.
- [ ] The website has an accurate download, source, license, security, support, and privacy path.

## After the first beta

- [ ] Triage crash, command-safety, data-loss, cancellation, and major accessibility reports before cosmetic requests.
- [ ] Add regression fixtures for Homebrew output that the beta encounters in the wild.
- [ ] Decide which beta findings block 1.0 and record them here.
- [ ] Tag Free 1.0 only when individual updates and reviewed Update All are stable enough to recommend outside the project.

## Completed foundation

- [x] Discover Apple Silicon and Intel Homebrew installations.
- [x] Run shell-free structured commands and serialize Homebrew work.
- [x] Capture executable, arguments, stdout, stderr, exit status, start time, and duration without pipe deadlocks.
- [x] Parse installed casks, formulae, versions, metadata, and structured outdated data.
- [x] Model pinned and otherwise non-upgradable packages.
- [x] Show installed and available versions, update counts, refresh progress, retained data, and last refresh time.
- [x] Review the exact typed formula or cask command before an update. The command layer retains standard uninstall support for future product review.
- [x] Require explicit confirmation and keep destructive uninstall separate.
- [x] Preserve operation output across success, failure, and unexpected interruption.
- [x] Refresh inventory after package actions.
- [x] Add Settings and launch-at-login support.
- [x] Add CI, a Release build check, static analysis, fixtures, command tests, and thirteen focused `PackageStore` state tests.
- [x] Build and test the Free app without any private repository or dependency.

## Open-core boundary

These are product rules, not unchecked beta tasks:

- Homebrew discovery, parsing, command construction, execution safety, individual updates, and reviewed Update All remain public.
- BrewPulse Free must keep building without Commercial, Web, or Cloud.
- Private modules extend the public core; they do not copy it or replace its safety rules.
- Add commercial interfaces only when a real private implementation needs them.
- Keep signing secrets, payment credentials, entitlement-signing keys, and production service configuration out of this repository.

Extract the shared engine into a Swift package or framework when `BrewPulse-Commercial` has its first real consumer. That work is not a Free beta blocker.

## Other repositories

- `BrewPulse-Web` owns the public beta website. Its immediate job is accurate product, download, source, support, security, and privacy pages.
- `BrewPulse-Commercial` stays parked until the Free beta and Pro demand test produce evidence for a paid feature set.
- `BrewPulse-Cloud` stays parked until a validated paid feature has a server-side requirement.
- Teams and Enterprise stay parked until direct conversations with organizations justify them.

## Definition of done for BrewPulse Free

A normal Homebrew user can install BrewPulse, understand what needs attention, safely review one update or all available updates, recover from common failures, and verify that the app never performs hidden package-manager work.
