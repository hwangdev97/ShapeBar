import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("pollInterval") private var pollInterval: Double = 60
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Refresh Interval", systemImage: "arrow.clockwise")
                        Spacer()
                        Text("\(Int(pollInterval))s")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $pollInterval, in: 30...300, step: 30) {
                        Text("Refresh interval")
                    } minimumValueLabel: {
                        Text("30s").font(.caption).foregroundStyle(.tertiary)
                    } maximumValueLabel: {
                        Text("5m").font(.caption).foregroundStyle(.tertiary)
                    }
                    .onChange(of: pollInterval) { _, _ in
                        appState.restartPolling()
                    }
                }
                .padding(.vertical, 4)
            } footer: {
                Text("How often StackLight fetches new deployment data.")
            }

            Section {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Status Change Notifications", systemImage: "bell.badge")
                }
            } footer: {
                Text("Notify when a deployment succeeds or fails.")
            }
        }
        .navigationTitle("General")
        .navigationBarTitleDisplayMode(.inline)
    }
}
