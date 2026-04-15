import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    NavigationLink {
                        GeneralSettingsView()
                    } label: {
                        Label("General", systemImage: "gear")
                    }
                }

                Section("Services") {
                    ForEach(ServiceRegistry.shared.providers, id: \.id) { provider in
                        NavigationLink {
                            ProviderSettingsView(provider: provider)
                                .environmentObject(appState)
                        } label: {
                            ProviderRow(provider: provider, error: appState.errors[provider.id])
                        }
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                    Link(destination: URL(string: "https://github.com/hwangdev97/stacklight")!) {
                        HStack {
                            Label("GitHub", systemImage: "link")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var appVersion: String {
        let v = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "—"
        let b = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "?"
        return "\(v) (\(b))"
    }
}

private struct ProviderRow: View {
    let provider: DeploymentProvider
    let error: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: provider.iconSymbol)
                .font(.body)
                .frame(width: 28, height: 28)
                .foregroundStyle(.secondary)

            Text(provider.displayName)

            Spacer()

            if !provider.isConfigured {
                Text("Not configured")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else if error != nil {
                Circle().fill(.red).frame(width: 8, height: 8)
            } else {
                Circle().fill(.green).frame(width: 8, height: 8)
            }
        }
    }
}
