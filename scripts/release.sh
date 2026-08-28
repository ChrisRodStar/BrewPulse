#!/bin/zsh

set -euo pipefail

script_directory="$(cd -- "$(dirname -- "$0")" && pwd)"
repository_root="$(dirname "$script_directory")"
mode="notarized"

case "${1:-}" in
    "") ;;
    --unsigned) mode="unsigned" ;;
    --unsigned-preview) mode="unsigned-preview" ;;
    --skip-notarization) mode="signed" ;;
    *)
        echo "Usage: $0 [--unsigned|--unsigned-preview|--skip-notarization]" >&2
        exit 2
        ;;
esac

project_path="$repository_root/macOS/BrewPulse.xcodeproj"
version="${BREWPULSE_VERSION:-$(awk -F ' = ' '/MARKETING_VERSION =/ { gsub(/;/, "", $2); print $2; exit }' "$project_path/project.pbxproj")}"
project_build_number="$(awk -F ' = ' '/CURRENT_PROJECT_VERSION =/ { gsub(/;/, "", $2); print $2; exit }' "$project_path/project.pbxproj")"
build_number="${BREWPULSE_BUILD_NUMBER:-$project_build_number}"
project_analytics_ingestion_url="$(awk -F ' = ' '/BREWPULSE_ANALYTICS_INGESTION_URL =/ && /https:/ { gsub(/[";]/, "", $2); print $2; exit }' "$project_path/project.pbxproj")"
analytics_ingestion_url="${BREWPULSE_ANALYTICS_INGESTION_URL:-$project_analytics_ingestion_url}"
artifact_directory="${BREWPULSE_ARTIFACT_DIRECTORY:-$repository_root/artifacts}"
architecture_specs=("arm64:arm64" "x86_64:x64")
installer_background="$repository_root/macOS/Packaging/BrewPulseInstallerBackground.png"
installer_background_2x="$repository_root/macOS/Packaging/BrewPulseInstallerBackground@2x.png"
installer_layout_template="$repository_root/macOS/Packaging/BrewPulseInstallerDSStore"

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
if [[ ! -f "$installer_background" || ! -f "$installer_background_2x" ]]; then
    echo "The BrewPulse installer background assets are missing." >&2
    exit 1
fi
if [[ ! -f "$installer_layout_template" ]]; then
    echo "The BrewPulse installer layout template is missing." >&2
    exit 1
fi
if [[ "$mode" != "unsigned" && -z "${BREWPULSE_BUILD_NUMBER:-}" ]]; then
    echo "Set BREWPULSE_BUILD_NUMBER explicitly for published or signed release builds." >&2
    exit 1
fi
if [[ "$mode" != "unsigned" && -z "$analytics_ingestion_url" ]]; then
    echo "Configure BREWPULSE_ANALYTICS_INGESTION_URL for published or signed release builds." >&2
    exit 1
fi

case "$mode" in
    unsigned|unsigned-preview)
        artifact_suffix="-unsigned"
        signing_arguments=(
            CODE_SIGNING_ALLOWED=NO
            CODE_SIGNING_REQUIRED=NO
        )
        ;;
    signed)
        artifact_suffix="-signed-unnotarized"
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
        artifact_suffix=""
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

architecture_specs+=("arm64 x86_64:universal")

if [[ "$mode" == "notarized" || "$mode" == "unsigned-preview" ]]; then
    if [[ -n "$(git -C "$repository_root" status --porcelain --untracked-files=normal)" ]]; then
        echo "Published releases must be built from a clean checkout." >&2
        exit 1
    fi

    if [[ "$mode" == "unsigned-preview" ]]; then
        : "${BREWPULSE_RELEASE_TAG:?Set BREWPULSE_RELEASE_TAG to the unsigned preview tag}"
        release_tag="$BREWPULSE_RELEASE_TAG"
    else
        release_tag="${BREWPULSE_RELEASE_TAG:-v$version}"
    fi
    tagged_commit="$(git -C "$repository_root" rev-list -n 1 "$release_tag" 2>/dev/null || true)"
    head_commit="$(git -C "$repository_root" rev-parse HEAD)"
    if [[ -z "$tagged_commit" || "$tagged_commit" != "$head_commit" ]]; then
        echo "Tag $release_tag must point to the checked-out commit before creating a published release." >&2
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

