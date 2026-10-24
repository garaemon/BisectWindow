struct WindowInfo: Equatable {
    /// Process ID of the app that owns the window. A move re-resolves that
    /// app's focused window from this pid.
    let ownerProcessId: Int
    let frame: Rect
    let isResizable: Bool
}
