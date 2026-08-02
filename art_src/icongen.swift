import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Generates the 1024×1024 app icon: an abstract amber token on a soft radial
// ground. Opaque RGB, no alpha channel (App Store Connect rejects alpha).
// Usage: icongen <output-path.png>

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon-1024.png"
let S = 1024

let space = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: S, height: S, bitsPerComponent: 8,
                          bytesPerRow: S * 4, space: space,
                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    exit(1)
}
ctx.setAllowsAntialiasing(true)
ctx.interpolationQuality = .high

func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(colorSpace: space, components: [CGFloat(r), CGFloat(g), CGFloat(b), CGFloat(a)])!
}

let f = CGFloat(S)

// Ground.
ctx.setFillColor(rgb(0.086, 0.070, 0.063))
ctx.fill(CGRect(x: 0, y: 0, width: f, height: f))

// Soft warm radial behind the emblem.
if let grad = CGGradient(colorsSpace: space,
                         colors: [rgb(0.278, 0.153, 0.078),
                                  rgb(0.153, 0.106, 0.078),
                                  rgb(0.078, 0.063, 0.055)] as CFArray,
                         locations: [0, 0.55, 1]) {
    ctx.drawRadialGradient(grad,
                           startCenter: CGPoint(x: f * 0.5, y: f * 0.54), startRadius: 0,
                           endCenter: CGPoint(x: f * 0.5, y: f * 0.54), endRadius: f * 0.72,
                           options: [])
}

// Outer ring.
ctx.setStrokeColor(rgb(0.475, 0.365, 0.157, 0.55))
ctx.setLineWidth(f * 0.012)
ctx.strokeEllipse(in: CGRect(x: f * 0.215, y: f * 0.215, width: f * 0.57, height: f * 0.57))

// The token itself.
let coin = CGRect(x: f * 0.275, y: f * 0.275, width: f * 0.45, height: f * 0.45)
if let grad = CGGradient(colorsSpace: space,
                         colors: [rgb(0.996, 0.796, 0.373),
                                  rgb(0.878, 0.545, 0.176),
                                  rgb(0.596, 0.286, 0.086)] as CFArray,
                         locations: [0, 0.55, 1]) {
    ctx.saveGState()
    ctx.addEllipse(in: coin)
    ctx.clip()
    ctx.drawRadialGradient(grad,
                           startCenter: CGPoint(x: coin.midX - coin.width * 0.16,
                                                y: coin.midY + coin.height * 0.18),
                           startRadius: 0,
                           endCenter: CGPoint(x: coin.midX, y: coin.midY),
                           endRadius: coin.width * 0.78,
                           options: [])
    ctx.restoreGState()
}

// Inner bevel line.
ctx.setStrokeColor(rgb(0.400, 0.208, 0.063, 0.75))
ctx.setLineWidth(f * 0.010)
ctx.strokeEllipse(in: coin.insetBy(dx: f * 0.035, dy: f * 0.035))

// A single facet chevron across the token — abstract, not a literal subject.
ctx.saveGState()
ctx.addEllipse(in: coin.insetBy(dx: f * 0.035, dy: f * 0.035))
ctx.clip()
ctx.setFillColor(rgb(1.000, 0.910, 0.667, 0.30))
ctx.beginPath()
ctx.move(to: CGPoint(x: coin.minX, y: coin.midY + coin.height * 0.10))
ctx.addLine(to: CGPoint(x: coin.midX, y: coin.midY + coin.height * 0.30))
ctx.addLine(to: CGPoint(x: coin.maxX, y: coin.midY + coin.height * 0.10))
ctx.addLine(to: CGPoint(x: coin.maxX, y: coin.maxY))
ctx.addLine(to: CGPoint(x: coin.minX, y: coin.maxY))
ctx.closePath()
ctx.fillPath()
ctx.restoreGState()

// Two small sparks.
func spark(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ alpha: Double) {
    ctx.setFillColor(rgb(1.000, 0.878, 0.588, alpha))
    ctx.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
}
spark(f * 0.775, f * 0.735, f * 0.020, 0.85)
spark(f * 0.238, f * 0.318, f * 0.014, 0.65)
spark(f * 0.300, f * 0.775, f * 0.010, 0.50)

guard let image = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL,
                                                 UTType.png.identifier as CFString, 1, nil) else {
    exit(1)
}
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out)")
