import AppKit
import Carbon.HIToolbox
import ServiceManagement

/// A handful of preset hotkeys. A full key recorder is a lot of code for a
/// choice most people make once.
// ponytail: presets, not a recorder. Add a recorder if someone actually wants
// a key that isn't here.
enum HotKeyChoice: String, CaseIterable {
    case optionSpace, controlSpace, commandShiftSpace

    var title: String {
        switch self {
        case .optionSpace: "⌥Space"
        case .controlSpace: "⌃Space"
        case .commandShiftSpace: "⌘⇧Space"
        }
    }

    var modifiers: UInt32 {
        switch self {
        case .optionSpace: UInt32(optionKey)
        case .controlSpace: UInt32(controlKey)
        case .commandShiftSpace: UInt32(cmdKey | shiftKey)
        }
    }

    var keyCode: UInt32 { UInt32(kVK_Space) }
}

enum Settings {
    private static var defaults: UserDefaults { .standard }

    static var hotKey: HotKeyChoice {
        get { HotKeyChoice(rawValue: defaults.string(forKey: "hotKey") ?? "") ?? .optionSpace }
        set { defaults.set(newValue.rawValue, forKey: "hotKey") }
    }

    static var spaceInFinder: Bool {
        get { defaults.bool(forKey: "spaceInFinder") }
        set { defaults.set(newValue, forKey: "spaceInFinder") }
    }

    static var muteVideo: Bool {
        get { defaults.object(forKey: "muteVideo") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "muteVideo") }
    }

    /// Read from the system rather than a stored flag, so the menu matches
    /// Login Items even when the user changes it there.
    static var openAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                newValue ? try SMAppService.mainApp.register()
                         : try SMAppService.mainApp.unregister()
            } catch {
                NSLog("SeeThrough: could not change login item — \(error)")
            }
        }
    }
}
