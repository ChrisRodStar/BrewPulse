# Release process

The ordinary public beta is distributed as a notarized ZIP containing `BrewPulse.app`. A prerelease may be distributed as an explicitly labeled unsigned preview. Both builds are universal and contain Apple Silicon and Intel code.

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

This builds a universal unsigned archive and ZIP:

```text
./scripts/release.sh --unsigned
```

The output filename contains `unsigned` so it cannot be confused with the signed public artifact. The script builds in isolated temporary directories, verifies the app version and both architectures, tests the ZIP, and writes a SHA-256 checksum before publishing the artifacts to `artifacts/`.

## Publish an unsigned preview

Unsigned previews are GitHub prereleases for early testers who accept the Gatekeeper warning. They are not the signed public beta.

1. Use a clean commit whose changelog names the preview and its limitations.
2. Create a prerelease tag such as `v0.1.0-beta.1` on that commit.
3. Set `BREWPULSE_RELEASE_TAG` to the preview tag and `BREWPULSE_BUILD_NUMBER` to a positive integer.
4. Run `./scripts/release.sh --unsigned-preview`.
5. Verify the ZIP checksum and confirm the packaged app contains `arm64` and `x86_64`.
6. Create a GitHub prerelease. Put `Unsigned` in its title and opening warning.
7. Attach only the unsigned ZIP and checksum. Keep the `.xcarchive` private.
8. Link the website to the exact prerelease and repeat the download and checksum test.

For the first preview:

```text
export BREWPULSE_RELEASE_TAG="v0.1.0-beta.1"
export BREWPULSE_BUILD_NUMBER="1"
./scripts/release.sh --unsigned-preview
```

The release and website must tell users that macOS cannot verify the developer or notarization status. Link to Apple's [Gatekeeper override instructions](https://support.apple.com/en-us/102445). The checksum only confirms that the ZIP matches the GitHub asset; it does not replace signing or notarization. Do not recommend disabling Gatekeeper or removing quarantine attributes.

## Create the signed public artifact

```text
export BREWPULSE_SIGNING_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"
export BREWPULSE_DEVELOPMENT_TEAM="TEAM_ID"
export BREWPULSE_NOTARY_PROFILE="BrewPulse"
export BREWPULSE_BUILD_NUMBER="1"
./scripts/release.sh
```

Use a positive integer for `BREWPULSE_BUILD_NUMBER` and increase it for every release build. The script writes it to `CFBundleVersion` and checks the archived and packaged copies.

The script:

1. creates a universal Release archive;
2. confirms the bundle and filename versions match;
3. checks that the executable contains `arm64` and `x86_64`;
4. verifies the Developer ID authority, team, hardened runtime, and timestamp;
5. submits the staged ZIP to Apple's notarization service and waits for the result;
6. staples and validates the ticket;
7. asks Gatekeeper to assess the app;
8. recreates and extracts the ZIP, then checks the packaged copy again;
9. writes a SHA-256 checksum and moves only verified artifacts into `artifacts/`.

Successful output is written to `artifacts/`:

- `BrewPulse-VERSION-macos.xcarchive`
- `BrewPulse-VERSION-macos.zip`
- `BrewPulse-VERSION-macos.zip.sha256`

The script refuses to overwrite an existing artifact. Move a prior build elsewhere or change the version before rebuilding.

Verify the downloaded ZIP from the directory containing both files:

```text
shasum -a 256 -c BrewPulse-VERSION-macos.zip.sha256
```

## Signed diagnostic build

`./scripts/release.sh --skip-notarization` creates an explicitly named `signed-unnotarized` artifact. Use it only to diagnose signing. Never publish it.

## Release checklist

1. Confirm the release-candidate pull request head passed `macOS Validation`.
2. Run the full manual beta matrix in [TODO.md](../TODO.md) against its archived app.
3. Update [CHANGELOG.md](../CHANGELOG.md) with the final date and known limitations, then merge the release commit.
4. Create and push the matching `vVERSION` tag on that clean commit.
5. Run the notarized release command from the tag.
6. Confirm the packaged-copy signature, stapler validation, Gatekeeper assessment, and checksum all pass.
7. Repeat the install, open, launch-at-login, package update, package uninstall, quit, and app removal smoke tests using the exact notarized ZIP.
8. Create the GitHub release and attach the ZIP and its `.sha256` file. Keep the `.xcarchive` private.
9. Update the website download link to that release.
