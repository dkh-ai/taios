import Foundation
import Combine

/// Manages alerts for signal matches
@MainActor
class AlertManager: ObservableObject {
    @Published var alerts: [Alert] = []
    @Published var unreadCount = 0

    private let detectionEngine: DetectionEngine

    struct Alert: Identifiable {
        let id: UUID
        let signalMatch: SignalMatch
        let message: String
        let timestamp: Date
        var isRead = false
        var priority: Int = 0

        var displayTitle: String {
            return "Signal Detected"
        }

        var displayMessage: String {
            return signalMatch.context ?? message
        }
    }

    init(detectionEngine: DetectionEngine) {
        self.detectionEngine = detectionEngine
    }

    // MARK: - Public Methods

    /// Handle a signal match by creating an alert
    func handleSignalMatch(_ match: SignalMatch, message: String) {
        let alert = Alert(
            id: UUID(),
            signalMatch: match,
            message: message,
            timestamp: Date(),
            priority: 1
        )

        alerts.insert(alert, at: 0)
        unreadCount += 1

        // Keep only last 500 alerts
        if alerts.count > 500 {
            alerts.removeLast(alerts.count - 500)
        }

        // TODO: Send system notification
    }

    /// Mark alert as read
    func markAsRead(_ alertId: UUID) {
        if let index = alerts.firstIndex(where: { $0.id == alertId }) {
            alerts[index].isRead = true
            updateUnreadCount()
        }
    }

    /// Clear all alerts
    func clearAllAlerts() {
        alerts.removeAll()
        unreadCount = 0
    }

    /// Delete alert
    func deleteAlert(_ alertId: UUID) {
        alerts.removeAll { $0.id == alertId }
        updateUnreadCount()
    }

    /// Get alerts for a specific signal
    func getAlertsForSignal(_ signalId: Int64) -> [Alert] {
        return alerts.filter { $0.signalMatch.signalId == signalId }
    }

    // MARK: - Private Methods

    private func updateUnreadCount() {
        unreadCount = alerts.filter { !$0.isRead }.count
    }
}
