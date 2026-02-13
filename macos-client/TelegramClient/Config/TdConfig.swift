import Foundation

/// Telegram API Configuration
struct TdConfig {
    /// Your Telegram API ID
    /// Get it from https://core.telegram.org/api/obtaining_api_id
    static let apiId: Int32 = 0 // TODO: Replace with your API ID

    /// Your Telegram API Hash
    /// Get it from https://core.telegram.org/api/obtaining_api_id
    static let apiHash = "" // TODO: Replace with your API hash

    /// Application name
    static let appName = "CustomTelegramClient"

    /// Application version
    static let appVersion = "1.0.0"

    /// Device model
    static let deviceModel = "macOS Client"

    /// System version
    static let systemVersion: String = {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }()

    /// Telegram server DC (data center)
    /// false = production, true = test DC
    static let useTestDC = false

    /// Enable message database
    static let useMessageDatabase = true

    /// Enable secret chats
    static let useSecretChats = true

    /// Enable file database
    static let useFileDatabase = true

    /// Enable chat info database
    static let useChatInfoDatabase = true

    /// Enable user database
    static let useUserDatabase = true

    /// Enable mini thumbnails
    static let useMiniThumbnail = true

    /// Database directory path
    static var databaseDirectory: String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let appSupportPath = paths[0]
        let appPath = (appSupportPath as NSString).appendingPathComponent("TelegramClient")
        let dbPath = (appPath as NSString).appendingPathComponent("database")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(atPath: dbPath, withIntermediateDirectories: true)

        return dbPath
    }

    /// Files directory path
    static var filesDirectory: String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let appSupportPath = paths[0]
        let appPath = (appSupportPath as NSString).appendingPathComponent("TelegramClient")
        let filesPath = (appPath as NSString).appendingPathComponent("files")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(atPath: filesPath, withIntermediateDirectories: true)

        return filesPath
    }

    /// Build TDLib parameters dictionary
    static func buildParameters() -> [String: Any] {
        return [
            "@type": "setTdlibParameters",
            "parameters": [
                "@type": "tdlibParameters",
                "use_test_dc": useTestDC,
                "database_directory": databaseDirectory,
                "files_directory": filesDirectory,
                "use_file_database": useFileDatabase,
                "use_chat_info_database": useChatInfoDatabase,
                "use_message_database": useMessageDatabase,
                "use_secret_chats": useSecretChats,
                "api_id": apiId,
                "api_hash": apiHash,
                "system_language_code": Locale.current.languageCode ?? "en",
                "device_model": deviceModel,
                "system_version": systemVersion,
                "application_version": appVersion,
                "enable_storage_optimizer": true,
                "use_minithumbnail": useMiniThumbnail
            ] as [String: Any]
        ]
    }

    /// Validate configuration
    static func validate() -> Bool {
        if apiId == 0 {
            print("Error: API ID not configured. Please set TdConfig.apiId")
            return false
        }
        if apiHash.isEmpty {
            print("Error: API hash not configured. Please set TdConfig.apiHash")
            return false
        }
        return true
    }
}
