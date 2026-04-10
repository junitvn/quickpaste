#!/bin/bash
#
# One-shot installer that solves the Accessibility-permission loop for
# ad-hoc signed builds. Run this every time after rebuilding.
#
# What it does:
#   1. Builds + signs a fresh app bundle via build_app.sh
#   2. Quits any running QuickPaste instance
#   3. Removes the old copy in /Applications
#   4. Copies the new bundle to /Applications
#   5. Strips quarantine from the installed copy
#   6. Resets the TCC permission entry so there's no stale grant
#   7. Opens System Settings > Accessibility and launches the new app
#
# After running:
#   - Click "+" in Accessibility, add /Applications/QuickPaste.app, turn it ON
#   - The app will show a dialog; click "Quit & Relaunch" so the fresh
#     process picks up the grant

set -e

APP_NAME="QuickPaste"
BUNDLE_ID="com.lamnguyen.quickpaste"
DEST="/Applications/${APP_NAME}.app"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"

echo "==> Building app bundle..."
./build_app.sh

echo ""
echo "==> Quitting any running instance..."
osascript -e "tell application \"${APP_NAME}\" to quit" 2>/dev/null || true
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 0.5

echo "==> Removing old installed copy..."
rm -rf "$DEST"

echo "==> Installing to /Applications..."
cp -R "${APP_NAME}.app" "$DEST"

echo "==> Stripping quarantine on installed copy..."
xattr -cr "$DEST" 2>/dev/null || true

echo "==> Resetting TCC entries..."
tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null || true
tccutil reset AppleEvents "$BUNDLE_ID" 2>/dev/null || true

echo "==> Opening Accessibility settings..."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
sleep 0.5

echo "==> Launching $APP_NAME..."
open "$DEST"

echo ""
echo "=============================================================="
echo "Next steps in the UI:"
echo "  1. In Accessibility settings, click '+' and add:"
echo "       $DEST"
echo "     (or drag the app icon into the list)"
echo "  2. Turn the toggle ON for QuickPaste"
echo "  3. In the QuickPaste dialog, click 'Quit & Relaunch'"
echo "  4. Try pasting — it should now work"
echo ""
echo "Diagnostics: Console.app, filter for '[QuickPaste]'"
echo "=============================================================="
