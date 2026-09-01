import AVKit
import AppKit

/// Quick Look chokes on long or oddly-muxed video. AVPlayerView gives real
/// scrubbing, keyboard control and audio-track selection for free — but only
/// for containers AVFoundation understands, so unplayable files fall back to
/// an ffmpeg poster frame plus stream details.
@MainActor
final class VideoPreview: NSView {
    private let url: URL

    init(url: URL, frame: NSRect) {
        self.url = url
        super.init(frame: frame)
        autoresizingMask = [.width, .height]
        load()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func load() {
        let asset = AVURLAsset(url: url)
        Task {
            let playable = (try? await asset.load(.isPlayable)) ?? false
            playable ? showPlayer(asset) : await showPoster()
        }
    }

    private func showPlayer(_ asset: AVURLAsset) {
        let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        player.isMuted = Settings.muteVideo

        let view = AVPlayerView(frame: bounds)
        view.player = player
        view.controlsStyle = .floating
        view.showsFullScreenToggleButton = true
        view.allowsPictureInPicturePlayback = true
        view.autoresizingMask = [.width, .height]
        swap(in: view)
    }

    private func showPoster() async {
        let path = url.path
        let (image, details) = await Task.detached {
            (FFmpeg.poster(URL(fileURLWithPath: path)), FFmpeg.probe(URL(fileURLWithPath: path)))
        }.value

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stack.frame = bounds
        stack.autoresizingMask = [.width, .height]

        if let image {
            let iv = NSImageView()
            iv.image = image
            iv.imageScaling = .scaleProportionallyUpOrDown
            stack.addArrangedSubview(iv)
        }

        let text = details ?? "\(url.pathExtension.uppercased()) — install ffmpeg to preview this container."
        let label = NSTextField(labelWithString: text)
        label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        label.maximumNumberOfLines = 0
        stack.addArrangedSubview(label)

        swap(in: stack)
    }

    private func swap(in view: NSView) {
        subviews.forEach { $0.removeFromSuperview() }
        view.frame = bounds
        addSubview(view)
    }
}
