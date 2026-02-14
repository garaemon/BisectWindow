import XCTest
@testable import BisectWindow

final class ScreenGeometryTests: XCTestCase {
    let screen1 = ScreenInfo(
        id: 1, frame: Rect(x: 0, y: 0, width: 1920, height: 1080)
    )
    let screen2 = ScreenInfo(
        id: 2, frame: Rect(x: 1920, y: 0, width: 1920, height: 1080)
    )
    let screen3 = ScreenInfo(
        id: 3, frame: Rect(x: 0, y: 1080, width: 1920, height: 1080)
    )

    func testFindScreenContainingWindowOnScreen1() {
        let window = Rect(x: 100, y: 100, width: 800, height: 600)
        let result = ScreenGeometry.findScreen(
            containing: window, screens: [screen1, screen2]
        )
        XCTAssertEqual(result, screen1)
    }

    func testFindScreenContainingWindowOnScreen2() {
        let window = Rect(x: 2000, y: 100, width: 800, height: 600)
        let result = ScreenGeometry.findScreen(
            containing: window, screens: [screen1, screen2]
        )
        XCTAssertEqual(result, screen2)
    }

    func testFindScreenReturnsNilWhenOffScreen() {
        let window = Rect(x: 5000, y: 5000, width: 100, height: 100)
        let result = ScreenGeometry.findScreen(
            containing: window, screens: [screen1, screen2]
        )
        XCTAssertNil(result)
    }

    func testFindAdjacentScreenToTheRight() {
        let result = ScreenGeometry.findAdjacentScreen(
            from: screen1, direction: .right, screens: [screen1, screen2]
        )
        XCTAssertEqual(result, screen2)
    }

    func testFindAdjacentScreenToTheLeft() {
        let result = ScreenGeometry.findAdjacentScreen(
            from: screen2, direction: .left, screens: [screen1, screen2]
        )
        XCTAssertEqual(result, screen1)
    }

    func testFindAdjacentScreenDown() {
        let result = ScreenGeometry.findAdjacentScreen(
            from: screen1, direction: .down,
            screens: [screen1, screen2, screen3]
        )
        XCTAssertEqual(result, screen3)
    }

    func testFindAdjacentScreenUp() {
        let result = ScreenGeometry.findAdjacentScreen(
            from: screen3, direction: .up,
            screens: [screen1, screen2, screen3]
        )
        XCTAssertEqual(result, screen1)
    }

    func testFindAdjacentScreenReturnsNilAtEdge() {
        let result = ScreenGeometry.findAdjacentScreen(
            from: screen1, direction: .left, screens: [screen1, screen2]
        )
        XCTAssertNil(result)
    }

    func testFindAdjacentScreenReturnsNilWithoutVerticalOverlap() {
        let noOverlap = ScreenInfo(
            id: 4, frame: Rect(x: 1920, y: 2000, width: 1920, height: 1080)
        )
        let result = ScreenGeometry.findAdjacentScreen(
            from: screen1, direction: .right, screens: [screen1, noOverlap]
        )
        XCTAssertNil(result)
    }
}
