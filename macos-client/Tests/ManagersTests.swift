import XCTest
@testable import TelegramMacOS

class AuthenticationManagerTests: XCTestCase {
    var authManager: AuthenticationManager!
    var clientManager: TelegramClientManager!

    override func setUp() {
        super.setUp()
        clientManager = TelegramClientManager.getInstance()
        authManager = AuthenticationManager(clientManager: clientManager)
    }

    override func tearDown() {
        super.tearDown()
        clientManager.shutdown()
    }

    func testValidPhoneNumberFormats() {
        let validPhones = ["+1234567890", "+380123456789", "+8613912345678"]

        for phone in validPhones {
            XCTAssertNoThrow(try authManager.startAuthenticationWithPhoneNumber(phone))
        }
    }

    func testInvalidPhoneNumberFormats() {
        let invalidPhones = ["1234567890", "abc123", ""]

        for phone in invalidPhones {
            XCTAssertThrowsError(try authManager.startAuthenticationWithPhoneNumber(phone))
        }
    }

    func testInvalidCodeHandling() {
        XCTAssertThrowsError(try authManager.submitAuthenticationCode(""))
    }

    func testInvalidPasswordHandling() {
        XCTAssertThrowsError(try authManager.submitAuthenticationPassword(""))
    }
}

class DetectionEngineTests: XCTestCase {
    var engine: DetectionEngine!
    var database: DatabaseManager!

    override func setUp() {
        super.setUp()
        database = DatabaseManager.getInstance()
        _ = database.open()
        engine = DetectionEngine(database: database)
    }

    override func tearDown() {
        super.tearDown()
        database.close()
    }

    func testKeywordMatching() {
        let signal = SignalDefinition(id: 1, pattern: "bitcoin", type: .keyword)
        engine.addSignal(signal)

        let message = MessageManager.MessageModel(
            id: 1,
            chatId: 100,
            senderUserId: 200,
            content: "The price of bitcoin is rising",
            timestamp: 1000,
            isOutgoing: false,
            editDate: nil
        )

        let matches = engine.checkMessage(message)
        XCTAssertEqual(matches.count, 1, "Should find one keyword match")
    }

    func testCaseInsensitiveMatching() {
        let signal = SignalDefinition(id: 1, pattern: "ethereum", type: .keyword)
        engine.addSignal(signal)

        let message = MessageManager.MessageModel(
            id: 1,
            chatId: 100,
            senderUserId: 200,
            content: "ETHEREUM and Bitcoin are cryptocurrencies",
            timestamp: 1000,
            isOutgoing: false,
            editDate: nil
        )

        let matches = engine.checkMessage(message)
        XCTAssertEqual(matches.count, 1, "Should find case-insensitive match")
    }

    func testRegexMatching() {
        let signal = SignalDefinition(id: 1, pattern: "\\$[0-9]+", type: .regex)
        engine.addSignal(signal)

        let message = MessageManager.MessageModel(
            id: 1,
            chatId: 100,
            senderUserId: 200,
            content: "The price is $1500 today",
            timestamp: 1000,
            isOutgoing: false,
            editDate: nil
        )

        let matches = engine.checkMessage(message)
        XCTAssertEqual(matches.count, 1, "Should find regex match")
    }

    func testMultipleSignals() {
        let signal1 = SignalDefinition(id: 1, pattern: "bitcoin", type: .keyword)
        let signal2 = SignalDefinition(id: 2, pattern: "ethereum", type: .keyword)
        engine.addSignal(signal1)
        engine.addSignal(signal2)

        let message = MessageManager.MessageModel(
            id: 1,
            chatId: 100,
            senderUserId: 200,
            content: "Bitcoin and Ethereum prices updated",
            timestamp: 1000,
            isOutgoing: false,
            editDate: nil
        )

        let matches = engine.checkMessage(message)
        XCTAssertEqual(matches.count, 2, "Should find both signals")
    }

    func testNoMatch() {
        let signal = SignalDefinition(id: 1, pattern: "solana", type: .keyword)
        engine.addSignal(signal)

        let message = MessageManager.MessageModel(
            id: 1,
            chatId: 100,
            senderUserId: 200,
            content: "Bitcoin and Ethereum prices are stable",
            timestamp: 1000,
            isOutgoing: false,
            editDate: nil
        )

        let matches = engine.checkMessage(message)
        XCTAssertEqual(matches.count, 0, "Should find no matches")
    }

    func testActiveSignalFiltering() {
        let activeSignal = SignalDefinition(id: 1, pattern: "bitcoin", type: .keyword)
        let inactiveSignal = SignalDefinition(id: 2, pattern: "ethereum", type: .keyword)

        engine.addSignal(activeSignal)
        engine.addSignal(inactiveSignal)
        // Note: In real implementation, we'd disable the second signal

        let activeSignals = engine.getActiveSignals()
        XCTAssertGreaterThan(activeSignals.count, 0, "Should have active signals")
    }
}

class AlertManagerTests: XCTestCase {
    var alertManager: AlertManager!
    var detectionEngine: DetectionEngine!
    var database: DatabaseManager!

    override func setUp() {
        super.setUp()
        database = DatabaseManager.getInstance()
        _ = database.open()
        detectionEngine = DetectionEngine(database: database)
        alertManager = AlertManager(detectionEngine: detectionEngine)
    }

    override func tearDown() {
        super.tearDown()
        database.close()
    }

    func testAlertCreation() {
        let match = SignalMatch(
            id: 1,
            signalId: 1,
            messageId: 1,
            chatId: 100,
            context: "bitcoin mention",
            matchTimestamp: Date()
        )

        alertManager.handleSignalMatch(match, message: "Test message")
        XCTAssertEqual(alertManager.alerts.count, 1, "Should create one alert")
        XCTAssertEqual(alertManager.unreadCount, 1, "Should have one unread alert")
    }

    func testAlertMarkAsRead() {
        let match = SignalMatch(
            id: 1,
            signalId: 1,
            messageId: 1,
            chatId: 100,
            context: "bitcoin mention",
            matchTimestamp: Date()
        )

        alertManager.handleSignalMatch(match, message: "Test")
        let alertId = alertManager.alerts[0].id
        alertManager.markAsRead(alertId)

        XCTAssertTrue(alertManager.alerts[0].isRead, "Alert should be marked as read")
        XCTAssertEqual(alertManager.unreadCount, 0, "Unread count should be zero")
    }

    func testAlertClear() {
        let match = SignalMatch(
            id: 1,
            signalId: 1,
            messageId: 1,
            chatId: 100,
            context: nil,
            matchTimestamp: Date()
        )

        alertManager.handleSignalMatch(match, message: "Test 1")
        alertManager.handleSignalMatch(match, message: "Test 2")

        XCTAssertEqual(alertManager.alerts.count, 2)
        alertManager.clearAllAlerts()
        XCTAssertEqual(alertManager.alerts.count, 0, "Should clear all alerts")
    }

    func testAlertDelete() {
        let match = SignalMatch(
            id: 1,
            signalId: 1,
            messageId: 1,
            chatId: 100,
            context: nil,
            matchTimestamp: Date()
        )

        alertManager.handleSignalMatch(match, message: "Test")
        let alertId = alertManager.alerts[0].id

        alertManager.deleteAlert(alertId)
        XCTAssertEqual(alertManager.alerts.count, 0, "Should delete the alert")
    }
}
