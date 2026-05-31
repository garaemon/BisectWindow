import XCTest
@testable import BisectWindow

final class DirectionTests: XCTestCase {
    func testOppositeOfLeftIsRight() {
        XCTAssertEqual(Direction.left.opposite, .right)
    }

    func testOppositeOfRightIsLeft() {
        XCTAssertEqual(Direction.right.opposite, .left)
    }

    func testOppositeOfUpIsDown() {
        XCTAssertEqual(Direction.up.opposite, .down)
    }

    func testOppositeOfDownIsUp() {
        XCTAssertEqual(Direction.down.opposite, .up)
    }

    func testOppositeIsInvolution() {
        // Applying opposite twice yields the original direction.
        let allCases: [Direction] = [.left, .right, .up, .down]
        for direction in allCases {
            XCTAssertEqual(direction.opposite.opposite, direction)
        }
    }
}
