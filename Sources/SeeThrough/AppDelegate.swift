import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let panel = PreviewPanel()
    private var hotKey: HotKey?
    private var status: StatusItem?
    private lazy var spaceTap = SpaceTap { [weak self] in self?.toggle() }

    func applicationDidFinishLaunching(_: Notification) {
        status = StatusItem(onPreview: { [weak self] in self?.toggle() },
                            onSettingsChange: { [weak self] in self?.apply() })
        apply()

        // Paths on the command line bypass Finder — used for testing.
        let args = Array(CommandLine.arguments.dropFirst())
        if !args.isEmpty { panel.show(args.map { URL(fileURLWithPath: $0) }) }
    }

    /// Re-reads every setting. Cheap enough to just run whenever one changes.
    private func apply() {
        hotKey?.unregister()
        hotKey = HotKey(Settings.hotKey) { [weak self] in self?.toggle() }

        if Settings.spaceInFinder {
            if !spaceTap.start() {
                // Not trusted yet. Prompt, and leave the toggle on so the tap
                // starts the next time the menu is touched or the app relaunches.
                SpaceTap.requestAccess()
            }
        } else {
            spaceTap.stop()
        }
    }

    var spaceTapRunning: Bool { spaceTap.isRunning }

    private func toggle() {
        if panel.isVisible { panel.orderOut(nil); return }
        panel.show(Finder.selection())
    }
}
