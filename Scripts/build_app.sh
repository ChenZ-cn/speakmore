#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
APP_DIR="${APP_DIR:-$ROOT_DIR/build/SpeakMore-多说有益.app}"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"
swift build -c "$CONFIGURATION"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp ".build/$CONFIGURATION/SpeakMore" "$MACOS_DIR/SpeakMore"
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
localized_resources=(Resources/*.lproj)
if (( ${#localized_resources[@]} > 0 )); then
    cp -R "${localized_resources[@]}" "$RESOURCES_DIR/"
fi
chmod +x "$MACOS_DIR/SpeakMore"

if command -v codesign >/dev/null 2>&1; then
    SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-}"
    if [[ -z "$SIGN_IDENTITY" ]] && command -v security >/dev/null 2>&1; then
        SIGN_IDENTITY="$(security find-identity -v -p codesigning | awk -F '"' '/"/ { print $2; exit }')"
    fi

    if [[ -n "$SIGN_IDENTITY" ]]; then
        codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_DIR" >/dev/null
    else
        codesign --force --deep --sign - "$APP_DIR" >/dev/null
    fi
fi

echo "Built $APP_DIR"
