import Cocoa

/// Curated set of prefix modifier combinations exposed in the Settings UI.
/// Captures the most common chord shapes so users can pick without a full
/// shortcut recorder (planned for a later iteration).
enum PrefixOption: String, CaseIterable, Identifiable {
    case cmdCtrl
    case cmdOpt
    case ctrlOpt
    case cmdCtrlShift

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cmdCtrl: return "Cmd + Ctrl"
        case .cmdOpt: return "Cmd + Option"
        case .ctrlOpt: return "Ctrl + Option"
        case .cmdCtrlShift: return "Cmd + Ctrl + Shift"
        }
    }

    var modifiers: UInt {
        switch self {
        case .cmdCtrl:
            return NSEvent.ModifierFlags.command.rawValue
                | NSEvent.ModifierFlags.control.rawValue
        case .cmdOpt:
            return NSEvent.ModifierFlags.command.rawValue
                | NSEvent.ModifierFlags.option.rawValue
        case .ctrlOpt:
            return NSEvent.ModifierFlags.control.rawValue
                | NSEvent.ModifierFlags.option.rawValue
        case .cmdCtrlShift:
            return NSEvent.ModifierFlags.command.rawValue
                | NSEvent.ModifierFlags.control.rawValue
                | NSEvent.ModifierFlags.shift.rawValue
        }
    }

    /// Returns the option whose modifier mask matches, falling back to
    /// `cmdCtrl` when nothing matches (e.g. config saved by a future version).
    static func match(modifiers: UInt) -> PrefixOption {
        for option in PrefixOption.allCases where option.modifiers == modifiers {
            return option
        }
        return .cmdCtrl
    }
}
