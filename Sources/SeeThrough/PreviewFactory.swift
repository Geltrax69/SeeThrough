import AppKit
import Quartz
import UniformTypeIdentifiers

/// Picks the view for a file. Anything we have no opinion about falls through
/// to Quick Look itself, which already handles images, PDFs, text and code.
enum PreviewFactory {
    @MainActor
    static func view(for url: URL, size: NSSize) -> NSView {
        let frame = NSRect(origin: .zero, size: size)

        if let type = type(of: url), type.conforms(to: .audiovisualContent) {
            return VideoPreview(url: url, frame: frame)
        }

        let ql = QLPreviewView(frame: frame, style: .normal) ?? QLPreviewView()
        ql.previewItem = url as QLPreviewItem
        ql.autoresizingMask = [.width, .height]
        return ql
    }

    static func type(of url: URL) -> UTType? {
        try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
    }
}
