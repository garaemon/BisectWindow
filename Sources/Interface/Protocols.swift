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
    /// Opens the Accessibility pane of System Settings. Returns before the
    /// user acts.
    func openSystemSettings()
}

/// The window that explains why the Accessibility permission is needed.
/// AccessibilityPermissionFlow owns the prompt and sets `onOpenSettings`.
protocol PermissionPromptProtocol: AnyObject {
    /// Called on the main thread when the user asks to open System Settings.
    var onOpenSettings: (() -> Void)? { get set }
    func showPrompt()
    func hidePrompt()
}

/// The app's login item. The system holds the setting, so AppConfig does
/// not store it.
protocol LaunchAtLoginProtocol {
    /// Whether macOS starts the app at login.
    var isEnabled: Bool { get }
    /// Whether the user turned the login item off in System Settings, so
    /// macOS waits for their approval before starting the app at login.
    var requiresApproval: Bool { get }
    /// Registers or unregisters the login item. Returns false when the
    /// system refuses the change.
    func setEnabled(_ isEnabled: Bool) -> Bool
    /// Opens the Login Items pane of System Settings. Returns before the
    /// user acts.
    func openSystemSettings()
}
