import Foundation

struct Snippet: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var category: String
    var content: String

    init(id: String = UUID().uuidString, name: String, category: String, content: String) {
        self.id = id
        self.name = name
        self.category = category
        self.content = content
    }
}
