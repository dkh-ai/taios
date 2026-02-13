import XCTest
@testable import TelegramMacOS

class DatabaseManagerTests: XCTestCase {
    var database: DatabaseManager!

    override func setUp() {
        super.setUp()
        database = DatabaseManager.getInstance()
        // Open in-memory database for testing
        _ = database.open()
    }

    override func tearDown() {
        super.tearDown()
        database.close()
    }

    // MARK: - Database Initialization Tests

    func testDatabaseSingleton() {
        let db1 = DatabaseManager.getInstance()
        let db2 = DatabaseManager.getInstance()
        XCTAssertTrue(db1 === db2, "DatabaseManager should be a singleton")
    }

    func testDatabaseOpen() {
        XCTAssertTrue(database.open(), "Database should open successfully")
    }

    // MARK: - Message Storage Tests

    func testInsertMessage() {
        let result = database.insertMessage(
            id: 1,
            chatId: 100,
            senderUserId: 200,
            content: "Test message",
            timestamp: Int(Date().timeIntervalSince1970),
            isOutgoing: false
        )
        XCTAssertTrue(result, "Message should be inserted successfully")
    }

    func testMessageCount() {
        // Insert test messages
        _ = database.insertMessage(id: 1, chatId: 100, senderUserId: nil, content: "Msg 1", timestamp: 1000, isOutgoing: false)
        _ = database.insertMessage(id: 2, chatId: 100, senderUserId: nil, content: "Msg 2", timestamp: 2000, isOutgoing: false)
        _ = database.insertMessage(id: 3, chatId: 101, senderUserId: nil, content: "Msg 3", timestamp: 3000, isOutgoing: false)

        let count100 = database.getMessageCount(chatId: 100)
        let count101 = database.getMessageCount(chatId: 101)

        XCTAssertEqual(count100, 2, "Chat 100 should have 2 messages")
        XCTAssertEqual(count101, 1, "Chat 101 should have 1 message")
    }

    // MARK: - Chat Storage Tests

    func testInsertChat() {
        let result = database.insertChat(
            id: 100,
            title: "Test Chat",
            type: "private",
            lastMessageDate: Int(Date().timeIntervalSince1970)
        )
        XCTAssertTrue(result, "Chat should be inserted successfully")
    }

    func testChatCount() {
        _ = database.insertChat(id: 100, title: "Chat 1", type: "private", lastMessageDate: 1000)
        _ = database.insertChat(id: 101, title: "Chat 2", type: "group", lastMessageDate: 2000)
        _ = database.insertChat(id: 102, title: "Chat 3", type: "channel", lastMessageDate: 3000)

        let count = database.getChatCount()
        XCTAssertGreaterThanOrEqual(count, 3, "Should have at least 3 chats")
    }

    // MARK: - Signal Storage Tests

    func testInsertSignal() {
        let signalId = database.insertSignal(
            pattern: "bitcoin",
            type: "keyword",
            category: "crypto",
            priority: 1
        )
        XCTAssertGreaterThan(signalId, 0, "Signal should be inserted with positive ID")
    }

    func testRecordSignalMatch() {
        // Insert a message and signal first
        _ = database.insertMessage(id: 1, chatId: 100, senderUserId: nil, content: "bitcoin", timestamp: 1000, isOutgoing: false)
        let signalId = database.insertSignal(pattern: "bitcoin", type: "keyword")

        let result = database.recordSignalMatch(
            signalId: signalId,
            messageId: 1,
            chatId: 100,
            context: "...bitcoin price is rising..."
        )
        XCTAssertTrue(result, "Signal match should be recorded successfully")
    }

    // MARK: - Data Integrity Tests

    func testMessageDataPersistence() {
        let testContent = "This is a test message with special chars: éàü"
        let testTimestamp = Int(Date().timeIntervalSince1970)

        _ = database.insertMessage(
            id: 999,
            chatId: 999,
            senderUserId: 888,
            content: testContent,
            timestamp: testTimestamp,
            isOutgoing: true
        )

        // In a real scenario, we'd retrieve and verify
        let count = database.getMessageCount(chatId: 999)
        XCTAssertGreaterThan(count, 0, "Message should be retrievable")
    }

    func testMultipleChatOperations() {
        // Insert multiple chats
        for i in 1...10 {
            _ = database.insertChat(
                id: Int64(i),
                title: "Chat \(i)",
                type: i % 2 == 0 ? "group" : "private",
                lastMessageDate: Int(Date().timeIntervalSince1970)
            )
        }

        let count = database.getChatCount()
        XCTAssertGreaterThanOrEqual(count, 10, "Should have inserted 10+ chats")
    }
}
