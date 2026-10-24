protocol SystemStateProtocol {
    func fetchFocusedWindow() -> WindowInfo?
    func listScreens() -> [ScreenInfo]
}

protocol WindowActionProtocol {
    func moveAndResizeFocusedWindow(
        ownerProcessId: Int, to frame: Rect
    ) -> Bool
}

protocol ConfigRepositoryProtocol {
    func loadConfig() -> AppConfig
    func saveConfig(_ config: AppConfig)
}

protocol OverlayProtocol {
    func showOverlay()
    func hideOverlay()
}

protocol AccessibilityPermissionProtocol {
    /// Returns whether the app may use the Accessibility API. Never shows UI.
    func isTrusted() -> Bool
    /// Adds the app to the Accessibility list in System Settings and shows
    /// the system permission dialog.
    func requestTrust()
    func openSystemSettings()
}

protocol PermissionPromptProtocol: AnyObject {
    var onOpenSettings: (() -> Void)? { get set }
    func showPrompt()
    func hidePrompt()
}
