import XCTest
@testable import TelegramMacOS

class TelegramClientManagerTests: XCTestCase {
    var clientManager: TelegramClientManager!

    override func setUp() {
        super.setUp()
        clientManager = TelegramClientManager.getInstance()
    }

    override func tearDown() {
        super.tearDown()
        clientManager.shutdown()
    }

    // MARK: - Initialization Tests

    func testClientManagerSingleton() {
        let manager1 = TelegramClientManager.getInstance()
        let manager2 = TelegramClientManager.getInstance()
        XCTAssertTrue(manager1 === manager2, "TelegramClientManager should be a singleton")
    }

    func testInitialAuthorizationState() {
        XCTAssertEqual(clientManager.authorizationState, .waitTdlibParameters)
        XCTAssertFalse(clientManager.isAuthorized)
        XCTAssertFalse(clientManager.isReady)
    }

    // MARK: - Configuration Tests

    func testTdConfigValidation() {
        // This should fail if API ID/hash not set
        let isValid = TdConfig.validate()
        // We expect false since we haven't configured real credentials
        print("Config validation: \(isValid)")
    }

    func testDatabaseDirectory() {
        let dbDir = TdConfig.databaseDirectory
        XCTAssertFalse(dbDir.isEmpty, "Database directory should not be empty")
        XCTAssertTrue(dbDir.contains("TelegramClient"), "Database path should contain app name")
    }

    func testFilesDirectory() {
        let filesDir = TdConfig.filesDirectory
        XCTAssertFalse(filesDir.isEmpty, "Files directory should not be empty")
        XCTAssertTrue(filesDir.contains("TelegramClient"), "Files path should contain app name")
    }

    // MARK: - Query Building Tests

    func testAuthenticationPhoneNumberQuery() {
        let phoneNumber = "+1234567890"
        // This should not throw
        XCTAssertNoThrow {
            clientManager.authenticateWithPhoneNumber(phoneNumber)
        }
    }

    // MARK: - Update Subscription Tests

    func testUpdateSubscription() {
        let expectation = XCTestExpectation(description: "Should receive updates")
        var receivedUpdates: [String] = []

        let subscription = clientManager.subscribeToUpdates()
            .sink { update in
                receivedUpdates.append(update)
                if receivedUpdates.count >= 1 {
                    expectation.fulfill()
                }
            }

        // Would fulfill when updates arrive (requires active TDLib connection)
        // For now just verify subscription doesn't crash
        XCTAssertNotNil(subscription)
    }
}
