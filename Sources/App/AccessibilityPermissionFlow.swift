import Foundation

/// Guides the user through granting the Accessibility permission and reports
/// the moment it is granted.
///
/// While the permission is missing, the flow shows the prompt window and
/// polls once per second, because macOS posts no notification on a grant.
final class AccessibilityPermissionFlow {
    /// Starts calling `tick` repeatedly and returns a closure that stops it.
    typealias PollScheduler = (_ tick: @escaping () -> Void) -> () -> Void

    private let permission: AccessibilityPermissionProtocol
    private let prompt: PermissionPromptProtocol
    private let schedulePoll: PollScheduler
    private var onGranted: (() -> Void)?
    private var cancelPoll: (() -> Void)?

    init(
        permission: AccessibilityPermissionProtocol,
        prompt: PermissionPromptProtocol,
        schedulePoll: @escaping PollScheduler =
            AccessibilityPermissionFlow.scheduleTimerPoll
    ) {
        self.permission = permission
        self.prompt = prompt
        self.schedulePoll = schedulePoll
        prompt.onOpenSettings = { [weak self] in
            // requestTrust() adds the app to the Accessibility list, so the
            // user finds a switch to turn on when System Settings opens.
            self?.permission.requestTrust()
            self?.permission.openSystemSettings()
        }
    }

    /// True between `begin` and the grant.
    var isAwaitingPermission: Bool { onGranted != nil }

    /// Calls `onGranted` once the permission is granted, immediately when it
    /// already is.
    func begin(onGranted: @escaping () -> Void) {
        if permission.isTrusted() {
            onGranted()
            return
        }
        debugLog("[AccessibilityPermissionFlow] waiting for permission")
        self.onGranted = onGranted
        prompt.showPrompt()
        cancelPoll = schedulePoll { [weak self] in
            self?.checkPermission()
        }
    }

    /// Shows the prompt again, for example after the user closed it.
    func showPrompt() {
        guard isAwaitingPermission else { return }
        prompt.showPrompt()
    }

    func cancel() {
        cancelPoll?()
        cancelPoll = nil
        onGranted = nil
    }

    private func checkPermission() {
        guard let grantHandler = onGranted, permission.isTrusted() else {
            return
        }
        debugLog("[AccessibilityPermissionFlow] permission granted")
        cancel()
        prompt.hidePrompt()
        grantHandler()
    }

    static func scheduleTimerPoll(
        _ tick: @escaping () -> Void
    ) -> () -> Void {
        let timer = Timer.scheduledTimer(
            withTimeInterval: 1.0, repeats: true
        ) { _ in tick() }
        return { timer.invalidate() }
    }
}
