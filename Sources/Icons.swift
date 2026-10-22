import AppKit

/// Portafilter glyph. Without a `color` it is a template image that follows light/dark mode.
enum PortafilterIcon {
    /// Coffee brown that stays readable on both light and dark menu bars.
    static let menuBarBrown = NSColor(srgbRed: 0.66, green: 0.43, blue: 0.24, alpha: 1)
    /// Ristretto, the panel's brown. Only readable on a light menu bar.
    static let ristretto = NSColor(srgbRed: 0x2A / 255, green: 0x1A / 255, blue: 0x10 / 255, alpha: 1)

    static func brewingColor(onDarkBar: Bool) -> NSColor {
        onDarkBar ? menuBarBrown : ristretto
    }

    static func image(brewing: Bool, size: CGFloat = 18, color: NSColor? = nil) -> NSImage {
        let canvas = NSSize(width: size * 22 / 18, height: size)
        let image = NSImage(size: canvas, flipped: false) { rect in
            let s = rect.height / 18
            (color ?? .black).setFill()
            (color ?? .black).setStroke()

            // Handle, running into the basket wall so there is no gap
            NSBezierPath(roundedRect: NSRect(x: 0.5 * s, y: 10 * s, width: 10.1 * s, height: 2.6 * s),
                         xRadius: 1.3 * s, yRadius: 1.3 * s).fill()

            // Rim
            NSBezierPath(roundedRect: NSRect(x: 8.5 * s, y: 12.2 * s, width: 13 * s, height: 1.8 * s),
                         xRadius: 0.9 * s, yRadius: 0.9 * s).fill()

            // Bottomless basket: straight vertical walls, only a slight chamfer into the flat bottom
            let basket = NSBezierPath()
            basket.move(to: NSPoint(x: 10.2 * s, y: 12.4 * s))
            basket.line(to: NSPoint(x: 10.2 * s, y: 8 * s))
            basket.line(to: NSPoint(x: 11.3 * s, y: 6.2 * s))
            basket.line(to: NSPoint(x: 18.7 * s, y: 6.2 * s))
            basket.line(to: NSPoint(x: 19.8 * s, y: 8 * s))
            basket.line(to: NSPoint(x: 19.8 * s, y: 12.4 * s))
            basket.close()
            basket.lineWidth = 1.4 * s
            basket.lineJoinStyle = .round
            basket.stroke()

            if brewing {
                // Stream: slightly wider where it leaves the basket, then narrowing in a soft curve
                let stream = NSBezierPath()
                stream.move(to: NSPoint(x: 13.4 * s, y: 6 * s))
                stream.curve(to: NSPoint(x: 14.45 * s, y: 3.2 * s),
                             controlPoint1: NSPoint(x: 14.2 * s, y: 5.6 * s),
                             controlPoint2: NSPoint(x: 14.45 * s, y: 4.4 * s))
                stream.line(to: NSPoint(x: 14.45 * s, y: 0.9 * s))
                stream.curve(to: NSPoint(x: 15.55 * s, y: 0.9 * s),
                             controlPoint1: NSPoint(x: 14.45 * s, y: 0.15 * s),
                             controlPoint2: NSPoint(x: 15.55 * s, y: 0.15 * s))
                stream.line(to: NSPoint(x: 15.55 * s, y: 3.2 * s))
                stream.curve(to: NSPoint(x: 16.6 * s, y: 6 * s),
                             controlPoint1: NSPoint(x: 15.55 * s, y: 4.4 * s),
                             controlPoint2: NSPoint(x: 15.8 * s, y: 5.6 * s))
                stream.close()
                stream.fill()
            }
            return true
        }
        image.isTemplate = color == nil
        return image
    }
}
