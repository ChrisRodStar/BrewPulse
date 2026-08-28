# Xcode Security Settings

Security build-setting and entitlement decisions for BrewPulse.

**Audit date:** 2026-08-28
**Target:** BrewPulse (macOS application)
**Languages:** Swift app-owned source

## Enabled settings

- `ENABLE_ENHANCED_SECURITY` to `YES` at the project level. This enables Xcode's compiler-side Enhanced Security protections for Debug and Release.
- `ENABLE_SECURITY_COMPILER_WARNINGS` to `YES` through the Enhanced Security cascade.
- Stack zero initialization through the Enhanced Security cascade.
- `CLANG_CXX_STANDARD_LIBRARY_HARDENING` through the Enhanced Security cascade. It is inherited even though BrewPulse's app-owned source is Swift.
- `CLANG_ENABLE_C_TYPED_ALLOCATOR_SUPPORT` and `CLANG_ENABLE_CPLUSPLUS_TYPED_ALLOCATOR_SUPPORT` through the Enhanced Security cascade.
- Hardened Runtime remains enabled for the BrewPulse target.
- `CODE_SIGN_ENTITLEMENTS` to `BrewPulse/BrewPulse.entitlements` for Debug and Release.

## Enabled Enhanced Security entitlements

- `com.apple.security.hardened-process` = `true`
- `com.apple.security.hardened-process.enhanced-security-version-string` = `"2"`
- `com.apple.security.hardened-process.hardened-heap` = `true`
- `com.apple.security.hardened-process.dyld-ro` = `true`
- `com.apple.security.hardened-process.platform-restrictions-string` = `"2"`
- `com.apple.security.hardened-process.checked-allocations` = `true`
- `com.apple.security.hardened-process.checked-allocations.soft-mode` = `true`

Hardware Memory Tagging is intentionally in soft mode. On supported hardware it records simulated crash reports without terminating the process. Review those reports before considering strict mode.

## Disabled settings

- `ENABLE_POINTER_AUTHENTICATION` to `NO` at the BrewPulse target. Enhanced Security normally enables this and produces an `arm64e` slice, but Sparkle 2.9.6 ships only `arm64` and `x86_64`. The first validation attempt failed to link the `arm64e` app against Sparkle. Keep this narrow target-level exception until Sparkle supplies an `arm64e` slice, then remove it and rerun the complete validation suite.
- Developer ID signing and notarization are an accepted release-process exception because the project does not have a paid Apple Developer account. Revisit only if the distribution model or budget changes.

## Deferred or not applicable

- Additional C, C++, Objective-C, and Objective-C++ compiler, analyzer, clang-tidy, and bounds-safety settings were not enabled individually because BrewPulse's app-owned source is Swift. Reassess if app-owned source in one of those languages is added.
- `com.apple.security.hardened-process.checked-allocations.enable-pure-data` is deferred. Soft-mode Hardware Memory Tagging is the lower-risk initial rollout.
- `com.apple.security.hardened-process.checked-allocations.no-tagged-receive` is deferred because BrewPulse has no demonstrated need to reject tagged pointers received through Mach IPC.

## Verification

The repository's complete `scripts/validate.sh` workflow passed after these settings were applied: full Debug tests, focused Release tests, a Release build, and Debug static analysis. A normal local ad-hoc-signed Debug build also passed `codesign --verify --deep --strict`; inspection of the built app confirmed all seven Enhanced Security entitlements were embedded. This local verification does not require a paid Apple Developer account.
