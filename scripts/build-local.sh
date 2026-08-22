#!/bin/zsh

set -euo pipefail

script_directory="$(cd -- "$(dirname -- "$0")" && pwd)"
repository_root="$(dirname "$script_directory")"
configuration="${1:-Debug}"

case "$configuration" in
    Debug|Release) ;;
    *)
        echo "Usage: $0 [Debug|Release]" >&2
        exit 2
        ;;
esac

derived_data_path="${BREWPULSE_DERIVED_DATA_PATH:-$repository_root/build/local}"

if ! xcodebuild -version >/dev/null 2>&1; then
    echo "Select a full Xcode installation with xcode-select or set DEVELOPER_DIR, then try again." >&2
    exit 1
fi

xcodebuild \
    -project "$repository_root/macOS/BrewPulse.xcodeproj" \
    -scheme BrewPulse \
    -configuration "$configuration" \
    -destination "platform=macOS" \
    -derivedDataPath "$derived_data_path" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    COMPILER_INDEX_STORE_ENABLE=NO \
    build

app_path="$derived_data_path/Build/Products/$configuration/BrewPulse.app"
if [[ ! -d "$app_path" ]]; then
    echo "Build succeeded but BrewPulse.app was not found at $app_path" >&2
    exit 1
fi

echo "Built BrewPulse.app at $app_path"
