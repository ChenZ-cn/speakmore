#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${APP_DIR:-$ROOT_DIR/build/SpeakMore-多说有益.app}"
DMG_PATH="${DMG_PATH:-$ROOT_DIR/dist/SpeakMore-internal.dmg}"
VOLUME_NAME="${VOLUME_NAME:-SpeakMore}"

"$ROOT_DIR/Scripts/build_app.sh"

rm -f "$DMG_PATH"
mkdir -p "$(dirname "$DMG_PATH")"

STAGE_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGE_DIR"' EXIT

cp -R "$APP_DIR" "$STAGE_DIR/SpeakMore-多说有益.app"
ln -s /Applications "$STAGE_DIR/Applications"

hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGE_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

echo "Built $DMG_PATH"
