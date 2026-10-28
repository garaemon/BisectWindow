import Cocoa

/// Wires the hot-key tap, BisectEngine, the Accessibility client, the
/// overlay, and the settings UI together.
///
/// - `start()` installs the status bar item and starts the tap once the
///   Accessibility permission is granted. AccessibilityPermissionFlow
///   guides the user until then.
/// - Holding the prefix moves `state` to `.pendingInput` and shows the
///   overlay. Releasing the prefix returns `state` to `.idle`.
/// - All callbacks arrive on the main thread.
final class AppCoordinator {
    private let engine = BisectEngine()
    private let systemState: SystemStateProtocol
    private let windowAction: WindowActionProtocol
    private let configRepository: ConfigRepositoryProtocol
    private let overlay: OverlayProtocol
    private let hotKeyManager: HotKeyManager
    private let permissionFlow: AccessibilityPermissionFlow
    private let settingsWindowController: SettingsWindowController
    private var statusBarController: StatusBarController?

    private var state: AppState = .idle
    private var isOverlayEnabled: Bool

    init(
        systemState: SystemStateProtocol = AXClient(),
        windowAction: WindowActionProtocol = AXClient(),
        configRepository: ConfigRepositoryProtocol =
            UserDefaultsConfigRepository(),
        overlay: OverlayProtocol = OverlayWindowController(),
        launchAtLogin: LaunchAtLoginProtocol = LaunchAtLoginClient(),
        permissionFlow: AccessibilityPermissionFlow =
            AccessibilityPermissionFlow(
                permission: AccessibilityPermissionClient(),
                prompt: PermissionPromptWindowController()
            )
    ) {
        let config = configRepository.loadConfig()
        self.systemState = systemState
        self.windowAction = windowAction
        self.configRepository = configRepository
        self.overlay = overlay
        self.permissionFlow = permissionFlow
        self.isOverlayEnabled = config.isOverlayEnabled
        let settingsViewModel = SettingsViewModel(
            configRepository: configRepository,
            launchAtLogin: launchAtLogin
        )
        self.settingsWindowController = SettingsWindowController(
            viewModel: settingsViewModel
        )
        self.hotKeyManager = HotKeyManager(
            prefixModifiers: config.prefixKeyModifiers
        )
        settingsViewModel.onConfigChanged = { [weak self] in
            self?.reloadConfig()
        }
    }

    func start() {
        installStatusBar()
        permissionFlow.begin { [weak self] in
            self?.statusBarController?.setGrantAccessibilityItemVisible(false)
            self?.startHotKeyManager()
        }
        statusBarController?.setGrantAccessibilityItemVisible(
            permissionFlow.isAwaitingPermission
        )
    }

    private func installStatusBar() {
        statusBarController = StatusBarController(
            onOpenSettings: { [weak self] in
                self?.settingsWindowController.showSettings()
            },
            onGrantAccessibility: { [weak self] in
                self?.permissionFlow.showPrompt()
            }
        )
    }

    private func startHotKeyManager() {
        debugLog("[AppCoordinator] screens: \(systemState.listScreens())")
        hotKeyManager.onAction = { [weak self] action in
            self?.handleAction(action)
        }
        hotKeyManager.start()
        debugLog("[AppCoordinator] hotKeyManager started")
    }

    func stop() {
        permissionFlow.cancel()
        hotKeyManager.stop()
        overlay.hideOverlay()
        state = .idle
    }

    /// Refresh overlay-enabled flag and prefix modifiers from persisted config.
    /// Settings UI calls this after saving changes.
    func reloadConfig() {
        let config = configRepository.loadConfig()
        isOverlayEnabled = config.isOverlayEnabled
        hotKeyManager.updatePrefixModifiers(config.prefixKeyModifiers)
        if state == .pendingInput, isOverlayEnabled {
            overlay.showOverlay()
        } else {
            overlay.hideOverlay()
        }
    }
}

extension AppCoordinator {
    /// Applies one hot-key event to the pending-input state, the overlay,
    /// and the focused window. Internal so tests can drive it without a tap.
    func handleAction(_ action: HotKeyAction) {
        switch action {
        case .prefixBegan:
            debugLog("[AppCoordinator] prefix began")
            state = .pendingInput
            if isOverlayEnabled {
                overlay.showOverlay()
            }
        case .prefixEnded:
            debugLog("[AppCoordinator] prefix ended")
            state = .idle
            overlay.hideOverlay()
        case .directionPressed(let direction):
            debugLog("[AppCoordinator] direction: \(direction)")
            handleDirection(direction)
        case .maximizePressed:
            debugLog("[AppCoordinator] maximize pressed")
            handleMaximize()
        }
    }
}

private extension AppCoordinator {
    func handleDirection(_ direction: Direction) {
        guard let window = systemState.fetchFocusedWindow() else {
            debugLog("[AppCoordinator] fetchFocusedWindow failed")
            return
        }
        debugLog("[AppCoordinator] window: pid=\(window.ownerProcessId) frame=\(window.frame) resizable=\(window.isResizable)")
        let screens = systemState.listScreens()
        let result = engine.computeFrame(
            direction: direction, window: window, screens: screens
        )
        debugLog("[AppCoordinator] computeFrame result: \(result)")
        applyResult(result, ownerProcessId: window.ownerProcessId)
    }

    func handleMaximize() {
        guard let window = systemState.fetchFocusedWindow() else {
            debugLog("[AppCoordinator] fetchFocusedWindow failed (maximize)")
            return
        }
        debugLog("[AppCoordinator] maximize window: pid=\(window.ownerProcessId) frame=\(window.frame)")
        let screens = systemState.listScreens()
        let result = engine.computeMaximize(
            window: window, screens: screens
        )
        debugLog("[AppCoordinator] computeMaximize result: \(result)")
        applyResult(result, ownerProcessId: window.ownerProcessId)
    }

    func applyResult(_ result: BisectResult, ownerProcessId: Int) {
        if case .move(let frame) = result {
            debugLog("[AppCoordinator] moving focused window of pid \(ownerProcessId) to \(frame)")
            let didMove = windowAction.moveAndResizeFocusedWindow(
                ownerProcessId: ownerProcessId, to: frame
            )
            debugLog("[AppCoordinator] moveAndResize success: \(didMove)")
        } else {
            debugLog("[AppCoordinator] noAction")
        }
    }
}
