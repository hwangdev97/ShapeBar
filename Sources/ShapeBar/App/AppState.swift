import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var deployments: [Deployment] = []
    @Published var errors: [String: String] = [:] // providerID -> error message
    @Published var lastRefresh: Date?

    var onDeploymentsChanged: (() -> Void)?

    private let pollingManager = PollingManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Observe published changes to trigger menu rebuild
        $deployments
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.onDeploymentsChanged?() }
            .store(in: &cancellables)

        $errors
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.onDeploymentsChanged?() }
            .store(in: &cancellables)
    }

    func startPolling() {
        pollingManager.onUpdate = { [weak self] deployments in
            self?.deployments = deployments
            self?.lastRefresh = Date()
        }
        pollingManager.onError = { [weak self] providerID, error in
            self?.errors[providerID] = error.localizedDescription
        }
        pollingManager.start()
    }

    func refresh() {
        errors.removeAll()
        pollingManager.refresh()
    }

    func restartPolling() {
        pollingManager.stop()
        errors.removeAll()
        startPolling()
    }
}
