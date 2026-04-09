import AppKit
import KeyboardShortcuts

enum FocusSection {
    case snippets
    case clipboard
}

class HotkeyManager {
    static let shared = HotkeyManager()

    var onTrigger: ((FocusSection) -> Void)?

    private init() {}

    func register() {
        KeyboardShortcuts.onKeyUp(for: .openSnippets) { [weak self] in
            self?.onTrigger?(.snippets)
        }

        KeyboardShortcuts.onKeyUp(for: .openClipboard) { [weak self] in
            self?.onTrigger?(.clipboard)
        }
    }

    func unregister() {
        KeyboardShortcuts.removeAllHandlers()
    }
}
