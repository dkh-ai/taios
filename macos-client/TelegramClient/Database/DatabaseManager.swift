import Foundation
import SQLite3

/// Manages local SQLite database for Telegram data
class DatabaseManager {
    private let databasePath: String
    private var database: OpaquePointer?
    private let queue = DispatchQueue(label: "com.telegram.database", attributes: .concurrent)

    // MARK: - Singleton

    private static let shared = DatabaseManager()

    static func getInstance() -> DatabaseManager {
        return shared
    }

    // MARK: - Initialization

    private init() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0]
        let appDirectory = (documentsPath as NSString).appendingPathComponent("TelegramClient")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(atPath: appDirectory, withIntermediateDirectories: true)

        self.databasePath = (appDirectory as NSString).appendingPathComponent("telegram.db")
    }

    /// Open database connection
    func open() -> Bool {
        var returnCode = sqlite3_open(databasePath.cString(using: .utf8), &database)
        if returnCode == SQLITE_OK {
            // Enable foreign keys
            sqlite3_exec(database, "PRAGMA foreign_keys = ON;", nil, nil, nil)
            // Create tables
            createTables()
            return true
        } else {
            print("Error opening database: \(returnCode)")
            return false
        }
    }

    /// Close database connection
    func close() {
        if let db = database {
            sqlite3_close(db)
            database = nil
        }
    }

    // MARK: - Table Creation

    private func createTables() {
        // Messages table
        let messagesSQL = """
        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY NOT NULL,
            chat_id INTEGER NOT NULL,
            sender_user_id INTEGER,
            content TEXT,
            timestamp INTEGER,
            edit_date INTEGER,
            is_outgoing BOOLEAN,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (chat_id) REFERENCES chats(id)
        );
        """

        // Chats table
        let chatsSQL = """
        CREATE TABLE IF NOT EXISTS chats (
            id INTEGER PRIMARY KEY NOT NULL,
            title TEXT,
            type TEXT,
            unread_count INTEGER DEFAULT 0,
            unread_mention_count INTEGER DEFAULT 0,
            last_message_date INTEGER,
            last_message_id INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """

        // Users table
        let usersSQL = """
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY NOT NULL,
            username TEXT,
            first_name TEXT,
            last_name TEXT,
            phone_number TEXT,
            is_bot BOOLEAN,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """

        // Signals table (for keyword/signal definitions)
        let signalsSQL = """
        CREATE TABLE IF NOT EXISTS signals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pattern TEXT NOT NULL UNIQUE,
            type TEXT DEFAULT 'keyword',
            category TEXT,
            priority INTEGER DEFAULT 0,
            is_active BOOLEAN DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """

        // Signal matches table
        let signalMatchesSQL = """
        CREATE TABLE IF NOT EXISTS signal_matches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            signal_id INTEGER NOT NULL,
            message_id INTEGER NOT NULL,
            chat_id INTEGER NOT NULL,
            context TEXT,
            match_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (signal_id) REFERENCES signals(id),
            FOREIGN KEY (message_id) REFERENCES messages(id),
            FOREIGN KEY (chat_id) REFERENCES chats(id)
        );
        """

        // Create indexes for performance
        let indexesSQL = [
            "CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);",
            "CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp);",
            "CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_user_id);",
            "CREATE INDEX IF NOT EXISTS idx_signal_matches_signal_id ON signal_matches(signal_id);",
            "CREATE INDEX IF NOT EXISTS idx_signal_matches_timestamp ON signal_matches(match_timestamp);",
            "CREATE INDEX IF NOT EXISTS idx_chats_last_message_date ON chats(last_message_date);"
        ]

        // Full-text search table
        let ftsSQL = """
        CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts USING fts5(
            content,
            chat_id UNINDEXED,
            timestamp UNINDEXED,
            content=messages,
            content_rowid=id
        );
        """

        executeSQL(messagesSQL)
        executeSQL(chatsSQL)
        executeSQL(usersSQL)
        executeSQL(signalsSQL)
        executeSQL(signalMatchesSQL)
        executeSQL(ftsSQL)

        for indexSQL in indexesSQL {
            executeSQL(indexSQL)
        }
    }

    // MARK: - Execution Methods

    private func executeSQL(_ sql: String) {
        var errorMessage: UnsafeMutablePointer<CChar>?
        let returnCode = sqlite3_exec(database, sql, nil, nil, &errorMessage)

        if returnCode != SQLITE_OK {
            if let errorMessage = errorMessage {
                print("SQL Error: \(String(cString: errorMessage))")
                sqlite3_free(errorMessage)
            }
        }
    }

    // MARK: - Insert Methods

    func insertMessage(
        id: Int64,
        chatId: Int64,
        senderUserId: Int64?,
        content: String,
        timestamp: Int,
        isOutgoing: Bool
    ) -> Bool {
        let sql = """
        INSERT OR REPLACE INTO messages (id, chat_id, sender_user_id, content, timestamp, is_outgoing)
        VALUES (?, ?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return false
        }

        sqlite3_bind_int64(statement, 1, id)
        sqlite3_bind_int64(statement, 2, chatId)
        if let senderUserId = senderUserId {
            sqlite3_bind_int64(statement, 3, senderUserId)
        } else {
            sqlite3_bind_null(statement, 3)
        }
        sqlite3_bind_text(statement, 4, content.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 5, Int32(timestamp))
        sqlite3_bind_int(statement, 6, isOutgoing ? 1 : 0)

        let result = sqlite3_step(statement) == SQLITE_DONE
        sqlite3_finalize(statement)

        return result
    }

    func insertChat(
        id: Int64,
        title: String,
        type: String,
        lastMessageDate: Int
    ) -> Bool {
        let sql = """
        INSERT OR REPLACE INTO chats (id, title, type, last_message_date)
        VALUES (?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return false
        }

        sqlite3_bind_int64(statement, 1, id)
        sqlite3_bind_text(statement, 2, title.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 3, type.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 4, Int32(lastMessageDate))

        let result = sqlite3_step(statement) == SQLITE_DONE
        sqlite3_finalize(statement)

        return result
    }

    // MARK: - Query Methods

    func getMessageCount(chatId: Int64) -> Int {
        let sql = "SELECT COUNT(*) FROM messages WHERE chat_id = ?"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return 0
        }

        sqlite3_bind_int64(statement, 1, chatId)

        var count = 0
        if sqlite3_step(statement) == SQLITE_ROW {
            count = Int(sqlite3_column_int(statement, 0))
        }
        sqlite3_finalize(statement)

        return count
    }

    func getChatCount() -> Int {
        let sql = "SELECT COUNT(*) FROM chats"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return 0
        }

        var count = 0
        if sqlite3_step(statement) == SQLITE_ROW {
            count = Int(sqlite3_column_int(statement, 0))
        }
        sqlite3_finalize(statement)

        return count
    }

    // MARK: - Signal Methods

    func insertSignal(pattern: String, type: String = "keyword", category: String? = nil, priority: Int = 0) -> Int64 {
        let sql = """
        INSERT INTO signals (pattern, type, category, priority)
        VALUES (?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return -1
        }

        sqlite3_bind_text(statement, 1, pattern.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, type.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        if let category = category {
            sqlite3_bind_text(statement, 3, category.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 3)
        }
        sqlite3_bind_int(statement, 4, Int32(priority))

        let result = sqlite3_step(statement)
        sqlite3_finalize(statement)

        return result == SQLITE_DONE ? sqlite3_last_insert_rowid(database) : -1
    }

    func recordSignalMatch(signalId: Int64, messageId: Int64, chatId: Int64, context: String? = nil) -> Bool {
        let sql = """
        INSERT INTO signal_matches (signal_id, message_id, chat_id, context)
        VALUES (?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return false
        }

        sqlite3_bind_int64(statement, 1, signalId)
        sqlite3_bind_int64(statement, 2, messageId)
        sqlite3_bind_int64(statement, 3, chatId)
        if let context = context {
            sqlite3_bind_text(statement, 4, context.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 4)
        }

        let result = sqlite3_step(statement) == SQLITE_DONE
        sqlite3_finalize(statement)

        return result
    }

    deinit {
        close()
    }
}
