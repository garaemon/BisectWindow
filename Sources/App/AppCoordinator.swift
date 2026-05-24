import Cocoa

final class AppCoordinator {
    private let engine = BisectEngine()
    private let axClient = AXClient()
    private let configRepository = UserDefaultsConfigRepository()
    private let hotKeyManager: HotKeyManager

    private var state: AppState = .idle
    private var accessibilityPollTimer: Timer?

    init() {
        let config = configRepository.loadConfig()
        hotKeyManager = HotKeyManager(
            prefixModifiers: config.prefixKeyModifiers
        )
    }

    func start() {
        let trusted = AccessibilityChecker.checkAccessibility()
        debugLog("[AppCoordinator] accessibility trusted: \(trusted)")
        if trusted {
            startHotKeyManager()
        } else {
            debugLog("[AppCoordinator] waiting for accessibility permission...")
            pollForAccessibility()
        }
    }

    private func startHotKeyManager() {
        let screens = axClient.listScreens()
        debugLog("[AppCoordinator] screens: \(screens)")

        let config = configRepository.loadConfig()
        debugLog("[AppCoordinator] config: prefixModifiers=\(config.prefixKeyModifiers) (0x\(String(config.prefixKeyModifiers, radix: 16)))")

        hotKeyManager.onAction = { [weak self] action in
            self?.handleAction(action)
        }
        hotKeyManager.start()
        debugLog("[AppCoordinator] hotKeyManager started")
    }

    private func pollForAccessibility() {
        accessibilityPollTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0, repeats: true
        ) { [weak self] timer in
            if AXIsProcessTrusted() {
                debugLog("[AppCoordinator] accessibility now granted!")
                timer.invalidate()
                self?.accessibilityPollTimer = nil
                self?.startHotKeyManager()
            }
        }
    }

    func stop() {
        hotKeyManager.stop()
        state = .idle
    }
}

// MARK: - Private

private extension AppCoordinator {
    func handleAction(_ action: HotKeyAction) {
        switch action {
        case .prefixBegan:
            debugLog("[AppCoordinator] prefix began")
            state = .pendingInput
        case .prefixEnded:
            debugLog("[AppCoordinator] prefix ended")
            state = .idle
        case .directionPressed(let direction):
            debugLog("[AppCoordinator] direction: \(direction)")
            handleDirection(direction)
        case .maximizePressed:
            debugLog("[AppCoordinator] maximize pressed")
            handleMaximize()
        }
    }

    func handleDirection(_ direction: Direction) {
        guard let window = axClient.fetchFocusedWindow() else {
            debugLog("[AppCoordinator] fetchFocusedWindow failed")
            return
        }
        debugLog("[AppCoordinator] window: pid=\(window.id) frame=\(window.frame) screenId=\(window.screenId) resizable=\(window.isResizable)")
        let screens = axClient.listScreens()
        let result = engine.computeFrame(
            direction: direction, window: window, screens: screens
        )
        debugLog("[AppCoordinator] computeFrame result: \(result)")
        applyResult(result, windowId: window.id)
    }

    func handleMaximize() {
        guard let window = axClient.fetchFocusedWindow() else {
            debugLog("[AppCoordinator] fetchFocusedWindow failed (maximize)")
            return
        }
        debugLog("[AppCoordinator] maximize window: pid=\(window.id) frame=\(window.frame)")
        let screens = axClient.listScreens()
        let result = engine.computeMaximize(
            window: window, screens: screens
        )
        debugLog("[AppCoordinator] computeMaximize result: \(result)")
        applyResult(result, windowId: window.id)
    }

    func applyResult(_ result: BisectResult, windowId: Int) {
        if case .move(let frame) = result {
            debugLog("[AppCoordinator] moving window \(windowId) to \(frame)")
            let success = axClient.moveAndResize(
                windowId: windowId, to: frame
            )
            debugLog("[AppCoordinator] moveAndResize success: \(success)")
        } else {
            debugLog("[AppCoordinator] noAction")
        }
    }
}
