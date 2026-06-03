import AppKit
import SwiftUI

// NSHostingView subclass that accepts the first mouse click immediately,
// so buttons work inside a nonactivatingPanel without needing a prior click.
class ClickThroughHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

class FloatingPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        // Panel configuration
        isFloatingPanel = true
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = false

        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Required for SwiftUI .onHover to work inside a nonactivatingPanel
        acceptsMouseMovedEvents = true

        // Rounded corners
        if let contentView = contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 12
            contentView.layer?.masksToBounds = true
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Keyboard keyCodes for the top-row digits 1...9, in order.
    static let numberKeyCodes: [UInt16] = [18, 19, 20, 21, 23, 22, 26, 28, 25]

    /// Maps a digit keyCode to its 1-based number (1...9), or nil.
    static func number(for keyCode: UInt16) -> Int? {
        guard let idx = numberKeyCodes.firstIndex(of: keyCode) else { return nil }
        return idx + 1
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown {
            if event.keyCode == 53 { // Escape
                close()
                return // Swallow the event
            } else if [125, 126, 36, 76].contains(event.keyCode) {
                // Forward arrow up/down and enter keys to SwiftUI view
                NotificationCenter.default.post(
                    name: NSNotification.Name("FloatingPanelKeyDown"),
                    object: nil,
                    userInfo: ["keyCode": event.keyCode]
                )
                return // Swallow the event so TextField doesn't move its internal text cursor vertically
            } else if event.modifierFlags.contains(.control),
                      FloatingPanel.numberKeyCodes.contains(event.keyCode) {
                // Forward Ctrl+<1-9> as a quick-select shortcut
                NotificationCenter.default.post(
                    name: NSNotification.Name("FloatingPanelKeyDown"),
                    object: nil,
                    userInfo: [
                        "keyCode": event.keyCode,
                        "control": true
                    ]
                )
                return // Swallow so it doesn't reach the TextField
            }
        }
        super.sendEvent(event)
    }

    // MARK: - Positioning

    func showAtMouseLocation() {
        let mouseLocation = NSEvent.mouseLocation

        let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
            ?? NSScreen.main ?? NSScreen.screens.first!

        let screenFrame = screen.visibleFrame
        let panelSize = frame.size

        var x = mouseLocation.x
        var y = mouseLocation.y - panelSize.height

        if x + panelSize.width > screenFrame.maxX {
            x = screenFrame.maxX - panelSize.width - 8
        }
        if x < screenFrame.minX {
            x = screenFrame.minX + 8
        }
        if y < screenFrame.minY {
            y = mouseLocation.y + 8
        }
        if y + panelSize.height > screenFrame.maxY {
            y = screenFrame.maxY - panelSize.height - 8
        }

        setFrameOrigin(NSPoint(x: x, y: y))
        makeKeyAndOrderFront(nil)
    }
}

// MARK: - Panel Controller

class FloatingPanelController: ObservableObject {
    static let shared = FloatingPanelController()

    private var panel: FloatingPanel?
    private var eventMonitor: Any?
    /// The app that was frontmost when the panel opened. We restore focus
    /// to it before pasting so Cmd+V reliably lands on the correct target,
    /// even if our own app was briefly activated during panel interaction.
    private var previousFrontmostApp: NSRunningApplication?

    @Published var isVisible = false

    func toggle(focus: FocusSection) {
        if isVisible {
            hide()
        } else {
            show(focus: focus)
        }
    }

    func show(focus: FocusSection) {
        hide()

        // Capture whichever app currently owns focus so we can paste into
        // it later. Skip ourselves in case the hotkey fires while our own
        // settings window happens to be active.
        let currentFrontmost = NSWorkspace.shared.frontmostApplication
        if currentFrontmost?.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousFrontmostApp = currentFrontmost
        }

        let panelWidth: CGFloat = 340
        let panelHeight: CGFloat = 440

        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
        )

        let contentView = UnifiedContentView(
            focusSection: focus,
            onDismiss: { [weak self] in
                self?.hide()
            },
            onPaste: { [weak self] text in
                guard let self = self else { return }
                let targetApp = self.previousFrontmostApp
                self.hide()
                self.pasteAfterRestoringFocus(text: text, targetApp: targetApp)
            }
        )
        .environmentObject(AppSettings.shared)
        .environmentObject(ClipboardMonitor.shared)

        panel.contentView = ClickThroughHostingView(rootView: contentView)
        panel.showAtMouseLocation()

        self.panel = panel
        isVisible = true

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, let panel = self.panel else { return }
            if !panel.frame.contains(NSEvent.mouseLocation) {
                self.hide()
            }
        }
    }

    func hide() {
        panel?.close()
        panel = nil
        isVisible = false

        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    /// Re-activates the target app, waits for the activation to actually
    /// take effect, then triggers the paste. Clicking inside a
    /// nonActivatingPanel packaged as a .app bundle can briefly steal
    /// focus to our own process, which would cause Cmd+V to be swallowed.
    private func pasteAfterRestoringFocus(text: String, targetApp: NSRunningApplication?) {
        guard let targetApp = targetApp else {
            // No captured target: fall back to a small delay and paste.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                PasteService.shared.paste(text)
            }
            return
        }

        // Explicitly re-activate the target app. If panel interaction never
        // stole focus this is a no-op; if it did, this restores it.
        targetApp.activate(options: [])

        // Poll briefly until the target is actually frontmost (max ~300ms),
        // then paste. This is far more reliable than a fixed delay.
        let deadline = Date().addingTimeInterval(0.3)
        func waitAndPaste() {
            if NSWorkspace.shared.frontmostApplication?.processIdentifier == targetApp.processIdentifier {
                PasteService.shared.paste(text)
            } else if Date() < deadline {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                    waitAndPaste()
                }
            } else {
                // Timed out: paste anyway, best effort.
                PasteService.shared.paste(text)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            waitAndPaste()
        }
    }
}
