import XCTest
import Cocoa
@testable import BisectWindow

final class PrefixOptionTests: XCTestCase {
    func testMatchReturnsCmdCtrlForCmdControlModifiers() {
        let modifiers =
            NSEvent.ModifierFlags.command.rawValue
            | NSEvent.ModifierFlags.control.rawValue
        XCTAssertEqual(PrefixOption.match(modifiers: modifiers), .cmdCtrl)
    }

    func testMatchReturnsCmdOptForCmdOptionModifiers() {
        let modifiers =
            NSEvent.ModifierFlags.command.rawValue
            | NSEvent.ModifierFlags.option.rawValue
        XCTAssertEqual(PrefixOption.match(modifiers: modifiers), .cmdOpt)
    }

    func testMatchFallsBackToCmdCtrlForUnknownModifiers() {
        XCTAssertEqual(PrefixOption.match(modifiers: 0), .cmdCtrl)
    }

    func testModifiersRoundTripForEveryOption() {
        for option in PrefixOption.allCases {
            XCTAssertEqual(
                PrefixOption.match(modifiers: option.modifiers),
                option,
                "match should round-trip for \(option)"
            )
        }
    }
}
