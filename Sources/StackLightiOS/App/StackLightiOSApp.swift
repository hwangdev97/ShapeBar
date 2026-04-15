import SwiftUI
import UserNotifications

@main
struct StackLightiOSApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        requestNotificationAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appState)
                .task {
                    appState.startPolling()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        appState.refresh()
                    }
                }
        }
    }

    private func requestNotificationAuthorization() {
        guard Bundle.main.bundleIdentifier != nil else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
