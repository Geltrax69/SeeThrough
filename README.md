# SeeThrough

Quick Look, but for the things Quick Look is bad at.

Press **⌥Space** and whatever is selected in Finder previews in a floating panel.
Esc closes it.

macOS won't let anything replace Finder's spacebar — Quick Look is system-owned —
so SeeThrough uses its own hotkey instead.

## What it previews

| Selection | What you get |
|---|---|
| **Video** (mp4, mov, m4v) | `AVPlayerView` with real scrubbing, PiP and full-screen. Works on multi-hour files. |
| **Video AVFoundation can't open** (mkv, avi) | Poster frame pulled with `ffmpeg`, plus codec, resolution, audio channels, duration and size. |
| **Folders** | The files inside — icons, names, sizes, subfolder item counts. Folders first, like Finder. |
| **Zip / tar / tar.gz** | Member list with sizes, read from the central directory. A 7GB archive opens instantly, nothing is extracted. |
| **Everything else** | Falls through to Quick Look itself, which already handles images, PDFs, text and code. |

## Is it running?

Look for the **eye icon in the menu bar**. That icon is the whole control panel:

- **Preview Finder Selection** — same as the hotkey, for when you forget it
- **Hotkey** — ⌥Space, ⌃Space or ⌘⇧Space
- **Mute Video Previews** — on by default
- **Open at Login**
- **Quit SeeThrough**

There is no Dock icon and no preferences window; the menu is it.

## Build

```bash
./build.sh && open SeeThrough.app
```

Runs as a background app — no Dock icon. Quit it from the menu bar icon.

## Requirements

- macOS 14+
- Xcode toolchain to build
- `ffmpeg` (optional) — only for mkv/avi poster frames. Without it those files
  show a short note instead.

## Permissions

The first ⌥Space asks for permission to control Finder. That's how it reads your
selection; decline it and the panel just says nothing is selected.

## Known gaps

- No drill-down into subfolders or archive members yet.
- Three preset hotkeys, no free-form key recorder.
- tar members list without sizes.
