import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let panel = PreviewPanel()

    func applicationDidFinishLaunching(_: Notification) {
        panel.show(message: "SeeThrough is running.")
    }
}
