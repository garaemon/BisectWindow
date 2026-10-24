import XCTest
@testable import BisectWindow

final class AccessibilityPermissionFlowTests: XCTestCase {
    private var permission: FakePermission!
    private var prompt: RecordingPrompt!
    private var poller: ManualPoller!
    private var grantCount = 0

    override func setUp() {
        super.setUp()
        permission = FakePermission()
        prompt = RecordingPrompt()
        poller = ManualPoller()
        grantCount = 0
    }

    private func makeFlow() -> AccessibilityPermissionFlow {
        AccessibilityPermissionFlow(
            permission: permission,
            prompt: prompt,
            schedulePoll: poller.schedule
        )
    }

    private func beginFlow(_ flow: AccessibilityPermissionFlow) {
        flow.begin { [unowned self] in self.grantCount += 1 }
    }

    func testAlreadyTrustedGrantsImmediately() {
        permission.isTrustedValue = true
        let flow = makeFlow()

        beginFlow(flow)

        XCTAssertEqual(grantCount, 1)
    }

    func testAlreadyTrustedShowsNoPrompt() {
        permission.isTrustedValue = true
        let flow = makeFlow()

        beginFlow(flow)

        XCTAssertEqual(prompt.events, [])
    }

    func testUntrustedShowsPrompt() {
        let flow = makeFlow()

        beginFlow(flow)

        XCTAssertEqual(prompt.events, [.shown])
    }

    func testUntrustedDoesNotGrant() {
        let flow = makeFlow()

        beginFlow(flow)

        XCTAssertEqual(grantCount, 0)
    }

    func testUntrustedIsAwaitingPermission() {
        let flow = makeFlow()

        beginFlow(flow)

        XCTAssertTrue(flow.isAwaitingPermission)
    }

    func testPollWhileUntrustedDoesNotGrant() {
        let flow = makeFlow()
        beginFlow(flow)

        poller.tick()

        XCTAssertEqual(grantCount, 0)
    }

    func testPollAfterGrantCallsOnGranted() {
        let flow = makeFlow()
        beginFlow(flow)
        permission.isTrustedValue = true

        poller.tick()

        XCTAssertEqual(grantCount, 1)
    }

    func testPollAfterGrantHidesPrompt() {
        let flow = makeFlow()
        beginFlow(flow)
        permission.isTrustedValue = true

        poller.tick()

        XCTAssertEqual(prompt.events, [.shown, .hidden])
    }

    func testPollAfterGrantStopsPolling() {
        let flow = makeFlow()
        beginFlow(flow)
        permission.isTrustedValue = true

        poller.tick()

        XCTAssertTrue(poller.isCancelled)
    }

    func testPollAfterGrantEndsAwaiting() {
        let flow = makeFlow()
        beginFlow(flow)
        permission.isTrustedValue = true

        poller.tick()

        XCTAssertFalse(flow.isAwaitingPermission)
    }

    func testOpenSettingsRequestsTrustAndOpensSystemSettings() {
        let flow = makeFlow()
        beginFlow(flow)

        prompt.onOpenSettings?()

        XCTAssertEqual(permission.calls, [.requestTrust, .openSystemSettings])
    }

    func testShowPromptWhileAwaitingShowsPromptAgain() {
        let flow = makeFlow()
        beginFlow(flow)

        flow.showPrompt()

        XCTAssertEqual(prompt.events, [.shown, .shown])
    }

    func testShowPromptAfterGrantDoesNothing() {
        permission.isTrustedValue = true
        let flow = makeFlow()
        beginFlow(flow)

        flow.showPrompt()

        XCTAssertEqual(prompt.events, [])
    }

    func testCancelStopsPolling() {
        let flow = makeFlow()
        beginFlow(flow)

        flow.cancel()

        XCTAssertTrue(poller.isCancelled)
    }

    func testPollAfterCancelDoesNotGrant() {
        let flow = makeFlow()
        beginFlow(flow)
        flow.cancel()
        permission.isTrustedValue = true

        poller.tick()

        XCTAssertEqual(grantCount, 0)
    }
}

private final class FakePermission: AccessibilityPermissionProtocol {
    enum Call: Equatable {
        case requestTrust
        case openSystemSettings
    }

    var isTrustedValue = false
    private(set) var calls: [Call] = []

    func isTrusted() -> Bool { isTrustedValue }
    func requestTrust() { calls.append(.requestTrust) }
    func openSystemSettings() { calls.append(.openSystemSettings) }
}

private final class RecordingPrompt: PermissionPromptProtocol {
    enum Event: Equatable {
        case shown
        case hidden
    }

    var onOpenSettings: (() -> Void)?
    private(set) var events: [Event] = []

    func showPrompt() { events.append(.shown) }
    func hidePrompt() { events.append(.hidden) }
}

/// Stands in for the one-second timer so tests decide when a poll happens.
private final class ManualPoller {
    private var scheduledTick: (() -> Void)?
    private(set) var isCancelled = false

    func schedule(_ tick: @escaping () -> Void) -> () -> Void {
        scheduledTick = tick
        return { [unowned self] in self.isCancelled = true }
    }

    func tick() {
        guard !isCancelled else { return }
        scheduledTick?()
    }
}
