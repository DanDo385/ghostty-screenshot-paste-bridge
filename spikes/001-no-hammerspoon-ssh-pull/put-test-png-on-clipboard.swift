import AppKit
import Foundation

let size = NSSize(width: 16, height: 16)
let image = NSImage(size: size)
image.lockFocus()
NSColor.systemRed.setFill()
NSRect(origin: .zero, size: size).fill()
NSColor.white.setFill()
NSRect(x: 4, y: 4, width: 8, height: 8).fill()
image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("failed to create PNG\n", stderr)
    exit(1)
}

let pb = NSPasteboard.general
pb.clearContents()
pb.setData(png, forType: .png)
print("wrote PNG clipboard bytes: \(png.count)")
