import XCTest
@testable import BisectWindow

final class SettingsViewModelTests: XCTestCase {
    private var repository: InMemoryConfigRepository!

    override func setUp() {
        super.setUp()
        repository = InMemoryConfigRepository()
    }

    func testLoadPopulatesFromRepository() {
        repository.storedConfig = AppConfig(
            prefixKeyModifiers: PrefixOption.cmdOpt.modifiers,
            isOverlayEnabled: false
        )
        let viewModel = SettingsViewModel(configRepository: repository)
        XCTAssertEqual(viewModel.selectedPrefix, .cmdOpt)
        XCTAssertFalse(viewModel.isOverlayEnabled)
    }

    func testChangingOverlayPersistsAndNotifies() {
        let viewModel = SettingsViewModel(configRepository: repository)
        var notificationCount = 0
        viewModel.onConfigChanged = { notificationCount += 1 }

        viewModel.isOverlayEnabled = false

        XCTAssertEqual(notificationCount, 1)
        XCTAssertEqual(repository.storedConfig.isOverlayEnabled, false)
    }

    func testChangingPrefixPersistsAndNotifies() {
        let viewModel = SettingsViewModel(configRepository: repository)
        var notificationCount = 0
        viewModel.onConfigChanged = { notificationCount += 1 }

        viewModel.selectedPrefix = .ctrlOpt

        XCTAssertEqual(notificationCount, 1)
        XCTAssertEqual(
            repository.storedConfig.prefixKeyModifiers,
            PrefixOption.ctrlOpt.modifiers
        )
    }

    func testInitialLoadDoesNotNotify() {
        var notificationCount = 0
        let viewModel = SettingsViewModel(configRepository: repository)
        viewModel.onConfigChanged = { notificationCount += 1 }
        XCTAssertEqual(notificationCount, 0)
    }
}

private final class InMemoryConfigRepository: ConfigRepositoryProtocol {
    var storedConfig: AppConfig = .defaultConfig

    func loadConfig() -> AppConfig { storedConfig }
    func saveConfig(_ config: AppConfig) { storedConfig = config }
}
