#!/usr/bin/env bash
# Builds Crema.app (universal) into ./build.
#   ./build.sh            build only
#   ./build.sh --install  build and copy to /Applications
#   ./build.sh --release  build and zip to dist/Crema-<version>.zip (+ sha256)
set -euo pipefail
cd "$(dirname "$0")"

VERSION="1.0.0"
APP="build/Crema.app"
TMP="build/tmp"
rm -rf "$APP" "$TMP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$TMP"

for arch in arm64 x86_64; do
  swiftc -O -parse-as-library \
    -target "$arch-apple-macosx13.0" \
    -o "$TMP/Crema-$arch" \
    Sources/*.swift
done
lipo -create -output "$APP/Contents/MacOS/Crema" "$TMP/Crema-arm64" "$TMP/Crema-x86_64"

# App icon
swiftc -parse-as-library -o "$TMP/make-icon" Scripts/make-icon.swift Sources/Icons.swift
"$TMP/make-icon" "$TMP/icon.png"
ICONSET="$TMP/AppIcon.iconset"
mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z $s $s "$TMP/icon.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  sips -z $((s * 2)) $((s * 2)) "$TMP/icon.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Crema</string>
  <key>CFBundleDisplayName</key><string>Crema</string>
  <key>CFBundleIdentifier</key><string>com.theitger.crema</string>
  <key>CFBundleExecutable</key><string>Crema</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>© 2026 Tristan Heitger. MIT License.</string>
</dict>
</plist>
PLIST

rm -rf "$TMP"
codesign --force --sign - "$APP"
echo "Built $APP ($VERSION)"

case "${1:-}" in
  --install)
    rm -rf "/Applications/Crema.app"
    cp -R "$APP" /Applications/
    echo "Installed to /Applications"
    ;;
  --release)
    mkdir -p dist
    ZIP="dist/Crema-$VERSION.zip"
    rm -f "$ZIP"
    ditto -c -k --keepParent "$APP" "$ZIP"
    echo "Release: $ZIP"
    shasum -a 256 "$ZIP"
    ;;
esac
