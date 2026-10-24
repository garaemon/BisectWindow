import Cocoa

/// Owns the menu-bar NSStatusItem and routes user-initiated actions
/// (grant access, open settings, quit) back to the coordinator.
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let onOpenSettings: () -> Void
    private let onGrantAccessibility: () -> Void
    private let grantAccessibilityItem = NSMenuItem(
        title: "Grant Accessibility Access…",
        action: #selector(grantAccessibility),
        keyEquivalent: ""
    )

    init(
        onOpenSettings: @escaping () -> Void,
        onGrantAccessibility: @escaping () -> Void
    ) {
        self.statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )
        self.onOpenSettings = onOpenSettings
        self.onGrantAccessibility = onGrantAccessibility
        configureButton()
        configureMenu()
    }

    /// Shows the menu item that reopens the permission prompt. Only useful
    /// while the Accessibility permission is missing.
    func setGrantAccessibilityItemVisible(_ isVisible: Bool) {
        grantAccessibilityItem.isHidden = !isVisible
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func grantAccessibility() {
        onGrantAccessibility()
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
        grantAccessibilityItem.target = self
        grantAccessibilityItem.isHidden = true
        menu.addItem(grantAccessibilityItem)

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
