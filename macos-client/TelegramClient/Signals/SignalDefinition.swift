import Foundation

/// Represents a signal definition (keyword/pattern to detect)
struct SignalDefinition: Codable, Identifiable {
    let id: Int64
    var pattern: String
    var type: SignalType
    var category: String?
    var priority: Int
    var isActive: Bool
    var createdAt: Date

    enum SignalType: String, Codable {
        case keyword = "keyword"
        case regex = "regex"
        case phrase = "phrase"
        case custom = "custom"
    }

    init(id: Int64, pattern: String, type: SignalType = .keyword, category: String? = nil, priority: Int = 0) {
        self.id = id
        self.pattern = pattern
        self.type = type
        self.category = category
        self.priority = priority
        self.isActive = true
        self.createdAt = Date()
    }
}

/// Signal match result
struct SignalMatch: Identifiable {
    let id: Int64
    let signalId: Int64
    let messageId: Int64
    let chatId: Int64
    let context: String?
    let matchTimestamp: Date

    var displayText: String {
        return context ?? "Signal match detected"
    }
}
