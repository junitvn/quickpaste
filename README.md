# QuickPaste

QuickPaste is a fast, native macOS application designed to supercharge your workflow with lightning-fast text snippets, quick actions, and clipboard history. 
It sits in your menu bar and features a sleek floating popup window that appears instantly wherever your cursor is, allowing you to paste your most-used content into any app with a single click or keyboard press.

## Features

- **Swift Keyboard Shortcuts**: Uses global customizable shortcuts (e.g., `Cmd+Shift+V`) to bring up the UI.
- **Smart Floating Popup**: Appears directly where your mouse cursor is focused. Disappears when you click outside or press Escape.
- **Quick Actions**: Highly accessible mini-buttons for pinning emojis, generic symbols, or macros. Custom configurable!
- **Rich Snippet Manager**: Catalog unlimited text snippets (e.g., emails, phone numbers, standard replies) and organize them by categories.
- **Clipboard History Tracker**: Automatically tracks copied text and keeps a recent history up to 50 items.
- **iOS Simulator Support**: Intelligent pasting logic natively bypasses Simulator restrictions and drops text perfectly into Xcode iOS Simulator fields.
- **Unified List & Keyboard Nav**: Search, filter, and use your arrow keys (`Up`/`Down`/`Enter`) to navigate the popup and paste directly.
- **Bilingual Interface**: Seamlessly toggles between English and Tiếng Việt (Vietnamese).
- **Lightweight & Native**: Re-designed completely in Swift 5, utilizing raw AppKit window management paired with SwiftUI styling.

## Installation

You can build and run QuickPaste right away from source, or package it into a standard macOS `.app` bundle.

### Running from source

1. Clone the repository and navigate to the root directory `quickpaste/`.
2. Ensure you have the latest Xcode or Swift CLI installed.
3. Run the app directly using Swift Package Manager:
   ```bash
   swift run
   ```

### Packaging into a `.app` bundle

To convert the raw binary into a proper native macOS application suitable for installation into `/Applications`, run the provided `build_app.sh` script:

```bash
chmod +x build_app.sh
./build_app.sh
```

A fully standalone `QuickPaste.app` will be generated in your current folder. You can drag and drop it into your `Applications` folder!

### Download from GitHub Releases

1. Download the latest `QuickPaste.app.zip` from [Releases](../../releases).
2. Unzip and move `QuickPaste.app` to `/Applications`.
3. Since the app is not notarized, macOS will show **"QuickPaste is damaged and can't be opened"**. To fix this, open Terminal and run:
   ```bash
   xattr -cr /Applications/QuickPaste.app
   ```
4. Open the app normally.

## Requirements

- **Permissions**: The app requires macOS Accessibility Permissions (`System Preferences > Privacy & Security > Accessibility`) to paste text and register global hotkeys. 
- macOS 13.0 (Ventura) or newer natively supported.

## License

MIT License
