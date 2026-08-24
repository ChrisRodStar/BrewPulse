# Release process

Every release has separate disk images for Apple Silicon and Intel, plus a universal DMG used by the in-app updater. Each DMG contains `BrewPulse.app` and an Applications shortcut. Until Developer ID signing is available, published builds must be explicitly labeled unsigned and not notarized.

## Build prerequisite

- the Xcode version pinned in `.github/workflows/macos-ci.yml`

The scripts use the Xcode selected for command-line tools. Set `DEVELOPER_DIR` on the command if the required Xcode is installed in a nonstandard location.

An unsigned release does not require Apple signing or notarization credentials.

Every published release, including an unsigned one, requires the BrewPulse Sparkle EdDSA private key in the login keychain under the `ed25519` account. This key signs the update archive and appcast; it is separate from Apple Developer ID signing.

## Signed-release prerequisites

- a valid `Developer ID Application` identity in the login keychain
- an Apple Developer team ID
- a `notarytool` keychain profile named `BrewPulse`, or a different name supplied through `BREWPULSE_NOTARY_PROFILE`

A published build must come from a clean checkout. Its release tag must point to the checked-out commit, and the version heading in `CHANGELOG.md` must end with a release date instead of `unreleased`.

Store notarization credentials once:

```text
xcrun notarytool store-credentials BrewPulse \
  --apple-id "APPLE_ID" \
  --team-id "TEAM_ID" \
  --password "APP_SPECIFIC_PASSWORD"
```

Sparkle's private key signs update archives. Back it up somewhere encrypted with Sparkle's `generate_keys -x` option. The public key is stored in `Info.plist`; never commit the exported private key.

Do not commit certificate exports, passwords, API keys, private keys, or notarization credentials.

## Validate without credentials

This builds unsigned Apple Silicon and Intel disk images plus the universal archive used to validate the in-app update path:

```text
./scripts/release.sh --unsigned
```

The output filenames contain `unsigned` so they cannot be confused with signed public artifacts. The script builds in isolated temporary directories, verifies each app version and architecture, mounts each DMG to verify its contents, and writes a SHA-256 checksum before moving the artifacts to `artifacts/`.

## Publish an unsigned release

Unsigned releases are GitHub releases for testers who accept the Gatekeeper warning. Sparkle signs the universal update archive and appcast with the separate EdDSA key; this does not sign or notarize the app with Apple. The app bundle also receives a free ad-hoc signature so macOS can verify its internal integrity, but that signature does not identify the developer.

1. Use a clean commit whose changelog names the release and its limitations.
2. Create a release tag such as `v0.2.2` on that commit.
3. Set `BREWPULSE_RELEASE_TAG` to the tag and `BREWPULSE_BUILD_NUMBER` to a positive integer.
4. Run `./scripts/release.sh --unsigned-preview`.
5. Verify all three DMG checksums. Confirm the Apple Silicon image contains `arm64`, the Intel image contains `x86_64`, and the universal image contains both architectures.
6. Create a GitHub release. Put `Unsigned` in its title and opening warning.
7. Attach all three unsigned DMGs and their checksums. The universal DMG serves the appcast; the website links to the smaller architecture-specific downloads.
8. Confirm the universal DMG URL in `appcast.xml` matches the release, then commit and push the updated feed to `main`.
9. Link the website to the exact release and repeat the download and checksum test.

For version 0.2.2:

```text
export BREWPULSE_RELEASE_TAG="v0.2.2"
export BREWPULSE_BUILD_NUMBER="6"
./scripts/release.sh --unsigned-preview
```

The release and website must tell users that macOS cannot verify the developer or notarization status. Link to Apple's [Gatekeeper override instructions](https://support.apple.com/en-us/102445). A checksum only confirms that a DMG matches the GitHub asset; it does not replace signing or notarization. Do not recommend disabling Gatekeeper or removing quarantine attributes.

## Create the signed public artifact

```text
export BREWPULSE_SIGNING_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"
export BREWPULSE_DEVELOPMENT_TEAM="TEAM_ID"
export BREWPULSE_NOTARY_PROFILE="BrewPulse"
export BREWPULSE_BUILD_NUMBER="1"
./scripts/release.sh
```

Use a positive integer for `BREWPULSE_BUILD_NUMBER` and increase it for every release build. The script writes it to `CFBundleVersion` and checks the archived and packaged copies.

For each release variant, the script:

1. creates a Release archive containing only the requested architecture;
2. confirms the bundle version, build number, and executable architecture;
3. verifies the Developer ID authority, team, hardened runtime, and timestamp;
4. creates a compact branded DMG containing `BrewPulse.app`, an Applications shortcut, and a saved Finder layout;
5. signs the DMG, submits it to Apple's notarization service, and waits for the result;
6. staples and validates the DMG ticket;
7. asks Gatekeeper to assess the disk image;
8. mounts the DMG read-only, verifies the packaged app again, and asks Gatekeeper to assess the app;
9. writes a SHA-256 checksum;
10. signs the universal update archive with Sparkle and updates `appcast.xml` with its release notes and URL;
11. moves all three disk images and their checksums into `artifacts/` only after the complete set passes.

Successful output is written to `artifacts/`:

- `BrewPulse-VERSION-macos-arm64.dmg`
- `BrewPulse-VERSION-macos-arm64.dmg.sha256`
- `BrewPulse-VERSION-macos-x64.dmg`
- `BrewPulse-VERSION-macos-x64.dmg.sha256`
- `BrewPulse-VERSION-macos-universal.dmg`
- `BrewPulse-VERSION-macos-universal.dmg.sha256`

The script refuses to overwrite an existing artifact. Move a prior build elsewhere or change the version before rebuilding.

Verify a downloaded DMG from the directory containing it and its checksum:

```text
shasum -a 256 -c BrewPulse-VERSION-macos-arm64.dmg.sha256
```

## Signed diagnostic build

`./scripts/release.sh --skip-notarization` creates explicitly named Apple Silicon, Intel, and universal `signed-unnotarized` disk images. Use them only to diagnose signing. Never publish them.

## Release checklist

1. Confirm the release candidate passed `./scripts/validate.sh`. If it uses a pull request, confirm that its current head also passed `macOS Validation`.
2. Run the full manual beta matrix in [TODO.md](../TODO.md) against its archived app.
3. Update [CHANGELOG.md](../CHANGELOG.md) with the final date and known limitations, then merge the release commit.
4. Create and push the matching `vVERSION` tag on that clean commit.
5. Run the notarized release command from the tag.
6. Confirm the packaged-copy signature, stapler validation, Gatekeeper assessment, and checksum all pass.
7. Repeat the install, open, launch-at-login, individual update, Update All, quit, and app removal smoke tests with both notarized disk images on matching Macs.
8. Create the GitHub release and attach all three DMGs and their `.sha256` files. The universal DMG is for in-app updates; keep the smaller architecture-specific downloads on the website.
9. Confirm the universal DMG URL in `appcast.xml` resolves, then commit and push the updated feed to `main`.
10. From the previous update-capable BrewPulse release, choose "Check for Updates…" and complete an update on both Apple Silicon and Intel.
11. Confirm the website detects a supported architecture where the browser exposes it, chooses the matching DMG, and keeps the manual Apple Silicon/Intel switch available.
