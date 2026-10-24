import Cocoa
import SwiftUI

/// Shows the window that explains why BisectWindow needs the Accessibility
/// permission and links to System Settings.
final class PermissionPromptWindowController: PermissionPromptProtocol {
    var onOpenSettings: (() -> Void)?

    private var window: NSWindow?

    func showPrompt() {
        let promptWindow = fetchOrMakeWindow()
        promptWindow.makeKeyAndOrderFront(nil)
        // LSUIElement apps do not become active on their own, so the window
        // would open behind the frontmost app without this.
        NSApp.activate(ignoringOtherApps: true)
    }

    func hidePrompt() {
        window?.orderOut(nil)
    }
}

private extension PermissionPromptWindowController {
    func fetchOrMakeWindow() -> NSWindow {
        if let existingWindow = window { return existingWindow }
        let hostingView = NSHostingView(
            rootView: PermissionPromptView { [weak self] in
                self?.onOpenSettings?()
            }
        )
        let newWindow = NSWindow(
            contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "BisectWindow"
        newWindow.contentView = hostingView
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        window = newWindow
        return newWindow
    }
}
