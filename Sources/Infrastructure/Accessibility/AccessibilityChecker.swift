import Cocoa

enum AccessibilityChecker {
    /// Returns whether the Accessibility permission is granted, and shows
    /// the system permission dialog when it is not.
    static func requestAccessibilityIfNeeded() -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Returns whether the Accessibility permission is granted without
    /// showing any dialog, so polling is safe.
    static func isAccessibilityTrusted() -> Bool {
        AXIsProcessTrusted()
    }
}
