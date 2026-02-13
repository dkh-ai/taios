import Foundation
import Combine

/// Detects signal matches in incoming messages
@MainActor
class DetectionEngine: ObservableObject {
    @Published var recentMatches: [SignalMatch] = []

    private let database: DatabaseManager
    private var signals: [SignalDefinition] = []

    init(database: DatabaseManager) {
        self.database = database
        loadSignals()
    }

    // MARK: - Public Methods

    /// Add a new signal to detect
    func addSignal(_ signal: SignalDefinition) {
        signals.append(signal)
        // TODO: Persist to database
    }

    /// Remove a signal
    func removeSignal(_ signalId: Int64) {
        signals.removeAll { $0.id == signalId }
        // TODO: Remove from database
    }

    /// Check if a message matches any signals
    func checkMessage(_ message: MessageManager.MessageModel) -> [SignalMatch] {
        var matches: [SignalMatch] = []

        for signal in signals where signal.isActive {
            if isMatch(message.content, pattern: signal.pattern, type: signal.type) {
                let match = SignalMatch(
                    id: Int64(Date().timeIntervalSince1970 * 1000),
                    signalId: signal.id,
                    messageId: message.id,
                    chatId: message.chatId,
                    context: extractContext(message.content, pattern: signal.pattern),
                    matchTimestamp: Date()
                )
                matches.append(match)

                // Record in database
                _ = database.recordSignalMatch(
                    signalId: signal.id,
                    messageId: message.id,
                    chatId: message.chatId,
                    context: match.context
                )
            }
        }

        if !matches.isEmpty {
            recentMatches.insert(contentsOf: matches, at: 0)
            // Keep only last 1000 matches in memory
            if recentMatches.count > 1000 {
                recentMatches.removeLast(recentMatches.count - 1000)
            }
        }

        return matches
    }

    /// Get all active signals
    func getActiveSignals() -> [SignalDefinition] {
        return signals.filter { $0.isActive }
    }

    // MARK: - Private Methods

    private func loadSignals() {
        // TODO: Load signals from database
    }

    private func isMatch(_ content: String, pattern: String, type: SignalDefinition.SignalType) -> Bool {
        switch type {
        case .keyword:
            return content.localizedCaseInsensitiveContains(pattern)

        case .phrase:
            return content.range(of: pattern, options: .caseInsensitive) != nil

        case .regex:
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(content.startIndex..<content.endIndex, in: content)
                return regex.firstMatch(in: content, range: range) != nil
            } catch {
                return false
            }

        case .custom:
            // TODO: Implement custom matching logic
            return false
        }
    }

    private func extractContext(_ content: String, pattern: String) -> String {
        // Extract surrounding text (50 chars before and after match)
        let contextLength = 50
        guard let range = content.range(of: pattern, options: .caseInsensitive) else {
            return content
        }

        let start = max(content.startIndex, content.index(range.lowerBound, offsetBy: -contextLength))
        let end = min(content.endIndex, content.index(range.upperBound, offsetBy: contextLength))

        return String(content[start..<end]).trimmingCharacters(in: .whitespaces)
    }
}
