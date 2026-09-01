import AppKit

/// The app has no Dock icon, so this is both the "yes, it is running" signal
/// and the only place to change anything.
@MainActor
final class StatusItem: NSObject, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let onPreview: () -> Void
    private let onHotKeyChange: () -> Void

    init(onPreview: @escaping () -> Void, onHotKeyChange: @escaping () -> Void) {
        self.onPreview = onPreview
        self.onHotKeyChange = onHotKeyChange
        super.init()

        item.button?.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "SeeThrough")
        item.button?.toolTip = "SeeThrough"

        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
    }

    /// Rebuilt on open so the checkmarks always match the real settings.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let preview = NSMenuItem(title: "Preview Finder Selection", action: #selector(preview), keyEquivalent: "")
        preview.target = self
        menu.addItem(preview)
        menu.addItem(.separator())

        let hotKeyItem = NSMenuItem(title: "Hotkey", action: nil, keyEquivalent: "")
        let hotKeyMenu = NSMenu()
        for choice in HotKeyChoice.allCases {
            let entry = NSMenuItem(title: choice.title, action: #selector(setHotKey(_:)), keyEquivalent: "")
            entry.target = self
            entry.representedObject = choice.rawValue
            entry.state = choice == Settings.hotKey ? .on : .off
            hotKeyMenu.addItem(entry)
        }
        hotKeyItem.submenu = hotKeyMenu
        menu.addItem(hotKeyItem)

        let mute = NSMenuItem(title: "Mute Video Previews", action: #selector(toggleMute), keyEquivalent: "")
        mute.target = self
        mute.state = Settings.muteVideo ? .on : .off
        menu.addItem(mute)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "SeeThrough \(version)", action: nil, keyEquivalent: ""))
        let quit = NSMenuItem(title: "Quit SeeThrough", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    @objc private func preview() { onPreview() }

    @objc private func setHotKey(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let choice = HotKeyChoice(rawValue: raw) else { return }
        Settings.hotKey = choice
        onHotKeyChange()
    }

    @objc private func toggleMute() { Settings.muteVideo.toggle() }
}
