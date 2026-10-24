import Cocoa

final class AXClient: SystemStateProtocol, WindowActionProtocol {

    // MARK: - SystemStateProtocol

    func fetchFocusedWindow() -> WindowInfo? {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        let pid = app.processIdentifier
        let axApp = AXUIElementCreateApplication(pid)

        guard let axWindow = copyAttributeValue(
            axApp, attribute: kAXFocusedWindowAttribute
        ) else {
            return nil
        }

        guard let position = extractAXValue(
            axWindow, attribute: kAXPositionAttribute,
            type: .cgPoint, initial: CGPoint.zero
        ) else {
            return nil
        }

        guard let size = extractAXValue(
            axWindow, attribute: kAXSizeAttribute,
            type: .cgSize, initial: CGSize.zero
        ) else {
            return nil
        }

        let frame = Rect(
            x: Double(position.x),
            y: Double(position.y),
            width: Double(size.width),
            height: Double(size.height)
        )

        let isResizable = checkIsResizable(axWindow)

        return WindowInfo(
            ownerProcessId: Int(pid),
            frame: frame,
            isResizable: isResizable
        )
    }

    func listScreens() -> [ScreenInfo] {
        // visibleFrame excludes the menu bar and Dock so tiling never lands
        // under them. We then flip the Y axis: NSScreen uses bottom-left
        // origin while AXUIElement (and therefore window frames returned by
        // fetchFocusedWindow) uses top-left origin anchored on the primary
        // display.
        let primaryHeight = NSScreen.screens
            .first { $0.frame.origin == .zero }?
            .frame.height ?? 0
        return NSScreen.screens.compactMap { screen in
            guard let screenNumber = screen.deviceDescription[
                NSDeviceDescriptionKey("NSScreenNumber")
            ] as? NSNumber else {
                return nil
            }
            let visible = screen.visibleFrame
            let yAX = primaryHeight - visible.maxY
            return ScreenInfo(
                id: screenNumber.uint32Value,
                frame: Rect(
                    x: Double(visible.origin.x),
                    y: Double(yAX),
                    width: Double(visible.size.width),
                    height: Double(visible.size.height)
                )
            )
        }
    }

    // MARK: - WindowActionProtocol

    @discardableResult
    func moveAndResizeFocusedWindow(
        ownerProcessId: Int, to frame: Rect
    ) -> Bool {
        let pid = pid_t(ownerProcessId)
        let axApp = AXUIElementCreateApplication(pid)

        guard let axWindow = copyAttributeValue(
            axApp, attribute: kAXFocusedWindowAttribute
        ) else {
            return false
        }

        var point = CGPoint(x: frame.x, y: frame.y)
        var size = CGSize(width: frame.width, height: frame.height)

        let positionValue = AXValueCreate(
            .cgPoint, &point
        )!
        let sizeValue = AXValueCreate(
            .cgSize, &size
        )!

        let positionResult = AXUIElementSetAttributeValue(
            axWindow, kAXPositionAttribute as CFString, positionValue
        )
        let sizeResult = AXUIElementSetAttributeValue(
            axWindow, kAXSizeAttribute as CFString, sizeValue
        )

        // Apps clamp the first position change when the old size does not
        // fit at the new origin, so set the position again after resizing.
        if sizeResult == .success {
            AXUIElementSetAttributeValue(
                axWindow, kAXPositionAttribute as CFString, positionValue
            )
        }

        // A non-resizable window rejects the size but still moves, which
        // counts as success.
        return positionResult == .success || sizeResult == .success
    }
}

// MARK: - Private helpers

private extension AXClient {
    func copyAttributeValue(
        _ element: AXUIElement, attribute: String
    ) -> AXUIElement? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            element, attribute as CFString, &value
        )
        guard result == .success else { return nil }
        // AXUIElement is a CFTypeRef bridged type
        return (value as! AXUIElement)
    }

    func extractAXValue<Value>(
        _ element: AXUIElement, attribute: String,
        type: AXValueType, initial: Value
    ) -> Value? {
        var rawValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            element, attribute as CFString, &rawValue
        )
        guard result == .success, let axValue = rawValue else {
            return nil
        }
        var decoded = initial
        guard AXValueGetValue(axValue as! AXValue, type, &decoded) else {
            return nil
        }
        return decoded
    }

    func checkIsResizable(_ window: AXUIElement) -> Bool {
        var isSettable: DarwinBoolean = false
        let result = AXUIElementIsAttributeSettable(
            window, kAXSizeAttribute as CFString, &isSettable
        )
        guard result == .success else { return true }
        return isSettable.boolValue
    }
}
