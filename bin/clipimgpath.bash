#!/usr/bin/env bash
# Save image data from the macOS clipboard to a temp PNG, copy the path back to clipboard,
# and print the path. Useful because Ghostty pastes text, not image clipboard payloads.
set -euo pipefail

usage() {
  cat <<'USAGE'
clipimgpath [--plain]

Saves the current macOS clipboard image to a temp PNG and copies its path back to the clipboard.
Default output is shell-escaped, matching iTerm2-style terminal paste paths.
Use --plain to copy/print the raw path.
USAGE
}

plain=0
case "${1:-}" in
  --plain) plain=1 ;;
  -h|--help) usage; exit 0 ;;
  "") ;;
  *) echo "clipimgpath: unknown option: $1" >&2; usage >&2; exit 2 ;;
esac

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "clipimgpath: missing required command: $1" >&2; exit 127; }
}
need /usr/bin/osascript
need /usr/bin/perl
need /usr/bin/xxd
need /usr/bin/sips
need /usr/bin/pbcopy
need /bin/mkdir
need /bin/date
need /bin/rm

outdir="${TMPDIR:-/tmp}/ghostty-clipboard-images"
/bin/mkdir -p "$outdir"
ts="$(/bin/date '+%Y-%m-%d_%H.%M.%S')"
out="$outdir/Screenshot $ts.png"
tiff="$outdir/.clipboard-$ts.tiff"

extract_applescript_data() {
  # stdin: AppleScript data object text, e.g. «data PNGf89504E...». stdout: binary.
  /usr/bin/perl -0pe 's/^\s*«data\s+\S+\s*//; s/»\s*$//; s/[^0-9A-Fa-f]//g' | /usr/bin/xxd -r -p
}

save_png_direct() {
  local data
  data="$(/usr/bin/osascript -e 'get the clipboard as «class PNGf»' 2>/dev/null)" || return 1
  [[ "$data" == *"«data"* || "$data" == "«data"* ]] || return 1
  printf '%s' "$data" | extract_applescript_data > "$out"
  [[ -s "$out" ]]
}

save_tiff_then_convert() {
  local data
  data="$(/usr/bin/osascript -e 'get the clipboard as TIFF picture' 2>/dev/null)" || return 1
  [[ "$data" == *"«data"* || "$data" == "«data"* ]] || return 1
  printf '%s' "$data" | extract_applescript_data > "$tiff"
  [[ -s "$tiff" ]] || return 1
  /usr/bin/sips -s format png "$tiff" --out "$out" >/dev/null
  /bin/rm -f "$tiff"
  [[ -s "$out" ]]
}

if ! save_png_direct; then
  /bin/rm -f "$out"
  if ! save_tiff_then_convert; then
    /bin/rm -f "$out" "$tiff"
    cat >&2 <<'ERR'
clipimgpath: clipboard does not appear to contain image data.
Tip: use Apple's screenshot tool with "Copy to Clipboard", then run clipimgpath.
ERR
    exit 1
  fi
fi

if [[ "$plain" -eq 1 ]]; then
  clip="$out"
else
  # Bash's %q gives a paste-safe path with spaces escaped, like iTerm2's temp path behavior.
  printf -v clip '%q' "$out"
fi

printf '%s' "$clip" | /usr/bin/pbcopy
printf '%s\n' "$clip"
