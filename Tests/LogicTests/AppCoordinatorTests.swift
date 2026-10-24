import XCTest
@testable import BisectWindow

final class AppCoordinatorTests: XCTestCase {
    private let screen = ScreenInfo(
        id: 1, frame: Rect(x: 0, y: 0, width: 1920, height: 1080)
    )
    private var systemState: FakeSystemState!
    private var windowAction: RecordingWindowAction!
    private var configRepository: StubConfigRepository!
    private var overlay: RecordingOverlay!

    override func setUp() {
        super.setUp()
        systemState = FakeSystemState(screens: [screen])
        windowAction = RecordingWindowAction()
        configRepository = StubConfigRepository()
        overlay = RecordingOverlay()
    }

    private func makeCoordinator() -> AppCoordinator {
        AppCoordinator(
            systemState: systemState,
            windowAction: windowAction,
            configRepository: configRepository,
            overlay: overlay
        )
    }

    func testPrefixBeganShowsOverlayWhenEnabled() {
        let coordinator = makeCoordinator()

        coordinator.handleAction(.prefixBegan)

        XCTAssertEqual(overlay.events, [.shown])
    }

    func testPrefixBeganKeepsOverlayHiddenWhenDisabled() {
        configRepository.storedConfig.isOverlayEnabled = false
        let coordinator = makeCoordinator()

        coordinator.handleAction(.prefixBegan)

        XCTAssertEqual(overlay.events, [])
    }

    func testPrefixEndedHidesOverlay() {
        let coordinator = makeCoordinator()
        coordinator.handleAction(.prefixBegan)

        coordinator.handleAction(.prefixEnded)

        XCTAssertEqual(overlay.events, [.shown, .hidden])
    }

    func testReloadConfigHidesOverlayWhenDisabledWhilePending() {
        let coordinator = makeCoordinator()
        coordinator.handleAction(.prefixBegan)
        configRepository.storedConfig.isOverlayEnabled = false

        coordinator.reloadConfig()

        XCTAssertEqual(overlay.events, [.shown, .hidden])
    }

    func testReloadConfigShowsOverlayWhenEnabledWhilePending() {
        configRepository.storedConfig.isOverlayEnabled = false
        let coordinator = makeCoordinator()
        coordinator.handleAction(.prefixBegan)
        configRepository.storedConfig.isOverlayEnabled = true

        coordinator.reloadConfig()

        XCTAssertEqual(overlay.events, [.shown])
    }

    func testDirectionMovesFocusedWindowToComputedHalf() {
        systemState.focusedWindow = WindowInfo(
            ownerProcessId: 42,
            frame: Rect(x: 500, y: 300, width: 800, height: 400),
            isResizable: true
        )
        let coordinator = makeCoordinator()

        coordinator.handleAction(.directionPressed(.left))

        XCTAssertEqual(
            windowAction.moves.first?.frame, screen.frame.leftHalf()
        )
    }

    func testDirectionMovesWindowOfFocusedProcess() {
        systemState.focusedWindow = WindowInfo(
            ownerProcessId: 42,
            frame: Rect(x: 500, y: 300, width: 800, height: 400),
            isResizable: true
        )
        let coordinator = makeCoordinator()

        coordinator.handleAction(.directionPressed(.left))

        XCTAssertEqual(windowAction.moves.first?.ownerProcessId, 42)
    }

    func testMaximizeMovesFocusedWindowToFullScreen() {
        systemState.focusedWindow = WindowInfo(
            ownerProcessId: 42,
            frame: Rect(x: 500, y: 300, width: 800, height: 400),
            isResizable: true
        )
        let coordinator = makeCoordinator()

        coordinator.handleAction(.maximizePressed)

        XCTAssertEqual(windowAction.moves.first?.frame, screen.frame)
    }

    func testDirectionWithoutFocusedWindowDoesNotMove() {
        let coordinator = makeCoordinator()

        coordinator.handleAction(.directionPressed(.left))

        XCTAssertTrue(windowAction.moves.isEmpty)
    }
}

private final class FakeSystemState: SystemStateProtocol {
    var focusedWindow: WindowInfo?
    let screens: [ScreenInfo]

    init(screens: [ScreenInfo]) {
        self.screens = screens
    }

    func fetchFocusedWindow() -> WindowInfo? { focusedWindow }
    func listScreens() -> [ScreenInfo] { screens }
}

private final class RecordingWindowAction: WindowActionProtocol {
    private(set) var moves: [(ownerProcessId: Int, frame: Rect)] = []

    func moveAndResizeFocusedWindow(
        ownerProcessId: Int, to frame: Rect
    ) -> Bool {
        moves.append((ownerProcessId, frame))
        return true
    }
}

private final class StubConfigRepository: ConfigRepositoryProtocol {
    var storedConfig: AppConfig = .defaultConfig

    func loadConfig() -> AppConfig { storedConfig }
    func saveConfig(_ config: AppConfig) { storedConfig = config }
}

private final class RecordingOverlay: OverlayProtocol {
    enum Event: Equatable {
        case shown
        case hidden
    }

    private(set) var events: [Event] = []

    func showOverlay() { events.append(.shown) }
    func hideOverlay() { events.append(.hidden) }
}
