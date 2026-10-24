import Carbon.HIToolbox

/// Interprets modifier flags and virtual key codes without touching CGEvent,
/// so the input rules stay unit-testable.
struct HotKeyMapper {
    var prefixModifiers: UInt

    /// Returns true when every prefix bit is held. Extra modifiers are
    /// allowed, so Cmd+Ctrl+Shift still activates a Cmd+Ctrl prefix.
    func matchesPrefix(_ activeFlags: UInt) -> Bool {
        (activeFlags & prefixModifiers) == prefixModifiers
    }

    func mapKeyCode(_ keyCode: Int64) -> HotKeyAction? {
        switch Int(keyCode) {
        case kVK_LeftArrow: return .directionPressed(.left)
        case kVK_RightArrow: return .directionPressed(.right)
        case kVK_UpArrow: return .directionPressed(.up)
        case kVK_DownArrow: return .directionPressed(.down)
        case kVK_ANSI_F: return .maximizePressed
        default: return nil
        }
    }
}
