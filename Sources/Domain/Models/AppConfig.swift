struct AppConfig: Codable, Equatable {
    var prefixKeyModifiers: UInt
    var isOverlayEnabled: Bool

    /// Cmd + Ctrl. The bits follow NSEvent.ModifierFlags (command = 1 << 20,
    /// control = 1 << 18), written as integers to keep the Domain layer free
    /// of AppKit.
    static let defaultPrefixKeyModifiers: UInt = (1 << 20) | (1 << 18)

    static let defaultConfig = AppConfig(
        prefixKeyModifiers: defaultPrefixKeyModifiers,
        isOverlayEnabled: true
    )
}
