-- Ghostty macOS screenshot paste bridge for Hammerspoon.
--
-- Behavior:
--   * Cmd+V in Ghostty with text clipboard: paste normally.
--   * Cmd+V in Ghostty with image-only clipboard: save image to temp PNG,
--     replace clipboard with a shell-escaped path, then let Ghostty paste it.
--
-- Requires bin/clipimgpath to be installed at ~/.local/bin/clipimgpath.

local ghosttyBundleID = "com.mitchellh.ghostty"
local clipimgpath = os.getenv("HOME") .. "/.local/bin/clipimgpath"
local lastConversionAt = 0

-- Enable the `hs` CLI for reload/debug checks when available.
if hs.ipc then
  hs.ipc.cliInstall()
end

if hs.autoLaunch then
  hs.autoLaunch(true)
end

local function frontAppIsGhostty()
  local app = hs.application.frontmostApplication()
  return app and app:bundleID() == ghosttyBundleID
end

local function clipboardHasText()
  local text = hs.pasteboard.getContents()
  return text ~= nil and text ~= ""
end

local function clipboardHasImageType()
  local types = hs.pasteboard.contentTypes() or {}
  for _, t in ipairs(types) do
    local lower = string.lower(t)
    if string.find(lower, "png", 1, true)
      or string.find(lower, "tiff", 1, true)
      or string.find(lower, "jpeg", 1, true)
      or string.find(lower, "jpg", 1, true)
      or string.find(lower, "image", 1, true) then
      return true
    end
  end
  return false
end

local function convertImageClipboardToPath()
  local now = hs.timer.secondsSinceEpoch()
  if now - lastConversionAt < 0.35 then
    return true
  end
  lastConversionAt = now

  local ok, output, status, _ = hs.execute(clipimgpath, true)
  if ok and status == 0 then
    local path = (output or ""):gsub("%s+$", "")
    if path ~= "" then
      hs.alert.show("Screenshot path copied", 0.45)
    end
    return true
  end

  hs.alert.show("Image paste failed: clipimgpath", 1.5)
  hs.printf("clipimgpath failed: %s", tostring(output))
  return false
end

local ghosttyScreenshotPasteBridge = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  if not frontAppIsGhostty() then
    return false
  end

  local flags = event:getFlags()
  local keyCode = event:getKeyCode()

  -- Cmd+V only. Ignore Ctrl/Alt/Shift variants so Ghostty/tmux/custom shortcuts still work.
  if keyCode ~= hs.keycodes.map.v then
    return false
  end
  if not flags.cmd or flags.ctrl or flags.alt or flags.shift or flags.fn then
    return false
  end

  -- If the clipboard already has text, Ghostty should paste normally.
  if clipboardHasText() then
    return false
  end

  -- If it is image-only, convert first and let the original Cmd+V continue.
  if clipboardHasImageType() then
    convertImageClipboardToPath()
    return false
  end

  return false
end)

ghosttyScreenshotPasteBridge:start()
_G.ghosttyScreenshotPasteBridge = ghosttyScreenshotPasteBridge

hs.alert.show("Ghostty screenshot paste bridge loaded", 1.0)
