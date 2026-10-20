// Renders the 1024px app icon PNG. Run via scripts/make-icon.sh.
import AppKit

let canvas: CGFloat = 1024
// macOS icon grid: an 824pt rounded square centered on the 1024 canvas.
let body = CGRect(x: 100, y: 100, width: 824, height: 824)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat(hex >> 16 & 0xff) / 255, green: CGFloat(hex >> 8 & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
}

func draw() {
    NSGradient(starting: color(0x2b3a67), ending: color(0x101728))!
        .draw(in: NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185), angle: -90)

    // Same motif as the menu bar icon: external display (large) right of the MacBook (small),
    // bottoms aligned, edges touching.
    let large = CGSize(width: 400, height: 270), small = CGSize(width: 270, height: 182)
    let x = body.midX - (large.width + small.width) / 2, bottom = body.midY - large.height / 2
    let external = CGRect(x: x + small.width, y: bottom, width: large.width, height: large.height)
    let builtin = CGRect(x: x, y: bottom, width: small.width, height: small.height)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color(0x000000, 0.3)
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.shadowBlurRadius = 30
    shadow.set()
    color(0xffffff).setFill()
    NSBezierPath(rect: external).fill()
    color(0xdfe7ff).setFill()
    NSBezierPath(rect: builtin).fill()
    NSGraphicsContext.restoreGraphicsState()

    // Seam so the two screens read as two displays, not one shape.
    color(0x101728, 0.35).setFill()
    NSBezierPath(rect: CGRect(x: external.minX - 4, y: bottom, width: 8, height: small.height)).fill()
}

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(canvas), pixelsHigh: Int(canvas),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
draw()
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
