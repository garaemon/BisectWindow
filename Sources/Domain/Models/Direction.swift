enum Direction: Equatable {
    case left
    case right
    case up
    case down

    var opposite: Direction {
        switch self {
        case .left: return .right
        case .right: return .left
        case .up: return .down
        case .down: return .up
        }
    }
}
