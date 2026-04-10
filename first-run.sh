#!/bin/bash
# first-run.sh — Run this once after installing QuickPaste.app to /Applications
# Usage: bash first-run.sh
set -e

APP="/Applications/QuickPaste.app"
BUNDLE_ID="com.lamnguyen.quickpaste"

if [ ! -d "$APP" ]; then
  echo "❌  QuickPaste.app not found in /Applications."
  echo "    Please move QuickPaste.app to /Applications first."
  exit 1
fi

echo "🔧  Removing quarantine attribute..."
xattr -cr "$APP"

echo "🔄  Resetting Accessibility permission (will be re-prompted on launch)..."
tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null || true

echo "✅  Done! Launching QuickPaste..."
open "$APP"
