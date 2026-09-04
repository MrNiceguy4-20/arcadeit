
import SwiftUI

@main
struct arcadeitApp: App {

    @StateObject private var settingsStore = RuntimeSettingsStore()
    @StateObject private var logStore = LogStore()
    @StateObject private var gameLibraryStore = GameLibraryStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsStore)
                .environmentObject(logStore)
                .environmentObject(gameLibraryStore)
                .onAppear {
                    GameLauncher.shared.configure(
                        with: settingsStore,
                        logStore: logStore
                    )
                    ControllerManager.shared.configure(
                        logStore: logStore
                    )
                }
        }

        Settings {
            RuntimeSettingsView(store: settingsStore)
                .environmentObject(logStore)
                .environmentObject(gameLibraryStore)
        }

        Window("Log", id: "log-window") {
            LogView()
                .environmentObject(logStore)
        }
    }
}
