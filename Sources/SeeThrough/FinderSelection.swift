import Foundation

enum Finder {
    /// Whatever is selected in Finder right now. Empty if Finder is not frontmost,
    /// nothing is selected, or the user declined the Automation prompt.
    static func selection() -> [URL] {
        let source = """
        tell application "Finder"
            set out to ""
            repeat with item_ in (get selection)
                set out to out & (POSIX path of (item_ as alias)) & linefeed
            end repeat
            return out
        end tell
        """
        guard let script = NSAppleScript(source: source) else { return [] }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let error { NSLog("SeeThrough: Finder selection failed — \(error)") ; return [] }
        return (result.stringValue ?? "")
            .split(separator: "\n")
            .map { URL(fileURLWithPath: String($0)) }
    }
}
