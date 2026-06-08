# 001: No-Hammerspoon SSH Pull

## Question

Given Ghostty is running on the iMac and the shell/Hermes runtime is on the MBP over SSH, can the MBP pull an image-only iMac clipboard screenshot into a MBP-local PNG without Hammerspoon?

## Approach

Build `clipshot-sync`:

1. Run from MBP.
2. SSH to `imac-cockpit`.
3. Run iMac-side `clipimgpath --plain` to materialize the image clipboard as an iMac temp PNG.
4. Stream the PNG bytes back over SSH with `/bin/cat`.
5. Save to a MBP-local destination.
6. Optionally copy the MBP path back to the iMac clipboard with `pbcopy`.

## Result

Validated with a generated PNG placed on the iMac pasteboard.

Final verification output:

```text
wrote PNG clipboard bytes: 3045
path /tmp/clipshot-final-test/Screenshot 2026-06-03_13.33.05.png
exists True
bytes 3045
png_signature_ok True
remote_clipboard='/tmp/clipshot-final-test/Screenshot 2026-06-03_13.33.05.png'
```

## Verdict: VALIDATED

### What worked

- MBP can SSH to `imac-cockpit` with `BatchMode=yes`.
- iMac has `~/.local/bin/clipimgpath`.
- Image clipboard bytes can be materialized on iMac and streamed to MBP.
- Resulting MBP file is a valid PNG.
- `--copy-remote` sets the iMac clipboard to the MBP path, so `Cmd-V` in Ghostty pastes a path that the MBP can read.

### What didn't

- Ghostty cannot currently bind a key to run a local shell command. Official keybind actions do not include `exec`/`shell`.
- This does not intercept plain `Cmd-V`; it is command-driven.

### Surprises

- This mode is strategically better for the MBP-hosted Hermes workflow than the pure Hammerspoon bridge because the final path is worker-local.

### Recommendation for the real build

Promote `clipshot-sync` as a first-class companion command. Next: installer support plus tmux popup binding.
