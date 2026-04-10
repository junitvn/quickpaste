#!/bin/bash

# Exit on error
set -e

APP_NAME="QuickPaste"
BUNDLE_ID="com.lamnguyen.quickpaste"
BUILD_DIR=".build/release"
APP_DIR="${APP_NAME}.app"

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
    <string>1.2.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/> <!-- Hides icon from dock -->
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "App Bundle created successfully at: ./$APP_DIR"
echo "You can now drag $APP_DIR to your /Applications folder."
