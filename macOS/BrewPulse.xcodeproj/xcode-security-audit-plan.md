# BrewPulse security audit plan

**Project:** BrewPulse
**Audit date:** 2026-08-28
**Scope:** The macOS app in this worktree, plus a read-only review of the separate BrewPulse Cloud repository against the supplied checklist.

## Baseline

- Hardened Runtime is enabled for the BrewPulse app target.
- Enhanced Security is enabled at the project level.
- The BrewPulse target uses `BrewPulse/BrewPulse.entitlements` with the Enhanced Security runtime protections and Hardware Memory Tagging in soft mode.
- App-owned source is Swift; the C and Objective-C diagnostic settings in this audit do not materially apply.
- The existing full validation passes: tests, focused Release tests, Release build, and static analysis.

## Proposed Xcode security changes

- **Enhanced Security**
  - [x] Enable Enhanced Security at the project level for the BrewPulse app.
  - [x] Create and configure the BrewPulse entitlements file required by Enhanced Security.
- [x] Enable Hardware Memory Tagging in soft mode for supported hardware.
- [ ] Enable additional C and Objective-C diagnostics. Leave unchecked because app-owned source is Swift.

Execution completed in Xcode. Pointer authentication is disabled only for the BrewPulse target because Sparkle 2.9.6 does not ship an `arm64e` slice; all other Enhanced Security protections remain enabled.

## Audit findings

| Checklist area | Result | Evidence and next action |
| --- | --- | --- |
| Authorization | Pass / not applicable to anonymous ingestion | The public cloud endpoint accepts anonymous product analytics by design. The maintainer overview requires authentication and the `analytics:view` permission, with tests for unauthenticated, forbidden, and authorized access. There is no user-owned row API to test for cross-user access. |
| Server-side validation | Pass | The cloud endpoint rejects unknown fields and invalid types, categories, timestamps, UUIDs, oversized bodies, and oversized batches before its internal write. |
| Rate limiting | Pass | Per-installation and per-network token buckets are implemented. Concurrent installation rate-limit coverage now verifies that simultaneous batches cannot exceed the bucket capacity. |
| Supply chain | Pass for repository controls | Sparkle is lockfile-pinned to 2.9.6, app and cloud CI actions use immutable commit SHAs, dependency audits are clean, and weekly Swift and GitHub Actions updates are automated. The cloud runs a weekly Bun vulnerability audit; Bun version updates remain manual because GitHub's updater currently rejects its version 2 text lockfile. |
| Logging and monitoring | Improved and live | The read-only health route is deployed, and the free scheduled GitHub Actions monitor passed an end-to-end production check. Convex usage-threshold alerts still require dashboard configuration. |
| Secrets | Pass | Targeted current-tree and full-history scans found no common secret formats. The client contains public configuration only; the cloud development environment file is ignored. |
| Backups and recovery | Export verified; restore pending | A real development snapshot export was created and its ZIP integrity verified. A destructive restore was not run because no disposable deployment was available; the operations guide now records the exact rehearsal procedure and required evidence. |

## Other release-security work

These items are findings, not part of the checked Xcode-settings execution:

1. Accepted exception: Developer ID signing and notarization are deferred because the project does not have a paid Apple Developer account. Revisit only if the distribution model changes.
2. Weekly Swift dependency update automation is included in this app branch.
3. Cloud dependency auditing, GitHub Actions updates, immutable CI action pins, rate-limit tests, and free health monitoring are live on cloud `main`. A destructive restore rehearsal remains a manual operation against a disposable deployment.
4. Final Xcode security decisions are recorded in `xcode-security-settings.md`, including the narrow Sparkle pointer-authentication exception.

## Execution result

The checked changes were applied in the security worktrees. Full Debug tests, focused Release tests, the Release build, and Debug static analysis all passed. The final decisions are recorded in `xcode-security-settings.md`.