for architecture_spec in "${architecture_specs[@]}"; do
    asset_architecture="${architecture_spec#*:}"
    artifact_name="BrewPulse-$version-macos-$asset_architecture$artifact_suffix"
    output_dmg="$artifact_directory/$artifact_name.dmg"
    output_checksum="$artifact_directory/$artifact_name.dmg.sha256"
    if [[ -e "$output_dmg" || -e "$output_checksum" ]]; then
        echo "Refusing to overwrite an existing release artifact for $artifact_name" >&2
        exit 1
    fi
done

temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/BrewPulse-release.XXXXXX")"
staging_directory="$(mktemp -d "$artifact_directory/.BrewPulse-release.XXXXXX")"
derived_data_path="$temporary_directory/DerivedData"
source_packages_path="$temporary_directory/SourcePackages"
mounted_volume=""

cleanup() {
    if [[ -n "$mounted_volume" && -d "$mounted_volume" ]]; then
        hdiutil detach -quiet "$mounted_volume" >/dev/null 2>&1 || true
    fi
    /bin/rm -rf "$temporary_directory"
    /bin/rm -rf "$staging_directory"
}
trap cleanup EXIT

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

sign_ad_hoc_app_bundle() {
    local target_app="$1"
    local sparkle_framework="$target_app/Contents/Frameworks/Sparkle.framework"
    local sparkle_version="$sparkle_framework/Versions/B"
    local app_entitlements="$repository_root/macOS/BrewPulse/BrewPulse.entitlements"

    # Xcode strips development-only Sparkle resources while archiving. Re-sign
    # every nested component inside out so the final app seal describes the
    # files that are actually shipped. An ad-hoc signature is not a substitute
    # for Developer ID or notarization, but it prevents Gatekeeper from treating
    # the unsigned preview as a damaged bundle.
    codesign \
        --force \
        --sign - \
        --options runtime \
        "$sparkle_version/XPCServices/Installer.xpc"
    codesign \
        --force \
        --sign - \
        --options runtime \
        --preserve-metadata=entitlements \
        "$sparkle_version/XPCServices/Downloader.xpc"
    codesign \
        --force \
        --sign - \
        --options runtime \
        "$sparkle_version/Autoupdate"
    codesign \
        --force \
        --sign - \
        --options runtime \
        "$sparkle_version/Updater.app"
    codesign \
        --force \
        --sign - \
        "$sparkle_framework"
    codesign \
        --force \
        --sign - \
        --options runtime \
        --entitlements "$app_entitlements" \
        "$target_app"
}

