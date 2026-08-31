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
    /// `AXIsProcessTrusted()` can read stale immediately after the grant is
    /// made — `tccd` needs a brief moment to propagate it to the process
    /// asking. This shows up right after "Quit & Relaunch", and even more
    /// often on a login-item launch, which starts earlier in the boot/login
    /// sequence than an interactive launch. Retry briefly on the main queue
    /// before treating a `false` reading as final, instead of immediately
    /// prompting the user to re-grant a permission they already granted.
    static func isTrustedWithRetry(
        attempts: Int = 6,
        interval: TimeInterval = 0.25,
        completion: @escaping (Bool) -> Void
    ) {
        if AXIsProcessTrusted() {
            completion(true)
            return
        }
        guard attempts > 1 else {
            completion(false)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            isTrustedWithRetry(attempts: attempts - 1, interval: interval, completion: completion)
        }
    }

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
            "sleep 1.0; /usr/bin/open \"\(bundleURL.path)\""
        ]
        try? task.run()
        NSApp.terminate(nil)
    }
}
