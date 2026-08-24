# Release process

The ordinary public beta is distributed as two notarized disk images: one for Apple Silicon and one for Intel. Each DMG contains `BrewPulse.app` and an Applications shortcut. A prerelease may use the same format as an explicitly labeled unsigned preview.

## Build prerequisite

- the Xcode version pinned in `.github/workflows/macos-ci.yml`

The scripts use the Xcode selected for command-line tools. Set `DEVELOPER_DIR` on the command if the required Xcode is installed in a nonstandard location.

An unsigned preview does not require Apple signing or notarization credentials.

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

Do not commit certificate exports, passwords, API keys, or notarization credentials.

## Validate without credentials

This builds unsigned Apple Silicon and Intel disk images:

```text
./scripts/release.sh --unsigned
```

The output filenames contain `unsigned` so they cannot be confused with signed public artifacts. The script builds in isolated temporary directories, verifies each app version and architecture, mounts each DMG to verify its contents, and writes a SHA-256 checksum before moving the artifacts to `artifacts/`.

## Publish an unsigned preview

Unsigned previews are GitHub prereleases for early testers who accept the Gatekeeper warning. They are not the signed public beta.

1. Use a clean commit whose changelog names the preview and its limitations.
2. Create a prerelease tag such as `v0.1.0-beta.1` on that commit.
3. Set `BREWPULSE_RELEASE_TAG` to the preview tag and `BREWPULSE_BUILD_NUMBER` to a positive integer.
4. Run `./scripts/release.sh --unsigned-preview`.
5. Verify both DMG checksums and confirm the Apple Silicon image contains `arm64` while the Intel image contains `x86_64`.
6. Create a GitHub prerelease. Put `Unsigned` in its title and opening warning.
7. Attach the two unsigned DMGs and their checksums.
8. Link the website to the exact prerelease and repeat the download and checksum test.

For the first preview:

```text
export BREWPULSE_RELEASE_TAG="v0.1.0-beta.1"
export BREWPULSE_BUILD_NUMBER="1"
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

For each architecture, the script:

1. creates a Release archive containing only the requested architecture;
2. confirms the bundle version, build number, and executable architecture;
3. verifies the Developer ID authority, team, hardened runtime, and timestamp;
4. creates a DMG containing `BrewPulse.app` and an Applications shortcut;
5. signs the DMG, submits it to Apple's notarization service, and waits for the result;
6. staples and validates the DMG ticket;
7. asks Gatekeeper to assess the disk image;
8. mounts the DMG read-only, verifies the packaged app again, and asks Gatekeeper to assess the app;
9. writes a SHA-256 checksum;
10. moves both architectures and both checksums into `artifacts/` only after the complete set passes.

Successful output is written to `artifacts/`:

- `BrewPulse-VERSION-macos-arm64.dmg`
- `BrewPulse-VERSION-macos-arm64.dmg.sha256`
- `BrewPulse-VERSION-macos-x64.dmg`
- `BrewPulse-VERSION-macos-x64.dmg.sha256`

The script refuses to overwrite an existing artifact. Move a prior build elsewhere or change the version before rebuilding.

Verify a downloaded DMG from the directory containing it and its checksum:

```text
shasum -a 256 -c BrewPulse-VERSION-macos-arm64.dmg.sha256
```

## Signed diagnostic build

`./scripts/release.sh --skip-notarization` creates explicitly named Apple Silicon and Intel `signed-unnotarized` disk images. Use them only to diagnose signing. Never publish them.

## Release checklist

1. Confirm the release candidate passed `./scripts/validate.sh`. If it uses a pull request, confirm that its current head also passed `macOS Validation`.
2. Run the full manual beta matrix in [TODO.md](../TODO.md) against its archived app.
3. Update [CHANGELOG.md](../CHANGELOG.md) with the final date and known limitations, then merge the release commit.
4. Create and push the matching `vVERSION` tag on that clean commit.
5. Run the notarized release command from the tag.
6. Confirm the packaged-copy signature, stapler validation, Gatekeeper assessment, and checksum all pass.
7. Repeat the install, open, launch-at-login, individual update, Update All, quit, and app removal smoke tests with both notarized disk images on matching Macs.
8. Create the GitHub release and attach both DMGs and both `.sha256` files.
9. Confirm the website detects a supported architecture where the browser exposes it, chooses the matching DMG, and keeps the manual Apple Silicon/Intel switch available.