verify_enhanced_security_entitlements() {
    local target_app="$1"
    local extracted_entitlements="$temporary_directory/BrewPulse-entitlements.plist"

    codesign -d --entitlements "$extracted_entitlements" --xml "$target_app" 2>/dev/null
    if [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.hardened-process' "$extracted_entitlements")" != "true" ]] ||
        [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.hardened-process.enhanced-security-version-string' "$extracted_entitlements")" != "2" ]] ||
        [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.hardened-process.hardened-heap' "$extracted_entitlements")" != "true" ]] ||
        [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.hardened-process.dyld-ro' "$extracted_entitlements")" != "true" ]] ||
        [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.hardened-process.platform-restrictions-string' "$extracted_entitlements")" != "2" ]] ||
        [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.hardened-process.checked-allocations' "$extracted_entitlements")" != "true" ]] ||
        [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.hardened-process.checked-allocations.soft-mode' "$extracted_entitlements")" != "true" ]]; then
        echo "Packaged app is missing the expected Enhanced Security entitlements." >&2
        exit 1
    fi
}

verify_ad_hoc_signature() {
    local target_app="$1"
    local signature_metadata

    codesign --verify --deep --strict --verbose=2 "$target_app"
    signature_metadata="$(codesign -dv --verbose=4 "$target_app" 2>&1)"

    if ! print -r -- "$signature_metadata" | grep -q '^Signature=adhoc$'; then
        echo "Unsigned preview app does not have a complete ad-hoc signature." >&2
        exit 1
    fi
    if ! print -r -- "$signature_metadata" | grep -q '^Sealed Resources version=2'; then
        echo "Unsigned preview app does not have a version 2 resource seal." >&2
        exit 1
    fi
}

verify_app_bundle() {
    local target_app="$1"
    local expected_architecture="$2"
    local target_binary="$target_app/Contents/MacOS/BrewPulse"
    local bundle_version
    local bundle_build_number
    local bundle_analytics_ingestion_url
    local architectures

    if [[ ! -d "$target_app" ]]; then
        echo "BrewPulse.app was not found at $target_app" >&2
        exit 1
    fi

    bundle_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$target_app/Contents/Info.plist")"
    if [[ "$bundle_version" != "$version" ]]; then
        echo "Artifact version $bundle_version does not match requested version $version." >&2
        exit 1
    fi

    bundle_build_number="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$target_app/Contents/Info.plist")"
    if [[ "$bundle_build_number" != "$build_number" ]]; then
        echo "Artifact build $bundle_build_number does not match requested build $build_number." >&2
        exit 1
    fi

    bundle_analytics_ingestion_url="$(/usr/libexec/PlistBuddy -c 'Print :BrewPulseAnalyticsIngestionURL' "$target_app/Contents/Info.plist")"
    if [[ "$bundle_analytics_ingestion_url" != "$analytics_ingestion_url" ]]; then
        echo "Artifact analytics configuration does not match the requested ingestion URL." >&2
        exit 1
    fi

    architectures="$(lipo -archs "$target_binary" | tr ' ' '\n' | sort | tr '\n' ' ')"
    expected_architecture="$(print -r -- "$expected_architecture" | tr ' ' '\n' | sort | tr '\n' ' ')"
    if [[ "$architectures" != "$expected_architecture" ]]; then
        echo "Expected architectures $expected_architecture, found: $architectures" >&2
        exit 1
    fi
}

build_disk_image() {
    local build_architecture="$1"
    local asset_architecture="$2"
    local artifact_name="BrewPulse-$version-macos-$asset_architecture$artifact_suffix"
    local archive_path="$temporary_directory/$artifact_name.xcarchive"
    local app_path="$archive_path/Products/Applications/BrewPulse.app"
    local image_root="$temporary_directory/$artifact_name-image"
    local staged_dmg="$staging_directory/$artifact_name.dmg"
    local staged_checksum="$staging_directory/$artifact_name.dmg.sha256"
    local writable_dmg="$temporary_directory/$artifact_name-writable.dmg"
    local output_dmg="$artifact_directory/$artifact_name.dmg"
    local output_checksum="$artifact_directory/$artifact_name.dmg.sha256"
    local mount_point="$temporary_directory/dmg-$asset_architecture"
    local mounted_app
    local checksum

    xcodebuild \
        -project "$project_path" \
        -scheme BrewPulse \
        -configuration Release \
        -destination "generic/platform=macOS" \
        -archivePath "$archive_path" \
        -derivedDataPath "$derived_data_path" \
        -clonedSourcePackagesDirPath "$source_packages_path" \
        "MARKETING_VERSION=$version" \
        "CURRENT_PROJECT_VERSION=$build_number" \
        "BREWPULSE_ANALYTICS_INGESTION_URL=$analytics_ingestion_url" \
        "ARCHS=$build_architecture" \
        ONLY_ACTIVE_ARCH=NO \
        COMPILER_INDEX_STORE_ENABLE=NO \
        "${signing_arguments[@]}" \
        archive

    verify_app_bundle "$app_path" "$build_architecture"
    if [[ "$mode" == "unsigned" || "$mode" == "unsigned-preview" ]]; then
        sign_ad_hoc_app_bundle "$app_path"
        verify_ad_hoc_signature "$app_path"
    else
        verify_developer_id_signature "$app_path"
    fi
    verify_enhanced_security_entitlements "$app_path"

    mkdir -p "$image_root"
    ditto "$app_path" "$image_root/BrewPulse.app"
    ln -s /Applications "$image_root/Applications"
    mkdir -p "$image_root/.background"
    tiffutil -cathidpicheck \
        "$installer_background" \
        "$installer_background_2x" \
        -out "$image_root/.background/BrewPulseInstallerBackground.tiff"
    cp "$installer_layout_template" "$image_root/.DS_Store"
    hdiutil create \
        -quiet \
        -volname "BrewPulse" \
        -srcfolder "$image_root" \
        -fs HFS+ \
        -format UDRW \
        "$writable_dmg"

    hdiutil convert \
        -quiet \
        "$writable_dmg" \
        -format UDZO \
        -imagekey zlib-level=9 \
        -o "$staged_dmg"

    if [[ "$mode" != "unsigned" && "$mode" != "unsigned-preview" ]]; then
        codesign \
            --force \
            --sign "$BREWPULSE_SIGNING_IDENTITY" \
            --timestamp \
            "$staged_dmg"
        codesign --verify --strict --verbose=2 "$staged_dmg"
    fi

    if [[ "$mode" == "notarized" ]]; then
        local notary_profile="${BREWPULSE_NOTARY_PROFILE:-BrewPulse}"
        xcrun notarytool submit "$staged_dmg" \
            --keychain-profile "$notary_profile" \
            --wait
        xcrun stapler staple "$staged_dmg"
        xcrun stapler validate "$staged_dmg"
        spctl --assess \
            --type open \
            --context context:primary-signature \
            --verbose=2 \
            "$staged_dmg"
    fi

    mkdir -p "$mount_point"
    hdiutil attach \
        -quiet \
        -nobrowse \
        -readonly \
        -mountpoint "$mount_point" \
        "$staged_dmg"
    mounted_volume="$mount_point"
    mounted_app="$mount_point/BrewPulse.app"

    verify_app_bundle "$mounted_app" "$build_architecture"
    if [[ ! -L "$mount_point/Applications" || "$(readlink "$mount_point/Applications")" != "/Applications" ]]; then
        echo "The disk image does not contain an Applications shortcut." >&2
        exit 1
    fi
    if [[ ! -f "$mount_point/.DS_Store" ]]; then
        echo "The disk image does not contain its saved Finder layout." >&2
        exit 1
    fi
    if [[ ! -f "$mount_point/.background/BrewPulseInstallerBackground.tiff" ]]; then
        echo "The disk image does not contain its installer background." >&2
        exit 1
    fi
    if [[ "$mode" == "unsigned" || "$mode" == "unsigned-preview" ]]; then
        verify_ad_hoc_signature "$mounted_app"
    else
        verify_developer_id_signature "$mounted_app"
    fi
    verify_enhanced_security_entitlements "$mounted_app"
    if [[ "$mode" == "notarized" ]]; then
        spctl --assess \
            --type execute \
            --verbose=2 \
            "$mounted_app"
    fi

    hdiutil detach -quiet "$mount_point"
    mounted_volume=""

    checksum="$(shasum -a 256 "$staged_dmg" | awk '{ print $1 }')"
    print -r -- "$checksum  $(basename "$output_dmg")" > "$staged_checksum"

    echo "Prepared $staged_dmg"
    echo "Prepared $staged_checksum"
    echo "Architecture: $build_architecture"
}

generate_update_feed() {
    local appcast_directory="$temporary_directory/Appcast"
    local generate_appcast="$source_packages_path/artifacts/sparkle/Sparkle/bin/generate_appcast"
    local release_notes="$temporary_directory/release-notes.md"
    local download_url="https://github.com/ChrisRodStar/BrewPulse/releases/download/$release_tag/"
    local staged_dmg="$staging_directory/BrewPulse-$version-macos-universal$artifact_suffix.dmg"

    if [[ ! -x "$generate_appcast" ]]; then
        echo "Sparkle's generate_appcast tool was not found at $generate_appcast" >&2
        exit 1
    fi

    awk -v version="$version" '
        index($0, "## " version) == 1 { capture = 1; next }
        capture && /^## / { exit }
        capture { print }
    ' "$repository_root/CHANGELOG.md" > "$release_notes"

    if [[ ! -s "$release_notes" ]]; then
        echo "Could not extract release notes for $version from CHANGELOG.md." >&2
        exit 1
    fi

    mkdir -p "$appcast_directory"
    cp "$repository_root/appcast.xml" "$appcast_directory/appcast.xml"

    if [[ ! -f "$staged_dmg" ]]; then
        echo "The universal update disk image was not found at $staged_dmg" >&2
        exit 1
    fi

    local appcast_dmg="$appcast_directory/$(basename "$staged_dmg")"
    local release_notes_path="${appcast_dmg:r}.md"
    cp "$staged_dmg" "$appcast_dmg"
    cp "$release_notes" "$release_notes_path"

    "$generate_appcast" \
        --account "${BREWPULSE_SPARKLE_ACCOUNT:-ed25519}" \
        --disable-signing-warning \
        --download-url-prefix "$download_url" \
        --embed-release-notes \
        --maximum-deltas 0 \
        "$appcast_directory"

    xmllint --noout "$appcast_directory/appcast.xml"
    cp "$appcast_directory/appcast.xml" "$repository_root/appcast.xml"
    echo "Updated $repository_root/appcast.xml"
}

for architecture_spec in "${architecture_specs[@]}"; do
    build_architecture="${architecture_spec%%:*}"
    asset_architecture="${architecture_spec#*:}"
    build_disk_image "$build_architecture" "$asset_architecture"
done

if [[ "$mode" == "notarized" || "$mode" == "unsigned-preview" ]]; then
    generate_update_feed
fi

for staged_artifact in "$staging_directory"/*; do
    output_artifact="$artifact_directory/$(basename "$staged_artifact")"
    mv "$staged_artifact" "$output_artifact"
    echo "Created $output_artifact"
done

echo "Version: $version"
echo "Build: $build_number"
