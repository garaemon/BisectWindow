import Cocoa

struct AppConfig: Codable, Equatable {
    var prefixKeyModifiers: UInt
    var isOverlayEnabled: Bool

    // Cmd + Ctrl
    static let defaultPrefixKeyModifiers: UInt =
        NSEvent.ModifierFlags.command.rawValue
            | NSEvent.ModifierFlags.control.rawValue

    static let defaultConfig = AppConfig(
        prefixKeyModifiers: defaultPrefixKeyModifiers,
        isOverlayEnabled: true
    )
}
