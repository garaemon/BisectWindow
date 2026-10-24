import Cocoa

struct AccessibilityPermissionClient: AccessibilityPermissionProtocol {
    private static let accessibilitySettingsURL = URL(
        string: "x-apple.systempreferences:"
            + "com.apple.preference.security?Privacy_Accessibility"
    )!

    func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    func requestTrust() {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true
        ] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func openSystemSettings() {
        NSWorkspace.shared.open(Self.accessibilitySettingsURL)
    }
}
