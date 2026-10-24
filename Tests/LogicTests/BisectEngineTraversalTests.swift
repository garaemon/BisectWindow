import XCTest
@testable import BisectWindow

/// Focused coverage for the screen-traversal branch of `BisectEngine.computeFrame`.
/// All cases stay in the Domain layer (pure Swift structs).
final class BisectEngineTraversalTests: XCTestCase {
    let engine = BisectEngine()

    // MARK: - Two equal-sized monitors side by side

    private let leftScreen = EngineFixtures.primaryScreen
    private let rightScreen = EngineFixtures.secondaryScreen

    func testRightHalfTraversesAndLandsOnNeighbourLeftHalf() {
        // Window exactly fills the left screen's rightHalf and is pushed
        // further right; the new home is the right screen's leftHalf.
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 960, y: 0, width: 960, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .right, window: window,
            screens: [leftScreen, rightScreen]
        )
        XCTAssertEqual(
            result,
            .move(Rect(x: 1920, y: 0, width: 960, height: 1080))
        )
    }

    func testLeftHalfTraversesAndLandsOnNeighbourRightHalf() {
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 1920, y: 0, width: 960, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .left, window: window,
            screens: [leftScreen, rightScreen]
        )
        XCTAssertEqual(
            result,
            .move(Rect(x: 960, y: 0, width: 960, height: 1080))
        )
    }

    // MARK: - Apps with a minimum window width

    func testWiderThanHalfWindowStillTraversesRight() {
        // The window is 100px wider than the screen's rightHalf because
        // the app refuses to resize narrower; traversal must still fire.
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 860, y: 0, width: 1060, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .right, window: window,
            screens: [leftScreen, rightScreen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 1920, y: 0, width: 960, height: 1080))
        )
    }

    func testWiderThanHalfWindowStillTraversesLeft() {
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 1920, y: 0, width: 1060, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .left, window: window,
            screens: [leftScreen, rightScreen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 1080))
        )
    }

    // MARK: - Three monitors in a row

    func testTraverseFromMiddleScreenRight() {
        let middleScreen = ScreenInfo(
            id: 2, frame: Rect(x: 1920, y: 0, width: 1920, height: 1080)
        )
        let farRightScreen = ScreenInfo(
            id: 3, frame: Rect(x: 3840, y: 0, width: 1920, height: 1080)
        )
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 2880, y: 0, width: 960, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .right, window: window,
            screens: [leftScreen, middleScreen, farRightScreen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 3840, y: 0, width: 960, height: 1080))
        )
    }

    func testTraverseFromMiddleScreenLeft() {
        let middleScreen = ScreenInfo(
            id: 2, frame: Rect(x: 1920, y: 0, width: 1920, height: 1080)
        )
        let farRightScreen = ScreenInfo(
            id: 3, frame: Rect(x: 3840, y: 0, width: 1920, height: 1080)
        )
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 1920, y: 0, width: 960, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .left, window: window,
            screens: [leftScreen, middleScreen, farRightScreen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 1080))
        )
    }

    // MARK: - Screens with different sizes

    func testTraverseFromBigScreenToSmallScreen() {
        // Big primary (1920x1080) → small secondary (1280x800)
        let small = ScreenInfo(
            id: 2, frame: Rect(x: 1920, y: 0, width: 1280, height: 800)
        )
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 960, y: 0, width: 960, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .right, window: window,
            screens: [leftScreen, small]
        )
        // Lands on small.leftHalf = (1920, 0, 640, 800)
        XCTAssertEqual(
            result, .move(Rect(x: 1920, y: 0, width: 640, height: 800))
        )
    }

    func testTraverseFromSmallScreenToBigScreen() {
        let small = ScreenInfo(
            id: 1, frame: Rect(x: 0, y: 0, width: 1280, height: 800)
        )
        let big = ScreenInfo(
            id: 2, frame: Rect(x: 1280, y: 0, width: 1920, height: 1080)
        )
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 640, y: 0, width: 640, height: 800)
        )
        let result = engine.computeFrame(
            direction: .right, window: window,
            screens: [small, big]
        )
        // Lands on big.leftHalf = (1280, 0, 960, 1080)
        XCTAssertEqual(
            result, .move(Rect(x: 1280, y: 0, width: 960, height: 1080))
        )
    }

    func testWiderThanHalfWindowTraversesRightOntoSmallerScreen() {
        // App minimum width pushes the window past the exact rightHalf
        // size, but it still hugs the right edge and spans vertically.
        // Lands on the smaller screen's leftHalf, next to the boundary.
        let smallerScreen = ScreenInfo(
            id: 2,
            frame: Rect(x: 1920, y: 0, width: 1680, height: 1050)
        )
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 860, y: 0, width: 1060, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .right, window: window,
            screens: [leftScreen, smallerScreen]
        )
        XCTAssertEqual(
            result,
            .move(Rect(x: 1920, y: 0, width: 840, height: 1050))
        )
    }

    func testWiderThanHalfWindowTraversesLeftFromSmallerScreen() {
        // Window sits at the left edge of the right screen but is wider
        // than that screen's leftHalf; pressing left should still cross
        // back to the left screen and land on its rightHalf.
        let smallerScreen = ScreenInfo(
            id: 2,
            frame: Rect(x: 1920, y: 0, width: 1680, height: 1050)
        )
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 1920, y: 0, width: 940, height: 1050)
        )
        let result = engine.computeFrame(
            direction: .left, window: window,
            screens: [leftScreen, smallerScreen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 1080))
        )
    }

    // MARK: - Vertical span guard

    func testQuarterWindowTouchingRightEdgeDoesNotTraverse() {
        // topRightQuarter touches the right edge but only spans the top
        // half vertically; should snap to rightHalf instead of crossing.
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 960, y: 0, width: 960, height: 540)
        )
        let result = engine.computeFrame(
            direction: .right, window: window,
            screens: [leftScreen, rightScreen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 1080))
        )
    }

    func testBottomRightQuarterDoesNotTraverse() {
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 960, y: 540, width: 960, height: 540)
        )
        let result = engine.computeFrame(
            direction: .right, window: window,
            screens: [leftScreen, rightScreen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 1080))
        )
    }

    // MARK: - Edge-touch guard

    func testWindowFloatingInRightHalfButNotTouchingEdgeDoesNotTraverse() {
        // Right half by midX, but stops 200px short of the right edge.
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 960, y: 0, width: 760, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .right, window: window,
            screens: [leftScreen, rightScreen]
        )
        // Falls through to rightHalf snap.
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 1080))
        )
    }

    func testWindowCenteredOnScreenDoesNotTraverse() {
        // midX == screen.midX → biased neither left nor right.
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 460, y: 0, width: 1000, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .right, window: window,
            screens: [leftScreen, rightScreen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 1080))
        )
    }

    func testMaximizedWindowDoesNotTraverseRight() {
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 0, y: 0, width: 1920, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .right, window: window,
            screens: [leftScreen, rightScreen]
        )
        // Falls through to rightHalf snap.
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 1080))
        )
    }

    func testMaximizedWindowDoesNotTraverseLeft() {
        // Maximized window touches both edges; pressing left should not
        // sneak it onto the previous screen.
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 1920, y: 0, width: 1920, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .left, window: window,
            screens: [leftScreen, rightScreen]
        )
        // Maximized window's midX == screen.midX, so traversal does
        // not trigger; it falls through to leftHalf snap on rightScreen.
        XCTAssertEqual(
            result, .move(Rect(x: 1920, y: 0, width: 960, height: 1080))
        )
    }

    // MARK: - Boundary cases (no traversal when no neighbour)

    func testNoNeighbourSoTraversalReturnsNoAction() {
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 960, y: 0, width: 960, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .right, window: window, screens: [leftScreen]
        )
        XCTAssertEqual(result, .noAction)
    }

    func testLeftEdgeNoNeighbourSoNoTraversal() {
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 0, y: 0, width: 960, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .left, window: window, screens: [leftScreen]
        )
        XCTAssertEqual(result, .noAction)
    }

    // MARK: - Up/Down never traverse (V2.0 scope)

    func testRightHalfPressingUpProducesQuarterNotTraversal() {
        // Even though there is a screen above conceptually, V2.0
        // does not traverse vertically; quarter tiling kicks in.
        let topScreen = ScreenInfo(
            id: 3, frame: Rect(x: 0, y: -1080, width: 1920, height: 1080)
        )
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 960, y: 0, width: 960, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .up, window: window,
            screens: [leftScreen, topScreen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 540))
        )
    }

    func testBottomHalfPressingDownDoesNotTraverseVertically() {
        let bottomScreen = ScreenInfo(
            id: 3, frame: Rect(x: 0, y: 1080, width: 1920, height: 1080)
        )
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 0, y: 540, width: 1920, height: 540)
        )
        let result = engine.computeFrame(
            direction: .down, window: window,
            screens: [leftScreen, bottomScreen]
        )
        // bottomHalf + down: not a quarter combination, no traversal,
        // falls through to bottomHalf snap (a no-op visually).
        XCTAssertEqual(
            result, .move(Rect(x: 0, y: 540, width: 1920, height: 540))
        )
    }

    // MARK: - Non-resizable windows

    func testNonResizableWindowAwayFromEdgeHalfSnapsWithoutResizing() {
        // The window stops 120px short of the right edge, outside the
        // 50px edge tolerance, so it half-snaps on the same screen.
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 1000, y: 100, width: 800, height: 600),
            isResizable: false
        )
        let result = engine.computeFrame(
            direction: .right, window: window,
            screens: [leftScreen, rightScreen]
        )
        // Half-snap result, centred because non-resizable. rightHalf
        // target = (960, 0, 960, 1080), centre = (1440, 540), window
        // size kept at (800, 600).
        XCTAssertEqual(
            result,
            .move(Rect(x: 1040, y: 240, width: 800, height: 600))
        )
    }

    func testNonResizableWindowAtRightEdgeCrossesToNextScreen() {
        // Non-resizable but already touching the right edge of leftScreen
        // and spanning vertically → traversal fires; result is the
        // centred placement inside the right screen's leftHalf target.
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 1120, y: 0, width: 800, height: 1080),
            isResizable: false
        )
        let result = engine.computeFrame(
            direction: .right, window: window,
            screens: [leftScreen, rightScreen]
        )
        // Target = rightScreen.leftHalf = (1920, 0, 960, 1080);
        // centre = (2400, 540); window size kept at (800, 1080).
        XCTAssertEqual(
            result,
            .move(Rect(x: 2000, y: 0, width: 800, height: 1080))
        )
    }
}
