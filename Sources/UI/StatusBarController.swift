import Cocoa

/// Owns the menu-bar NSStatusItem and routes user-initiated actions
/// (open settings, quit) back to the coordinator.
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let onOpenSettings: () -> Void

    init(onOpenSettings: @escaping () -> Void) {
        self.statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )
        self.onOpenSettings = onOpenSettings
        configureButton()
        configureMenu()
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

private extension StatusBarController {
    func configureButton() {
        guard let button = statusItem.button else { return }
        let image = NSImage(
            systemSymbolName: "rectangle.split.2x2",
            accessibilityDescription: "BisectWindow"
        )
        image?.isTemplate = true
        button.image = image
        button.toolTip = "BisectWindow"
    }

    func configureMenu() {
        let menu = NSMenu()
        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit BisectWindow",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }
}
