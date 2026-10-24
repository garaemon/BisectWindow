import XCTest
@testable import BisectWindow

final class UserDefaultsConfigRepositoryTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var repository: UserDefaultsConfigRepository!

    override func setUp() {
        super.setUp()
        suiteName = "com.garaemon.BisectWindowTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        repository = UserDefaultsConfigRepository(defaults: defaults)
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(
            forName: suiteName
        )
        super.tearDown()
    }

    func testLoadReturnsDefaultWhenEmpty() {
        let config = repository.loadConfig()
        XCTAssertEqual(config, AppConfig.defaultConfig)
    }

    func testSaveAndLoadRoundTrip() {
        let custom = AppConfig(
            prefixKeyModifiers: 42,
            isOverlayEnabled: false
        )
        repository.saveConfig(custom)
        let loaded = repository.loadConfig()
        XCTAssertEqual(loaded, custom)
    }

    func testLoadReturnsDefaultForCorruptedData() {
        defaults.set(
            Data([0xFF, 0xFE]),
            forKey: UserDefaultsConfigRepository.configKey
        )
        let config = repository.loadConfig()
        XCTAssertEqual(config, AppConfig.defaultConfig)
    }

    func testOverwriteExistingConfig() {
        let first = AppConfig(
            prefixKeyModifiers: 10,
            isOverlayEnabled: true
        )
        repository.saveConfig(first)

        let second = AppConfig(
            prefixKeyModifiers: 20,
            isOverlayEnabled: false
        )
        repository.saveConfig(second)

        let loaded = repository.loadConfig()
        XCTAssertEqual(loaded, second)
    }
}
