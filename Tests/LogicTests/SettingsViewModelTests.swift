import XCTest
@testable import BisectWindow

final class SettingsViewModelTests: XCTestCase {
    private var repository: InMemoryConfigRepository!
    private var launchAtLogin: FakeLaunchAtLogin!

    override func setUp() {
        super.setUp()
        repository = InMemoryConfigRepository()
        launchAtLogin = FakeLaunchAtLogin()
    }

    private func makeViewModel() -> SettingsViewModel {
        SettingsViewModel(
            configRepository: repository, launchAtLogin: launchAtLogin
        )
    }

    func testLoadPopulatesFromRepository() {
        repository.storedConfig = AppConfig(
            prefixKeyModifiers: PrefixOption.cmdOpt.modifiers,
            isOverlayEnabled: false
        )
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.selectedPrefix, .cmdOpt)
        XCTAssertFalse(viewModel.isOverlayEnabled)
    }

    func testChangingOverlayPersistsAndNotifies() {
        let viewModel = makeViewModel()
        var notificationCount = 0
        viewModel.onConfigChanged = { notificationCount += 1 }

        viewModel.isOverlayEnabled = false

        XCTAssertEqual(notificationCount, 1)
        XCTAssertEqual(repository.storedConfig.isOverlayEnabled, false)
    }

    func testChangingPrefixPersistsAndNotifies() {
        let viewModel = makeViewModel()
        var notificationCount = 0
        viewModel.onConfigChanged = { notificationCount += 1 }

        viewModel.selectedPrefix = .ctrlOpt

        XCTAssertEqual(notificationCount, 1)
        XCTAssertEqual(
            repository.storedConfig.prefixKeyModifiers,
            PrefixOption.ctrlOpt.modifiers
        )
    }

    func testInitialLoadDoesNotPersist() {
        _ = makeViewModel()

        XCTAssertEqual(repository.saveCount, 0)
    }

    func testLaunchAtLoginStartsFromSystemState() {
        launchAtLogin.isEnabled = true
        launchAtLogin.requiresApproval = true

        let viewModel = makeViewModel()

        XCTAssertTrue(viewModel.isLaunchAtLoginEnabled)
        XCTAssertTrue(viewModel.launchAtLoginRequiresApproval)
    }

    func testInitialLoadDoesNotChangeLaunchAtLogin() {
        _ = makeViewModel()

        XCTAssertEqual(launchAtLogin.setEnabledCalls, [])
    }

    func testTogglingLaunchAtLoginRegistersWithoutPersisting() {
        let viewModel = makeViewModel()
        var notificationCount = 0
        viewModel.onConfigChanged = { notificationCount += 1 }

        viewModel.isLaunchAtLoginEnabled = true

        XCTAssertEqual(launchAtLogin.setEnabledCalls, [true])
        XCTAssertTrue(viewModel.isLaunchAtLoginEnabled)
        XCTAssertEqual(notificationCount, 0)
        XCTAssertEqual(repository.saveCount, 0)
    }

    func testRefusedLaunchAtLoginChangeReverts() {
        launchAtLogin.shouldFail = true
        let viewModel = makeViewModel()

        viewModel.isLaunchAtLoginEnabled = true

        XCTAssertEqual(launchAtLogin.setEnabledCalls, [true])
        XCTAssertFalse(viewModel.isLaunchAtLoginEnabled)
    }

    func testRefreshReadsSystemStateWithoutChangingIt() {
        let viewModel = makeViewModel()
        launchAtLogin.isEnabled = true
        launchAtLogin.requiresApproval = true

        viewModel.refreshLaunchAtLogin()

        XCTAssertTrue(viewModel.isLaunchAtLoginEnabled)
        XCTAssertTrue(viewModel.launchAtLoginRequiresApproval)
        XCTAssertEqual(launchAtLogin.setEnabledCalls, [])
    }

    func testOpenLoginItemsSettingsOpensSystemSettings() {
        let viewModel = makeViewModel()

        viewModel.openLoginItemsSettings()

        XCTAssertEqual(launchAtLogin.openSystemSettingsCount, 1)
    }
}

private final class InMemoryConfigRepository: ConfigRepositoryProtocol {
    var storedConfig: AppConfig = .defaultConfig
    private(set) var saveCount = 0

    func loadConfig() -> AppConfig { storedConfig }
    func saveConfig(_ config: AppConfig) {
        storedConfig = config
        saveCount += 1
    }
}

private final class FakeLaunchAtLogin: LaunchAtLoginProtocol {
    var isEnabled = false
    var requiresApproval = false
    var shouldFail = false
    private(set) var setEnabledCalls: [Bool] = []
    private(set) var openSystemSettingsCount = 0

    func setEnabled(_ isEnabled: Bool) -> Bool {
        setEnabledCalls.append(isEnabled)
        if shouldFail { return false }
        self.isEnabled = isEnabled
        return true
    }

    func openSystemSettings() {
        openSystemSettingsCount += 1
    }
}
