# Ghostty macOS Screenshot Paste Bridge

Make Ghostty behave more like iTerm2 when pasting macOS screenshots copied directly to the clipboard.

## Problem

On macOS, Apple Screenshot can copy raw image data to the clipboard. Some terminal workflows expect pasting that clipboard into a terminal to produce a temporary image file path. Ghostty currently handles normal text paste, but image-only clipboard payloads do not become a path automatically.

This is especially annoying when using tools that accept image file paths, such as AI coding agents, OCR tools, or shell scripts.

## Solution

This project uses a Swift/AppKit clipboard helper plus a small Hammerspoon bridge. The Swift helper is intentional: Ghostty’s macOS pasteboard code is also Swift/AppKit, so the core behavior is easier to compare with a future native Ghostty implementation.

Runtime behavior:

- If Ghostty is frontmost and you press `Cmd+V`
- and the clipboard already contains text, Ghostty pastes normally
- but if the clipboard contains image-only data, the bridge saves it as a temporary PNG, copies the shell-escaped path to the clipboard, and lets the same paste continue

Result: screenshot clipboard → `Cmd+V` in Ghostty → temp PNG path.

## Requirements

- macOS
- [Ghostty](https://ghostty.org/)
- [Hammerspoon](https://www.hammerspoon.org/)
- Xcode Command Line Tools for the Swift helper: `swiftc`
- Standard macOS tools for the fallback helper: `osascript`, `sips`, `pbcopy`, `perl`, `xxd`

## Install

```sh
git clone https://github.com/DanDo385/ghostty-screenshot-paste-bridge.git
cd ghostty-screenshot-paste-bridge
./install.sh
```

Then enable Hammerspoon accessibility permission:

```text
System Settings -> Privacy & Security -> Accessibility -> Hammerspoon
```

Reload Hammerspoon:

```sh
hs -A -c 'hs.reload()'
```

If the `hs` command is not available yet, open Hammerspoon once from `/Applications` and try again.

## Test

1. Press `Shift+Cmd+Ctrl+4`.
2. Drag a screen region. macOS copies the screenshot to the clipboard.
3. Focus a Ghostty window.
4. Press `Cmd+V`.
5. A path like this should paste:

```text
/var/folders/.../ghostty-clipboard-images/Screenshot\ 2026-05-25_15.00.00.png
```

## Normal paste behavior

Text paste is intentionally unchanged. If the clipboard has text, the bridge does nothing and Ghostty handles `Cmd+V` normally.

## Uninstall

```sh
./uninstall.sh
```

This removes:

- `~/.local/bin/clipimgpath`
- `~/.hammerspoon/ghostty-screenshot-paste-bridge.lua`
- the managed `require(...)` block from `~/.hammerspoon/init.lua`

## Implementation notes

The primary converter is `src/clipimgpath.swift`. It reads `NSPasteboard.general`, converts image clipboard data to PNG using AppKit, writes the result under the macOS temp directory, copies the shell-escaped path back to the pasteboard, and prints it.

`bin/clipimgpath.bash` is a fallback for machines without `swiftc`.

Hammerspoon is only used for the Ghostty-specific `Cmd+V` interception because Ghostty itself does not currently expose a built-in hook for “before paste, convert image clipboard to path.”

## Manual use

You can also run the converter directly:

```sh
clipimgpath
```

Or print/copy the raw unescaped path:

```sh
clipimgpath --plain
```

## Related Ghostty upstream work

This project is a companion workaround, not a Ghostty fork.

Related upstream threads:

- Ghostty discussion `#10478`: support pasting images captured directly to clipboard
- Ghostty issue `#11444`: image paste in macOS workflows
- Ghostty PR `#11571`: attempted native macOS clipboard image-to-temp-path behavior

Ghostty has strict contribution rules, including a vouch process for first-time contributors and mandatory disclosure of AI assistance. If this behavior is proposed upstream, the implementation should be discussed with maintainers first.

## AI disclosure

This project was developed with AI assistance from Hermes/OpenAI. The maintainer is responsible for reviewing, understanding, testing, and editing all code and documentation before publishing or contributing upstream.

## License

MIT
