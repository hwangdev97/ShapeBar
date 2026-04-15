import SwiftUI
import SafariServices

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSettings = false
    @State private var showAddIntegration = false
    @State private var safariTarget: SafariTarget?
    @State private var showErrorBanner = true

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Deployments")
                .navigationBarTitleDisplayMode(.large)
                .toolbar { toolbarContent }
                .refreshable {
                    appState.refresh()
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                        .environmentObject(appState)
                }
                .sheet(isPresented: $showAddIntegration) {
                    AddIntegrationView()
                        .environmentObject(appState)
                }
                .sheet(item: $safariTarget) { target in
                    SafariView(url: target.url).ignoresSafeArea()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !appState.hasConfiguredProvider {
            emptyStateNoProviders
        } else if appState.sortedDeployments.isEmpty && appState.errors.isEmpty {
            emptyStateNoDeployments
        } else {
            deploymentList
        }
    }

    private var deploymentList: some View {
        List {
            if !appState.errors.isEmpty && showErrorBanner {
                Section {
                    errorBanner
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                ForEach(appState.sortedDeployments) { deployment in
                    Button {
                        if let url = deployment.url {
                            safariTarget = SafariTarget(url: url)
                        }
                    } label: {
                        DeploymentRow(deployment: deployment)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.visible)
                }
            } footer: {
                if let lastRefresh = appState.lastRefresh {
                    Text("Updated \(Self.relativeFormatter.localizedString(for: lastRefresh, relativeTo: Date()))")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var errorBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Some services failed to refresh")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    withAnimation { showErrorBanner = false }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            ForEach(appState.errors.sorted(by: { $0.key < $1.key }), id: \.key) { providerID, message in
                let name = ServiceRegistry.shared.provider(withID: providerID)?.displayName ?? providerID
                Text("\(name): \(message)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private var emptyStateNoProviders: some View {
        ContentUnavailableView {
            Label("No Integrations", systemImage: "tray")
        } description: {
            Text("Add an integration to start monitoring deployments.")
        } actions: {
            Button {
                showAddIntegration = true
            } label: {
                Label("Add Integration", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var emptyStateNoDeployments: some View {
        ContentUnavailableView {
            Label("No Deployments Yet", systemImage: "clock")
        } description: {
            Text("Pull to refresh.")
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showAddIntegration = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add Integration")
        }
    }
}

// MARK: - Sheet item wrapper

struct SafariTarget: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - SafariView wrapper

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
