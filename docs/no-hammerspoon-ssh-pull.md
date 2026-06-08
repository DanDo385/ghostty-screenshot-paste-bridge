# No-Hammerspoon SSH Pull Mode

## Verdict: VALIDATED

This mode solves the iMac-to-MBP screenshot path problem without Hammerspoon, Accessibility permissions, or eventtap key interception.

## Mechanism

The GUI-owning Mac has the screenshot clipboard. In Dan's cockpit, that is the iMac running Ghostty.

The worker/runtime Mac needs the file path. In Dan's cockpit, that is the MBP running SSH/tmux/Hermes.

`clipshot-sync` runs on the MBP and does this:

1. SSH to the GUI Mac, default `imac-cockpit`.
2. Run the existing Swift/AppKit `clipimgpath --plain` helper on that Mac.
3. Read the image file bytes back over SSH.
4. Save them to a MBP-local PNG path.
5. Print the MBP path.
6. Optionally copy that MBP path back to the GUI Mac clipboard with `--copy-remote`.
7. Optionally emit OSC 52 with `--osc52`, asking Ghostty to copy the MBP path to the GUI clipboard.

## Why this has real value

The Hammerspoon bridge converts an image clipboard into an iMac-local temp path. That path is not readable by the MBP-hosted Hermes runtime.

This mode produces a MBP-local path, which is exactly what Hermes, tmux shells, and remote CLI agents can read.

## Usage

On the iMac:

```text
Ctrl-Cmd-Shift-4, then drag a screenshot region
```

Inside the MBP shell shown in Ghostty:

```sh
bin/clipshot-sync --copy-remote
```

Then press `Cmd-V` in Ghostty. The clipboard should now contain a shell-escaped MBP path, for example:

```text
'/Users/openclaw/.cache/hermes/clipshots/Screenshot 2026-06-03_13.31.17.png'
```

For raw output:

```sh
bin/clipshot-sync --plain
```

To choose another GUI Mac:

```sh
bin/clipshot-sync --host imac-cockpit
```

To choose the local destination:

```sh
bin/clipshot-sync --dest /tmp/clipshots
```

## Requirements

- SSH from MBP to GUI Mac works with `BatchMode=yes`.
- GUI Mac has `~/.local/bin/clipimgpath` or `clipimgpath` on PATH.
- GUI Mac clipboard contains image data.
- For `--copy-remote`, GUI Mac has `/usr/bin/pbcopy`.
- For `--osc52`, terminal must allow clipboard writes. Dan's Ghostty config currently has `clipboard-write = allow`.

## Verified on 2026-06-03

Command sequence:

```sh
ssh imac-cockpit '/tmp/put-test-png-on-clipboard'
./spikes/001-no-hammerspoon-ssh-pull/clipshot-sync --copy-remote --dest /tmp/clipshot-spike-test
```

Observed:

```text
printed='/tmp/clipshot-spike-test/Screenshot 2026-06-03_13.31.17.png'
imac_clipboard='/tmp/clipshot-spike-test/Screenshot 2026-06-03_13.31.17.png'
local_file_exists True
local_file_png True
```

A prior plain transfer also verified:

```text
/tmp/clipshot-spike-test/Screenshot 2026-06-03_13.31.05.png: PNG image data, 32 x 32, 8-bit/color RGBA, non-interlaced
bytes 3045
png_signature_ok True
```

## Tradeoffs

Pros:

- No Hammerspoon.
- No Accessibility permission.
- Produces MBP-readable paths.
- Works from SSH/tmux shells.
- Better evidence for real terminal-agent workflows.

Cons:

- It is command-driven, not automatic Cmd-V interception.
- Needs SSH from MBP back to iMac.
- Needs the Swift helper installed on the GUI Mac.
- If invoked from inside Neovim or a TUI, printed text may go to the app, not a shell. Use a shell pane or bind a tmux command later.

## Recommendation for real build

Keep this as a first-class companion mode named `clipshot-sync`.

Next improvements:

1. Add installer support to install `clipshot-sync` on the MBP.
2. Add a tmux binding that runs it in a popup and copies the MBP path back to iMac clipboard.
3. Add an optional Ghostty keybind that sends a shell command only for shell-focused panes, with clear caveats.
4. Add a cleanup policy for old copied images.
