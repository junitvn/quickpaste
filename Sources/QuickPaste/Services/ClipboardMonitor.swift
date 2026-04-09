import AppKit
import Foundation

class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()

    @Published var history: [ClipboardItem] = []

    private var timer: Timer?
    private var lastChangeCount: Int
    private let pasteboard: NSPasteboard

    private init() {
        self.pasteboard = .general
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        // Don't start twice
        guard timer == nil else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPasteboard() {
        let currentCount = pasteboard.changeCount

        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // Skip if this was an internal paste from QuickPaste
        if PasteService.shared.isInternalPaste { return }

        // Get the string content
        guard let content = pasteboard.string(forType: .string),
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Don't add duplicates at the top
        if let first = history.first, first.content == content { return }

        let item = ClipboardItem(content: content)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Remove any existing identical item
            self.history.removeAll { $0.content == content }
            // Insert at the beginning
            self.history.insert(item, at: 0)
            // Trim to max
            let max = AppSettings.shared.maxClipboardHistory
            if self.history.count > max {
                self.history = Array(self.history.prefix(max))
            }
        }
    }

    func clearHistory() {
        history.removeAll()
    }
}
