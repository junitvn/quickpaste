import Foundation

struct QuickAction: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var icon: String
    var content: String

    init(id: String = UUID().uuidString, name: String, icon: String, content: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.content = content
    }
}
