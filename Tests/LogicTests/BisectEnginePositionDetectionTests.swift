import XCTest
@testable import BisectWindow

/// Boundary coverage for `BisectEngine.detectPosition` and downstream
/// quarter-tiling / half-snap behaviour driven by `tolerance`.
final class BisectEnginePositionDetectionTests: XCTestCase {
    private let engine = BisectEngine(tolerance: 10.0)
    private let screen = Rect(x: 0, y: 0, width: 1920, height: 1080)
    private let screenInfo = ScreenInfo(
        id: 1, frame: Rect(x: 0, y: 0, width: 1920, height: 1080)
    )

    private func makeWindow(frame: Rect) -> WindowInfo {
        WindowInfo(id: 1, frame: frame, screenId: 1, isResizable: true)
    }

    // MARK: - Exact half / quarter detection

    func testExactLeftHalfDetected() {
        let position = engine.detectPosition(
            window: screen.leftHalf(), screen: screen
        )
        XCTAssertEqual(position, .leftHalf)
    }

    func testExactRightHalfDetected() {
        let position = engine.detectPosition(
            window: screen.rightHalf(), screen: screen
        )
        XCTAssertEqual(position, .rightHalf)
    }

    func testExactTopHalfDetected() {
        let position = engine.detectPosition(
            window: screen.topHalf(), screen: screen
        )
        XCTAssertEqual(position, .topHalf)
    }

    func testExactBottomHalfDetected() {
        let position = engine.detectPosition(
            window: screen.bottomHalf(), screen: screen
        )
        XCTAssertEqual(position, .bottomHalf)
    }

    func testExactTopLeftQuarterDetected() {
        let position = engine.detectPosition(
            window: screen.topLeftQuarter(), screen: screen
        )
        XCTAssertEqual(position, .topLeftQuarter)
    }

    func testExactTopRightQuarterDetected() {
        let position = engine.detectPosition(
            window: screen.topRightQuarter(), screen: screen
        )
        XCTAssertEqual(position, .topRightQuarter)
    }

    func testExactBottomLeftQuarterDetected() {
        let position = engine.detectPosition(
            window: screen.bottomLeftQuarter(), screen: screen
        )
        XCTAssertEqual(position, .bottomLeftQuarter)
    }

    func testExactBottomRightQuarterDetected() {
        let position = engine.detectPosition(
            window: screen.bottomRightQuarter(), screen: screen
        )
        XCTAssertEqual(position, .bottomRightQuarter)
    }

    func testExactMaximizedDetected() {
        let position = engine.detectPosition(
            window: screen, screen: screen
        )
        XCTAssertEqual(position, .maximized)
    }

    // MARK: - Tolerance boundaries (default 10px)

    func testWithinToleranceOnLeftHalfStillCountsAsLeftHalf() {
        // Each component offset by 10px (the inclusive boundary).
        let window = Rect(x: 10, y: 10, width: 970, height: 1090)
        let position = engine.detectPosition(window: window, screen: screen)
        XCTAssertEqual(position, .leftHalf)
    }

    func testBeyondToleranceFallsBackToOther() {
        // Width is off by 11px → outside tolerance.
        let window = Rect(x: 0, y: 0, width: 949, height: 1080)
        let position = engine.detectPosition(window: window, screen: screen)
        XCTAssertEqual(position, .other)
    }

    func testRightHalfWithMenubarOffsetWithinTolerance() {
        // Common macOS case: y offset by menubar height handled before
        // detectPosition (visibleFrame). Here we mirror the residual
        // few-px difference and expect rightHalf detection.
        let window = Rect(x: 960, y: 5, width: 960, height: 1075)
        let position = engine.detectPosition(window: window, screen: screen)
        XCTAssertEqual(position, .rightHalf)
    }

    func testQuarterTilingFiresOnTolerantLeftHalf() {
        // Window is rightHalf within tolerance, pressing Up should jump
        // to topRightQuarter rather than re-snapping to topHalf.
        let window = makeWindow(
            frame: Rect(x: 965, y: 3, width: 955, height: 1077)
        )
        let result = engine.computeFrame(
            direction: .up, window: window, screens: [screenInfo]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 540))
        )
    }

    func testQuarterTilingDoesNotFireBeyondTolerance() {
        // Width 100px too narrow → not rightHalf → Up falls through
        // to topHalf snap.
        let window = makeWindow(
            frame: Rect(x: 1060, y: 0, width: 860, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .up, window: window, screens: [screenInfo]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 0, y: 0, width: 1920, height: 540))
        )
    }

    // MARK: - .other classification

    func testFloatingCenterWindowIsOther() {
        let window = Rect(x: 400, y: 200, width: 1000, height: 600)
        let position = engine.detectPosition(window: window, screen: screen)
        XCTAssertEqual(position, .other)
    }

    func testRightHalfWithWrongHeightIsOther() {
        // Width matches rightHalf but height is wrong by 100 → other.
        let window = Rect(x: 960, y: 0, width: 960, height: 800)
        let position = engine.detectPosition(window: window, screen: screen)
        XCTAssertEqual(position, .other)
    }

    func testNearMaximizedButTooSmallIsOther() {
        let window = Rect(x: 0, y: 0, width: 1920, height: 1000)
        let position = engine.detectPosition(window: window, screen: screen)
        XCTAssertEqual(position, .other)
    }

    // MARK: - Custom tolerance

    func testWiderToleranceAcceptsFurtherMismatch() {
        // With 100px tolerance, a window 50px wider than rightHalf still
        // registers as .rightHalf.
        let lenient = BisectEngine(tolerance: 100.0)
        let window = Rect(x: 960, y: 0, width: 1010, height: 1080)
        let position = lenient.detectPosition(
            window: window, screen: screen
        )
        XCTAssertEqual(position, .rightHalf)
    }

    func testZeroToleranceRequiresExactMatch() {
        let strict = BisectEngine(tolerance: 0.0)
        let almost = Rect(x: 0, y: 0, width: 959, height: 1080)
        XCTAssertEqual(
            strict.detectPosition(window: almost, screen: screen),
            .other
        )
        XCTAssertEqual(
            strict.detectPosition(window: screen.leftHalf(), screen: screen),
            .leftHalf
        )
    }

    // MARK: - Quarter tiling fall-through for orphan combinations

    func testTopHalfPressingUpFallsThroughToTopHalfSnap() {
        // (.topHalf, .up) is not a quarter combination → halfsnap to topHalf.
        let window = makeWindow(frame: screen.topHalf())
        let result = engine.computeFrame(
            direction: .up, window: window, screens: [screenInfo]
        )
        XCTAssertEqual(result, .move(screen.topHalf()))
    }

    func testBottomHalfPressingDownFallsThroughToBottomHalfSnap() {
        let window = makeWindow(frame: screen.bottomHalf())
        let result = engine.computeFrame(
            direction: .down, window: window, screens: [screenInfo]
        )
        XCTAssertEqual(result, .move(screen.bottomHalf()))
    }
}
