import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var clipboardMonitor: ClipboardMonitor
    
    @State private var editingSnippet: Snippet?
    @State private var isAddingSnippet = false
    @State private var newName = ""
    @State private var newCategory = ""
    @State private var newContent = ""

    var body: some View {
        TabView {
            snippetsTab
                .tabItem {
                    Label(tr("tab_snippets", lang: settings.language), systemImage: "doc.text")
                }

            quickActionTab
                .tabItem {
                    Label(tr("tab_quick_action", lang: settings.language), systemImage: "bolt.square")
                }

            clipboardTab
                .tabItem {
                    Label(tr("tab_clipboard", lang: settings.language), systemImage: "clock")
                }

            generalTab
                .tabItem {
                    Label(tr("tab_general", lang: settings.language), systemImage: "gear")
                }
        }
        .frame(width: 520, height: 440)
    }

    // MARK: - Clipboard Tab
    private var clipboardTab: some View {
        VStack(spacing: 0) {
            HStack {
                Text(tr("clipboard_history", lang: settings.language))
                    .font(.headline)
                Spacer()
                Button {
                    clipboardMonitor.history.removeAll()
                } label: {
                    Label(tr("clear_clipboard", lang: settings.language), systemImage: "trash")
                }
            }
            .padding()

            Divider()

            ScrollViewReader { proxy in
                List {
                    ForEach(clipboardMonitor.history) { item in
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(item.content, forType: .string)
                            clipboardMonitor.history.removeAll { $0.id == item.id }
                            let moved = ClipboardItem(id: item.id, content: item.content)
                            clipboardMonitor.history.insert(moved, at: 0)
                            withAnimation {
                                proxy.scrollTo(clipboardMonitor.history.first?.id, anchor: .top)
                            }
                        } label: {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.preview)
                                        .font(.system(size: 13, weight: .medium))
                                    Text(item.content)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(item.timeAgo(lang: settings.language))
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 4)
                    }
                }
                .onChange(of: clipboardMonitor.history.first?.id) { _ in
                    proxy.scrollTo(clipboardMonitor.history.first?.id, anchor: .top)
                }
            }
        }
    }

    // MARK: - Quick Action Tab

    @State private var editingQuickAction: QuickAction?
    @State private var isAddingQuickAction = false
    @State private var newQAIcon = ""
    @State private var newQAName = ""
    @State private var newQAContent = ""

    private var quickActionTab: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text(tr("manage_qa", lang: settings.language))
                    .font(.headline)

                Spacer()

                Button {
                    newQAIcon = ""
                    newQAName = ""
                    newQAContent = ""
                    isAddingQuickAction = true
                } label: {
                    Label(tr("add", lang: settings.language), systemImage: "plus")
                }
            }
            .padding()

            Divider()

            List {
                ForEach(settings.quickActions) { action in
                    HStack {
                        Text(action.icon)
                            .font(.system(size: 20))
                            .frame(width: 32, height: 32)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(6)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(action.name)
                                .font(.system(size: 13, weight: .medium))
                            Text(action.content)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Button {
                            newQAIcon = action.icon
                            newQAName = action.name
                            newQAContent = action.content
                            editingQuickAction = action
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        settings.removeQuickAction(at: index)
                    }
                }
            }
        }
        .sheet(isPresented: $isAddingQuickAction) {
            quickActionEditor(
                title: tr("add_qa", lang: settings.language),
                icon: $newQAIcon,
                name: $newQAName,
                content: $newQAContent,
                onSave: {
                    let action = QuickAction(name: newQAName, icon: newQAIcon, content: newQAContent)
                    settings.addQuickAction(action)
                    isAddingQuickAction = false
                },
                onCancel: {
                    isAddingQuickAction = false
                }
            )
        }
        .sheet(item: $editingQuickAction) { action in
            quickActionEditor(
                title: tr("edit_qa", lang: settings.language),
                icon: $newQAIcon,
                name: $newQAName,
                content: $newQAContent,
                onSave: {
                    var updated = action
                    updated.icon = newQAIcon
                    updated.name = newQAName
                    updated.content = newQAContent
                    settings.updateQuickAction(updated)
                    editingQuickAction = nil
                },
                onCancel: {
                    editingQuickAction = nil
                }
            )
        }
    }

    private func quickActionEditor(
        title: String,
        icon: Binding<String>,
        name: Binding<String>,
        content: Binding<String>,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)

            Form {
                HStack {
                    Text(tr("icon_emoji", lang: settings.language))
                    TextField("🎯", text: icon)
                        .frame(width: 50)
                }
                TextField(tr("display_name", lang: settings.language), text: name)
                
                VStack(alignment: .leading) {
                    Text(tr("paste_content", lang: settings.language))
                    TextEditor(text: content)
                        .frame(height: 60)
                        .font(.system(size: 13, design: .monospaced))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            .formStyle(.grouped)

            HStack {
                Button(tr("cancel", lang: settings.language), action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button(tr("save", lang: settings.language), action: onSave)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.wrappedValue.isEmpty || content.wrappedValue.isEmpty || icon.wrappedValue.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 320)
    }

    // MARK: - Snippets Tab

    private var snippetsTab: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text(tr("manage_snippets", lang: settings.language))
                    .font(.headline)

                Spacer()

                Button {
                    newName = ""
                    newCategory = ""
                    newContent = ""
                    isAddingSnippet = true
                } label: {
                    Label(tr("add", lang: settings.language), systemImage: "plus")
                }

                Button {
                    settings.resetToDefaults()
                } label: {
                    Label(tr("reset", lang: settings.language), systemImage: "arrow.counterclockwise")
                }
            }
            .padding()

            Divider()

            // Snippet list
            List {
                ForEach(settings.snippets) { snippet in
                    snippetListRow(snippet)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        settings.removeSnippet(at: index)
                    }
                }
            }
        }
        .sheet(isPresented: $isAddingSnippet) {
            snippetEditor(
                title: tr("add_snippet", lang: settings.language),
                name: $newName,
                category: $newCategory,
                content: $newContent,
                onSave: {
                    let snippet = Snippet(name: newName, category: newCategory, content: newContent)
                    settings.addSnippet(snippet)
                    isAddingSnippet = false
                },
                onCancel: {
                    isAddingSnippet = false
                }
            )
        }
        .sheet(item: $editingSnippet) { snippet in
            EditSnippetSheet(snippet: snippet, settings: settings) {
                editingSnippet = nil
            }
        }
    }

    private func snippetListRow(_ snippet: Snippet) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.name)
                    .font(.system(size: 13, weight: .medium))

                HStack(spacing: 6) {
                    Text(snippet.category)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.accentColor.opacity(0.1))
                        )

                    Text(snippet.content)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                newName = snippet.name
                newCategory = snippet.category
                newContent = snippet.content
                editingSnippet = snippet
            } label: {
                Image(systemName: "pencil")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private func snippetEditor(
        title: String,
        name: Binding<String>,
        category: Binding<String>,
        content: Binding<String>,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)

            Form {
                TextField(tr("name", lang: settings.language), text: name)
                TextField(tr("category", lang: settings.language), text: category)

                VStack(alignment: .leading) {
                    Text(tr("content", lang: settings.language))
                    TextEditor(text: content)
                        .frame(height: 80)
                        .font(.system(size: 13, design: .monospaced))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            .formStyle(.grouped)

            HStack {
                Button(tr("cancel", lang: settings.language)) {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(tr("save", lang: settings.language)) {
                    onSave()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.wrappedValue.isEmpty || content.wrappedValue.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 320)
    }

    // MARK: - General Tab

    private var generalTab: some View {
        VStack(spacing: 0) {
        Form {
            Section(header: Text(tr("shortcuts", lang: settings.language))) {
                KeyboardShortcuts.Recorder(tr("open_snippets", lang: settings.language), name: .openSnippets)
                KeyboardShortcuts.Recorder(tr("open_clipboard", lang: settings.language), name: .openClipboard)
            }

            Section(tr("display", lang: settings.language)) {
                Toggle(tr("show_snippets", lang: settings.language), isOn: $settings.showSnippets)
                Toggle(tr("show_clipboard", lang: settings.language), isOn: $settings.showClipboard)
            }

            Section(tr("clipboard_history", lang: settings.language)) {
                HStack {
                    Text(tr("max_items", lang: settings.language))
                    Spacer()
                    Picker("", selection: $settings.maxClipboardHistory) {
                        ForEach([3, 5, 10, 15, 20, 30, 40, 50], id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    .frame(width: 80)
                }
            }

            Section(tr("info", lang: settings.language)) {
                HStack {
                    Text(tr("language", lang: settings.language))
                    Spacer()
                    Picker("", selection: $settings.language) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.rawValue).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }

                HStack {
                    Text("QuickPaste")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text("v1.2.0")
                        .foregroundStyle(.secondary)
                }
            }

        }
        .formStyle(.grouped)

        HStack(spacing: 4) {
            Spacer()
            Text("made by lamnn with")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            Image(systemName: "heart.fill")
                .font(.system(size: 10))
                .foregroundStyle(.pink.opacity(0.7))
            Spacer()
        }
        .padding(.vertical, 8)
        } // VStack
    }
}

// MARK: - Edit Snippet Sheet

struct EditSnippetSheet: View {
    let snippet: Snippet
    let settings: AppSettings
    let onDismiss: () -> Void

    @State private var name: String
    @State private var category: String
    @State private var content: String

    init(snippet: Snippet, settings: AppSettings, onDismiss: @escaping () -> Void) {
        self.snippet = snippet
        self.settings = settings
        self.onDismiss = onDismiss
        _name = State(initialValue: snippet.name)
        _category = State(initialValue: snippet.category)
        _content = State(initialValue: snippet.content)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(tr("edit_snippet", lang: settings.language))
                .font(.headline)

            Form {
                TextField(tr("name", lang: settings.language), text: $name)
                TextField(tr("category", lang: settings.language), text: $category)

                VStack(alignment: .leading) {
                    Text(tr("content", lang: settings.language))
                    TextEditor(text: $content)
                        .frame(height: 80)
                        .font(.system(size: 13, design: .monospaced))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            .formStyle(.grouped)

            HStack {
                Button(tr("cancel", lang: settings.language)) {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(tr("save", lang: settings.language)) {
                    var updated = snippet
                    updated.name = name
                    updated.category = category
                    updated.content = content
                    settings.updateSnippet(updated)
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || content.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 320)
    }
}
