import AppKit
import ApplicationServices

/// Centralized handling of Accessibility permission UX.
///
/// Ad-hoc signed apps frequently hit a state where System Settings shows
/// the permission as granted but `AXIsProcessTrusted()` keeps returning
/// false at runtime. The only reliable recovery is:
///   1. Reset the TCC entry for this bundle ID
///   2. Let the user re-grant to the current binary
///   3. Fully quit and relaunch so the new process picks up the grant
///
/// This helper guides the user through exactly that flow instead of
/// spamming the system prompt every time a paste is attempted.
enum PermissionGuide {
    static func showAlertOnce(hasShown: inout Bool) {
        guard !hasShown else { return }
        hasShown = true
        DispatchQueue.main.async {
            showAlert()
        }
    }

    static func showAlert() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "QuickPaste needs Accessibility permission"
        alert.informativeText = """
        Pasting requires Accessibility access so QuickPaste can send Cmd+V to the focused app.

        Steps:
          1. Click "Open Settings" below
          2. If QuickPaste is already listed, remove it with the "−" button
          3. Drag QuickPaste.app from /Applications into the list (or use "+")
          4. Turn the toggle ON
          5. Click "Quit & Relaunch" — this is REQUIRED, the running process cannot see the new grant until it is restarted

        If the permission keeps resetting, open Terminal and run:
            tccutil reset Accessibility com.lamnguyen.quickpaste
        then redo the steps above.
        """
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Quit & Relaunch")
        alert.addButton(withTitle: "Cancel")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            openAccessibilityPane()
        case .alertSecondButtonReturn:
            relaunchApp()
        default:
            break
        }
    }

    static func openAccessibilityPane() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Spawns a detached shell that waits briefly then relaunches the current
    /// app bundle, and terminates the current process. This is the only way
    /// the new process will observe a freshly granted TCC entry.
    static func relaunchApp() {
        let bundleURL = Bundle.main.bundleURL
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = [
            "-c",
            "sleep 0.5; /usr/bin/open \"\(bundleURL.path)\""
        ]
        try? task.run()
        NSApp.terminate(nil)
    }
}
