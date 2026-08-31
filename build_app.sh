#!/bin/bash

# Exit on error
set -e

APP_NAME="QuickPaste"
BUNDLE_ID="com.lamnguyen.quickpaste"
VERSION="1.3.1"
BUILD_DIR=".build/release"
APP_DIR="${APP_NAME}.app"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"

echo "Building release binary..."
swift build -c release

echo "Creating App Bundle Directory Structure..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

echo "Copying binary..."
cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/"

echo "Copying icon..."
cp "Sources/QuickPaste/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/"

echo "Generating Info.plist..."
cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/> <!-- Hides icon from dock -->
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>QuickPaste uses Apple Events to paste into apps like the iOS Simulator where standard keystroke injection does not work.</string>
</dict>
</plist>
EOF

echo "Stripping quarantine attribute..."
# Quarantine (com.apple.quarantine) confuses TCC: a granted permission
# can be silently revoked when macOS re-evaluates the quarantined binary.
xattr -cr "$APP_DIR" 2>/dev/null || true

echo "Ad-hoc signing the app bundle..."
# Accessibility permission on macOS is tied to the code signature.
# An unsigned or inconsistently signed bundle will have its granted
# permission silently rejected at runtime even though System Settings
# still shows it as granted. Ad-hoc signing keeps the identity stable
# for a single build.
codesign --force --deep --sign - "$APP_DIR"

echo ""
echo "App Bundle created successfully at: ./$APP_DIR"
echo "You can now drag $APP_DIR to your /Applications folder."
echo ""
echo "=============================================================="
echo "IMPORTANT: permission reset required for paste to work"
echo "=============================================================="
echo "Accessibility permission is bound to the code signature. After"
echo "rebuilding, the old grant becomes invalid even though System"
echo "Settings may still show it as enabled."
echo ""
echo "Run this once to fully reset the permission, then launch the app"
echo "and re-grant when prompted:"
echo ""
echo "  tccutil reset Accessibility ${BUNDLE_ID}"
echo "  tccutil reset AppleEvents   ${BUNDLE_ID}"
echo ""
echo "To view runtime diagnostics from the app, open Console.app and"
echo "filter for '[QuickPaste]'."
echo ""

# ---- Package for distribution ----
echo "Packaging for distribution..."
rm -f "$ZIP_NAME"
ditto -c -k --keepParent "$APP_DIR" "$ZIP_NAME"
SHA=$(shasum -a 256 "$ZIP_NAME" | awk '{print $1}')
echo ""
echo "=============================================================="
echo "Distribution package ready"
echo "=============================================================="
echo "  File   : $ZIP_NAME"
echo "  SHA256 : $SHA"
echo ""
echo "Update Casks/quickpaste.rb with the new SHA256 and upload"
echo "$ZIP_NAME to the GitHub Release before publishing the Cask."
