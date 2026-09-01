import AppKit

/// Borderless floating panel that never steals focus from Finder.
final class PreviewPanel: NSPanel {
    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
                   styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isMovableByWindowBackground = true
        level = .floating
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    override var canBecomeKey: Bool { true }

    func show(message: String) {
        let label = NSTextField(labelWithString: message)
        label.alignment = .center
        label.frame = NSRect(x: 0, y: 0, width: 720, height: 520)
        contentView = label
        center()
        orderFrontRegardless()
    }

    /// Esc closes, same as Quick Look.
    override func cancelOperation(_: Any?) { orderOut(nil) }
}
