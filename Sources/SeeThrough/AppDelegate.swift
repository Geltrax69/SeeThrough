import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let panel = PreviewPanel()
    private var hotKey: HotKey?
    private var status: StatusItem?

    func applicationDidFinishLaunching(_: Notification) {
        status = StatusItem(onPreview: { [weak self] in self?.toggle() },
                            onHotKeyChange: { [weak self] in self?.bindHotKey() })
        bindHotKey()

        // Paths on the command line bypass Finder — used for testing.
        let args = Array(CommandLine.arguments.dropFirst())
        if !args.isEmpty { panel.show(args.map { URL(fileURLWithPath: $0) }) }
    }

    private func bindHotKey() {
        hotKey?.unregister()
        hotKey = HotKey(Settings.hotKey) { [weak self] in self?.toggle() }
    }

    private func toggle() {
        if panel.isVisible { panel.orderOut(nil); return }
        panel.show(Finder.selection())
    }
}
