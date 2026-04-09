import Foundation

struct ClipboardItem: Identifiable, Hashable {
    let id: String
    let content: String
    let timestamp: Date

    init(id: String = UUID().uuidString, content: String, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
    }

    var timeAgo: String {
        timeAgo(lang: .vi)
    }

    func timeAgo(lang: AppLanguage) -> String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 {
            return tr("time_just_now", lang: lang)
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return String(format: tr("time_minutes_ago", lang: lang), minutes)
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return String(format: tr("time_hours_ago", lang: lang), hours)
        } else {
            let days = Int(interval / 86400)
            return String(format: tr("time_days_ago", lang: lang), days)
        }
    }

    var preview: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 80 {
            return String(trimmed.prefix(80)) + "…"
        }
        return trimmed
    }
}
