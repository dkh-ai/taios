# Testing Guide for Phase 1

This document describes how to test Phase 1 implementation of the Custom Telegram macOS client.

## Test Coverage

### 1. **Unit Tests**

Tests are organized by component:

#### TelegramClientManagerTests
- `testClientManagerSingleton()` - Verify singleton pattern
- `testInitialAuthorizationState()` - Check initial state
- `testTdConfigValidation()` - Validate configuration
- `testDatabaseDirectory()` - Verify DB path creation
- `testFilesDirectory()` - Verify files path creation
- `testAuthenticationPhoneNumberQuery()` - Test phone number handling
- `testUpdateSubscription()` - Test update stream

#### DatabaseManagerTests
- `testDatabaseSingleton()` - Verify singleton pattern
- `testDatabaseOpen()` - Database initialization
- `testInsertMessage()` - Message insertion
- `testMessageCount()` - Message counting
- `testInsertChat()` - Chat insertion
- `testChatCount()` - Chat counting
- `testInsertSignal()` - Signal definition storage
- `testRecordSignalMatch()` - Signal match recording
- `testMessageDataPersistence()` - Data integrity
- `testMultipleChatOperations()` - Batch operations

#### AuthenticationManagerTests
- `testValidPhoneNumberFormats()` - Phone number validation
- `testInvalidPhoneNumberFormats()` - Invalid phone handling
- `testInvalidCodeHandling()` - Code validation
- `testInvalidPasswordHandling()` - Password validation

#### DetectionEngineTests
- `testKeywordMatching()` - Keyword detection
- `testCaseInsensitiveMatching()` - Case-insensitive search
- `testRegexMatching()` - Regex pattern matching
- `testMultipleSignals()` - Multiple signal detection
- `testNoMatch()` - Negative matching
- `testActiveSignalFiltering()` - Signal filtering

#### AlertManagerTests
- `testAlertCreation()` - Alert creation
- `testAlertMarkAsRead()` - Read state tracking
- `testAlertClear()` - Bulk deletion
- `testAlertDelete()` - Individual deletion

## Running Tests

### Prerequisites

```bash
# Install dependencies
brew install openssl zlib cmake

# Ensure Xcode is properly set up
xcode-select --install
```

### Option 1: Using Xcode (Recommended)

#### Create Xcode Project

```bash
cd /home/user/taios/macos-client

# Create Xcode project (if not already created)
# You can use Xcode's File > New > Project menu to create a Swift package or app project
# Or use command line:
# swift package init --type executable
```

#### Run Tests in Xcode

1. Open project in Xcode
2. Product > Test (Cmd+U)
3. Select tests to run
4. View results in Test navigator

### Option 2: Using Command Line

#### Build and Test

```bash
cd /home/user/taios/macos-client

# Using Swift Package Manager (if configured)
swift test

# Or using xcodebuild
xcodebuild test -scheme TelegramMacOS

# With coverage
xcodebuild test -scheme TelegramMacOS -enableCodeCoverage YES
```

### Option 3: Using CMake

```bash
cd /home/user/taios/macos-client
mkdir -p build
cd build

# Build
cmake -DCMAKE_BUILD_TYPE=Debug ..
make

# Run tests
ctest --verbose
```

## Manual Testing Checklist

### Database Tests

- [ ] Create `~/Library/Application Support/TelegramClient/` directories
- [ ] Verify SQLite database is created
- [ ] Insert test messages and check they appear in DB
- [ ] Insert chats and verify count
- [ ] Add signals and verify storage
- [ ] Record signal matches and verify persistence

```swift
// Test in Swift Playground or app
let db = DatabaseManager.getInstance()
db.open()

// Test message insertion
let result = db.insertMessage(
    id: 1,
    chatId: 100,
    senderUserId: nil,
    content: "Test message",
    timestamp: Int(Date().timeIntervalSince1970),
    isOutgoing: false
)
print("Message inserted: \(result)")

// Test message count
let count = db.getMessageCount(chatId: 100)
print("Messages in chat: \(count)")

db.close()
```

### Configuration Tests

- [ ] Verify `TdConfig.databaseDirectory` points to correct location
- [ ] Verify `TdConfig.filesDirectory` is created
- [ ] Check that `TdConfig.validate()` returns appropriate value
- [ ] Verify API ID and hash can be configured

```swift
// In Swift Playground or app
print("DB Dir: \(TdConfig.databaseDirectory)")
print("Files Dir: \(TdConfig.filesDirectory)")
print("API ID: \(TdConfig.apiId)")
print("Valid: \(TdConfig.validate())")
```

### Manager Initialization Tests

- [ ] `TelegramClientManager` initializes without errors
- [ ] Initial auth state is `.waitTdlibParameters`
- [ ] `AuthenticationManager` validates phone numbers correctly
- [ ] `DetectionEngine` can add and check signals
- [ ] `AlertManager` creates and manages alerts

