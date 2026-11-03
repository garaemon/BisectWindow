import Foundation
import SwiftUI

/// Backs SettingsView. Persists each change immediately and notifies the
/// AppCoordinator so the hot-key tap and overlay pick up new values.
///
/// The launch-at-login toggle goes to the system instead of AppConfig, so
/// changing it does not call `onConfigChanged`.
final class SettingsViewModel: ObservableObject {
    @Published var isOverlayEnabled: Bool {
        didSet { persist() }
    }
    @Published var selectedPrefix: PrefixOption {
        didSet { persist() }
    }
    @Published var isLaunchAtLoginEnabled: Bool {
        didSet { applyLaunchAtLogin() }
    }
    @Published private(set) var launchAtLoginRequiresApproval: Bool

    var onConfigChanged: (() -> Void)?

    private let configRepository: ConfigRepositoryProtocol
    private let launchAtLogin: LaunchAtLoginProtocol
    private var isRefreshingLaunchAtLogin = false

    init(
        configRepository: ConfigRepositoryProtocol,
        launchAtLogin: LaunchAtLoginProtocol
    ) {
        self.configRepository = configRepository
        self.launchAtLogin = launchAtLogin
        let config = configRepository.loadConfig()
        self.isOverlayEnabled = config.isOverlayEnabled
        self.selectedPrefix = PrefixOption.match(
            modifiers: config.prefixKeyModifiers
        )
        self.isLaunchAtLoginEnabled = launchAtLogin.isEnabled
        self.launchAtLoginRequiresApproval = launchAtLogin.requiresApproval
    }

    /// Reads the login item state from the system again. The user can
    /// change it in System Settings while the app runs.
    func refreshLaunchAtLogin() {
        isRefreshingLaunchAtLogin = true
        isLaunchAtLoginEnabled = launchAtLogin.isEnabled
        isRefreshingLaunchAtLogin = false
        launchAtLoginRequiresApproval = launchAtLogin.requiresApproval
    }

    func openLoginItemsSettings() {
        launchAtLogin.openSystemSettings()
    }

    private func persist() {
        let config = AppConfig(
            prefixKeyModifiers: selectedPrefix.modifiers,
            isOverlayEnabled: isOverlayEnabled
        )
        configRepository.saveConfig(config)
        onConfigChanged?()
    }

    private func applyLaunchAtLogin() {
        guard !isRefreshingLaunchAtLogin else { return }
        if !launchAtLogin.setEnabled(isLaunchAtLoginEnabled) {
            debugLog("[SettingsViewModel] launch at login change refused")
        }
        // The system may refuse the change or hold it until the user
        // approves it, so show what the system reports.
        refreshLaunchAtLogin()
    }
}
