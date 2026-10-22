// Renders the app icon (Ristretto squircle with a crema-colored portafilter) as a 1024px PNG.
// Usage: swiftc -parse-as-library Scripts/make-icon.swift Sources/Icons.swift -o make-icon && ./make-icon out.png
import AppKit

@main
enum MakeIcon {
    static func main() throws {
        let size = 1024
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                   colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

        // macOS icon grid: 824pt body centered in the 1024 canvas
        let body = NSRect(x: 100, y: 100, width: 824, height: 824)
        let squircle = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)
        NSGradient(starting: NSColor(srgbRed: 0x3A / 255, green: 0x24 / 255, blue: 0x17 / 255, alpha: 1),
                   ending: NSColor(srgbRed: 0x2A / 255, green: 0x1A / 255, blue: 0x10 / 255, alpha: 1))!
            .draw(in: squircle, angle: -90)

        let glyph = PortafilterIcon.image(brewing: true, size: 470,
                                          color: NSColor(srgbRed: 0.85, green: 0.62, blue: 0.40, alpha: 1))
        let g = glyph.size
        glyph.draw(in: NSRect(x: (1024 - g.width) / 2 + 10, y: (1024 - g.height) / 2, width: g.width, height: g.height))

        NSGraphicsContext.restoreGraphicsState()
        try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
    }
}
