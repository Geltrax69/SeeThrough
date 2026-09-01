import AppKit

/// Two-column icon list. Shared by folder and archive previews, which differ
/// only in where the rows come from.
@MainActor
final class ListPreview: NSView, NSTableViewDataSource, NSTableViewDelegate {
    struct Row {
        let icon: NSImage
        let name: String
        let detail: String
    }

    private let rows: [Row]
    private let table = NSTableView()

    init(rows: [Row], frame: NSRect) {
        self.rows = rows
        super.init(frame: frame)
        autoresizingMask = [.width, .height]
        build()
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Icon for a path that may not exist on disk (archive members).
    static func icon(forName name: String, isDirectory: Bool) -> NSImage {
        isDirectory
            ? NSWorkspace.shared.icon(for: .folder)
            : NSWorkspace.shared.icon(forFileType: (name as NSString).pathExtension)
    }

    private func build() {
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

    func numberOfRows(in _: NSTableView) -> Int { rows.count }

    func tableView(_: NSTableView, viewFor column: NSTableColumn?, row index: Int) -> NSView? {
        let row = rows[index]

        if column?.identifier.rawValue == "detail" {
            let label = NSTextField(labelWithString: row.detail)
            label.textColor = .secondaryLabelColor
            label.font = .systemFont(ofSize: 11)
            return label
        }

        let cell = NSTableCellView()
        let icon = NSImageView(frame: NSRect(x: 0, y: 2, width: 18, height: 18))
        icon.image = row.icon
        let label = NSTextField(labelWithString: row.name)
        label.frame = NSRect(x: 24, y: 2, width: (column?.width ?? 400) - 24, height: 18)
        label.autoresizingMask = [.width]
        label.font = .systemFont(ofSize: 12)
        cell.addSubview(icon)
        cell.addSubview(label)
        return cell
    }
}
