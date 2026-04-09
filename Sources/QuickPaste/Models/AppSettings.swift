import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let snippetsKey = "quickpaste_snippets"
    private let languageKey = "quickpaste_language"
    private let maxClipboardKey = "quickpaste_max_clipboard"
    private let launchAtLoginKey = "quickpaste_launch_at_login"
    private let showSnippetsKey = "quickpaste_show_snippets"
    private let showClipboardKey = "quickpaste_show_clipboard"
    private let quickActionsKey = "quickpaste_quick_actions"

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: languageKey) }
    }

    @Published var snippets: [Snippet] {
        didSet { saveSnippets() }
    }

    @Published var quickActions: [QuickAction] {
        didSet { saveQuickActions() }
    }

    @Published var maxClipboardHistory: Int {
        didSet { UserDefaults.standard.set(maxClipboardHistory, forKey: maxClipboardKey) }
    }

    @Published var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: launchAtLoginKey) }
    }

    @Published var showSnippets: Bool {
        didSet { UserDefaults.standard.set(showSnippets, forKey: showSnippetsKey) }
    }

    @Published var showClipboard: Bool {
        didSet { UserDefaults.standard.set(showClipboard, forKey: showClipboardKey) }
    }

    init() {
        if let langString = UserDefaults.standard.string(forKey: languageKey), let lang = AppLanguage(rawValue: langString) {
            self.language = lang
        } else {
            self.language = .vi // Default to Vietnamese
        }

        // Load max clipboard history
        let savedMax = UserDefaults.standard.integer(forKey: maxClipboardKey)
        self.maxClipboardHistory = savedMax > 0 ? savedMax : 5 // Default changed to 5

        // Load launch at login
        self.launchAtLogin = UserDefaults.standard.bool(forKey: launchAtLoginKey)

        // Load visibility toggles
        if UserDefaults.standard.object(forKey: showSnippetsKey) == nil {
            self.showSnippets = true
        } else {
            self.showSnippets = UserDefaults.standard.bool(forKey: showSnippetsKey)
        }

        if UserDefaults.standard.object(forKey: showClipboardKey) == nil {
            self.showClipboard = true
        } else {
            self.showClipboard = UserDefaults.standard.bool(forKey: showClipboardKey)
        }

        // Default values to satisfy pure initialization
        self.snippets = []
        self.quickActions = []

        // Now safe to call self methods
        self.snippets = loadSnippets()
        self.quickActions = loadQuickActions()
    }

    // MARK: - Snippets Persistence

    private func loadSnippets() -> [Snippet] {
        if let data = UserDefaults.standard.data(forKey: snippetsKey) {
            if let decoded = try? JSONDecoder().decode([Snippet].self, from: data) {
                return decoded
            }
        }
        return loadDefaultSnippets()
    }

    private func loadDefaultSnippets() -> [Snippet] {
        guard let url = Bundle.module.url(forResource: "default_snippets", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let snippets = try? JSONDecoder().decode([Snippet].self, from: data) else {
            return [
                Snippet(name: "📧 Email", category: "Thông tin", content: "yourname@gmail.com"),
                Snippet(name: "📱 SĐT", category: "Thông tin", content: "+84 123 456 789"),
            ]
        }
        return snippets
    }

    private func saveSnippets() {
        if let data = try? JSONEncoder().encode(snippets) {
            UserDefaults.standard.set(data, forKey: snippetsKey)
        }
    }

    func addSnippet(_ snippet: Snippet) {
        snippets.append(snippet)
    }

    func removeSnippet(at index: Int) {
        guard snippets.indices.contains(index) else { return }
        snippets.remove(at: index)
    }

    func updateSnippet(_ snippet: Snippet) {
        if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[index] = snippet
        }
    }

    func resetToDefaults() {
        snippets = loadDefaultSnippets()
        quickActions = loadDefaultQuickActions()
    }

    // MARK: - Quick Actions Persistence

    private func loadQuickActions() -> [QuickAction] {
        if let data = UserDefaults.standard.data(forKey: quickActionsKey) {
            if let decoded = try? JSONDecoder().decode([QuickAction].self, from: data) {
                return decoded
            }
        }
        return loadDefaultQuickActions()
    }

    private func loadDefaultQuickActions() -> [QuickAction] {
        return [
            QuickAction(name: "Vỗ tay", icon: "👏", content: "👏"),
            QuickAction(name: "Cười", icon: "😂", content: "😂"),
            QuickAction(name: "Tuyệt", icon: "👍", content: "👍"),
            QuickAction(name: "Email", icon: "📧", content: "yourname@gmail.com")
        ]
    }

    private func saveQuickActions() {
        if let data = try? JSONEncoder().encode(quickActions) {
            UserDefaults.standard.set(data, forKey: quickActionsKey)
        }
    }

    func addQuickAction(_ action: QuickAction) {
        quickActions.append(action)
    }

    func removeQuickAction(at index: Int) {
        guard quickActions.indices.contains(index) else { return }
        quickActions.remove(at: index)
    }

    func updateQuickAction(_ action: QuickAction) {
        if let index = quickActions.firstIndex(where: { $0.id == action.id }) {
            quickActions[index] = action
        }
    }
}
