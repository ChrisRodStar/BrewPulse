#!/bin/zsh

set -euo pipefail

script_directory="$(cd -- "$(dirname -- "$0")" && pwd)"
repository_root="$(dirname "$script_directory")"
project_path="$repository_root/macOS/BrewPulse.xcodeproj"
scheme="BrewPulse"

if [[ -n "${BREWPULSE_VALIDATION_ROOT:-}" ]]; then
    validation_root="$BREWPULSE_VALIDATION_ROOT"
    mkdir -p "$validation_root"
else
    validation_root="$(mktemp -d "${TMPDIR:-/tmp}/BrewPulseValidation.XXXXXX")"
    trap 'rm -rf "$validation_root"' EXIT
fi

derived_data_path="$validation_root/DerivedData"
result_bundle_path="$validation_root/BrewPulseTests.xcresult"

if [[ -z "${DEVELOPER_DIR:-}" ]]; then
    for xcode_app in /Applications/Xcode_27.0.app /Applications/Xcode-beta.app /Applications/Xcode.app; do
        candidate_developer_directory="$xcode_app/Contents/Developer"
        if [[ -x "$candidate_developer_directory/usr/bin/xcodebuild" ]] && \
            DEVELOPER_DIR="$candidate_developer_directory" xcodebuild -version 2>/dev/null | grep -Eq '^Xcode 27([.]|$)'; then
            export DEVELOPER_DIR="$candidate_developer_directory"
            break
        fi
    done
fi

if ! xcodebuild -version >"$validation_root/xcode-version.txt" 2>&1; then
    echo "Select a full Xcode installation with xcode-select or set DEVELOPER_DIR, then try again." >&2
    exit 1
fi

cat "$validation_root/xcode-version.txt"
grep -Eq '^Xcode 27([.]|$)' "$validation_root/xcode-version.txt"
swift --version

plutil -lint "$project_path/project.pbxproj"

xcodebuild \
    -project "$project_path" \
    -scheme "$scheme" \
    -configuration Debug \
    -destination "platform=macOS" \
    -derivedDataPath "$derived_data_path" \
    -resultBundlePath "$result_bundle_path" \
    CODE_SIGNING_ALLOWED=NO \
    COMPILER_INDEX_STORE_ENABLE=NO \
    test

xcodebuild \
    -project "$project_path" \
    -scheme "$scheme" \
    -configuration Release \
    -destination "platform=macOS" \
    -derivedDataPath "$derived_data_path" \
    CODE_SIGNING_ALLOWED=NO \
    COMPILER_INDEX_STORE_ENABLE=NO \
    build

xcodebuild \
    -project "$project_path" \
    -scheme "$scheme" \
    -configuration Debug \
    -destination "platform=macOS" \
    -derivedDataPath "$derived_data_path" \
    CODE_SIGNING_ALLOWED=NO \
    COMPILER_INDEX_STORE_ENABLE=NO \
    analyze

echo "BrewPulse validation passed."
