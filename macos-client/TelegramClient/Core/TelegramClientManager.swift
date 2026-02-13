import Foundation
import Combine

/// Represents authorization states
enum AuthorizationState: String {
    case waitTdlibParameters = "authorizationStateWaitTdlibParameters"
    case waitPhoneNumber = "authorizationStateWaitPhoneNumber"
    case waitCode = "authorizationStateWaitCode"
    case waitPassword = "authorizationStateWaitPassword"
    case ready = "authorizationStateReady"
    case loggingOut = "authorizationStateLoggingOut"
    case closing = "authorizationStateClosing"
    case closed = "authorizationStateClosed"
    case unknown = "unknown"

    init(from string: String) {
        if let state = AuthorizationState(rawValue: string) {
            self = state
        } else {
            self = .unknown
        }
    }
}

/// Manages Telegram client lifecycle and operations
@MainActor
class TelegramClientManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var authorizationState: AuthorizationState = .waitTdlibParameters
    @Published var isReady = false

    private let bridge: TdBridge
    private let queue = DispatchQueue(label: "com.telegram.client.queue", attributes: .concurrent)
    private var updateSubscribers: [PassthroughSubject<String, Never>] = []

    // MARK: - Singleton

    private static let shared = TelegramClientManager()

    override private init() {
        self.bridge = TdBridge.getInstance()
        super.init()

        // Setup update handler
        setupUpdateHandler()
    }

    static func getInstance() -> TelegramClientManager {
        return shared
    }

    // MARK: - Public Methods

    /// Initialize TDLib with parameters
    func initializeWithParameters(
        apiId: Int32,
        apiHash: String,
        databaseDirectory: String,
        filesDirectory: String
    ) {
        let query = [
            "@type": "setTdlibParameters",
            "parameters": [
                "api_id": apiId,
                "api_hash": apiHash,
                "use_message_database": true,
                "use_secret_chats": true,
                "use_file_database": true,
                "use_chat_info_database": true,
                "use_user_database": true,
                "use_minithumbnail": true,
                "use_test_dc": false,
                "database_directory": databaseDirectory,
                "files_directory": filesDirectory,
                "use_file_database": true,
                "use_chat_info_database": true,
                "use_user_database": true,
                "use_secret_chats": true
            ] as [String: Any]
        ] as [String: Any]

        if let jsonData = try? JSONSerialization.data(withJSONObject: query),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            _ = bridge.send(jsonString)
        }
    }

    /// Send a query to TDLib
    func sendQuery(_ query: [String: Any]) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: query),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            bridge.send(jsonString)
        }
    }

    /// Authenticate with phone number
    func authenticateWithPhoneNumber(_ phoneNumber: String) {
        let query: [String: Any] = [
            "@type": "setAuthenticationPhoneNumber",
            "phone_number": phoneNumber
        ]
        sendQuery(query)
    }

    /// Submit authentication code
    func submitAuthenticationCode(_ code: String) {
        let query: [String: Any] = [
            "@type": "checkAuthenticationCode",
            "code": code
        ]
        sendQuery(query)
    }

    /// Submit authentication password (for 2FA)
    func submitAuthenticationPassword(_ password: String) {
        let query: [String: Any] = [
            "@type": "checkAuthenticationPassword",
            "password": password
        ]
        sendQuery(query)
    }

    /// Get current authorization state
    func getAuthorizationState() -> AuthorizationState {
        return authorizationState
    }

    /// Logout the current user
    func logout() {
        let query: [String: Any] = ["@type": "logOut"]
        sendQuery(query)
    }

    /// Shutdown the client
    func shutdown() {
        let query: [String: Any] = ["@type": "close"]
        sendQuery(query)
        bridge.shutdown()
    }

    // MARK: - Private Methods

    private func setupUpdateHandler() {
        bridge.setUpdateCallback { [weak self] updateJson in
            DispatchQueue.main.async {
                self?.handleUpdate(updateJson)
            }
        }
    }

    private func handleUpdate(_ updateJson: String) {
        guard let data = updateJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["@type"] as? String else {
            return
        }

        // Handle authorization state updates
        if type == "updateAuthorizationState" {
            if let state = json["authorization_state"] as? [String: Any],
               let stateType = state["@type"] as? String {
                let newState = AuthorizationState(from: stateType)
                authorizationState = newState
                isAuthorized = (newState == .ready)
                isReady = isAuthorized
            }
        }

        // Notify subscribers
        for subscriber in updateSubscribers {
            subscriber.send(updateJson)
        }
    }

    /// Subscribe to updates
    func subscribeToUpdates() -> AnyPublisher<String, Never> {
        let subject = PassthroughSubject<String, Never>()
        queue.async(flags: .barrier) { [weak self] in
            self?.updateSubscribers.append(subject)
        }
        return subject.eraseToAnyPublisher()
    }

    deinit {
        shutdown()
    }
}
