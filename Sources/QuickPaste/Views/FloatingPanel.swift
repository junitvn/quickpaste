import AppKit
import SwiftUI

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
                self?.hide()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    PasteService.shared.paste(text)
                }
            }
        )
        .environmentObject(AppSettings.shared)
        .environmentObject(ClipboardMonitor.shared)

        panel.contentView = NSHostingView(rootView: contentView)
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
}
