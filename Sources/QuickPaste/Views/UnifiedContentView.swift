import SwiftUI
import KeyboardShortcuts

struct UnifiedContentView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var clipboardMonitor: ClipboardMonitor
    
    let focusSection: FocusSection
    let onDismiss: () -> Void
    let onPaste: (String) -> Void
    
    @State private var searchText = ""
    @State private var selectedItemID: String? = nil
    
    // Focus state for search bar
    @FocusState private var isSearchFocused: Bool
    
    // Using ScrollViewReader to auto-scroll
    @Namespace private var scrollSpace

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Search
            searchBar
            
            if !settings.quickActions.isEmpty {
                quickActionsRow
            }
            
            // Scrollable List
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        
                        if settings.showSnippets {
                            snippetsSection
                        }
                        
                        if settings.showSnippets && settings.showClipboard {
                            Divider()
                                .padding(.vertical, 4)
                        }
                        
                        if settings.showClipboard {
                            clipboardSection
                        }
                        
                        if !settings.showSnippets && !settings.showClipboard {
                            Text(tr("error_no_display", lang: settings.language))
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 40)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
                .onAppear {
                    isSearchFocused = true // Always focus search on appear
                    setupInitialFocus(scrollProxy: scrollProxy)
                }
                .onChange(of: filteredItems) { _ in
                    // Reset selection if list changes due to search or edits
                    if let firstId = filteredItems.first?.id {
                        selectedItemID = firstId
                    } else {
                        selectedItemID = nil
                    }
                }
                .onChange(of: selectedItemID) { newId in
                    // Auto-scroll when navigated via arrow keys
                    if let id = newId {
                        withAnimation {
                            scrollProxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
            
            // Footer
            footerView
        }
        .frame(width: 340, height: 440)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        // Observe key events routed from the NSPanel
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FloatingPanelKeyDown"))) { notification in
            handleKeyEvent(notification: notification)
        }
    }
    
    // MARK: - Data Source & Selection
    
    struct UnifiedItem: Identifiable, Equatable {
        let id: String
        let title: String
        let subtitle: String
        let content: String
        let icon: String
        let isSnippet: Bool
    }
    
    private var filteredItems: [UnifiedItem] {
        var items: [UnifiedItem] = []
        let query = searchText.lowercased()
        
        if settings.showSnippets {
            let snippets = query.isEmpty ? settings.snippets : settings.snippets.filter {
                $0.name.lowercased().contains(query) ||
                $0.content.lowercased().contains(query) ||
                $0.category.lowercased().contains(query)
            }
            items.append(contentsOf: snippets.map {
                UnifiedItem(id: "snippet_\($0.id)", title: $0.name, subtitle: $0.content, content: $0.content, icon: "doc.text", isSnippet: true)
            })
        }
        
        if settings.showClipboard {
            let clips = query.isEmpty ? clipboardMonitor.history : clipboardMonitor.history.filter {
                $0.content.lowercased().contains(query)
            }
            items.append(contentsOf: clips.map {
                UnifiedItem(id: "clip_\($0.id)", title: $0.preview, subtitle: $0.timeAgo, content: $0.content, icon: "clock", isSnippet: false)
            })
        }
        
        return items
    }
    
    private func setupInitialFocus(scrollProxy: ScrollViewProxy) {
        // Set selection based on hotkey focus request
        let targetId: String?
        if focusSection == .clipboard && settings.showClipboard && !clipboardMonitor.history.isEmpty {
            targetId = "clip_\(clipboardMonitor.history.first!.id)"
        } else if focusSection == .snippets && settings.showSnippets && !settings.snippets.isEmpty {
            targetId = "snippet_\(settings.snippets.first!.id)"
        } else {
            targetId = filteredItems.first?.id
        }
        
        selectedItemID = targetId
        
        if let targetId = targetId {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    scrollProxy.scrollTo(targetId, anchor: .center)
                }
            }
        }
    }
    
    // MARK: - Keyboard Navigation
    
    private func handleKeyEvent(notification: Notification) {
        guard let keyCode = notification.userInfo?["keyCode"] as? UInt16 else { return }
        let items = filteredItems
        guard !items.isEmpty else { return }
        
        if let currentIdx = items.firstIndex(where: { $0.id == selectedItemID }) {
            if keyCode == 125 { // Down arrow
                isSearchFocused = false
                let nextIdx = min(currentIdx + 1, items.count - 1)
                selectedItemID = items[nextIdx].id
            } else if keyCode == 126 { // Up arrow
                if currentIdx == 0 {
                    selectedItemID = nil // De-highlight list
                    isSearchFocused = true // Focus search input
                } else {
                    isSearchFocused = false
                    let prevIdx = max(currentIdx - 1, 0)
                    selectedItemID = items[prevIdx].id
                }
            } else if keyCode == 36 || keyCode == 76 { // Enter or Keypad Enter
                handleAction(for: items[currentIdx])
            }
        } else {
            if keyCode == 125 { // Down arrow from search
                isSearchFocused = false
                selectedItemID = items.first?.id
            } else if keyCode == 36 || keyCode == 76 {
                if let first = items.first {
                    handleAction(for: first)
                }
            }
        }
    }
    
    private func handleAction(for item: UnifiedItem) {
        // Copy to clipboard
        PasteService.shared.copyToClipboard(item.content)
        
        // Remove from list
        if item.isSnippet {
            if let index = settings.snippets.firstIndex(where: { "snippet_\($0.id)" == item.id }) {
                settings.removeSnippet(at: index)
            }
        } else {
            if let index = clipboardMonitor.history.firstIndex(where: { "clip_\($0.id)" == item.id }) {
                clipboardMonitor.history.remove(at: index)
            }
        }
        
        onDismiss()
    }

    // MARK: - Views
    
    private var quickActionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(settings.quickActions) { qa in
                    Text(qa.icon)
                        .font(.system(size: 24))
                        .frame(width: 44, height: 44)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(10)
                        .help(qa.name)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                        .onTapGesture {
                            handleAction(for: UnifiedItem(id: "qa_\(qa.id)", title: qa.name, subtitle: "", content: qa.content, icon: "bolt.fill", isSnippet: true))
                        }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }
    
    private var snippetsSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("SNIPPETS")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.tertiary)
                .padding(.leading, 4)
                .padding(.top, 6)
            
            let snippetItems = filteredItems.filter { $0.isSnippet }
            if snippetItems.isEmpty {
                Text(tr("no_snippets", lang: settings.language))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
                    .padding(.leading, 4)
            } else {
                ForEach(snippetItems) { item in
                    itemRow(item)
                }
            }
        }
    }
    
    private var clipboardSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("CLIPBOARD")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.tertiary)
                
                Spacer()
                
                Text("\(clipboardMonitor.history.count)/\(settings.maxClipboardHistory)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 4)
            .padding(.top, 6)
            
            let clipItems = filteredItems.filter { !$0.isSnippet }
            if clipItems.isEmpty {
                Text(tr("empty", lang: settings.language))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
                    .padding(.leading, 4)
            } else {
                ForEach(clipItems) { item in
                    itemRow(item)
                }
            }
        }
    }
    
    private func itemRow(_ item: UnifiedItem) -> some View {
        let isSelected = selectedItemID == item.id
        
        return HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                
                if item.isSnippet {
                    Text(item.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if !item.isSnippet {
                    Text(item.subtitle) // contains the timestamp (timeAgo)
                        .font(.system(size: 10))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.gray.opacity(0.8))
                }
                
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.gray)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        // Add hover effect if not selected
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.001))
                .onHover { hovering in
                    if hovering && selectedItemID != item.id {
                        // Optional hover functionality
                    }
                }
        )
        .onTapGesture {
            selectedItemID = item.id
            handleAction(for: item)
        }
        .id(item.id)
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("QuickPaste")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .help("Đóng (Esc)")
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)

            TextField(tr("search", lang: settings.language), text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isSearchFocused)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary.opacity(0.5))
        )
        // Add visual highlight when conceptually focused
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(selectedItemID == nil ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private var footerView: some View {
        HStack {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 10))
            Text(tr("move", lang: settings.language))
                .font(.system(size: 10))
            
            Spacer().frame(width: 12)
            
            Image(systemName: "return")
                .font(.system(size: 10))
            Text(tr("select", lang: settings.language))
                .font(.system(size: 10))
            
            Spacer()

            Button {
                onDismiss() // Hide the popup first
                NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(tr("settings", lang: settings.language))
        }
        .foregroundStyle(.tertiary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
