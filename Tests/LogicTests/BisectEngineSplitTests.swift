import XCTest
@testable import BisectWindow

final class BisectEngineSplitTests: XCTestCase {
    let engine = BisectEngine()

    func testSplitBelowKeepsTopHalfOfWindowFrame() {
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 100, y: 200, width: 800, height: 600)
        )
        let result = engine.computeSplit(direction: .below, window: window)
        XCTAssertEqual(
            result, .move(Rect(x: 100, y: 200, width: 800, height: 300))
        )
    }

    func testSplitRightKeepsLeftHalfOfWindowFrame() {
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 100, y: 200, width: 800, height: 600)
        )
        let result = engine.computeSplit(direction: .right, window: window)
        XCTAssertEqual(
            result, .move(Rect(x: 100, y: 200, width: 400, height: 600))
        )
    }

    func testSplitBelowTwiceGivesTopQuarterOfOriginalFrame() {
        let original = Rect(x: 0, y: 0, width: 1920, height: 1080)
        let first = engine.computeSplit(
            direction: .below,
            window: EngineFixtures.makeWindow(frame: original)
        )
        guard case .move(let halfFrame) = first else {
            return XCTFail("Expected a move, got \(first)")
        }
        let second = engine.computeSplit(
            direction: .below,
            window: EngineFixtures.makeWindow(frame: halfFrame)
        )
        XCTAssertEqual(
            second, .move(Rect(x: 0, y: 0, width: 1920, height: 270))
        )
    }

    func testSplitOnNonResizableWindowDoesNothing() {
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: 100, y: 200, width: 800, height: 600),
            isResizable: false
        )
        XCTAssertEqual(
            engine.computeSplit(direction: .below, window: window), .noAction
        )
    }

    func testSplitBelowMinimumSizeDoesNothing() {
        let window = EngineFixtures.makeWindow(
            frame: Rect(
                x: 100, y: 200,
                width: 800, height: BisectEngine.minimumSplitSize * 2 - 2
            )
        )
        XCTAssertEqual(
            engine.computeSplit(direction: .below, window: window), .noAction
        )
    }

    func testSplitRightBelowMinimumSizeDoesNothing() {
        let window = EngineFixtures.makeWindow(
            frame: Rect(
                x: 100, y: 200,
                width: BisectEngine.minimumSplitSize * 2 - 2, height: 600
            )
        )
        XCTAssertEqual(
            engine.computeSplit(direction: .right, window: window), .noAction
        )
    }

    func testSplitWorksForWindowOffEveryScreen() {
        let window = EngineFixtures.makeWindow(
            frame: Rect(x: -5000, y: -5000, width: 800, height: 600)
        )
        XCTAssertEqual(
            engine.computeSplit(direction: .right, window: window),
            .move(Rect(x: -5000, y: -5000, width: 400, height: 600))
        )
    }
}
