import AppKit

/// Template image of the arrangement: the large rectangle is the external display, the small one the MacBook.
enum LayoutIcon {
    private static let large = CGSize(width: 16, height: 10)
    private static let small = CGSize(width: 10, height: 7)
    private static let stroke: CGFloat = 1.5

    static func image(_ arrangement: Arrangement, size: NSSize = NSSize(width: 26, height: 16)) -> NSImage {
        let image = NSImage(size: size, flipped: true) { bounds in
            draw(arrangement, in: bounds)
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func draw(_ arrangement: Arrangement, in bounds: CGRect) {
        // y down. Touching rectangles overlap by one stroke width so they share a single line.
        var e = CGRect(origin: .zero, size: large), b = CGRect(origin: .zero, size: small)
        switch arrangement {
        case .right:
            b.origin.y = e.height - b.height
            e.origin.x = b.width - stroke
        case .left:
            b.origin = CGPoint(x: e.width - stroke, y: e.height - b.height)
        case .above:
            b.origin = CGPoint(x: ((e.width - b.width) / 2).rounded(), y: e.height - stroke)
        case .mirror:
            b.origin = CGPoint(x: e.width - b.width + 2.5, y: e.height - b.height + 2.5)
        }

        let box = e.union(b)
        let dx = ((bounds.width - box.width) / 2).rounded(), dy = ((bounds.height - box.height) / 2).rounded()
        for (i, r) in [e, b].enumerated() {
            let path = NSBezierPath(rect: r.offsetBy(dx: dx, dy: dy).insetBy(dx: stroke / 2, dy: stroke / 2))
            if arrangement == .mirror && i == 1 {
                // Erase the display behind so the MacBook reads as in front.
                NSGraphicsContext.current?.compositingOperation = .clear
                path.fill()
                NSGraphicsContext.current?.compositingOperation = .sourceOver
            }
            NSColor.black.setStroke()
            path.lineWidth = stroke
            path.stroke()
        }
    }
}
