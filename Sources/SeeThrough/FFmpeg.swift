import AppKit

/// AVFoundation cannot open Matroska, AVI or Ogg at all. Rather than bundle
/// VLCKit (~50MB), lean on an ffmpeg that is already installed.
// ponytail: optional dependency. Bundle VLCKit only if shipping to people who
// will never have Homebrew.
enum FFmpeg {
    static var ffmpeg: String? { tool("ffmpeg") }
    static var ffprobe: String? { tool("ffprobe") }

    private static func tool(_ name: String) -> String? {
        ["/opt/homebrew/bin/", "/usr/local/bin/", "/usr/bin/"]
            .map { $0 + name }
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// Human-readable stream summary, or nil if ffprobe is missing.
    static func probe(_ url: URL) -> String? {
        guard let ffprobe else { return nil }
        let out = run(ffprobe, [
            "-v", "quiet",
            "-show_entries", "format=duration,size,format_long_name:stream=codec_type,codec_name,width,height,channels",
            "-of", "default=noprint_wrappers=1", url.path,
        ])
        return out.isEmpty ? nil : out
    }

    /// A frame from one minute in — far enough past titles to be recognisable.
    static func poster(_ url: URL) -> NSImage? {
        guard let ffmpeg else { return nil }
        let out = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("seethrough-\(abs(url.path.hashValue)).jpg")
        if !FileManager.default.fileExists(atPath: out.path) {
            _ = run(ffmpeg, ["-nostdin", "-ss", "60", "-i", url.path,
                             "-frames:v", "1", "-vf", "scale=1280:-2",
                             "-y", out.path])
        }
        return NSImage(contentsOf: out)
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
