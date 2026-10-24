import Cocoa

/// Reads the Accessibility permission from macOS, shows the system dialog,
/// and opens the Accessibility pane of System Settings.
struct AccessibilityPermissionClient: AccessibilityPermissionProtocol {
    // Apple documents no API that opens this pane. The
    // x-apple.systempreferences deep link is the common workaround.
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
