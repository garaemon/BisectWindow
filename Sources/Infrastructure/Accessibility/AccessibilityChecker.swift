import Cocoa

enum AccessibilityChecker {
    /// Returns true if accessibility permission is granted.
    /// When not trusted, shows a system prompt to guide the user.
    static func checkAccessibility() -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
