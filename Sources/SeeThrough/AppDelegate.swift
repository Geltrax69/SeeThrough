import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let panel = PreviewPanel()
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_: Notification) {
        hotKey = HotKey { [weak self] in self?.toggle() }

        // Paths on the command line bypass Finder — used for testing.
        let args = Array(CommandLine.arguments.dropFirst())
        if !args.isEmpty { panel.show(args.map { URL(fileURLWithPath: $0) }) }
    }

    private func toggle() {
        if panel.isVisible { panel.orderOut(nil); return }
        let urls = Finder.selection()
        panel.show(urls)
    }
}
