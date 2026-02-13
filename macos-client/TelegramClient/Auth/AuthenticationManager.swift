import Foundation

/// Manages Telegram authentication flow and state
@MainActor
class AuthenticationManager {
    enum AuthError: LocalizedError {
        case invalidPhoneNumber
        case invalidCode
        case invalidPassword
        case networkError
        case unknownError(String)

        var errorDescription: String? {
            switch self {
            case .invalidPhoneNumber:
                return "Invalid phone number format"
            case .invalidCode:
                return "Invalid authentication code"
            case .invalidPassword:
                return "Invalid password for 2FA"
            case .networkError:
                return "Network connection error"
            case .unknownError(let msg):
                return "Error: \(msg)"
            }
        }
    }

    private let clientManager: TelegramClientManager

    init(clientManager: TelegramClientManager) {
        self.clientManager = clientManager
    }

    /// Start authentication with phone number
    func startAuthenticationWithPhoneNumber(_ phoneNumber: String) throws {
        // Validate phone number format
        let phoneRegex = "^\\+?[1-9]\\d{1,14}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)

        guard predicate.evaluate(with: phoneNumber) else {
            throw AuthError.invalidPhoneNumber
        }

        clientManager.authenticateWithPhoneNumber(phoneNumber)
    }

    /// Submit authentication code
    func submitAuthenticationCode(_ code: String) throws {
        guard !code.isEmpty else {
            throw AuthError.invalidCode
        }
        clientManager.submitAuthenticationCode(code)
    }

    /// Submit 2FA password
    func submitAuthenticationPassword(_ password: String) throws {
        guard !password.isEmpty else {
            throw AuthError.invalidPassword
        }
        clientManager.submitAuthenticationPassword(password)
    }

    /// Get current authentication state
    func getCurrentAuthState() -> AuthorizationState {
        return clientManager.getAuthorizationState()
    }

    /// Check if authenticated
    var isAuthenticated: Bool {
        return clientManager.isAuthorized
    }
}
