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

    // MARK: - Three-screen horizontal row

    func testThreeScreenRowRightFromMiddlePicksFarRight() {
        let middle = ScreenInfo(
            id: 10, frame: Rect(x: 1920, y: 0, width: 1920, height: 1080)
        )
        let far = ScreenInfo(
            id: 11, frame: Rect(x: 3840, y: 0, width: 1920, height: 1080)
        )
        let result = ScreenGeometry.findAdjacentScreen(
            from: middle, direction: .right,
            screens: [screen1, middle, far]
        )
        XCTAssertEqual(result, far)
    }

    func testThreeScreenRowLeftFromFarRightPicksMiddle() {
        let middle = ScreenInfo(
            id: 10, frame: Rect(x: 1920, y: 0, width: 1920, height: 1080)
        )
        let far = ScreenInfo(
            id: 11, frame: Rect(x: 3840, y: 0, width: 1920, height: 1080)
        )
        let result = ScreenGeometry.findAdjacentScreen(
            from: far, direction: .left,
            screens: [screen1, middle, far]
        )
        XCTAssertEqual(result, middle)
    }

    func testRightPicksClosestWhenMultipleScreensFurtherRight() {
        // Two candidates: the closer one (right at maxX) and a distant one.
        let near = ScreenInfo(
            id: 20, frame: Rect(x: 1920, y: 0, width: 1280, height: 1080)
        )
        let distant = ScreenInfo(
            id: 21, frame: Rect(x: 5000, y: 0, width: 1280, height: 1080)
        )
        let result = ScreenGeometry.findAdjacentScreen(
            from: screen1, direction: .right,
            screens: [screen1, near, distant]
        )
        XCTAssertEqual(result, near)
    }

    // MARK: - Different sizes and vertical alignment

    func testSmallSecondaryAtRightWithVerticalOffsetStillAdjacent() {
        // Laptop-style configuration: secondary monitor smaller and
        // vertically offset but still overlaps the primary's range.
        let primary = ScreenInfo(
            id: 30, frame: Rect(x: 0, y: 0, width: 3008, height: 1692)
        )
        let secondary = ScreenInfo(
            id: 31, frame: Rect(x: 3008, y: 79, width: 1680, height: 1025)
        )
        let result = ScreenGeometry.findAdjacentScreen(
            from: primary, direction: .right,
            screens: [primary, secondary]
        )
        XCTAssertEqual(result, secondary)
    }

    func testVerticalOverlapBoundaryIsStrict() {
        // Touching edge-to-edge (maxY == minY) is NOT considered overlap
        // by hasVerticalOverlap (uses strict <).
        let touching = ScreenInfo(
            id: 40, frame: Rect(x: 1920, y: 1080, width: 1920, height: 1080)
        )
        let result = ScreenGeometry.findAdjacentScreen(
            from: screen1, direction: .right,
            screens: [screen1, touching]
        )
        XCTAssertNil(result)
    }

    func testTinyVerticalOverlapEnoughForAdjacency() {
        let almost = ScreenInfo(
            // overlaps primary by 1 pixel vertically
            id: 41, frame: Rect(x: 1920, y: 1079, width: 1920, height: 1080)
        )
        let result = ScreenGeometry.findAdjacentScreen(
            from: screen1, direction: .right,
            screens: [screen1, almost]
        )
        XCTAssertEqual(result, almost)
    }

    // MARK: - Vertical adjacency

    func testDownPicksClosestWhenMultipleScreensBelow() {
        let near = ScreenInfo(
            id: 50, frame: Rect(x: 0, y: 1080, width: 1920, height: 600)
        )
        let distant = ScreenInfo(
            id: 51, frame: Rect(x: 0, y: 3000, width: 1920, height: 1080)
        )
        let result = ScreenGeometry.findAdjacentScreen(
            from: screen1, direction: .down,
            screens: [screen1, near, distant]
        )
        XCTAssertEqual(result, near)
    }

    func testUpReturnsNilWhenScreenAboveHasNoHorizontalOverlap() {
        let aside = ScreenInfo(
            id: 60, frame: Rect(x: 4000, y: -1080, width: 1920, height: 1080)
        )
        let result = ScreenGeometry.findAdjacentScreen(
            from: screen1, direction: .up,
            screens: [screen1, aside]
        )
        XCTAssertNil(result)
    }

    // MARK: - Edge cases

    func testFindScreenReturnsNilForEmptyScreensList() {
        let window = Rect(x: 100, y: 100, width: 800, height: 600)
        XCTAssertNil(ScreenGeometry.findScreen(containing: window, screens: []))
    }

    func testFindAdjacentScreenReturnsNilForEmptyScreensList() {
        XCTAssertNil(
            ScreenGeometry.findAdjacentScreen(
                from: screen1, direction: .right, screens: []
            )
        )
    }

    func testFindAdjacentScreenIgnoresSelfWhenAlone() {
        // Even if the current screen is in the list, it is filtered out.
        XCTAssertNil(
            ScreenGeometry.findAdjacentScreen(
                from: screen1, direction: .right, screens: [screen1]
            )
        )
    }

    func testFindScreenUsesCenterPointNotEdges() {
        // The window crosses the screen boundary but its center sits on
        // screen2 → screen2 should be returned.
        let crossing = Rect(x: 1700, y: 100, width: 800, height: 600)
        let result = ScreenGeometry.findScreen(
            containing: crossing, screens: [screen1, screen2]
        )
        XCTAssertEqual(result, screen2)
    }
}
