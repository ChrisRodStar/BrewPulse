# Xcode Security Settings

Security build-setting and entitlement decisions for BrewPulse.

**Audit date:** 2026-08-28
**Target:** BrewPulse (macOS application)
**Languages:** Swift app-owned source

## Enabled settings

- Hardened Runtime remains enabled in the Xcode target. The unsigned release script applies an ordinary ad-hoc signature to the final app, because an ad-hoc Hardened Runtime signature cannot load BrewPulse's embedded Sparkle framework on current macOS.

## Disabled settings

- Enhanced Security is disabled. Its additional dynamic-library restrictions prevent an ad-hoc-signed BrewPulse release from loading its embedded Sparkle framework before the app starts.
- Developer ID signing and notarization are an accepted release-process exception because the project does not have a paid Apple Developer account. Revisit only if the distribution model or budget changes.

## Deferred or not applicable

- Additional C, C++, Objective-C, and Objective-C++ compiler, analyzer, clang-tidy, and bounds-safety settings were not enabled individually because BrewPulse's app-owned source is Swift. Reassess if app-owned source in one of those languages is added.
- Enhanced Security and Hardware Memory Tagging are not enabled for unsigned releases. Reassess them if BrewPulse adopts a distribution path compatible with the required dynamic-library restrictions.

## Verification

The repository's complete `scripts/validate.sh` workflow verifies full Debug tests, focused Release tests, a Release build, and Debug static analysis. Release packaging must also be tested from the final unsigned DMG because the launch failure occurs before app code runs.
