import AppKit
import ApplicationServices

/// The app has no Dock icon, so this is both the "yes, it is running" signal
/// and the only place to change anything.
@MainActor
final class StatusItem: NSObject, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let onPreview: () -> Void
    private let onSettingsChange: () -> Void

    init(onPreview: @escaping () -> Void, onSettingsChange: @escaping () -> Void) {
        self.onPreview = onPreview
        self.onSettingsChange = onSettingsChange
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

        let space = NSMenuItem(title: "Use Space in Finder", action: #selector(toggleSpace), keyEquivalent: "")
        space.target = self
        space.state = Settings.spaceInFinder ? .on : .off
        if Settings.spaceInFinder, !AXIsProcessTrusted() {
            space.title = "Use Space in Finder — needs Accessibility"
        }
        menu.addItem(space)

        let mute = NSMenuItem(title: "Mute Video Previews", action: #selector(toggleMute), keyEquivalent: "")
        mute.target = self
        mute.state = Settings.muteVideo ? .on : .off
        menu.addItem(mute)

        let login = NSMenuItem(title: "Open at Login", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = Settings.openAtLogin ? .on : .off
        menu.addItem(login)

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
        onSettingsChange()
    }

    @objc private func toggleSpace() {
        Settings.spaceInFinder.toggle()
        if Settings.spaceInFinder, !AXIsProcessTrusted() { SpaceTap.requestAccess() }
        onSettingsChange()
    }

    @objc private func toggleMute() { Settings.muteVideo.toggle() }

    @objc private func toggleLogin() { Settings.openAtLogin.toggle() }
}
