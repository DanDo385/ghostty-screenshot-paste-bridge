# Contributing

Thanks for improving Ghostty macOS Screenshot Paste Bridge.

## Development principles

- Keep normal text paste untouched.
- Only intercept `Cmd+V` when Ghostty is frontmost.
- Prefer small, auditable shell/Lua changes.
- Do not store screenshots outside the system temp directory.
- Do not collect telemetry.

## Testing checklist

Before opening a PR, test:

- `bash -n install.sh uninstall.sh bin/clipimgpath`
- Lua syntax for `hammerspoon/ghostty-screenshot-paste-bridge.lua`
- text clipboard still pastes normally in Ghostty
- image-only screenshot clipboard pastes a temporary PNG path
- uninstall removes only the managed Hammerspoon block

## AI-assisted contributions

AI-assisted contributions are allowed, but contributors must review and understand the code they submit. If you used AI tools materially, disclose that in the PR.
