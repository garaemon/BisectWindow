@testable import BisectWindow

/// Screens and windows shared by the BisectEngine test suites. The primary
/// screen sits at the origin and the secondary screen sits to its right.
enum EngineFixtures {
    static let primaryScreen = ScreenInfo(
        id: 1, frame: Rect(x: 0, y: 0, width: 1920, height: 1080)
    )
    static let secondaryScreen = ScreenInfo(
        id: 2, frame: Rect(x: 1920, y: 0, width: 1920, height: 1080)
    )

    static func makeWindow(
        frame: Rect, isResizable: Bool = true
    ) -> WindowInfo {
        WindowInfo(
            ownerProcessId: 1, frame: frame, isResizable: isResizable
        )
    }
}
