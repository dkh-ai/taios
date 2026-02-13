import Foundation
import Combine

/// Handles real-time updates from TDLib
@MainActor
class UpdateStreamHandler {
    typealias UpdateHandler = (String) -> Void

    private var handlers: [String: [UpdateHandler]] = [:]
    private let queue = DispatchQueue(label: "com.telegram.updates", attributes: .concurrent)

    // MARK: - Public Methods

    /// Subscribe to updates of a specific type
    /// - Parameters:
    ///   - updateType: Type of update (e.g., "updateNewMessage")
    ///   - handler: Closure called when update arrives
    func subscribe(to updateType: String, handler: @escaping UpdateHandler) {
        queue.async(flags: .barrier) {
            if self.handlers[updateType] == nil {
                self.handlers[updateType] = []
            }
            self.handlers[updateType]?.append(handler)
        }
    }

    /// Handle incoming update from TDLib
    func handleUpdate(_ updateJson: String) {
        guard let data = updateJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let updateType = json["@type"] as? String else {
            return
        }

        queue.async {
            let handlers = self.handlers[updateType] ?? []
            DispatchQueue.main.async {
                for handler in handlers {
                    handler(updateJson)
                }
            }
        }
    }

    /// Subscribe to all updates
    func subscribeToAll(handler: @escaping UpdateHandler) {
        queue.async(flags: .barrier) {
            if self.handlers["*"] == nil {
                self.handlers["*"] = []
            }
            self.handlers["*"]?.append(handler)
        }
    }
}
