import AppKit
import Foundation

struct ClipImgPathError: Error, CustomStringConvertible {
    let description: String
}

func usage() -> String {
    return """
    clipimgpath [--plain]

    Saves image data from the macOS clipboard to a temporary PNG and copies the path back to the clipboard.
    Default output is shell-escaped. Use --plain for the raw path.
    """
}

func shellEscape(_ path: String) -> String {
    // POSIX-safe single-quote escaping. Example: /tmp/Screenshot 1.png -> '/tmp/Screenshot 1.png'
    return "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
}

func pasteboardData(for rawTypes: [String], pasteboard: NSPasteboard) -> Data? {
    for rawType in rawTypes {
        let type = NSPasteboard.PasteboardType(rawType)
        if let data = pasteboard.data(forType: type), !data.isEmpty {
            return data
        }
    }
    return nil
}

func convertBitmapDataToPNG(_ data: Data) -> Data? {
    guard let bitmap = NSBitmapImageRep(data: data) else {
        return nil
    }
    return bitmap.representation(using: .png, properties: [:])
}

func pngDataFromPasteboard(_ pasteboard: NSPasteboard) throws -> Data {
    // If concrete PNG bytes are available, use them directly. This avoids fragile NSImage/TIFF round-trips.
    let pngTypes = [
        "public.png",
        "com.apple.png",
        "Apple PNG pasteboard type"
    ]
    if let pngData = pasteboardData(for: pngTypes, pasteboard: pasteboard), !pngData.isEmpty {
        return pngData
    }

    // Apple Screenshot commonly provides TIFF-compatible image data.
    let tiffTypes = [
        "public.tiff",
        "com.apple.tiff",
        "NeXT TIFF v4.0 pasteboard type",
        "NSTIFFPboardType"
    ]
    if let tiffData = pasteboardData(for: tiffTypes, pasteboard: pasteboard),
       let png = convertBitmapDataToPNG(tiffData) {
        return png
    }

    // Last resort: ask AppKit to materialize an NSImage from the pasteboard.
    let imageClasses: [AnyClass] = [NSImage.self]
    if let images = pasteboard.readObjects(forClasses: imageClasses, options: nil) as? [NSImage],
       let image = images.first,
       let tiff = image.tiffRepresentation,
       let png = convertBitmapDataToPNG(tiff) {
        return png
    }

    let available = pasteboard.types?.map { $0.rawValue }.joined(separator: ", ") ?? "none"
    throw ClipImgPathError(description: "clipboard does not appear to contain image data. Available pasteboard types: \(available)")
}

func outputURL() throws -> URL {
    let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let dir = tempRoot.appendingPathComponent("ghostty-clipboard-images", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd_HH.mm.ss"
    let timestamp = formatter.string(from: Date())
    return dir.appendingPathComponent("Screenshot \(timestamp).png")
}

func main() throws {
    let args = CommandLine.arguments.dropFirst()
    var plain = false

    for arg in args {
        switch arg {
        case "--plain":
            plain = true
        case "-h", "--help":
            print(usage())
            return
        default:
            throw ClipImgPathError(description: "unknown option: \(arg)\n\(usage())")
        }
    }

    let pasteboard = NSPasteboard.general
    let png = try pngDataFromPasteboard(pasteboard)
    let url = try outputURL()
    try png.write(to: url, options: .atomic)

    let rawPath = url.path
    let pastedPath = plain ? rawPath : shellEscape(rawPath)

    pasteboard.clearContents()
    pasteboard.setString(pastedPath, forType: .string)
    print(pastedPath)
}

do {
    try main()
} catch {
    fputs("clipimgpath: \(error)\n", stderr)
    fputs("Tip: use Apple's screenshot tool with Copy to Clipboard, then run clipimgpath.\n", stderr)
    exit(1)
}
