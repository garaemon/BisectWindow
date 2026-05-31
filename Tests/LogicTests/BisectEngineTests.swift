import XCTest
@testable import BisectWindow

final class BisectEngineTests: XCTestCase {
    let engine = BisectEngine()
    let screen = ScreenInfo(
        id: 1, frame: Rect(x: 0, y: 0, width: 1920, height: 1080)
    )

    func makeWindow(
        frame: Rect, isResizable: Bool = true
    ) -> WindowInfo {
        WindowInfo(
            id: 1, frame: frame, screenId: 1,
            isResizable: isResizable
        )
    }

    // MARK: - Half tiling

    func testHalfTileRight() {
        let window = makeWindow(
            frame: Rect(x: 100, y: 100, width: 800, height: 600)
        )
        let result = engine.computeFrame(
            direction: .right, window: window, screens: [screen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 1080))
        )
    }

    func testHalfTileLeft() {
        let window = makeWindow(
            frame: Rect(x: 100, y: 100, width: 800, height: 600)
        )
        let result = engine.computeFrame(
            direction: .left, window: window, screens: [screen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 0, y: 0, width: 960, height: 1080))
        )
    }

    func testHalfTileUp() {
        let window = makeWindow(
            frame: Rect(x: 100, y: 100, width: 800, height: 600)
        )
        let result = engine.computeFrame(
            direction: .up, window: window, screens: [screen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 0, y: 0, width: 1920, height: 540))
        )
    }

    func testHalfTileDown() {
        let window = makeWindow(
            frame: Rect(x: 100, y: 100, width: 800, height: 600)
        )
        let result = engine.computeFrame(
            direction: .down, window: window, screens: [screen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 0, y: 540, width: 1920, height: 540))
        )
    }

    // MARK: - Quarter tiling

    func testQuarterTileRightThenUp() {
        let window = makeWindow(
            frame: Rect(x: 960, y: 0, width: 960, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .up, window: window, screens: [screen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 540))
        )
    }

    func testQuarterTileRightThenDown() {
        let window = makeWindow(
            frame: Rect(x: 960, y: 0, width: 960, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .down, window: window, screens: [screen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 540, width: 960, height: 540))
        )
    }

    func testQuarterTileLeftThenUp() {
        let window = makeWindow(
            frame: Rect(x: 0, y: 0, width: 960, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .up, window: window, screens: [screen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 0, y: 0, width: 960, height: 540))
        )
    }

    func testQuarterTileLeftThenDown() {
        let window = makeWindow(
            frame: Rect(x: 0, y: 0, width: 960, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .down, window: window, screens: [screen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 0, y: 540, width: 960, height: 540))
        )
    }

    func testQuarterTileTopThenLeft() {
        let window = makeWindow(
            frame: Rect(x: 0, y: 0, width: 1920, height: 540)
        )
        let result = engine.computeFrame(
            direction: .left, window: window, screens: [screen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 0, y: 0, width: 960, height: 540))
        )
    }

    func testQuarterTileTopThenRight() {
        let window = makeWindow(
            frame: Rect(x: 0, y: 0, width: 1920, height: 540)
        )
        let result = engine.computeFrame(
            direction: .right, window: window, screens: [screen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 540))
        )
    }

    func testQuarterTileBottomThenLeft() {
        let window = makeWindow(
            frame: Rect(x: 0, y: 540, width: 1920, height: 540)
        )
        let result = engine.computeFrame(
            direction: .left, window: window, screens: [screen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 0, y: 540, width: 960, height: 540))
        )
    }

    func testQuarterTileBottomThenRight() {
        let window = makeWindow(
            frame: Rect(x: 0, y: 540, width: 1920, height: 540)
        )
        let result = engine.computeFrame(
            direction: .right, window: window, screens: [screen]
        )
        XCTAssertEqual(
            result,
            .move(Rect(x: 960, y: 540, width: 960, height: 540))
        )
    }

    // MARK: - Maximize

    func testMaximize() {
        let window = makeWindow(
            frame: Rect(x: 100, y: 100, width: 800, height: 600)
        )
        let result = engine.computeMaximize(
            window: window, screens: [screen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 0, y: 0, width: 1920, height: 1080))
        )
    }

    // MARK: - Screen traversal

    func testScreenTraversalRightToNextScreen() {
        // Lands on the next screen's leftHalf so the window stays near
        // the boundary it just crossed.
        let screen2 = ScreenInfo(
            id: 2,
            frame: Rect(x: 1920, y: 0, width: 1920, height: 1080)
        )
        let window = makeWindow(
            frame: Rect(x: 960, y: 0, width: 960, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .right, window: window,
            screens: [screen, screen2]
        )
        XCTAssertEqual(
            result,
            .move(Rect(x: 1920, y: 0, width: 960, height: 1080))
        )
    }

    func testScreenTraversalLeftToNextScreen() {
        // Lands on the previous screen's rightHalf for the same reason.
        let screen2 = ScreenInfo(
            id: 2,
            frame: Rect(x: 1920, y: 0, width: 1920, height: 1080)
        )
        let window = makeWindow(
            frame: Rect(x: 1920, y: 0, width: 960, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .left, window: window,
            screens: [screen, screen2]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 1080))
        )
    }

    func testScreenTraversalNoActionAtBoundary() {
        let window = makeWindow(
            frame: Rect(x: 960, y: 0, width: 960, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .right, window: window, screens: [screen]
        )
        XCTAssertEqual(result, .noAction)
    }

    func testScreenTraversalLeftNoActionAtBoundary() {
        let window = makeWindow(
            frame: Rect(x: 0, y: 0, width: 960, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .left, window: window, screens: [screen]
        )
        XCTAssertEqual(result, .noAction)
    }

    // MARK: - Non-resizable windows

    func testNonResizableWindowMovesOnly() {
        let window = makeWindow(
            frame: Rect(x: 100, y: 100, width: 400, height: 300),
            isResizable: false
        )
        let result = engine.computeFrame(
            direction: .right, window: window, screens: [screen]
        )
        // Centered in right half: (960+480 - 200, 540 - 150)
        let expected = Rect(x: 1240, y: 390, width: 400, height: 300)
        XCTAssertEqual(result, .move(expected))
    }

    func testNonResizableWindowMaximize() {
        let window = makeWindow(
            frame: Rect(x: 100, y: 100, width: 400, height: 300),
            isResizable: false
        )
        let result = engine.computeMaximize(
            window: window, screens: [screen]
        )
        // Centered in full screen: (1920/2-200, 1080/2-150)
        let expected = Rect(x: 760, y: 390, width: 400, height: 300)
        XCTAssertEqual(result, .move(expected))
    }

    // MARK: - Tolerance matching

    func testToleranceMatchingForHalfDetection() {
        // Window slightly off from perfect right-half position
        let window = makeWindow(
            frame: Rect(x: 963, y: 2, width: 957, height: 1078)
        )
        let result = engine.computeFrame(
            direction: .up, window: window, screens: [screen]
        )
        // Should detect as right-half and produce top-right quarter
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 540))
        )
    }

    // MARK: - Position detection

    func testDetectPositionOther() {
        let arbitrary = Rect(x: 100, y: 200, width: 500, height: 400)
        let position = engine.detectPosition(
            window: arbitrary, screen: screen.frame
        )
        XCTAssertEqual(position, .other)
    }

    func testDetectPositionMaximized() {
        let position = engine.detectPosition(
            window: screen.frame, screen: screen.frame
        )
        XCTAssertEqual(position, .maximized)
    }

    // MARK: - Window off screen

    func testNoActionWhenWindowOffScreen() {
        let window = makeWindow(
            frame: Rect(x: 5000, y: 5000, width: 100, height: 100)
        )
        let result = engine.computeFrame(
            direction: .right, window: window, screens: [screen]
        )
        XCTAssertEqual(result, .noAction)
    }

    // MARK: - Quarter does not further subdivide

    func testQuarterDoesNotSubdivide() {
        // Window at top-right quarter, pressing right should snap to right-half
        let window = makeWindow(
            frame: Rect(x: 960, y: 0, width: 960, height: 540)
        )
        let result = engine.computeFrame(
            direction: .right, window: window, screens: [screen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 1080))
        )
    }

    // MARK: - Edge-touch traversal (apps with minimum width)

    func testTraversalRightWhenWindowWiderThanHalf() {
        // App minimum width pushes the window past the exact rightHalf
        // size, but it still hugs the right edge and spans vertically.
        // Lands on screen2's leftHalf to stay near the crossed boundary.
        let screen2 = ScreenInfo(
            id: 2,
            frame: Rect(x: 1920, y: 0, width: 1680, height: 1050)
        )
        let window = makeWindow(
            frame: Rect(x: 860, y: 0, width: 1060, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .right, window: window,
            screens: [screen, screen2]
        )
        XCTAssertEqual(
            result,
            .move(Rect(x: 1920, y: 0, width: 840, height: 1050))
        )
    }

    func testTraversalLeftWhenWindowWiderThanHalf() {
        // Window sits at the left edge of the right screen but is wider
        // than that screen's leftHalf; pressing left should still cross
        // back to the left screen and land on its rightHalf.
        let screen2 = ScreenInfo(
            id: 2,
            frame: Rect(x: 1920, y: 0, width: 1680, height: 1050)
        )
        let window = makeWindow(
            frame: Rect(x: 1920, y: 0, width: 940, height: 1050)
        )
        let result = engine.computeFrame(
            direction: .left, window: window,
            screens: [screen, screen2]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 1080))
        )
    }

    func testNoTraversalFromQuarterWindowAtRightEdge() {
        // topRightQuarter touches the right edge but does not span the
        // full height, so pressing right should fall back to half-snap
        // rather than crossing to the neighbour screen.
        let screen2 = ScreenInfo(
            id: 2,
            frame: Rect(x: 1920, y: 0, width: 1920, height: 1080)
        )
        let window = makeWindow(
            frame: Rect(x: 960, y: 0, width: 960, height: 540)
        )
        let result = engine.computeFrame(
            direction: .right, window: window,
            screens: [screen, screen2]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 1080))
        )
    }

    func testNoTraversalForMaximizedWindow() {
        // Maximized window touches both edges; pressing left should not
        // sneak it onto the previous screen.
        let screen2 = ScreenInfo(
            id: 2,
            frame: Rect(x: 1920, y: 0, width: 1920, height: 1080)
        )
        let window = makeWindow(
            frame: Rect(x: 1920, y: 0, width: 1920, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .left, window: window,
            screens: [screen, screen2]
        )
        // Maximized window's midX == screen.midX, so traversal does
        // not trigger; it falls through to leftHalf snap on screen2.
        XCTAssertEqual(
            result, .move(Rect(x: 1920, y: 0, width: 960, height: 1080))
        )
    }
}
