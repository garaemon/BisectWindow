import XCTest
@testable import BisectWindow

final class RectTests: XCTestCase {
    let screen = Rect(x: 0, y: 0, width: 1920, height: 1080)

    func testComputedProperties() {
        XCTAssertEqual(screen.minX, 0)
        XCTAssertEqual(screen.minY, 0)
        XCTAssertEqual(screen.maxX, 1920)
        XCTAssertEqual(screen.maxY, 1080)
        XCTAssertEqual(screen.midX, 960)
        XCTAssertEqual(screen.midY, 540)
    }

    func testIsApproximatelyEqualExactMatch() {
        let other = Rect(x: 0, y: 0, width: 1920, height: 1080)
        XCTAssertTrue(screen.isApproximatelyEqual(
            to: other, tolerance: BisectEngine.defaultTolerance
        ))
    }

    func testIsApproximatelyEqualWithinTolerance() {
        let other = Rect(x: 5, y: -3, width: 1925, height: 1075)
        XCTAssertTrue(screen.isApproximatelyEqual(
            to: other, tolerance: BisectEngine.defaultTolerance
        ))
    }

    func testIsApproximatelyEqualOutsideTolerance() {
        let other = Rect(x: 15, y: 0, width: 1920, height: 1080)
        XCTAssertFalse(screen.isApproximatelyEqual(
            to: other, tolerance: BisectEngine.defaultTolerance
        ))
    }

    func testLeftHalf() {
        let expected = Rect(x: 0, y: 0, width: 960, height: 1080)
        XCTAssertEqual(screen.leftHalf(), expected)
    }

    func testRightHalf() {
        let expected = Rect(x: 960, y: 0, width: 960, height: 1080)
        XCTAssertEqual(screen.rightHalf(), expected)
    }

    func testTopHalf() {
        let expected = Rect(x: 0, y: 0, width: 1920, height: 540)
        XCTAssertEqual(screen.topHalf(), expected)
    }

    func testBottomHalf() {
        let expected = Rect(x: 0, y: 540, width: 1920, height: 540)
        XCTAssertEqual(screen.bottomHalf(), expected)
    }

    func testTopLeftQuarter() {
        let expected = Rect(x: 0, y: 0, width: 960, height: 540)
        XCTAssertEqual(screen.topLeftQuarter(), expected)
    }

    func testTopRightQuarter() {
        let expected = Rect(x: 960, y: 0, width: 960, height: 540)
        XCTAssertEqual(screen.topRightQuarter(), expected)
    }

    func testBottomLeftQuarter() {
        let expected = Rect(x: 0, y: 540, width: 960, height: 540)
        XCTAssertEqual(screen.bottomLeftQuarter(), expected)
    }

    func testBottomRightQuarter() {
        let expected = Rect(x: 960, y: 540, width: 960, height: 540)
        XCTAssertEqual(screen.bottomRightQuarter(), expected)
    }
}
