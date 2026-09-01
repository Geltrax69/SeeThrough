import AppKit
import Carbon.HIToolbox

/// System-wide hotkey via Carbon. Chosen over NSEvent global monitors because
/// this needs no Accessibility permission. ⌘Space is Spotlight and Finder owns
/// plain Space, hence the modifier presets in `HotKeyChoice`.
@MainActor
final class HotKey {
    private static var action: (() -> Void)?
    private static var handlerInstalled = false
    private var ref: EventHotKeyRef?

    init(_ choice: HotKeyChoice, action: @escaping () -> Void) {
        HotKey.action = action
        HotKey.installHandlerOnce()

        let id = EventHotKeyID(signature: OSType(0x53_54_52_48), id: 1)  // 'STRH'
        RegisterEventHotKey(choice.keyCode, choice.modifiers, id,
                            GetApplicationEventTarget(), 0, &ref)
    }

    /// Explicit rather than `deinit` — Swift 6 will not touch a non-Sendable
    /// Carbon handle from a nonisolated deinit.
    func unregister() {
        if let ref { UnregisterEventHotKey(ref) }
        ref = nil
    }

    /// One Carbon handler for the process; re-installing on every rebind leaks.
    private static func installHandlerOnce() {
        guard !handlerInstalled else { return }
        handlerInstalled = true
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            Task { @MainActor in HotKey.action?() }
            return noErr
        }, 1, &spec, nil, nil)
    }
}
