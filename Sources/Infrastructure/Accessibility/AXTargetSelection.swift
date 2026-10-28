import Darwin

/// Picks the process and the window to tile from Accessibility lookups,
/// without touching AXUIElement, so the fallback order stays unit-testable.
/// Each fallback is a closure so later lookups run only when earlier ones
/// fail.
enum AXTargetSelection {
    /// Returns the workspace pid when it is valid, else the pid of the
    /// focused application. NSWorkspace reports pid -1 for some apps, such
    /// as Emacs started through a launcher script.
    static func selectProcessId(
        workspaceProcessId: pid_t?,
        focusedApplicationProcessId: () -> pid_t?
    ) -> pid_t? {
        if let pid = workspaceProcessId, pid > 0 {
            return pid
        }
        guard let pid = focusedApplicationProcessId(), pid > 0 else {
            return nil
        }
        return pid
    }

    /// Returns the focused window, else the main window, else the first
    /// entry of the window list. Some apps report no focused window.
    static func selectWindow<Window>(
        focusedWindow: () -> Window?,
        mainWindow: () -> Window?,
        windows: () -> [Window]
    ) -> Window? {
        focusedWindow() ?? mainWindow() ?? windows().first
    }
}
