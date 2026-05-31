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

        guard let position = extractCGPoint(
            axWindow, attribute: kAXPositionAttribute
        ) else {
            return nil
        }

        guard let size = extractCGSize(
            axWindow, attribute: kAXSizeAttribute
        ) else {
            return nil
        }

        let frame = Rect(
            x: Double(position.x),
            y: Double(position.y),
            width: Double(size.width),
            height: Double(size.height)
        )

        let resizable = checkIsResizable(axWindow)
        let screenId = findScreenId(containing: position)

        return WindowInfo(
            id: Int(pid),
            frame: frame,
            screenId: screenId,
            isResizable: resizable
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
    func moveAndResize(windowId: Int, to frame: Rect) -> Bool {
        let pid = pid_t(windowId)
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

        // Set position first, then size
        let posResult = AXUIElementSetAttributeValue(
            axWindow, kAXPositionAttribute as CFString, positionValue
        )
        let sizeResult = AXUIElementSetAttributeValue(
            axWindow, kAXSizeAttribute as CFString, sizeValue
        )

        // Re-apply position after resize to handle edge cases
        if sizeResult == .success {
            AXUIElementSetAttributeValue(
                axWindow, kAXPositionAttribute as CFString, positionValue
            )
        }

        return posResult == .success || sizeResult == .success
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

    func extractCGPoint(
        _ element: AXUIElement, attribute: String
    ) -> CGPoint? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            element, attribute as CFString, &value
        )
        guard result == .success, let axValue = value else {
            return nil
        }
        var point = CGPoint.zero
        guard AXValueGetValue(
            axValue as! AXValue, .cgPoint, &point
        ) else {
            return nil
        }
        return point
    }

    func extractCGSize(
        _ element: AXUIElement, attribute: String
    ) -> CGSize? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            element, attribute as CFString, &value
        )
        guard result == .success, let axValue = value else {
            return nil
        }
        var size = CGSize.zero
        guard AXValueGetValue(
            axValue as! AXValue, .cgSize, &size
        ) else {
            return nil
        }
        return size
    }

    func checkIsResizable(_ window: AXUIElement) -> Bool {
        var settable: DarwinBoolean = false
        let result = AXUIElementIsAttributeSettable(
            window, kAXSizeAttribute as CFString, &settable
        )
        guard result == .success else { return true }
        return settable.boolValue
    }

    func findScreenId(containing point: CGPoint) -> UInt32 {
        let primaryHeight = NSScreen.screens
            .first { $0.frame.origin == .zero }?
            .frame.height ?? 0
        for screen in NSScreen.screens {
            let visible = screen.visibleFrame
            let axRect = NSRect(
                x: visible.origin.x,
                y: primaryHeight - visible.maxY,
                width: visible.size.width,
                height: visible.size.height
            )
            if axRect.contains(point) {
                if let num = screen.deviceDescription[
                    NSDeviceDescriptionKey("NSScreenNumber")
                ] as? NSNumber {
                    return num.uint32Value
                }
            }
        }
        // Fallback to main screen
        if let main = NSScreen.main,
           let num = main.deviceDescription[
               NSDeviceDescriptionKey("NSScreenNumber")
           ] as? NSNumber {
            return num.uint32Value
        }
        return 0
    }
}
