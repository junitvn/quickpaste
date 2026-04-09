import AppKit
import Carbon

class PasteService {
    static let shared = PasteService()

    /// Flag to indicate QuickPaste itself is changing the pasteboard
    /// so ClipboardMonitor can ignore it
    var isInternalPaste = false

    func paste(_ text: String) {
        isInternalPaste = true

        // 1. Set text to pasteboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // 2. Perform paste using the appropriate method for the active app
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            guard let self = self else { return }
            
            if self.isSimulatorActive() {
                self.pasteIntoSimulator()
            } else {
                self.simulateCmdV()
            }

            // Reset flag after paste completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isInternalPaste = false
            }
        }
    }

    func copyToClipboard(_ text: String) {
        isInternalPaste = true
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isInternalPaste = false
        }
    }

    // MARK: - App Detection

    private func isSimulatorActive() -> Bool {
        if let frontmostApp = NSWorkspace.shared.frontmostApplication {
            return frontmostApp.bundleIdentifier == "com.apple.iphonesimulator"
        }
        return false
    }

    // MARK: - Paste Methods

    private func pasteIntoSimulator() {
        // AppleScript reliably sends the keystroke to the focused application bypassing lower-level interceptions
        let scriptSource = """
        tell application "System Events"
            keystroke "v" using command down
        end tell
        """
        
        if let script = NSAppleScript(source: scriptSource) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript paste error: \(error)")
            }
        }
    }

    private func simulateCmdV() {
        let source = CGEventSource(stateID: .hidSystemState)
        source?.localEventsSuppressionInterval = 0.0

        // Key code for 'V' is 9 (0x09)
        let vKeyCode: CGKeyCode = 9

        // Command key down
        guard let cmdVDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true) else { return }
        cmdVDown.flags = .maskCommand

        guard let cmdVUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else { return }
        cmdVUp.flags = .maskCommand

        // Post events
        let tap = CGEventTapLocation.cghidEventTap
        cmdVDown.post(tap: tap)
        cmdVUp.post(tap: tap)
    }
}
