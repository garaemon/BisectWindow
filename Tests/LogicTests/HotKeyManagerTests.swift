import XCTest
import Carbon.HIToolbox
@testable import BisectWindow

final class HotKeyManagerTests: XCTestCase {
    private let prefixFlags: CGEventFlags = [.maskCommand, .maskControl]
    private var manager: HotKeyManager!
    private var actions: [HotKeyAction] = []

    override func setUp() {
        super.setUp()
        actions = []
        manager = HotKeyManager(
            prefixModifiers: PrefixOption.cmdCtrl.modifiers
        )
        manager.onAction = { [unowned self] action in
            self.actions.append(action)
        }
    }

    private func makeFlagsChangedEvent(_ flags: CGEventFlags) -> CGEvent {
        let event = CGEvent(source: nil)!
        event.type = .flagsChanged
        event.flags = flags
        return event
    }

    private func makeKeyDownEvent(
        _ keyCode: Int, flags: CGEventFlags, isAutorepeat: Bool = false
    ) -> CGEvent {
        let event = CGEvent(
            keyboardEventSource: nil,
            virtualKey: CGKeyCode(keyCode),
            keyDown: true
        )!
        event.flags = flags
        event.setIntegerValueField(
            .keyboardEventAutorepeat, value: isAutorepeat ? 1 : 0
        )
        return event
    }

    private func pressPrefix() {
        let flagsEvent = makeFlagsChangedEvent(prefixFlags)
        withExtendedLifetime(flagsEvent) {
            _ = manager.handleEvent(type: .flagsChanged, event: flagsEvent)
        }
    }

    func testPrefixFlagsBeginPrefix() {
        pressPrefix()

        XCTAssertEqual(actions, [.prefixBegan])
    }

    func testMappedKeyWithPrefixDispatchesAction() {
        pressPrefix()

        _ = manager.handleEvent(
            type: .keyDown,
            event: makeKeyDownEvent(kVK_LeftArrow, flags: prefixFlags)
        )

        XCTAssertEqual(actions, [.prefixBegan, .directionPressed(.left)])
    }

    func testMappedKeyWithPrefixIsConsumed() {
        pressPrefix()

        let passedEvent = manager.handleEvent(
            type: .keyDown,
            event: makeKeyDownEvent(kVK_LeftArrow, flags: prefixFlags)
        )

        XCTAssertNil(passedEvent)
    }

    func testKeyDownWithoutPrefixFlagsEndsStalePrefix() {
        pressPrefix()

        _ = manager.handleEvent(
            type: .keyDown,
            event: makeKeyDownEvent(kVK_LeftArrow, flags: [])
        )

        XCTAssertEqual(actions, [.prefixBegan, .prefixEnded])
    }

    func testKeyDownWithoutPrefixFlagsPassesThrough() {
        pressPrefix()

        let keyEvent = makeKeyDownEvent(kVK_LeftArrow, flags: [])

        let passedEvent = manager.handleEvent(type: .keyDown, event: keyEvent)

        XCTAssertTrue(passedEvent?.takeUnretainedValue() === keyEvent)
    }

    func testKeyDownWithPrefixFlagsBeginsMissedPrefixAndDispatches() {
        let keyEvent = makeKeyDownEvent(kVK_LeftArrow, flags: prefixFlags)

        _ = manager.handleEvent(type: .keyDown, event: keyEvent)

        XCTAssertEqual(actions, [.prefixBegan, .directionPressed(.left)])
    }

    func testAutorepeatKeyDownDispatchesNothing() {
        pressPrefix()

        _ = manager.handleEvent(
            type: .keyDown,
            event: makeKeyDownEvent(
                kVK_LeftArrow, flags: prefixFlags, isAutorepeat: true
            )
        )

        XCTAssertEqual(actions, [.prefixBegan])
    }

    func testAutorepeatKeyDownIsConsumed() {
        pressPrefix()

        let passedEvent = manager.handleEvent(
            type: .keyDown,
            event: makeKeyDownEvent(
                kVK_LeftArrow, flags: prefixFlags, isAutorepeat: true
            )
        )

        XCTAssertNil(passedEvent)
    }

    func testUnmappedKeyWithPrefixPassesThrough() {
        pressPrefix()

        let keyEvent = makeKeyDownEvent(kVK_ANSI_A, flags: prefixFlags)

        let passedEvent = manager.handleEvent(type: .keyDown, event: keyEvent)

        XCTAssertTrue(passedEvent?.takeUnretainedValue() === keyEvent)
    }
}
