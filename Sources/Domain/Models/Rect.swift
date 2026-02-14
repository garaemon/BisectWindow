struct Rect: Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    var minX: Double { x }
    var minY: Double { y }
    var maxX: Double { x + width }
    var maxY: Double { y + height }
    var midX: Double { x + width / 2.0 }
    var midY: Double { y + height / 2.0 }

    func isApproximatelyEqual(to other: Rect, tolerance: Double = 10.0) -> Bool {
        return abs(x - other.x) <= tolerance
            && abs(y - other.y) <= tolerance
            && abs(width - other.width) <= tolerance
            && abs(height - other.height) <= tolerance
    }

    // MARK: - Half-screen factory methods

    func leftHalf() -> Rect {
        Rect(x: x, y: y, width: width / 2.0, height: height)
    }

    func rightHalf() -> Rect {
        Rect(x: midX, y: y, width: width / 2.0, height: height)
    }

    func topHalf() -> Rect {
        Rect(x: x, y: y, width: width, height: height / 2.0)
    }

    func bottomHalf() -> Rect {
        Rect(x: x, y: midY, width: width, height: height / 2.0)
    }

    // MARK: - Quarter-screen factory methods

    func topLeftQuarter() -> Rect {
        Rect(x: x, y: y, width: width / 2.0, height: height / 2.0)
    }

    func topRightQuarter() -> Rect {
        Rect(x: midX, y: y, width: width / 2.0, height: height / 2.0)
    }

    func bottomLeftQuarter() -> Rect {
        Rect(x: x, y: midY, width: width / 2.0, height: height / 2.0)
    }

    func bottomRightQuarter() -> Rect {
        Rect(x: midX, y: midY, width: width / 2.0, height: height / 2.0)
    }

    func centerPoint() -> (x: Double, y: Double) {
        (midX, midY)
    }
}
