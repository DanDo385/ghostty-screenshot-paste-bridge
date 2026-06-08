#!/usr/bin/env bash
# Install Ghostty macOS Screenshot Paste Bridge.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME:?HOME is required}"
LOCAL_BIN="$HOME_DIR/.local/bin"
HS_DIR="$HOME_DIR/.hammerspoon"
HS_INIT="$HS_DIR/init.lua"
BRIDGE_LUA="$HS_DIR/ghostty-screenshot-paste-bridge.lua"
BEGIN_MARKER="-- >>> ghostty-screenshot-paste-bridge"
END_MARKER="-- <<< ghostty-screenshot-paste-bridge"

need_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "install.sh: this tool is macOS-only." >&2
    exit 1
  fi
}

install_hammerspoon_if_possible() {
  if [[ -d "/Applications/Hammerspoon.app" ]]; then
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    echo "Hammerspoon not found. Installing with Homebrew..."
    brew install --cask hammerspoon
  else
    cat >&2 <<'MSG'
Hammerspoon is not installed and Homebrew is not available.
Install Hammerspoon first:
  https://www.hammerspoon.org/
MSG
    exit 1
  fi
}

install_clipimgpath() {
  mkdir -p "$LOCAL_BIN"
  if command -v swiftc >/dev/null 2>&1; then
    echo "Building Swift clipimgpath helper..."
    swiftc -framework AppKit "$ROOT/src/clipimgpath.swift" -o "$LOCAL_BIN/clipimgpath"
  else
    echo "swiftc not found; installing bash fallback helper."
    install -m 0755 "$ROOT/bin/clipimgpath.bash" "$LOCAL_BIN/clipimgpath"
  fi
}

patch_hammerspoon_init() {
  mkdir -p "$HS_DIR"
  touch "$HS_INIT"

  if grep -Fq -- "$BEGIN_MARKER" "$HS_INIT"; then
    perl -0pi -e "s|\Q$BEGIN_MARKER\E.*?\Q$END_MARKER\E|$BEGIN_MARKER\nrequire(\"ghostty-screenshot-paste-bridge\")\n$END_MARKER|s" "$HS_INIT"
  else
    {
      printf '\n%s\n' "$BEGIN_MARKER"
      printf 'require("ghostty-screenshot-paste-bridge")\n'
      printf '%s\n' "$END_MARKER"
    } >> "$HS_INIT"
  fi
}

main() {
  need_macos
  mkdir -p "$LOCAL_BIN" "$HS_DIR"

  install_clipimgpath
  install -m 0644 "$ROOT/hammerspoon/ghostty-screenshot-paste-bridge.lua" "$BRIDGE_LUA"
  patch_hammerspoon_init
  install_hammerspoon_if_possible

  open -a Hammerspoon || true

  cat <<'MSG'
Installed Ghostty macOS Screenshot Paste Bridge.

Required macOS permission:
  System Settings -> Privacy & Security -> Accessibility -> enable Hammerspoon

Then reload Hammerspoon:
  hs -A -c 'hs.reload()'

Test:
  1. Press Shift+Cmd+Ctrl+4 and drag a region. This copies a screenshot to clipboard.
  2. Focus Ghostty.
  3. Press Cmd+V.
  4. A temporary PNG path should paste into the terminal.
MSG
}

main "$@"
