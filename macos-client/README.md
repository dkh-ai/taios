# Custom Telegram macOS Client

A customized Telegram client for macOS built on TDLib with advanced message monitoring, signal detection, and local data analysis capabilities.

## Features

- **Full Message Access**: Direct access to all messages, chats, and groups
- **Real-time Monitoring**: Monitor incoming messages as they arrive
- **Signal Detection**: Define and detect important keywords/patterns
- **Local Indexing**: Full-text search on all cached messages
- **macOS Integration**: Native notifications and system integration
- **Analytics**: Signal detection trends and statistics

## Architecture

```
┌─────────────────────────────────────┐
│    macOS SwiftUI GUI Layer          │
├─────────────────────────────────────┤
│    Application Logic & Monitoring   │
├─────────────────────────────────────┤
│    Local Database (SQLite)          │
├─────────────────────────────────────┤
│    TDLib C++ Bridge                 │
├─────────────────────────────────────┤
│    TDLib Core (MTProto)             │
└─────────────────────────────────────┘
```

## Project Structure

```
macos-client/
├── TelegramClient/          # Core backend logic
│   ├── Bridge/             # C++/Swift interop layer
│   ├── Core/               # TelegramClientManager
│   ├── Auth/               # Authentication
│   ├── Chat/               # Chat management
│   ├── Message/            # Message handling
│   ├── Updates/            # Update streaming
│   ├── Database/           # Local SQLite DB
│   ├── Signals/            # Signal detection
│   ├── Alerts/             # Alert management
│   ├── Analytics/          # Statistics
│   ├── Notifications/      # Notification manager
│   ├── Config/             # Configuration
│   ├── Performance/        # Performance monitoring
│   └── Startup/            # Initialization
├── TelegramMacOS/          # macOS GUI (SwiftUI)
│   ├── App/                # Entry point
│   ├── Views/              # SwiftUI views
│   ├── Settings/           # Preferences
│   ├── Notifications/      # macOS notifications
│   └── Models/             # Data models
├── Tests/                  # Unit & integration tests
├── CMakeLists.txt         # Build configuration
└── README.md

```

## Getting Started

### Prerequisites

- macOS 11.0 or later
- Xcode 14.0+
- Swift 5.7+
- CMake 3.10+
- OpenSSL and zlib (install via Homebrew)

```bash
brew install openssl zlib cmake
```

### Build Instructions

#### 1. Setup TDLib

```bash
# The TDLib library should be in the parent directory
cd /home/user/taios
# Build TDLib (if not already built)
# See TDLib documentation for build instructions
```

#### 2. Build macOS Client

```bash
cd macos-client
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make
```

#### 3. Obtain Telegram API Credentials

1. Go to https://core.telegram.org/api/obtaining_api_id
2. Create a new application and get your `api_id` and `api_hash`
3. Update these in `TelegramClient/Config/TdConfig.swift`

### Development

#### Running Tests

```bash
cd build
ctest
```

#### Code Organization

- **Bridge Layer**: C++ `TdBridge` communicates with TDLib via JSON
- **Manager Layer**: Swift classes wrap the bridge and provide async APIs
- **Database Layer**: SQLite stores messages, chats, signals locally
- **UI Layer**: SwiftUI components for user interface

## Phase Development

- **Phase 1** ✅: Foundation & TDLib Integration
- **Phase 2** ⏳: Authentication & Initialization
- **Phase 3** ⏳: Core Message Access & Streaming
- **Phase 4** ⏳: Keyword Detection & Signal System
- **Phase 5** ⏳: Local Database & Indexing
- **Phase 6** ⏳: macOS GUI - Core UI Framework
- **Phase 7** ⏳: Notification Center Integration
- **Phase 8** ⏳: Advanced UI Features
- **Phase 9** ⏳: Performance Optimization & Testing

## API Usage Example

```swift
// Initialize client
let clientManager = TelegramClientManager.getInstance()

// Setup parameters
clientManager.initializeWithParameters(
    apiId: 12345,
    apiHash: "your_api_hash",
    databaseDirectory: "~/Library/Application Support/TelegramClient/database",
    filesDirectory: "~/Library/Application Support/TelegramClient/files"
)

// Authenticate
clientManager.authenticateWithPhoneNumber("+1234567890")

// Subscribe to updates
clientManager.subscribeToUpdates()
    .sink { update in
        print("Update: \(update)")
    }
    .store(in: &cancellables)
```

## Configuration

### TDLib Parameters

Key configuration parameters in `TelegramClient/Config/TdConfig.swift`:

- `api_id`: Telegram API ID
- `api_hash`: Telegram API hash
- `use_message_database`: Enable local message caching
- `use_secret_chats`: Support secret chats
- `database_directory`: Path for local database

### Signal Configuration

Define signals/keywords in the UI or directly:

```swift
let db = DatabaseManager.getInstance()
let signalId = db.insertSignal(
    pattern: "bitcoin",
    type: "keyword",
    category: "crypto",
    priority: 1
)
```

## Performance Considerations

- **Database Indexing**: Messages are indexed by chat, timestamp, and sender
- **Full-Text Search**: FTS5 virtual table for efficient text search
- **Update Batching**: Updates are coalesced to reduce database writes
- **Message Virtualization**: UI only renders visible messages

## Security

- **Credentials**: Stored in macOS Keychain
- **Local Database**: Encrypted SQLite
- **Network**: TDLib handles MTProto encryption
- **Memory**: Automatic cleanup of sensitive data

## Troubleshooting

### Build Errors

If you encounter build errors:

1. Ensure TDLib is built in parent directory
2. Check OpenSSL and zlib are installed
3. Verify CMake version: `cmake --version`

### Runtime Issues

- Check database permissions in `~/Library/Application Support/TelegramClient/`
- Verify API ID and hash are correct
- Review logs in Console.app for detailed errors

## License

This project is built on TDLib, which is licensed under the Boost Software License 1.0.

## Contributing

Contributions are welcome! Please ensure:

- Code follows Swift style guidelines
- All tests pass
- Database schema changes are backward compatible
- Commits follow semantic versioning conventions

## References

- [TDLib Documentation](https://core.telegram.org/tdlib)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [MTProto Protocol](https://core.telegram.org/mtproto)
