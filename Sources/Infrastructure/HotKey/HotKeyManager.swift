import Cocoa

enum HotKeyAction {
    case directionPressed(Direction)
    case maximizePressed
    case prefixBegan
    case prefixEnded
}

final class HotKeyManager {
    var onAction: ((HotKeyAction) -> Void)?

    fileprivate var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var prefixModifiers: UInt
    private var isPrefixActive = false

    init(prefixModifiers: UInt = AppConfig.defaultPrefixKeyModifiers) {
        self.prefixModifiers = prefixModifiers
    }

    func start() {
        debugLog("[HotKeyManager] starting with prefixModifiers=0x\(String(prefixModifiers, radix: 16))")
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
        prefixModifiers = modifiers
    }

    // MARK: - Event handling

    fileprivate func handleEvent(
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

        if matchesPrefixModifiers(activeFlags) {
            if !isPrefixActive {
                debugLog("[HotKeyManager] prefix ACTIVE (flags=0x\(String(activeFlags, radix: 16)))")
                isPrefixActive = true
                onAction?(.prefixBegan)
            }
        } else {
            if isPrefixActive {
                debugLog("[HotKeyManager] prefix RELEASED")
                isPrefixActive = false
                onAction?(.prefixEnded)
            }
        }
        return Unmanaged.passUnretained(event)
    }

    func handleKeyDown(
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        guard isPrefixActive else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        debugLog("[HotKeyManager] keyDown while prefix active: keyCode=\(keyCode)")
        guard let action = mapKeyCodeToAction(keyCode) else {
            debugLog("[HotKeyManager] keyCode \(keyCode) not mapped, passing through")
            return Unmanaged.passUnretained(event)
        }

        debugLog("[HotKeyManager] dispatching action: \(action)")
        onAction?(action)
        // Consume the event so it doesn't propagate
        return nil
    }

    func extractModifierFlags(
        _ flags: CGEventFlags
    ) -> UInt {
        // Extract only modifier key bits
        let modifierMask: UInt = NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue
        return UInt(flags.rawValue) & modifierMask
    }

    func matchesPrefixModifiers(_ activeFlags: UInt) -> Bool {
        return (activeFlags & prefixModifiers) == prefixModifiers
    }

    func mapKeyCodeToAction(_ keyCode: Int64) -> HotKeyAction? {
        switch keyCode {
        case 123: return .directionPressed(.left)   // Left arrow
        case 124: return .directionPressed(.right)  // Right arrow
        case 126: return .directionPressed(.up)     // Up arrow
        case 125: return .directionPressed(.down)   // Down arrow
        case 3:   return .maximizePressed            // F key
        default:  return nil
        }
    }
}

// MARK: - C callback

private func hotKeyCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    // Re-enable tap if disabled by system timeout
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
