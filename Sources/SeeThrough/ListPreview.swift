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
        let icon = NSImageView()
        icon.image = row.icon
        let label = NSTextField(labelWithString: row.name)
        label.font = .systemFont(ofSize: 12)
        // Archive members are full paths; keep the tail, which is the part that
        // tells one entry from another.
        label.lineBreakMode = .byTruncatingHead
        label.usesSingleLineMode = true

        for view in [icon, label] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(view)
        }
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
            icon.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        return cell
    }
}
