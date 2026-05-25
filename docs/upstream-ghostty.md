# Upstream Ghostty Notes

This project is intentionally a companion workaround, not an upstream Ghostty patch. These notes explain how the Swift helper maps to a possible native Ghostty implementation.

## Why Swift

Ghostty's macOS pasteboard integration lives in Swift/AppKit code. The core helper in this repository is also Swift/AppKit so the behavior can be reasoned about in the same language and APIs as Ghostty's macOS layer.

Relevant local file:

```text
src/clipimgpath.swift
```

Relevant Ghostty area to study before proposing upstream work:

```text
macos/Sources/Helpers/Extensions/NSPasteboard+Extension.swift
```

## Behavior to preserve

A native implementation should preserve normal paste behavior:

1. If the clipboard contains text, paste text normally.
2. If the clipboard contains file URLs, preserve existing file URL behavior.
3. If the clipboard contains image-only data from macOS Screenshot, write a temporary PNG and paste its path.
4. Do not intercept unrelated keybindings.
5. Do not send clipboard data over the network.

## Helper-to-Ghostty mapping

This repository's Swift helper does four things:

1. Reads concrete image bytes from `NSPasteboard.general`.
2. Prefers existing PNG data when present.
3. Converts TIFF/AppKit image data to PNG only when needed.
4. Writes the PNG under the macOS temp directory and returns a shell-safe path.

In Ghostty, the equivalent logic would likely belong inside the pasteboard-to-string/file handling code rather than in a separate CLI helper.

## Contribution process warning

Ghostty has strict contribution rules:

- first-time contributors need to be vouched before PRs are accepted
- AI assistance must be disclosed
- contributors must understand the code they submit
- low-effort or unclear AI-generated contributions are explicitly unwelcome

Recommended path:

1. Read Ghostty's `CONTRIBUTING.md` and `AI_POLICY.md`.
2. Join the existing screenshot paste discussion before writing code.
3. Request a vouch if you intend to submit a PR.
4. Build Ghostty locally and reproduce the behavior.
5. Submit the smallest possible patch with manual test notes.

Related upstream threads:

- Discussion `#10478`: support pasting images captured directly to clipboard
- Issue `#11444`: macOS image paste workflow
- PR `#11571`: prior native attempt, closed due to vouch policy
