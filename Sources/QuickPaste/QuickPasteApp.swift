import SwiftUI

@main
struct QuickPasteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var clipboardMonitor = ClipboardMonitor.shared

    var body: some Scene {
        // Menu bar icon
        MenuBarExtra {
            menuContent
        } label: {
            Image(systemName: "doc.on.clipboard")
        }

        // Settings window (accessible from menu bar)
        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(clipboardMonitor)
        }
    }

    @ViewBuilder
    private var menuContent: some View {
        Button(tr("menu_open", lang: settings.language)) {
            FloatingPanelController.shared.show(focus: .snippets)
        }
        .keyboardShortcut("v", modifiers: .control)

        Divider()

        if !settings.quickActions.isEmpty {
            Menu("⚡️ Quick Actions") {
                ForEach(settings.quickActions) { qa in
                    Button("\(qa.icon)  \(qa.name)") {
                        PasteService.shared.paste(qa.content)
                    }
                }
            }
        }

        if !settings.snippets.isEmpty {
            Menu("📋 Snippets") {
                ForEach(settings.snippets) { snippet in
                    Button(snippet.name) {
                        PasteService.shared.paste(snippet.content)
                    }
                }
            }
        }

        if !clipboardMonitor.history.isEmpty {
            Menu("🕒 " + tr("clipboard_history", lang: settings.language)) {
                ForEach(clipboardMonitor.history.prefix(15)) { item in
                    Button(item.preview) {
                        PasteService.shared.paste(item.content)
                    }
                }
                Divider()
                Button(tr("clear_clipboard", lang: settings.language)) {
                    clipboardMonitor.history.removeAll()
                }
            }
        }

        Divider()

        Button(tr("menu_settings", lang: settings.language)) {
            appDelegate.showSettings()
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button(tr("menu_quit", lang: settings.language)) {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
