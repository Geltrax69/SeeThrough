import AppKit

/// Quick Look shows a zip as a zip icon. This lists the members by reading the
/// central directory only — no extraction, so a 7GB archive opens instantly.
@MainActor
enum ArchivePreview {
    static func handles(_ url: URL) -> Bool {
        let name = url.lastPathComponent.lowercased()
        return name.hasSuffix(".zip") || name.hasSuffix(".tar")
            || name.hasSuffix(".tar.gz") || name.hasSuffix(".tgz")
    }

    static func view(for url: URL, frame: NSRect) -> NSView {
        let rows = url.lastPathComponent.lowercased().hasSuffix(".zip")
            ? zipRows(url)
            : tarRows(url)
        guard !rows.isEmpty else {
            let label = NSTextField(labelWithString: "Could not read \(url.lastPathComponent).")
            label.alignment = .center
            label.frame = frame
            label.autoresizingMask = [.width, .height]
            return label
        }
        return ListPreview(rows: rows, frame: frame)
    }

    /// `unzip -l` lines look like: "  1234  01-02-2026 03:04   path/to/file"
    private static func zipRows(_ url: URL) -> [ListPreview.Row] {
        run("/usr/bin/unzip", ["-l", url.path])
            .split(separator: "\n")
            .compactMap { line in
                let parts = line.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
                guard parts.count == 4, let bytes = Int64(parts[0]) else { return nil }
                let name = String(parts[3])
                let isDirectory = name.hasSuffix("/")
                return ListPreview.Row(
                    icon: ListPreview.icon(forName: name, isDirectory: isDirectory),
                    name: name,
                    detail: isDirectory ? "" : ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
            }
    }

    // ponytail: no sizes for tar members. `tar -tvf` has them but scans the
    // whole stream; not worth it until someone asks.
    private static func tarRows(_ url: URL) -> [ListPreview.Row] {
        run("/usr/bin/tar", ["-tf", url.path])
            .split(separator: "\n")
            .map { line in
                let name = String(line)
                return ListPreview.Row(
                    icon: ListPreview.icon(forName: name, isDirectory: name.hasSuffix("/")),
                    name: name, detail: "")
            }
    }

    private static func run(_ path: String, _ args: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(decoding: data, as: UTF8.self)
    }
}
