import Foundation
import SwiftUI

/// Backs SettingsView. Persists each change immediately and notifies the
/// AppCoordinator so the hot-key tap and overlay pick up new values.
final class SettingsViewModel: ObservableObject {
    @Published var isOverlayEnabled: Bool {
        didSet { persist() }
    }
    @Published var selectedPrefix: PrefixOption {
        didSet { persist() }
    }

    var onConfigChanged: (() -> Void)?

    private let configRepository: ConfigRepositoryProtocol

    init(configRepository: ConfigRepositoryProtocol) {
        self.configRepository = configRepository
        let config = configRepository.loadConfig()
        self.isOverlayEnabled = config.isOverlayEnabled
        self.selectedPrefix = PrefixOption.match(
            modifiers: config.prefixKeyModifiers
        )
    }

    private func persist() {
        let config = AppConfig(
            prefixKeyModifiers: selectedPrefix.modifiers,
            isOverlayEnabled: isOverlayEnabled
        )
        configRepository.saveConfig(config)
        onConfigChanged?()
    }
}
