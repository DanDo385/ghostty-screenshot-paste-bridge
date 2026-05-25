#!/usr/bin/env bash
# Uninstall Ghostty macOS Screenshot Paste Bridge.
set -euo pipefail

HOME_DIR="${HOME:?HOME is required}"
HS_INIT="$HOME_DIR/.hammerspoon/init.lua"
BEGIN_MARKER="-- >>> ghostty-screenshot-paste-bridge"
END_MARKER="-- <<< ghostty-screenshot-paste-bridge"

if [[ -f "$HS_INIT" ]] && grep -Fq "$BEGIN_MARKER" "$HS_INIT"; then
  perl -0pi -e "s|\n?\Q$BEGIN_MARKER\E.*?\Q$END_MARKER\E\n?||s" "$HS_INIT"
fi

rm -f "$HOME_DIR/.hammerspoon/ghostty-screenshot-paste-bridge.lua"
rm -f "$HOME_DIR/.local/bin/clipimgpath"

if command -v hs >/dev/null 2>&1; then
  hs -A -c 'hs.reload()' >/dev/null 2>&1 || true
fi

echo "Uninstalled Ghostty macOS Screenshot Paste Bridge."
