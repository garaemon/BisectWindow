enum BisectResult: Equatable {
    case move(Rect)
    case noAction
}

/// Detected position state of a window relative to its screen.
enum WindowPosition {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case topLeftQuarter
    case topRightQuarter
    case bottomLeftQuarter
    case bottomRightQuarter
    case maximized
    case other
}

struct BisectEngine {
    private let tolerance: Double

    init(tolerance: Double = 10.0) {
        self.tolerance = tolerance
    }

    func computeFrame(
        direction: Direction,
        window: WindowInfo,
        screens: [ScreenInfo]
    ) -> BisectResult {
        guard let screen = ScreenGeometry.findScreen(
            containing: window.frame, screens: screens
        ) else {
            return .noAction
        }

        let position = detectPosition(
            window: window.frame, screen: screen.frame
        )

        // Screen traversal: already at half in same direction at edge
        if shouldTraverseScreen(
            position: position, direction: direction
        ) {
            return computeScreenTraversal(
                direction: direction, window: window,
                currentScreen: screen, screens: screens
            )
        }

        // Quarter tiling: at half, perpendicular direction
        if let quarterFrame = computeQuarterTile(
            position: position, direction: direction,
            screen: screen.frame
        ) {
            return handleResizability(
                window: window, targetFrame: quarterFrame,
                screen: screen.frame
            )
        }

        // Default: snap to half
        let halfFrame = computeHalfFrame(
            direction: direction, screen: screen.frame
        )
        return handleResizability(
            window: window, targetFrame: halfFrame,
            screen: screen.frame
        )
    }

    func computeMaximize(
        window: WindowInfo,
        screens: [ScreenInfo]
    ) -> BisectResult {
        guard let screen = ScreenGeometry.findScreen(
            containing: window.frame, screens: screens
        ) else {
            return .noAction
        }
        return handleResizability(
            window: window, targetFrame: screen.frame,
            screen: screen.frame
        )
    }

    // MARK: - Position detection

    func detectPosition(
        window: Rect, screen: Rect
    ) -> WindowPosition {
        if window.isApproximatelyEqual(
            to: screen.leftHalf(), tolerance: tolerance
        ) { return .leftHalf }
        if window.isApproximatelyEqual(
            to: screen.rightHalf(), tolerance: tolerance
        ) { return .rightHalf }
        if window.isApproximatelyEqual(
            to: screen.topHalf(), tolerance: tolerance
        ) { return .topHalf }
        if window.isApproximatelyEqual(
            to: screen.bottomHalf(), tolerance: tolerance
        ) { return .bottomHalf }
        if window.isApproximatelyEqual(
            to: screen.topLeftQuarter(), tolerance: tolerance
        ) { return .topLeftQuarter }
        if window.isApproximatelyEqual(
            to: screen.topRightQuarter(), tolerance: tolerance
        ) { return .topRightQuarter }
        if window.isApproximatelyEqual(
            to: screen.bottomLeftQuarter(), tolerance: tolerance
        ) { return .bottomLeftQuarter }
        if window.isApproximatelyEqual(
            to: screen.bottomRightQuarter(), tolerance: tolerance
        ) { return .bottomRightQuarter }
        if window.isApproximatelyEqual(
            to: screen, tolerance: tolerance
        ) { return .maximized }
        return .other
    }
}

// MARK: - Private helpers

private extension BisectEngine {
    func computeHalfFrame(
        direction: Direction, screen: Rect
    ) -> Rect {
        switch direction {
        case .left: return screen.leftHalf()
        case .right: return screen.rightHalf()
        case .up: return screen.topHalf()
        case .down: return screen.bottomHalf()
        }
    }

    func shouldTraverseScreen(
        position: WindowPosition, direction: Direction
    ) -> Bool {
        switch (position, direction) {
        case (.rightHalf, .right): return true
        case (.leftHalf, .left): return true
        // V2.0: up/down screen traversal is out of scope
        default: return false
        }
    }

    func computeScreenTraversal(
        direction: Direction,
        window: WindowInfo,
        currentScreen: ScreenInfo,
        screens: [ScreenInfo]
    ) -> BisectResult {
        guard let nextScreen = ScreenGeometry.findAdjacentScreen(
            from: currentScreen, direction: direction,
            screens: screens
        ) else {
            return .noAction
        }

        // Place in the half on the opposite side of the new screen
        let targetFrame = computeHalfFrame(
            direction: direction, screen: nextScreen.frame
        )
        return handleResizability(
            window: window, targetFrame: targetFrame,
            screen: nextScreen.frame
        )
    }

    func computeQuarterTile(
        position: WindowPosition, direction: Direction,
        screen: Rect
    ) -> Rect? {
        switch (position, direction) {
        case (.leftHalf, .up): return screen.topLeftQuarter()
        case (.leftHalf, .down): return screen.bottomLeftQuarter()
        case (.rightHalf, .up): return screen.topRightQuarter()
        case (.rightHalf, .down): return screen.bottomRightQuarter()
        case (.topHalf, .left): return screen.topLeftQuarter()
        case (.topHalf, .right): return screen.topRightQuarter()
        case (.bottomHalf, .left): return screen.bottomLeftQuarter()
        case (.bottomHalf, .right): return screen.bottomRightQuarter()
        default: return nil
        }
    }

    /// Non-resizable windows are moved only (centered in target).
    func handleResizability(
        window: WindowInfo, targetFrame: Rect, screen: Rect
    ) -> BisectResult {
        if window.isResizable {
            return .move(targetFrame)
        }
        let centeredX = targetFrame.midX - window.frame.width / 2.0
        let centeredY = targetFrame.midY - window.frame.height / 2.0
        let movedFrame = Rect(
            x: centeredX, y: centeredY,
            width: window.frame.width, height: window.frame.height
        )
        return .move(movedFrame)
    }
}
