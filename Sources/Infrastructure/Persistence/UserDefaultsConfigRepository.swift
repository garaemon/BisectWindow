import Foundation

final class UserDefaultsConfigRepository: ConfigRepositoryProtocol {
    static let configKey = "BisectWindow.AppConfig"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadConfig() -> AppConfig {
        guard let data = defaults.data(forKey: Self.configKey) else {
            return AppConfig.defaultConfig
        }
        let decoder = JSONDecoder()
        guard let config = try? decoder.decode(
            AppConfig.self, from: data
        ) else {
            return AppConfig.defaultConfig
        }
        return config
    }

    func saveConfig(_ config: AppConfig) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(config) else {
            return
        }
        defaults.set(data, forKey: Self.configKey)
    }
}
