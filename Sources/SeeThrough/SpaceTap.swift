import AppKit
import ApplicationServices

/// Finder's Space cannot be turned off — Quick Look is handled inside Finder.
/// The only way to win the key is to sit above every app with a CGEventTap and
/// swallow the keystroke before Finder ever sees it.
///
/// That means Accessibility permission, and it means every keystroke on the
/// machine passes through `handle` — so it stays as small and as early-exiting
/// as possible, and passes anything it does not care about straight through.
@MainActor
final class SpaceTap {
    nonisolated(unsafe) private static var shared: SpaceTap?

    private static let spaceKeyCode: Int64 = 49
    private static let finderBundleID = "com.apple.finder"

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var isRunning: Bool { tap != nil }

    /// Returns false if Accessibility has not been granted; call `requestAccess`
    /// first if you want the system prompt.
    @discardableResult
    func start() -> Bool {
        guard tap == nil else { return true }
        guard AXIsProcessTrusted() else { return false }

        let mask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.tapDisabledByTimeout.rawValue)
            | (1 << CGEventType.tapDisabledByUserInput.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, _ in SpaceTap.handle(type, event) },
            userInfo: nil
        ) else { return false }

        // Main run loop, so the callback runs on the main thread and can touch AppKit.
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.tap = tap
        self.source = source
        SpaceTap.shared = self
        return true
    }

    func stop() {
        guard let tap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        self.tap = nil
        self.source = nil
        SpaceTap.shared = nil
    }

    /// Shows the system Accessibility prompt. Returns the current trust state,
    /// which is still false right after prompting — the user has to act.
    @discardableResult
    static func requestAccess() -> Bool {
        // The constant itself is a mutable global; the string it holds is not.
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }

    private static func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        let passThrough = Unmanaged.passUnretained(event)

        // macOS disables a tap that responds too slowly. Re-arm it.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            MainActor.assumeIsolated {
                if let tap = shared?.tap { CGEvent.tapEnable(tap: tap, enable: true) }
            }
            return passThrough
        }

        guard type == .keyDown,
              event.getIntegerValueField(.keyboardEventKeycode) == spaceKeyCode
        else { return passThrough }

        // Any modifier means the user meant something else entirely.
        let modifiers: CGEventFlags = [.maskCommand, .maskShift, .maskAlternate, .maskControl]
        guard event.flags.isDisjoint(with: modifiers) else { return passThrough }

        // CGEvent is not Sendable, so decide with a Bool and return outside.
        let swallow = MainActor.assumeIsolated { () -> Bool in
            guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == finderBundleID,
                  !focusIsTextInput()
            else { return false }

            shared?.action()
            return true
        }
        return swallow ? nil : passThrough   // nil means Finder never sees it
    }

    /// Renaming a file or typing in Finder's search field must still get a space.
    private static func focusIsTextInput() -> Bool {
        let system = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let element = focused, CFGetTypeID(element) == AXUIElementGetTypeID()
        else { return false }

        var role: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element as! AXUIElement, kAXRoleAttribute as CFString, &role) == .success,
              let name = role as? String
        else { return false }

        return [kAXTextFieldRole, kAXTextAreaRole, kAXComboBoxRole].contains(name)
    }
}
