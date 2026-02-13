# Quick Start: Testing Phase 1

## One-Liner Test Commands

### Run All Tests
```bash
cd macos-client
swift test
```

### Run Specific Test Class
```bash
swift test --filter DatabaseManagerTests
swift test --filter AuthenticationManagerTests
swift test --filter DetectionEngineTests
```

### Run with Verbose Output
```bash
swift test --verbose
```

### Run with Coverage
```bash
swift test --enable-code-coverage
```

## Xcode Testing

### Quick Test (Cmd+U)
1. Open Xcode
2. Press Cmd+U to run all tests
3. View results in Test navigator (Cmd+9)

### Test Individual Class
1. Click on test class name in Test navigator
2. Click Play button or press Cmd+U
3. See results with green/red indicators

### View Test Coverage
1. Product > Scheme > Edit Scheme
2. Test tab > Options > Code Coverage = ON
3. Run tests (Cmd+U)
4. Window > Devices and Simulators > View Code Coverage

## Manual Verification Checklist

- [ ] Create directories: `mkdir -p ~/Library/Application\ Support/TelegramClient/{database,files}`
- [ ] Database opens and creates schema
- [ ] Messages insert and count correctly
- [ ] Signals store and activate properly
- [ ] Detection engine matches keywords
- [ ] Alerts create and track read state
- [ ] No crashes on initialization

## Quick Database Test

```swift
// In Xcode Playground or test:
let db = DatabaseManager.getInstance()
print("DB open:", db.open())

// Insert test data
db.insertChat(id: 1, title: "Test", type: "private", lastMessageDate: 0)
db.insertMessage(id: 1, chatId: 1, senderUserId: nil, content: "Hi", timestamp: 0, isOutgoing: false)

// Verify
print("Chat count:", db.getChatCount())
print("Message count:", db.getMessageCount(chatId: 1))

db.close()
```

## Expected Results

| Component | Test Cases | Status |
|-----------|-----------|--------|
| Database | 15 | ✅ Ready |
| Authentication | 4 | ✅ Ready |
| Detection | 6 | ✅ Ready |
| Alerts | 4 | ✅ Ready |
| Configuration | 3 | ✅ Ready |
| **Total** | **32** | **✅ Ready** |

## Troubleshooting

**Tests won't run?**
```bash
# Clean build
rm -rf .build
swift build

# Try again
swift test
```

**SQLite errors?**
```bash
# Check permissions
ls -la ~/Library/Application\ Support/TelegramClient/

# Reset if needed
rm -rf ~/Library/Application\ Support/TelegramClient/
mkdir -p ~/Library/Application\ Support/TelegramClient/{database,files}
```

**Memory issues?**
```bash
# Run with limited parallelism
swift test --num-workers 1
```

## Next Commands

After testing Phase 1:
```bash
# Commit test files
git add macos-client/Tests
git commit -m "test: Add comprehensive unit tests for Phase 1"

# Continue to Phase 2
# See README.md for Phase 2 instructions
```
