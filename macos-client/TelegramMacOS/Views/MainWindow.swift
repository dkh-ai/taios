import SwiftUI

/// Main application window with three-column layout
struct MainWindow: View {
    @EnvironmentObject var clientManager: TelegramClientManager
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            // Sidebar
            VStack(spacing: 0) {
                // User Profile Section
                UserProfileView()
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .border(Color(.separator), width: 1)

                // Chat List
                ChatListView()

                Divider()

                // Bottom Action Bar
                HStack(spacing: 8) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                            .font(.system(size: 16))
                    }
                    .help("Settings")

                    Spacer()
                }
                .padding(8)
                .background(Color(.controlBackgroundColor))
            }
            .frame(minWidth: 280, maxWidth: 380)

            // Main Content Area
            if clientManager.isAuthorized {
                ChatDetailView()
            } else {
                AuthenticationView()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsWindow()
        }
    }
}

// MARK: - User Profile View

struct UserProfileView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Circle()
                    .frame(width: 48, height: 48)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("User Name")
                        .font(.headline)
                    Text("Online")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Chat List View

struct ChatListView: View {
    var body: some View {
        List {
            ForEach(0..<10) { index in
                ChatListItemView(chatName: "Chat \(index)")
            }
        }
        .listStyle(.plain)
    }
}

struct ChatListItemView: View {
    let chatName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chatName)
                .font(.body)
            Text("Last message preview...")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Chat Detail View

struct ChatDetailView: View {
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Chat Name")
                    .font(.headline)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "info.circle")
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .border(Color(.separator), width: 1)

            // Messages Area
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Messages will appear here")
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            Divider()

            // Input Area
            HStack(spacing: 8) {
                TextField("Type a message...", text: .constant(""))
                    .textFieldStyle(.roundedBorder)

                Button(action: {}) {
                    Image(systemName: "paperplane.fill")
                }
            }
            .padding()
        }
    }
}

// MARK: - Authentication View

struct AuthenticationView: View {
    @State private var phoneNumber = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Sign in to Telegram")
                .font(.title)

            VStack(alignment: .leading, spacing: 8) {
                Text("Phone Number")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Enter phone number", text: $phoneNumber)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.phonePad)
            }

            Button(action: {}) {
                Text("Next")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: 400)
    }
}

// MARK: - Settings Window

struct SettingsWindow: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Settings")
                .font(.title2)

            Form {
                Section("Account") {
                    Label("Phone Number", systemImage: "phone")
                    Label("Username", systemImage: "person")
                }

                Section("Notifications") {
                    Toggle("Message Notifications", isOn: .constant(true))
                    Toggle("Signal Alerts", isOn: .constant(true))
                }

                Section("Privacy") {
                    Label("Manage Signals", systemImage: "target")
                }
            }

            HStack {
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()
        }
        .padding()
        .frame(width: 400, height: 500)
    }
}

#Preview {
    MainWindow()
        .environmentObject(TelegramClientManager.getInstance())
}
