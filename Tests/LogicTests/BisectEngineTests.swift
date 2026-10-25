import XCTest
@testable import BisectWindow

final class BisectEngineTests: XCTestCase {
    let engine = BisectEngine()
    let screen = EngineFixtures.primaryScreen

    // MARK: - Half tiling

    func testHalfTileRight() {
        let window = EngineFixtures.makeWindow(
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
        let window = EngineFixtures.makeWindow(
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
        let window = EngineFixtures.makeWindow(
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
        let window = EngineFixtures.makeWindow(
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
        let window = EngineFixtures.makeWindow(
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
        let window = EngineFixtures.makeWindow(
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
        let window = EngineFixtures.makeWindow(
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
        let window = EngineFixtures.makeWindow(
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
        let window = EngineFixtures.makeWindow(
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
        let window = EngineFixtures.makeWindow(
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
        let window = EngineFixtures.makeWindow(
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
        let window = EngineFixtures.makeWindow(
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
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 100, y: 100, width: 800, height: 600)
        )
        let result = engine.computeMaximize(
            window: window, screens: [screen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 0, y: 0, width: 1920, height: 1080))
        )
    }

    // MARK: - Non-resizable windows

    func testNonResizableWindowMovesOnly() {
        let window = EngineFixtures.makeWindow(
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
        let window = EngineFixtures.makeWindow(
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
        let window = EngineFixtures.makeWindow(
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
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 5000, y: 5000, width: 100, height: 100)
        )
        let result = engine.computeFrame(
            direction: .right, window: window, screens: [screen]
        )
        XCTAssertEqual(result, .noAction)
    }

    func testHalfTileLeftWhenWindowCenterHangsOffScreen() {
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 960, y: 0, width: 1920, height: 1080)
        )
        let result = engine.computeFrame(
            direction: .left, window: window, screens: [screen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 0, y: 0, width: 960, height: 1080))
        )
    }

    // MARK: - Quarter does not further subdivide

    func testQuarterDoesNotSubdivide() {
        // Window at top-right quarter, pressing right should snap to right-half
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 960, y: 0, width: 960, height: 540)
        )
        let result = engine.computeFrame(
            direction: .right, window: window, screens: [screen]
        )
        XCTAssertEqual(
            result, .move(Rect(x: 960, y: 0, width: 960, height: 1080))
        )
    }
}
