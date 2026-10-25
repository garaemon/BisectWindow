enum ScreenGeometry {
    /// Returns the screen that contains the center of `rect`. When the
    /// center lies on no screen, returns the screen that overlaps `rect` the
    /// most, or nil when `rect` overlaps no screen.
    static func findScreen(
        containing rect: Rect,
        screens: [ScreenInfo]
    ) -> ScreenInfo? {
        let center = rect.centerPoint()
        let screenAtCenter = screens.first { screen in
            center.x >= screen.frame.minX
                && center.x < screen.frame.maxX
                && center.y >= screen.frame.minY
                && center.y < screen.frame.maxY
        }
        // A window that hangs off the screen edge must stay reachable, or
        // every key press on it becomes a no-op.
        return screenAtCenter ?? findScreenWithLargestOverlap(
            rect, screens: screens
        )
    }

    private static func findScreenWithLargestOverlap(
        _ rect: Rect, screens: [ScreenInfo]
    ) -> ScreenInfo? {
        let overlaps = screens.map { screen in
            (screen: screen, area: computeOverlapArea(rect, screen.frame))
        }
        return overlaps
            .filter { $0.area > 0 }
            .max { $0.area < $1.area }?
            .screen
    }

    private static func computeOverlapArea(_ a: Rect, _ b: Rect) -> Double {
        let overlapWidth = min(a.maxX, b.maxX) - max(a.minX, b.minX)
        let overlapHeight = min(a.maxY, b.maxY) - max(a.minY, b.minY)
        return max(overlapWidth, 0) * max(overlapHeight, 0)
    }

    /// Screens that macOS arranges edge to edge may overlap by a fraction of
    /// a point after conversion to AX coordinates. In points.
    private static let adjacencySlack: Double = 1.0

    /// Returns the nearest screen beyond `current` in `direction` that
    /// overlaps it on the perpendicular axis, or nil when none exists.
    static func findAdjacentScreen(
        from current: ScreenInfo,
        direction: Direction,
        screens: [ScreenInfo]
    ) -> ScreenInfo? {
        let candidates = screens.filter { $0.id != current.id }
        switch direction {
        case .right:
            return candidates
                .filter { $0.frame.minX >= current.frame.maxX - adjacencySlack }
                .filter { hasVerticalOverlap($0.frame, current.frame) }
                .min { $0.frame.minX < $1.frame.minX }
        case .left:
            return candidates
                .filter { $0.frame.maxX <= current.frame.minX + adjacencySlack }
                .filter { hasVerticalOverlap($0.frame, current.frame) }
                .max { $0.frame.maxX < $1.frame.maxX }
        case .down:
            return candidates
                .filter { $0.frame.minY >= current.frame.maxY - adjacencySlack }
                .filter { hasHorizontalOverlap($0.frame, current.frame) }
                .min { $0.frame.minY < $1.frame.minY }
        case .up:
            return candidates
                .filter { $0.frame.maxY <= current.frame.minY + adjacencySlack }
                .filter { hasHorizontalOverlap($0.frame, current.frame) }
                .max { $0.frame.maxY < $1.frame.maxY }
        }
    }

    private static func hasVerticalOverlap(
        _ a: Rect, _ b: Rect
    ) -> Bool {
        a.minY < b.maxY && a.maxY > b.minY
    }

    private static func hasHorizontalOverlap(
        _ a: Rect, _ b: Rect
    ) -> Bool {
        a.minX < b.maxX && a.maxX > b.minX
    }
}
