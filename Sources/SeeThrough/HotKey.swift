import AppKit
import Carbon.HIToolbox

/// System-wide hotkey via Carbon. Chosen over NSEvent global monitors because
/// this needs no Accessibility permission.
@MainActor
final class HotKey {
    private static var action: (() -> Void)?
    private var ref: EventHotKeyRef?

    /// ⌥Space — ⌘Space is Spotlight, and Finder owns plain Space.
    init(keyCode: UInt32 = UInt32(kVK_Space), modifiers: UInt32 = UInt32(optionKey),
         action: @escaping () -> Void) {
        HotKey.action = action

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            Task { @MainActor in HotKey.action?() }
            return noErr
        }, 1, &spec, nil, nil)

        let id = EventHotKeyID(signature: OSType(0x53_54_52_48), id: 1)  // 'STRH'
        RegisterEventHotKey(keyCode, modifiers, id, GetApplicationEventTarget(), 0, &ref)
    }
}
