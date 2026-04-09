import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    // Default to Ctrl+V
    static let openSnippets = Self("openSnippets", default: .init(.v, modifiers: [.control]))
    // Default to Ctrl+Shift+V
    static let openClipboard = Self("openClipboard", default: .init(.v, modifiers: [.control, .shift]))
}
