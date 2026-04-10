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
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
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
