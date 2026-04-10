# QuickPaste

QuickPaste is a fast, native macOS application designed to supercharge your workflow with lightning-fast text snippets, quick actions, and clipboard history.
It sits in your menu bar and features a sleek floating popup window that appears instantly wherever your cursor is, allowing you to paste your most-used content into any app with a single click or keyboard press.

## Features

- **Swift Keyboard Shortcuts**: Global customizable shortcuts (e.g., `Ctrl+V`) to bring up the UI.
- **Smart Floating Popup**: Appears directly where your mouse cursor is. Disappears when you click outside or press Escape.
- **Quick Actions**: Highly accessible mini-buttons for pinning emojis, generic symbols, or macros.
- **Rich Snippet Manager**: Catalog unlimited text snippets and organize them by categories.
- **Clipboard History Tracker**: Automatically tracks copied text and keeps a recent history up to 50 items.
- **Save from Clipboard**: Save any clipboard item directly to Snippets or Quick Actions with one click.
- **iOS Simulator Support**: Intelligent pasting logic bypasses Simulator restrictions.
- **Unified List & Keyboard Nav**: Search, filter, and use arrow keys to navigate and paste.
- **Bilingual Interface**: Seamlessly toggles between English and Tiếng Việt.
- **Lightweight & Native**: Built entirely in Swift using AppKit + SwiftUI.

## Installation

### Option A — Homebrew (recommended)

> **Note:** The app is not notarized (no Apple Developer ID). The Cask automatically runs `xattr -cr` after install to bypass Gatekeeper. macOS will still prompt for Accessibility permission on first launch — grant it and the app is ready.

**1. Add the tap**

```bash
brew tap lamnguyen7/quickpaste
```

**2. Install**

```bash
brew install --cask quickpaste
```

**3. First launch**

Open the app from `/Applications`. macOS will ask for Accessibility permission — grant it.

If the app still shows "damaged" or paste doesn't work, run:

```bash
bash /Applications/QuickPaste.app/Contents/Resources/first-run.sh
# or from the repo:
bash first-run.sh
```

---

### Option B — Download from GitHub Releases

1. Download the latest `QuickPaste-<version>.zip` from [Releases](../../releases).
2. Unzip and move `QuickPaste.app` to `/Applications`.
3. Run the first-run helper (included inside the zip):

```bash
bash first-run.sh
```

Or manually:

```bash
# Remove quarantine flag (fixes "damaged" error)
xattr -cr /Applications/QuickPaste.app

# Reset Accessibility permission so macOS re-prompts cleanly
tccutil reset Accessibility com.lamnguyen.quickpaste

# Launch
open /Applications/QuickPaste.app
```

---

### Option C — Build from source

```bash
git clone https://github.com/lamnguyen7/quickpaste.git
cd quickpaste
./build_app.sh
# Drag QuickPaste.app to /Applications
bash first-run.sh
```

## Requirements

- macOS 13.0 (Ventura) or newer
- Accessibility permission required for global hotkeys and paste injection

## Publishing a new Homebrew release (maintainer notes)

1. Bump `VERSION` in `build_app.sh`.
2. Run `./build_app.sh` — it prints the `SHA256` of the zip.
3. Upload `QuickPaste-<version>.zip` to the GitHub Release tagged `v<version>`.
4. Update `sha256` and `version` in `Casks/quickpaste.rb` in the **`homebrew-quickpaste`** tap repo.
5. Push the tap repo — users can now `brew upgrade --cask quickpaste`.

## License

MIT License
