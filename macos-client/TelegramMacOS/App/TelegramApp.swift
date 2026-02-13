import SwiftUI

/// Main application entry point
@main
struct TelegramApp: App {
    @StateObject private var clientManager = TelegramClientManager.getInstance()

    var body: some Scene {
        WindowGroup {
            MainWindow()
                .environmentObject(clientManager)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
