import AppKit

/// Borderless floating panel that never steals focus from Finder.
final class PreviewPanel: NSPanel {
    private let content = NSVisualEffectView()

    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 820, height: 600),
                   styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isMovableByWindowBackground = true
        level = .floating
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        content.material = .hudWindow
        content.blendingMode = .behindWindow
        content.state = .active
        contentView = content
    }

    override var canBecomeKey: Bool { true }

    func show(_ urls: [URL]) {
        content.subviews.forEach { $0.removeFromSuperview() }

        guard let url = urls.first else {
            title = ""
            content.addSubview(centeredLabel("Nothing selected in Finder."))
            present()
            return
        }

        title = url.lastPathComponent
        let body = PreviewFactory.view(for: url, size: content.bounds.size)
        body.frame = content.bounds
        content.addSubview(body)
        present()
    }

    private func centeredLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.alignment = .center
        label.frame = content.bounds
        label.autoresizingMask = [.width, .height]
        return label
    }

    private func present() {
        if !isVisible { centerOnActiveScreen() }
        orderFrontRegardless()
    }

    /// The screen under the pointer, not `center()`'s idea of the main one —
    /// otherwise the panel opens on a display you are not looking at.
    private func centerOnActiveScreen() {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return center() }
        setFrameOrigin(NSPoint(x: visible.midX - frame.width / 2,
                               y: visible.midY - frame.height / 2))
    }

    /// Esc closes, same as Quick Look.
    override func cancelOperation(_: Any?) { orderOut(nil) }
}
