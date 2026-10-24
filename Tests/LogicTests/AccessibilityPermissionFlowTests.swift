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

    func testAlreadyTrustedSchedulesNoPoll() {
        permission.isTrustedValue = true
        let flow = makeFlow()

        beginFlow(flow)

        XCTAssertEqual(poller.subscriptionCount, 0)
    }

    func testReleasingFlowStopsPolling() {
        var flow: AccessibilityPermissionFlow? = makeFlow()
        beginFlow(flow!)

        flow = nil

        XCTAssertTrue(poller.isCancelled(subscriptionIndex: 0))
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

        XCTAssertTrue(poller.isCancelled(subscriptionIndex: 0))
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

    func testShowPromptWhenAlreadyTrustedDoesNothing() {
        permission.isTrustedValue = true
        let flow = makeFlow()
        beginFlow(flow)

        flow.showPrompt()

        XCTAssertEqual(prompt.events, [])
    }

    func testShowPromptAfterGrantDoesNothing() {
        let flow = makeFlow()
        beginFlow(flow)
        permission.isTrustedValue = true
        poller.tick()

        flow.showPrompt()

        XCTAssertEqual(prompt.events, [.shown, .hidden])
    }

    func testBeginTwiceCancelsFirstPoll() {
        let flow = makeFlow()
        beginFlow(flow)

        beginFlow(flow)

        XCTAssertTrue(poller.isCancelled(subscriptionIndex: 0))
    }

    func testBeginTwiceKeepsSecondPollRunning() {
        let flow = makeFlow()
        beginFlow(flow)

        beginFlow(flow)

        XCTAssertFalse(poller.isCancelled(subscriptionIndex: 1))
    }

    func testBeginTwiceGrantsOnceOnPoll() {
        let flow = makeFlow()
        beginFlow(flow)
        beginFlow(flow)
        permission.isTrustedValue = true

        poller.tick()

        XCTAssertEqual(grantCount, 1)
    }

    func testBeginAfterGrantWhileAwaitingDropsFirstHandler() {
        let flow = makeFlow()
        beginFlow(flow)
        permission.isTrustedValue = true
        beginFlow(flow)

        poller.tick()

        XCTAssertEqual(grantCount, 1)
    }

    func testBeginAfterGrantWhileAwaitingHidesPrompt() {
        let flow = makeFlow()
        beginFlow(flow)
        permission.isTrustedValue = true

        beginFlow(flow)

        XCTAssertEqual(prompt.events, [.shown, .hidden])
    }

    func testCancelHidesPrompt() {
        let flow = makeFlow()
        beginFlow(flow)

        flow.cancel()

        XCTAssertEqual(prompt.events, [.shown, .hidden])
    }

    func testCancelStopsPolling() {
        let flow = makeFlow()
        beginFlow(flow)

        flow.cancel()

        XCTAssertTrue(poller.isCancelled(subscriptionIndex: 0))
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
/// Each `schedule` call is a separate subscription with its own state.
private final class ManualPoller {
    private final class Subscription {
        let tick: () -> Void
        var isCancelled = false

        init(tick: @escaping () -> Void) {
            self.tick = tick
        }
    }

    private var subscriptions: [Subscription] = []

    var subscriptionCount: Int { subscriptions.count }

    func schedule(_ tick: @escaping () -> Void) -> () -> Void {
        let subscription = Subscription(tick: tick)
        subscriptions.append(subscription)
        return { subscription.isCancelled = true }
    }

    func isCancelled(subscriptionIndex: Int) -> Bool {
        subscriptions[subscriptionIndex].isCancelled
    }

    /// Fires every subscription that is still active.
    func tick() {
        for subscription in subscriptions where !subscription.isCancelled {
            subscription.tick()
        }
    }
}
