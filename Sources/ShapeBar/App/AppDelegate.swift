import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register built-in providers
        ServiceRegistry.shared.registerBuiltInProviders()

        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "shippingbox.fill",
                                   accessibilityDescription: "ShapeBar")
        }

        // Build initial menu
        rebuildMenu()

        // Wire up state changes to menu rebuilds
        appState.onDeploymentsChanged = { [weak self] in
            self?.rebuildMenu()
        }

        // Start polling
        appState.startPolling()
    }

    func rebuildMenu() {
        let menu = MenuBuilder.buildMenu(
            deployments: appState.deployments,
            errors: appState.errors,
            lastRefresh: appState.lastRefresh,
            target: self
        )
        statusItem.menu = menu
    }

    @objc func openDeploymentURL(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }

    @objc func refreshNow(_ sender: NSMenuItem) {
        appState.refresh()
    }

    @objc func openSettings(_ sender: NSMenuItem) {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quitApp(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }
}
