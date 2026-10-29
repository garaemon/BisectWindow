import Cocoa
import SwiftUI

/// Owns the settings NSWindow and re-uses it across opens. The window is not
/// released on close so we keep SwiftUI state between visits.
final class SettingsWindowController {
    private let viewModel: SettingsViewModel
    private var window: NSWindow?

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    func showSettings() {
        viewModel.refreshLaunchAtLogin()
        let settingsWindow = fetchOrMakeWindow()
        settingsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private extension SettingsWindowController {
    func fetchOrMakeWindow() -> NSWindow {
        if let existingWindow = window { return existingWindow }
        let newWindow = makeWindow()
        window = newWindow
        return newWindow
    }

    func makeWindow() -> NSWindow {
        let hostingView = NSHostingView(
            rootView: SettingsView(viewModel: viewModel)
        )
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "BisectWindow Settings"
        newWindow.contentView = hostingView
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        return newWindow
    }
}
