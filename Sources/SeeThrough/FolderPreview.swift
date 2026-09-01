import AppKit

/// Quick Look shows a folder as its own icon, which tells you nothing.
/// This lists what is actually inside.
@MainActor
enum FolderPreview {
    static func view(for url: URL, frame: NSRect) -> NSView {
        ListPreview(rows: rows(for: url), frame: frame)
    }

    private static func rows(for url: URL) -> [ListPreview.Row] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey]
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: url, includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles])) ?? []

        return contents
            // Folders first, then by name — the order Finder uses.
            .sorted { a, b in
                let aDir = (try? a.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                let bDir = (try? b.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                return aDir != bDir
                    ? aDir
                    : a.lastPathComponent.localizedStandardCompare(b.lastPathComponent) == .orderedAscending
            }
            .map { child in
                let values = try? child.resourceValues(forKeys: Set(keys))
                let isDirectory = values?.isDirectory ?? false
                let detail: String
                if isDirectory {
                    let count = (try? FileManager.default.contentsOfDirectory(atPath: child.path))?.count ?? 0
                    detail = "\(count) item\(count == 1 ? "" : "s")"
                } else {
                    detail = ByteCountFormatter.string(fromByteCount: Int64(values?.fileSize ?? 0), countStyle: .file)
                }
                return ListPreview.Row(icon: NSWorkspace.shared.icon(forFile: child.path),
                                       name: child.lastPathComponent,
                                       detail: detail)
            }
    }
}
