import Cocoa

enum HotKeyAction: Equatable {
    case directionPressed(Direction)
    case maximizePressed
    case prefixBegan
    case prefixEnded
}

/// Watches for the prefix chord and the follow-up keys with a CGEvent tap.
///
/// - A tap is used instead of `NSEvent.addGlobalMonitorForEvents` because
///   only a tap can swallow the arrow key before the frontmost app sees it.
/// - Creating the tap requires the Accessibility permission. `start()` logs
///   and returns when the permission is missing.
/// - The tap runs on the main run loop, so `onAction` fires on the main
///   thread.
final class HotKeyManager {
    var onAction: ((HotKeyAction) -> Void)?

    // fileprivate so the C callback can re-enable the tap after macOS
    // disables it for a slow callback or secure input.
    fileprivate var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var mapper: HotKeyMapper
    private var isPrefixActive = false

    init(prefixModifiers: UInt = AppConfig.defaultPrefixKeyModifiers) {
        self.mapper = HotKeyMapper(prefixModifiers: prefixModifiers)
    }

    func start() {
        debugLog("[HotKeyManager] starting with prefixModifiers=0x\(String(mapper.prefixModifiers, radix: 16))")
        let eventMask: CGEventMask =
            (1 << CGEventType.flagsChanged.rawValue)
            | (1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: hotKeyCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            debugLog("[HotKeyManager] ERROR: CGEvent.tapCreate failed - check accessibility permissions")
            return
        }

        debugLog("[HotKeyManager] event tap created successfully")
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault, tap, 0
        )
        CFRunLoopAddSource(
            CFRunLoopGetMain(), runLoopSource, .commonModes
        )
        CGEvent.tapEnable(tap: tap, enable: true)
        debugLog("[HotKeyManager] event tap enabled and running")
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(
                CFRunLoopGetMain(), source, .commonModes
            )
        }
        eventTap = nil
        runLoopSource = nil
        isPrefixActive = false
    }

    func updatePrefixModifiers(_ modifiers: UInt) {
        mapper.prefixModifiers = modifiers
    }

    /// Returns the event to pass on to the frontmost app, or nil to swallow
    /// it. Called from the tap callback; internal so tests can feed events.
    func handleEvent(
        type: CGEventType, event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        switch type {
        case .flagsChanged:
            return handleFlagsChanged(event: event)
        case .keyDown:
            return handleKeyDown(event: event)
        default:
            return Unmanaged.passUnretained(event)
        }
    }
}

// MARK: - Private event handlers

private extension HotKeyManager {
    func handleFlagsChanged(
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        let flags = event.flags
        let activeFlags = extractModifierFlags(flags)

        syncPrefixState(isPrefixHeld: mapper.matchesPrefix(activeFlags))
        return Unmanaged.passUnretained(event)
    }

    func syncPrefixState(isPrefixHeld: Bool) {
        guard isPrefixHeld != isPrefixActive else { return }
        isPrefixActive = isPrefixHeld
        debugLog("[HotKeyManager] prefix active: \(isPrefixHeld)")
        onAction?(isPrefixHeld ? .prefixBegan : .prefixEnded)
    }

    func handleKeyDown(
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        // macOS drops flagsChanged events while the tap is disabled, so the
        // key event's own flags are the source of truth for the prefix.
        let keyEventFlags = extractModifierFlags(event.flags)
        syncPrefixState(isPrefixHeld: mapper.matchesPrefix(keyEventFlags))
        guard isPrefixActive else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard let action = mapper.mapKeyCode(keyCode) else {
            return Unmanaged.passUnretained(event)
        }

        // Swallow auto-repeat so holding an arrow key fires one action.
        // Returning nil also keeps the repeats away from the frontmost app.
        let isAutorepeat =
            event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        if isAutorepeat {
            return nil
        }

        debugLog("[HotKeyManager] dispatching action: \(action)")
        onAction?(action)
        return nil
    }

    func extractModifierFlags(
        _ flags: CGEventFlags
    ) -> UInt {
        let modifierMask: UInt = NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue
        return UInt(flags.rawValue) & modifierMask
    }
}

// MARK: - C callback

private func hotKeyCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let userInfo = userInfo {
            let manager = Unmanaged<HotKeyManager>.fromOpaque(
                userInfo
            ).takeUnretainedValue()
            if let tap = manager.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
        }
        return Unmanaged.passUnretained(event)
    }

    guard let userInfo = userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let manager = Unmanaged<HotKeyManager>.fromOpaque(
        userInfo
    ).takeUnretainedValue()
    return manager.handleEvent(type: type, event: event)
}
