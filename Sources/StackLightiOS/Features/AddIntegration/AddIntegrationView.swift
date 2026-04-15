import SwiftUI

struct AddIntegrationView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ServiceRegistry.shared.providers, id: \.id) { provider in
                        NavigationLink {
                            ProviderSettingsView(provider: provider, dismissOnSave: true)
                                .environmentObject(appState)
                        } label: {
                            ProviderPickerRow(provider: provider)
                        }
                    }
                } footer: {
                    Text("Select a service to connect. Credentials are stored securely in the iOS Keychain.")
                }
            }
            .navigationTitle("Add Integration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private struct ProviderPickerRow: View {
    let provider: DeploymentProvider

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: provider.iconSymbol)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(iconTint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(provider.displayName)
                    .font(.body.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if provider.isConfigured {
                Text("Connected")
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.15), in: Capsule())
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 2)
    }

    private var subtitle: String {
        switch provider.id {
        case "vercel":       return "Deployments"
        case "cloudflare":   return "Pages deployments"
        case "githubActions": return "Workflow runs"
        case "githubPRs":    return "Open pull requests"
        case "netlify":      return "Deployments"
        case "railway":      return "Deployments"
        case "flyio":        return "Machine deployments"
        case "xcodeCloud":   return "Build results"
        case "testFlight":   return "Build processing & review"
        default:             return "Integration"
        }
    }

    private var iconTint: Color {
        switch provider.id {
        case "vercel":        return .black
        case "cloudflare":    return .orange
        case "githubActions": return .indigo
        case "githubPRs":     return .purple
        case "netlify":       return .teal
        case "railway":       return .mint
        case "flyio":         return .pink
        case "xcodeCloud":    return .blue
        case "testFlight":    return .cyan
        default:              return .gray
        }
    }
}
