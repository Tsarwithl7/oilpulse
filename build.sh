#!/usr/bin/env bash
set -euo pipefail

APP_NAME="OilPulse"
BUNDLE="${APP_NAME}.app"

echo "▶ Building ${APP_NAME} (release)…"
swift build -c release 2>&1

BINARY=".build/release/${APP_NAME}"

if [ ! -f "$BINARY" ]; then
    echo "✗ Build failed: binary not found at $BINARY"
    exit 1
fi

echo "▶ Packaging ${BUNDLE}…"
rm -rf "${BUNDLE}"
mkdir -p "${BUNDLE}/Contents/MacOS"
mkdir -p "${BUNDLE}/Contents/Resources"

cp "$BINARY"              "${BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${BUNDLE}/Contents/Info.plist"

# Make the binary executable
chmod +x "${BUNDLE}/Contents/MacOS/${APP_NAME}"

# Ad-hoc sign so macOS allows notification permissions
echo "▶ Signing ${BUNDLE} (ad-hoc)…"
codesign --force --deep --sign - "${BUNDLE}"

echo "✓ Done → ${BUNDLE}"
echo ""
echo "Run with:  open ${BUNDLE}"
echo "Or double-click ${BUNDLE} in Finder."
