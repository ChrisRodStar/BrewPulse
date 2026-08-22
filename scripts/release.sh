#!/bin/zsh

set -euo pipefail

script_directory="$(cd -- "$(dirname -- "$0")" && pwd)"
repository_root="$(dirname "$script_directory")"
mode="notarized"

case "${1:-}" in
    "") ;;
    --unsigned) mode="unsigned" ;;
    --skip-notarization) mode="signed" ;;
    *)
        echo "Usage: $0 [--unsigned|--skip-notarization]" >&2
        exit 2
        ;;
esac

project_path="$repository_root/macOS/BrewPulse.xcodeproj"
version="${BREWPULSE_VERSION:-$(awk -F ' = ' '/MARKETING_VERSION =/ { gsub(/;/, "", $2); print $2; exit }' "$project_path/project.pbxproj")}"
project_build_number="$(awk -F ' = ' '/CURRENT_PROJECT_VERSION =/ { gsub(/;/, "", $2); print $2; exit }' "$project_path/project.pbxproj")"
build_number="${BREWPULSE_BUILD_NUMBER:-$project_build_number}"
artifact_directory="${BREWPULSE_ARTIFACT_DIRECTORY:-$repository_root/artifacts}"

if ! xcodebuild -version >/dev/null 2>&1; then
    echo "Select a full Xcode installation with xcode-select or set DEVELOPER_DIR, then try again." >&2
    exit 1
fi

if [[ -z "$version" ]]; then
    echo "Could not determine the BrewPulse version." >&2
    exit 1
fi
if ! print -r -- "$build_number" | grep -Eq '^[1-9][0-9]*$'; then
    echo "BREWPULSE_BUILD_NUMBER must be a positive integer." >&2
    exit 1
fi
if [[ "$mode" != "unsigned" && -z "${BREWPULSE_BUILD_NUMBER:-}" ]]; then
    echo "Set BREWPULSE_BUILD_NUMBER explicitly for signed release builds." >&2
    exit 1
fi

case "$mode" in
    unsigned)
        artifact_name="BrewPulse-$version-macos-unsigned"
        signing_arguments=(
            CODE_SIGNING_ALLOWED=NO
            CODE_SIGNING_REQUIRED=NO
        )
        ;;
    signed)
        artifact_name="BrewPulse-$version-macos-signed-unnotarized"
        : "${BREWPULSE_SIGNING_IDENTITY:?Set BREWPULSE_SIGNING_IDENTITY to a Developer ID Application identity}"
        : "${BREWPULSE_DEVELOPMENT_TEAM:?Set BREWPULSE_DEVELOPMENT_TEAM to the Apple Developer team ID}"
        signing_arguments=(
            CODE_SIGN_STYLE=Manual
            "CODE_SIGN_IDENTITY=$BREWPULSE_SIGNING_IDENTITY"
            "DEVELOPMENT_TEAM=$BREWPULSE_DEVELOPMENT_TEAM"
            OTHER_CODE_SIGN_FLAGS=--timestamp
        )
        ;;
    notarized)
        artifact_name="BrewPulse-$version-macos"
        : "${BREWPULSE_SIGNING_IDENTITY:?Set BREWPULSE_SIGNING_IDENTITY to a Developer ID Application identity}"
        : "${BREWPULSE_DEVELOPMENT_TEAM:?Set BREWPULSE_DEVELOPMENT_TEAM to the Apple Developer team ID}"
        signing_arguments=(
            CODE_SIGN_STYLE=Manual
            "CODE_SIGN_IDENTITY=$BREWPULSE_SIGNING_IDENTITY"
            "DEVELOPMENT_TEAM=$BREWPULSE_DEVELOPMENT_TEAM"
            OTHER_CODE_SIGN_FLAGS=--timestamp
        )
        ;;
esac

if [[ "$mode" == "notarized" ]]; then
    if [[ -n "$(git -C "$repository_root" status --porcelain --untracked-files=normal)" ]]; then
        echo "Public releases must be built from a clean checkout." >&2
        exit 1
    fi

    release_tag="${BREWPULSE_RELEASE_TAG:-v$version}"
    tagged_commit="$(git -C "$repository_root" rev-list -n 1 "$release_tag" 2>/dev/null || true)"
    head_commit="$(git -C "$repository_root" rev-parse HEAD)"
    if [[ -z "$tagged_commit" || "$tagged_commit" != "$head_commit" ]]; then
        echo "Tag $release_tag must point to the checked-out commit before creating a public release." >&2
        exit 1
    fi

    changelog_heading="$(grep -E "^## ${version//./\\.}([[:space:]]|$)" "$repository_root/CHANGELOG.md" | head -n 1 || true)"
    if [[ -z "$changelog_heading" ]] || ! print -r -- "$changelog_heading" | grep -Eq '[[:space:]]-[[:space:]][0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
        echo "CHANGELOG.md must end the $version heading with a YYYY-MM-DD release date." >&2
        exit 1
    fi
fi

mkdir -p "$artifact_directory"
artifact_directory="$(cd "$artifact_directory" && pwd)"
output_archive="$artifact_directory/$artifact_name.xcarchive"
output_zip="$artifact_directory/$artifact_name.zip"
output_checksum="$artifact_directory/$artifact_name.zip.sha256"

if [[ -e "$output_archive" || -e "$output_zip" || -e "$output_checksum" ]]; then
    echo "Refusing to overwrite an existing release artifact for $artifact_name" >&2
    exit 1
fi

temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/BrewPulse-release.XXXXXX")"
staging_directory="$(mktemp -d "$artifact_directory/.BrewPulse-release.XXXXXX")"
archive_path="$staging_directory/$artifact_name.xcarchive"
staged_zip="$staging_directory/$artifact_name.zip"
staged_checksum="$staging_directory/$artifact_name.zip.sha256"
derived_data_path="$temporary_directory/DerivedData"
app_path="$archive_path/Products/Applications/BrewPulse.app"
binary_path="$app_path/Contents/MacOS/BrewPulse"

cleanup() {
    /bin/rm -rf "$temporary_directory"
    /bin/rm -rf "$staging_directory"
}
trap cleanup EXIT

xcodebuild \
    -project "$project_path" \
    -scheme BrewPulse \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -archivePath "$archive_path" \
    -derivedDataPath "$derived_data_path" \
    "MARKETING_VERSION=$version" \
    "CURRENT_PROJECT_VERSION=$build_number" \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    COMPILER_INDEX_STORE_ENABLE=NO \
    "${signing_arguments[@]}" \
    archive

if [[ ! -d "$app_path" ]]; then
    echo "Archive succeeded but BrewPulse.app was not found." >&2
    exit 1
fi

bundle_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_path/Contents/Info.plist")"
if [[ "$bundle_version" != "$version" ]]; then
    echo "Artifact version $bundle_version does not match requested version $version." >&2
    exit 1
fi
bundle_build_number="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$app_path/Contents/Info.plist")"
if [[ "$bundle_build_number" != "$build_number" ]]; then
    echo "Artifact build $bundle_build_number does not match requested build $build_number." >&2
    exit 1
fi

architectures="$(lipo -archs "$binary_path")"
if [[ "$architectures" != *arm64* || "$architectures" != *x86_64* ]]; then
    echo "Expected a universal binary, found: $architectures" >&2
    exit 1
fi

verify_developer_id_signature() {
    local target_app="$1"
    local signature_metadata
    local team_identifier

    codesign --verify --deep --strict --verbose=2 "$target_app"
    signature_metadata="$(codesign -dv --verbose=4 "$target_app" 2>&1)"
    team_identifier="$(print -r -- "$signature_metadata" | awk -F= '$1 == "TeamIdentifier" { print $2; exit }')"

    if [[ "$team_identifier" != "$BREWPULSE_DEVELOPMENT_TEAM" ]]; then
        echo "Signed app team $team_identifier does not match $BREWPULSE_DEVELOPMENT_TEAM." >&2
        exit 1
    fi
    if ! print -r -- "$signature_metadata" | grep -q '^Authority=Developer ID Application:'; then
        echo "Signed app does not use a Developer ID Application identity." >&2
        exit 1
    fi
    if ! print -r -- "$signature_metadata" | grep -Eq '^CodeDirectory .*flags=.*\(runtime\)'; then
        echo "Signed app is missing the hardened runtime flag." >&2
        exit 1
    fi
    if ! print -r -- "$signature_metadata" | grep -q '^Timestamp='; then
        echo "Signed app is missing a trusted timestamp." >&2
        exit 1
    fi
}

if [[ "$mode" != "unsigned" ]]; then
    verify_developer_id_signature "$app_path"
fi

ditto -c -k --sequesterRsrc --keepParent "$app_path" "$staged_zip"

if [[ "$mode" == "notarized" ]]; then
    notary_profile="${BREWPULSE_NOTARY_PROFILE:-BrewPulse}"
    xcrun notarytool submit "$staged_zip" \
        --keychain-profile "$notary_profile" \
        --wait
    xcrun stapler staple "$app_path"
    xcrun stapler validate "$app_path"
    spctl --assess --type execute --verbose=2 "$app_path"
    /bin/rm -f "$staged_zip"
    ditto -c -k --sequesterRsrc --keepParent "$app_path" "$staged_zip"
fi

unzip -tq "$staged_zip"
validation_directory="$temporary_directory/zip-validation"
mkdir -p "$validation_directory"
ditto -x -k "$staged_zip" "$validation_directory"
extracted_app="$validation_directory/BrewPulse.app"
extracted_binary="$extracted_app/Contents/MacOS/BrewPulse"

if [[ ! -d "$extracted_app" ]]; then
    echo "The packaged ZIP does not contain BrewPulse.app at its root." >&2
    exit 1
fi

extracted_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$extracted_app/Contents/Info.plist")"
if [[ "$extracted_version" != "$version" ]]; then
    echo "Packaged app version $extracted_version does not match requested version $version." >&2
    exit 1
fi
extracted_build_number="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$extracted_app/Contents/Info.plist")"
if [[ "$extracted_build_number" != "$build_number" ]]; then
    echo "Packaged app build $extracted_build_number does not match requested build $build_number." >&2
    exit 1
fi

extracted_architectures="$(lipo -archs "$extracted_binary")"
if [[ "$extracted_architectures" != *arm64* || "$extracted_architectures" != *x86_64* ]]; then
    echo "Packaged app is not universal: $extracted_architectures" >&2
    exit 1
fi

if [[ "$mode" != "unsigned" ]]; then
    verify_developer_id_signature "$extracted_app"
fi
if [[ "$mode" == "notarized" ]]; then
    xcrun stapler validate "$extracted_app"
    spctl --assess --type execute --verbose=2 "$extracted_app"
fi

checksum="$(shasum -a 256 "$staged_zip" | awk '{ print $1 }')"
print -r -- "$checksum  $(basename "$output_zip")" > "$staged_checksum"

mv "$archive_path" "$output_archive"
mv "$staged_zip" "$output_zip"
mv "$staged_checksum" "$output_checksum"

echo "Created $output_archive"
echo "Created $output_zip"
echo "Created $output_checksum"
echo "Version: $version"
echo "Build: $build_number"
echo "Architectures: $architectures"
