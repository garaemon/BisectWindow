import XCTest
import Carbon.HIToolbox
@testable import BisectWindow

final class HotKeyMapperTests: XCTestCase {
    private let mapper = HotKeyMapper(
        prefixModifiers: PrefixOption.cmdCtrl.modifiers
    )

    func testExactPrefixModifiersMatch() {
        XCTAssertTrue(mapper.matchesPrefix(PrefixOption.cmdCtrl.modifiers))
    }

    func testExtraShiftStillMatchesCmdCtrlPrefix() {
        XCTAssertTrue(
            mapper.matchesPrefix(PrefixOption.cmdCtrlShift.modifiers)
        )
    }

    func testMissingModifierDoesNotMatchPrefix() {
        XCTAssertFalse(mapper.matchesPrefix(PrefixOption.cmdOpt.modifiers))
    }

    func testLeftArrowMapsToLeftDirection() {
        XCTAssertEqual(
            mapper.mapKeyCode(Int64(kVK_LeftArrow)), .directionPressed(.left)
        )
    }

    func testRightArrowMapsToRightDirection() {
        XCTAssertEqual(
            mapper.mapKeyCode(Int64(kVK_RightArrow)), .directionPressed(.right)
        )
    }

    func testUpArrowMapsToUpDirection() {
        XCTAssertEqual(
            mapper.mapKeyCode(Int64(kVK_UpArrow)), .directionPressed(.up)
        )
    }

    func testDownArrowMapsToDownDirection() {
        XCTAssertEqual(
            mapper.mapKeyCode(Int64(kVK_DownArrow)), .directionPressed(.down)
        )
    }

    func testFKeyMapsToMaximize() {
        XCTAssertEqual(mapper.mapKeyCode(Int64(kVK_ANSI_F)), .maximizePressed)
    }

    func testOneKeyMapsToMaximize() {
        XCTAssertEqual(mapper.mapKeyCode(Int64(kVK_ANSI_1)), .maximizePressed)
    }

    func testTwoKeyMapsToSplitBelow() {
        XCTAssertEqual(
            mapper.mapKeyCode(Int64(kVK_ANSI_2)), .splitPressed(.below)
        )
    }

    func testThreeKeyMapsToSplitRight() {
        XCTAssertEqual(
            mapper.mapKeyCode(Int64(kVK_ANSI_3)), .splitPressed(.right)
        )
    }

    func testUnmappedKeyReturnsNil() {
        XCTAssertNil(mapper.mapKeyCode(Int64(kVK_ANSI_A)))
    }
}
