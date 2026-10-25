import Cocoa
import SwiftUI

/// Hosts a borderless, click-through NSPanel that surfaces a small app icon
/// shown while the prefix key is held.
final class OverlayWindowController: OverlayProtocol {
    private var panel: NSPanel?

    func showOverlay() {
        let activePanel = panel ?? makePanel()
        panel = activePanel
        repositionToBottomRight(activePanel)
        activePanel.orderFrontRegardless()
    }

    func hideOverlay() {
        panel?.orderOut(nil)
    }
}

private extension OverlayWindowController {
    static let panelSize = NSSize(width: 48, height: 48)
    static let screenMargin: CGFloat = 24

    func makePanel() -> NSPanel {
        let initialRect = NSRect(origin: .zero, size: Self.panelSize)
        let newPanel = NSPanel(
            contentRect: initialRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = false
        newPanel.level = .statusBar
        newPanel.ignoresMouseEvents = true
        newPanel.isMovableByWindowBackground = false
        newPanel.hidesOnDeactivate = false
        newPanel.collectionBehavior = [
            .canJoinAllSpaces, .stationary, .fullScreenAuxiliary
        ]

        let hostingView = NSHostingView(
            rootView: OverlayIconView(panelSize: Self.panelSize)
        )
        hostingView.frame = initialRect
        newPanel.contentView = hostingView
        return newPanel
    }

    func repositionToBottomRight(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let origin = NSPoint(
            x: visible.maxX - Self.panelSize.width - Self.screenMargin,
            y: visible.minY + Self.screenMargin
        )
        panel.setFrameOrigin(origin)
    }
}

private struct OverlayIconView: View {
    let panelSize: NSSize

    var body: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: panelSize.width * 0.75, height: panelSize.height * 0.75)
            .opacity(0.9)
            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 1)
            .frame(width: panelSize.width, height: panelSize.height)
    }
}
