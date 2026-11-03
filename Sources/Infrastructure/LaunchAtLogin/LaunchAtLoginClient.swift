import ServiceManagement

/// Registers the app as a login item through SMAppService. macOS lists it
/// under System Settings > General > Login Items.
struct LaunchAtLoginClient: LaunchAtLoginProtocol {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    var requiresApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    func setEnabled(_ isEnabled: Bool) -> Bool {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            debugLog("[LaunchAtLoginClient] setEnabled(\(isEnabled)) failed: \(error)")
            return false
        }
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
