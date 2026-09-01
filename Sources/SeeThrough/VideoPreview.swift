import AVKit
import AppKit

/// Quick Look chokes on long or oddly-muxed video. AVPlayerView gives real
/// scrubbing, keyboard control and audio-track selection for free.
@MainActor
enum VideoPreview {
    static func view(for url: URL, frame: NSRect) -> NSView {
        let player = AVPlayer(url: url)
        player.isMuted = true          // a preview should not blast audio

        let view = AVPlayerView(frame: frame)
        view.player = player
        view.controlsStyle = .floating
        view.showsFullScreenToggleButton = true
        view.allowsPictureInPicturePlayback = true
        view.autoresizingMask = [.width, .height]
        return view
    }
}
