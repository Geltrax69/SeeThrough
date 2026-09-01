import AppKit

/// Quick Look shows a folder as its own icon, which tells you nothing.
/// This lists what is actually inside.
@MainActor
final class FolderPreview: NSView, NSTableViewDataSource, NSTableViewDelegate {
    private struct Entry {
        let url: URL
        let isDirectory: Bool
        let size: Int
        let children: Int
    }

    private var entries: [Entry] = []
    private let table = NSTableView()

    init(url: URL, frame: NSRect) {
        super.init(frame: frame)
        autoresizingMask = [.width, .height]
        entries = Self.read(url)
        buildTable()
    }

    required init?(coder: NSCoder) { fatalError() }

    private static func read(_ url: URL) -> [Entry] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey]
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: url, includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles])) ?? []

        return contents.map { child in
            let values = try? child.resourceValues(forKeys: Set(keys))
            let isDirectory = values?.isDirectory ?? false
            let children = isDirectory
                ? ((try? FileManager.default.contentsOfDirectory(atPath: child.path))?.count ?? 0)
                : 0
            return Entry(url: child, isDirectory: isDirectory,
                         size: values?.fileSize ?? 0, children: children)
        }
        // Folders first, then by name — the order Finder uses.
        .sorted {
            $0.isDirectory != $1.isDirectory
                ? $0.isDirectory
                : $0.url.lastPathComponent.localizedStandardCompare($1.url.lastPathComponent) == .orderedAscending
        }
    }

    private func buildTable() {
        let name = NSTableColumn(identifier: .init("name"))
        name.title = "Name"
        name.width = bounds.width - 140
        let detail = NSTableColumn(identifier: .init("detail"))
        detail.title = "Size"
        detail.width = 120

        table.addTableColumn(name)
        table.addTableColumn(detail)
        table.dataSource = self
        table.delegate = self
        table.rowHeight = 24
        table.usesAlternatingRowBackgroundColors = true
        table.style = .inset

        let scroll = NSScrollView(frame: bounds)
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.autoresizingMask = [.width, .height]
        addSubview(scroll)
    }

    func numberOfRows(in _: NSTableView) -> Int { entries.count }

    func tableView(_: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        let entry = entries[row]

        if column?.identifier.rawValue == "detail" {
            let text = entry.isDirectory
                ? "\(entry.children) item\(entry.children == 1 ? "" : "s")"
                : ByteCountFormatter.string(fromByteCount: Int64(entry.size), countStyle: .file)
            let label = NSTextField(labelWithString: text)
            label.textColor = .secondaryLabelColor
            label.font = .systemFont(ofSize: 11)
            return label
        }

        let cell = NSTableCellView()
        let icon = NSImageView(frame: NSRect(x: 0, y: 2, width: 18, height: 18))
        icon.image = NSWorkspace.shared.icon(forFile: entry.url.path)
        let label = NSTextField(labelWithString: entry.url.lastPathComponent)
        label.frame = NSRect(x: 24, y: 2, width: (column?.width ?? 400) - 24, height: 18)
        label.autoresizingMask = [.width]
        label.font = .systemFont(ofSize: 12)
        cell.addSubview(icon)
        cell.addSubview(label)
        return cell
    }

    /// Double-click drills into a subfolder, the way Finder does.
    func tableViewSelectionDidChange(_: Notification) {}
}