```swift
// Test managers
let clientMgr = TelegramClientManager.getInstance()
let authMgr = AuthenticationManager(clientManager: clientMgr)
let db = DatabaseManager.getInstance()
db.open()
let detectionEngine = DetectionEngine(database: db)
let alertMgr = AlertManager(detectionEngine: detectionEngine)

print("Client manager ready: \(clientMgr.isAuthorized)")
print("Auth state: \(clientMgr.authorizationState)")

// Test signal detection
let signal = SignalDefinition(id: 1, pattern: "bitcoin", type: .keyword)
detectionEngine.addSignal(signal)

let activeSignals = detectionEngine.getActiveSignals()
print("Active signals: \(activeSignals.count)")
```

### UI Initialization Tests

- [ ] App launches without crashes
- [ ] Main window appears
- [ ] Navigation components render
- [ ] Settings window opens and closes
- [ ] No memory leaks on window close/open

## Test Metrics

### Expected Coverage

- **Target**: >80% code coverage
- **Database Layer**: 95%
- **Manager Classes**: 85%
- **UI Components**: 70% (lower due to SwiftUI complexity)

### Running Coverage Analysis

```bash
# With xcodebuild
xcodebuild test -scheme TelegramMacOS \
  -enableCodeCoverage YES \
  -derivedDataPath build

# View coverage report
open build/Logs/Test/
```

## Continuous Integration

### GitHub Actions (Future)

Example CI workflow:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: |
          cd macos-client
          swift test
```

## Troubleshooting

### Build Errors

**Error**: `Module not found`
```
Solution: Ensure bridging header path is correct in Xcode Build Settings
```

**Error**: `SQLite compilation error`
```
Solution: Verify SQLite3 framework is linked in Build Phases
```

### Test Failures

**Database tests fail**
```
Solution: Check file permissions in ~/Library/Application Support/
chmod -R 755 ~/Library/Application\ Support/TelegramClient/
```

**Memory warnings in tests**
```
Solution: Add tearDown cleanup for resources
Add `database.close()` in test tearDown
```

### Performance Issues

**Tests run slowly**
```
Solution: Disable code coverage for faster runs:
xcodebuild test -scheme TelegramMacOS -enableCodeCoverage NO
```

## Test Development Guidelines

### Writing New Tests

1. **Name tests clearly**: `test<Method><Condition><Expected>`
   ```swift
   func testInsertMessageSuccessfully() { }
   func testInvalidPhoneNumberThrowsError() { }
   ```

2. **Use Arrange-Act-Assert pattern**:
   ```swift
   // Arrange
   let signal = SignalDefinition(id: 1, pattern: "test")

   // Act
   engine.addSignal(signal)

   // Assert
   XCTAssertEqual(engine.getActiveSignals().count, 1)
   ```

3. **Add descriptive assertions**:
   ```swift
   XCTAssertEqual(count, expected,
     "Should have \(expected) messages, got \(count)")
   ```

4. **Test edge cases**:
   - Empty inputs
   - Null/nil values
   - Boundary values
   - Concurrent access

### Test File Organization

```
Tests/
├── TelegramClientManagerTests.swift
├── DatabaseManagerTests.swift
├── ManagersTests.swift
├── UITests.swift
└── Fixtures/
    └── MockData.swift
```

## Performance Benchmarking

### Database Performance

```swift
import Foundation

func benchmarkDatabaseInsertion() {
    let db = DatabaseManager.getInstance()
    db.open()

    let startTime = Date()

    for i in 0..<1000 {
        _ = db.insertMessage(
            id: Int64(i),
            chatId: 100,
            senderUserId: nil,
            content: "Message \(i)",
            timestamp: Int(Date().timeIntervalSince1970),
            isOutgoing: false
        )
    }

    let elapsed = Date().timeIntervalSince(startTime)
    print("Inserted 1000 messages in \(elapsed)s")
    // Expected: < 1 second for 1000 messages

    db.close()
}
```

### Signal Detection Performance

```swift
func benchmarkSignalDetection() {
    let db = DatabaseManager.getInstance()
    db.open()
    let engine = DetectionEngine(database: db)

    // Add 100 signals
    for i in 0..<100 {
        let signal = SignalDefinition(
            id: Int64(i),
            pattern: "keyword\(i)",
            type: .keyword
        )
        engine.addSignal(signal)
    }

    let message = MessageManager.MessageModel(
        id: 1,
        chatId: 100,
        senderUserId: 200,
        content: "This is a test message with keyword50 and other content",
        timestamp: 1000,
        isOutgoing: false,
        editDate: nil
    )

    let startTime = Date()

    for _ in 0..<1000 {
        _ = engine.checkMessage(message)
    }

    let elapsed = Date().timeIntervalSince(startTime)
    print("Checked message against 100 signals 1000x in \(elapsed)s")
    // Expected: < 0.5 seconds

    db.close()
}
```

## Next Steps

After Phase 1 testing is complete:

1. ✅ Verify all unit tests pass
2. ✅ Run manual testing checklist
3. ✅ Check code coverage > 80%
4. ✅ Commit test changes
5. → Proceed to Phase 2: Authentication & Initialization

## References

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Swift Testing Best Practices](https://swift.org/documentation/testing/)
- [SQLite Testing Patterns](https://www.sqlite.org/appfunc.html)
