import AppKit

@main
enum SeeThrough {
    // Held so the delegate outlives main(); NSApplication only keeps a weak ref.
    @MainActor static var delegate: AppDelegate?

    @MainActor static func main() {
        let app = NSApplication.shared
        delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
