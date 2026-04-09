import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set as UIElement (accessory) so no Dock icon appears
        NSApp.setActivationPolicy(.accessory)
        
        // Check accessibility permissions
        checkAccessibilityPermissions()

        // Start clipboard monitoring
        ClipboardMonitor.shared.start()

        // Register global hotkeys via KeyboardShortcuts
        HotkeyManager.shared.onTrigger = { [weak self] focus in
            FloatingPanelController.shared.toggle(focus: focus)
        }
        HotkeyManager.shared.register()

        // Observe open settings request from UnifiedContentView
        NotificationCenter.default.addObserver(forName: NSNotification.Name("OpenSettings"), object: nil, queue: .main) { [weak self] _ in
            self?.showSettings()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        ClipboardMonitor.shared.stop()
        HotkeyManager.shared.unregister()
    }

    // MARK: - Accessibility

    private func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)

        if !trusted {
            // Show a helpful alert
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let alert = NSAlert()
                alert.messageText = "QuickPaste cần quyền Accessibility"
                alert.informativeText = """
                    Để sử dụng QuickPaste, bạn cần cấp quyền Accessibility:
                    
                    1. Mở System Settings → Privacy & Security → Accessibility
                    2. Bật QuickPaste trong danh sách
                    3. Khởi động lại QuickPaste
                    """
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Mở System Settings")
                alert.addButton(withTitle: "Để sau")

                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
            }
        }
    }

    // MARK: - Settings Window

    func showSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
            .environmentObject(AppSettings.shared)
            .environmentObject(ClipboardMonitor.shared)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 440),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "QuickPaste Settings"
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)

        self.settingsWindow = window
    }
}
