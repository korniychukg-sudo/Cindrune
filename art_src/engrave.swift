import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// A copperplate engraving engine.
//
// Nothing here is filled with a flat colour. Every tone is built out of burin
// lines: parallel hatching for flat planes, curved strokes across the form for
// anything round, stipple for smoke and glow. That is what separates an
// engraving from a diagram with stripes drawn over it.

// MARK: - Deterministic RNG

var engSeed: UInt64 = 0x9E3779B97F4A7C15

func eSeed(_ v: UInt64) { engSeed = v &* 0x2545F4914F6CDD1D | 1 }

@discardableResult
func eNext() -> UInt64 {
    engSeed ^= engSeed << 13
    engSeed ^= engSeed >> 7
    engSeed ^= engSeed << 17
    return engSeed
}

func eRnd() -> CGFloat { CGFloat(eNext() % 1_000_000) / 1_000_000.0 }
func eRnd(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * eRnd() }

// MARK: - Colour

typealias Ink = (CGFloat, CGFloat, CGFloat)

let engSpace = CGColorSpaceCreateDeviceRGB()

func engColor(_ c: Ink, _ a: CGFloat) -> CGColor {
    CGColor(colorSpace: engSpace, components: [c.0, c.1, c.2, a])!
}

/// Warm printer's black — never a true black, which reads as digital.
let inkBlack: Ink = (0.129, 0.106, 0.086)
let inkSepia: Ink = (0.278, 0.188, 0.129)
let paperBase: Ink = (0.925, 0.886, 0.804)
let paperShade: Ink = (0.855, 0.800, 0.702)
let plateBrass: Ink = (0.549, 0.435, 0.216)

// MARK: - Context

func engCtx(_ w: Int, _ h: Int) -> CGContext {
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                        bytesPerRow: w * 4, space: engSpace,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high
    ctx.setLineCap(.round)
    return ctx
}

func engSave(_ ctx: CGContext, _ dir: String, _ name: String) {
    guard let image = ctx.makeImage() else { return }
    let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).png")
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL,
                                                     UTType.png.identifier as CFString, 1, nil)
    else { return }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(name).png")
}

// MARK: - The sheet

/// Lays down aged paper across the whole canvas: base tone, fibre, slow
/// blotching and a scatter of foxing.
func layPaper(_ ctx: CGContext, w: Int, h: Int) {
    let W = CGFloat(w), H = CGFloat(h)
    ctx.setFillColor(engColor(paperBase, 1))
    ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))

    // Slow, large-scale unevenness in the sheet.
    for _ in 0..<70 {
        let r = eRnd(W * 0.10, W * 0.36)
        let x = eRnd(-r * 0.4, W + r * 0.4)
        let y = eRnd(-r * 0.4, H + r * 0.4)
        let a = eRnd(0.012, 0.045)
        let warm = eRnd() > 0.45
        let c: Ink = warm ? (0.812, 0.741, 0.612) : (0.976, 0.949, 0.886)
        if let g = CGGradient(colorsSpace: engSpace,
                              colors: [engColor(c, a), engColor(c, 0)] as CFArray,
                              locations: [0, 1]) {
            ctx.drawRadialGradient(g, startCenter: CGPoint(x: x, y: y), startRadius: 0,
                                   endCenter: CGPoint(x: x, y: y), endRadius: r, options: [])
        }
    }

    // Paper fibre. Kept sparse: at the sizes these plates are actually shown
    // the density is invisible, but it dominates the PNG's weight.
    for _ in 0..<(w * h / 70) {
        let x = eRnd(0, W), y = eRnd(0, H)
        let len = eRnd(1.6, 6.5)
        let ang = eRnd(0, 6.283)
        let dark = eRnd() > 0.5
        ctx.setStrokeColor(engColor(dark ? (0.663, 0.612, 0.518) : (0.980, 0.965, 0.918),
                                    eRnd(0.05, 0.22)))
        ctx.setLineWidth(eRnd(0.5, 1.1))
        ctx.beginPath()
        ctx.move(to: CGPoint(x: x, y: y))
        ctx.addLine(to: CGPoint(x: x + cos(ang) * len, y: y + sin(ang) * len))
        ctx.strokePath()
    }

    // Foxing — the small rust blooms old paper picks up.
    for _ in 0..<46 {
        let x = eRnd(0, W), y = eRnd(0, H)
        let r = eRnd(2.5, 13)
        let a = eRnd(0.05, 0.20)
        if let g = CGGradient(colorsSpace: engSpace,
                              colors: [engColor((0.573, 0.408, 0.239), a),
                                       engColor((0.573, 0.408, 0.239), 0)] as CFArray,
                              locations: [0, 1]) {
            ctx.drawRadialGradient(g, startCenter: CGPoint(x: x, y: y), startRadius: 0,
                                   endCenter: CGPoint(x: x, y: y), endRadius: r, options: [])
        }
    }
}

/// The impression a copper plate presses into damp paper: a bevelled rectangle
/// with a slightly brighter band just inside it. The strongest single cue that
/// the image is a real print.
func plateMark(_ ctx: CGContext, _ rect: CGRect) {
    // Lighter band inside the impression, where the paper was stretched.
    ctx.setStrokeColor(engColor((1.0, 0.988, 0.949), 0.55))
    ctx.setLineWidth(9)
    ctx.stroke(rect.insetBy(dx: 5, dy: 5))

    // The bevel itself: dark on two sides, bright on the others.
    ctx.setStrokeColor(engColor((0.639, 0.576, 0.478), 0.75))
    ctx.setLineWidth(2.4)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: rect.minX, y: rect.minY))
    ctx.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    ctx.strokePath()
    ctx.setStrokeColor(engColor((0.996, 0.980, 0.937), 0.85))
    ctx.beginPath()
    ctx.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
    ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    ctx.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
    ctx.strokePath()

    // A hair of ink wiped along the plate edge, as always happens.
    ctx.setStrokeColor(engColor(inkSepia, 0.16))
    ctx.setLineWidth(1.4)
    ctx.stroke(rect.insetBy(dx: -1.5, dy: -1.5))
}

// MARK: - Tone

/// How many hatch passes and how tight to space them for a target darkness.
private func passesFor(_ tone: CGFloat) -> (passes: Int, spacing: CGFloat, weight: CGFloat, alpha: CGFloat) {
    let t = max(0, min(1, tone))
    switch t {
    case ..<0.10: return (0, 99, 0, 0)
    case ..<0.26: return (1, 11.0 - t * 12, 0.85, 0.55)
    case ..<0.44: return (1, 8.2 - t * 8, 1.00, 0.72)
    case ..<0.60: return (2, 7.4 - t * 5, 1.05, 0.76)
    case ..<0.76: return (3, 6.4 - t * 3.4, 1.15, 0.80)
    case ..<0.90: return (3, 4.4 - t * 2.0, 1.35, 0.88)
    default:      return (4, 3.4 - t * 1.4, 1.55, 0.94)
    }
}

/// Straight burin hatching over a clipped region, at a target tone.
func hatch(_ ctx: CGContext, clip: CGPath, tone: CGFloat, baseAngle: CGFloat = 0.62,
           ink: Ink = inkBlack, wobble: CGFloat = 1.0, phase: CGPoint? = nil) {
    let p = passesFor(tone)
    guard p.passes > 0 else { return }
    let box = clip.boundingBox
    guard box.width > 0.5, box.height > 0.5 else { return }
    let angles: [CGFloat] = [baseAngle, baseAngle + 1.14, baseAngle - 0.72, baseAngle + 1.92]

    ctx.saveGState()
    ctx.addPath(clip)
    ctx.clip()
    // Lines are laid out from a shared origin so that neighbouring or nested
    // clips stay in step instead of beating against each other.
    let origin = phase ?? CGPoint(x: box.midX, y: box.midY)
    let span = sqrt(box.width * box.width + box.height * box.height)
        + hypot(origin.x - box.midX, origin.y - box.midY) * 2
    let cx = origin.x, cy = origin.y
    for pass in 0..<p.passes {
        let a = angles[pass % angles.count]
        let dx = cos(a), dy = sin(a)
        let nx = -dy, ny = dx
        let spacing = p.spacing * (pass == 0 ? 1.0 : 1.18)
        ctx.setStrokeColor(engColor(ink, p.alpha * (pass == 0 ? 1.0 : 0.82)))
        var off = -span / 2
        while off < span / 2 {
            let ox = cx + nx * off, oy = cy + ny * off
            ctx.setLineWidth(p.weight * eRnd(0.82, 1.18))
            ctx.beginPath()
            // Burin lines are never perfectly straight; a slow drift sells it.
            let steps = 9
            for s in 0...steps {
                let f = CGFloat(s) / CGFloat(steps) - 0.5
                let drift = sin(f * 3.1 + off * 0.05) * wobble
                let px = ox + dx * span * f + nx * drift
                let py = oy + dy * span * f + ny * drift
                if s == 0 { ctx.move(to: CGPoint(x: px, y: py)) }
                else { ctx.addLine(to: CGPoint(x: px, y: py)) }
            }
            ctx.strokePath()
            off += spacing
        }
    }
    ctx.restoreGState()
}

/// Hatching whose tone ramps across the region — for walls, skies and floors.
func hatchRamp(_ ctx: CGContext, clip: CGPath, from: CGFloat, to: CGFloat,
               vertical: Bool = true, baseAngle: CGFloat = 0.62, ink: Ink = inkBlack) {
    let box = clip.boundingBox
    let bands = 16
    for i in 0..<bands {
        let f = CGFloat(i) / CGFloat(bands - 1)
        let tone = from + (to - from) * f
        let band: CGRect
        if vertical {
            let bh = box.height / CGFloat(bands)
            band = CGRect(x: box.minX, y: box.minY + CGFloat(i) * bh, width: box.width, height: bh + 1)
        } else {
            let bw = box.width / CGFloat(bands)
            band = CGRect(x: box.minX + CGFloat(i) * bw, y: box.minY, width: bw + 1, height: box.height)
        }
        let piece = CGMutablePath()
        piece.addRect(band)
        ctx.saveGState()
        ctx.addPath(clip)
        ctx.clip()
        hatch(ctx, clip: piece, tone: tone, baseAngle: baseAngle, ink: ink)
        ctx.restoreGState()
    }
}

/// Dot shading. Used where line work would look mechanical: smoke, glow, sky.
func stipple(_ ctx: CGContext, clip: CGPath, tone: CGFloat, ink: Ink = inkBlack,
             sizeRange: (CGFloat, CGFloat) = (0.7, 2.0)) {
    guard tone > 0.02 else { return }
    let box = clip.boundingBox
    let count = Int(box.width * box.height * tone / 26)
    guard count > 0 else { return }
    ctx.saveGState()
    ctx.addPath(clip)
    ctx.clip()
    for _ in 0..<count {
        let x = eRnd(box.minX, box.maxX)
        let y = eRnd(box.minY, box.maxY)
        let r = eRnd(sizeRange.0, sizeRange.1)
        ctx.setFillColor(engColor(ink, eRnd(0.35, 0.85)))
        ctx.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r))
    }
    ctx.restoreGState()
}

/// A contour line that thickens on the shaded side, the way a burin cut does.
func taperedOutline(_ ctx: CGContext, _ pts: [CGPoint], weight: CGFloat = 2.0,
                    lightAngle: CGFloat = 2.4, ink: Ink = inkBlack, closed: Bool = true) {
    guard pts.count > 2 else { return }
    let n = pts.count
    let last = closed ? n : n - 1
    for i in 0..<last {
        let a = pts[i], b = pts[(i + 1) % n]
        var dx = b.x - a.x, dy = b.y - a.y
        let len = max(0.0001, sqrt(dx * dx + dy * dy))
        dx /= len; dy /= len
        // Outward normal versus the light direction decides the weight.
        let nx = -dy, ny = dx
        let facing = nx * cos(lightAngle) + ny * sin(lightAngle)
        let w = weight * (0.45 + 0.95 * max(0, -facing))
        ctx.setStrokeColor(engColor(ink, 0.90))
        ctx.setLineWidth(max(0.5, w))
        ctx.beginPath()
        ctx.move(to: a)
        ctx.addLine(to: b)
        ctx.strokePath()
    }
}

// MARK: - Round forms

/// Engraves a cylindrical body — a bar, a handle, a horn.
///
/// Lines run **along** the axis, and their weight varies across the section:
/// nothing at all where the light strikes, thickening steadily into the far
/// shadow. That blank highlight band is what makes the section read as round.
///
/// `spine` is the centreline, `half` the half-thickness at each point.
func engraveCylinder(_ ctx: CGContext, spine: [CGPoint], half: [CGFloat],
                     tone: CGFloat = 0.62, lightFrom: CGFloat = -0.42,
                     ink: Ink = inkBlack, lines: Int = 26) {
    guard spine.count > 1, spine.count == half.count else { return }

    // Per-point normals, computed once.
    var normals: [CGPoint] = []
    for i in 0..<spine.count {
        let a = spine[max(0, i - 1)], b = spine[min(spine.count - 1, i + 1)]
        var dx = b.x - a.x, dy = b.y - a.y
        let l = max(0.0001, sqrt(dx * dx + dy * dy))
        dx /= l; dy /= l
        normals.append(CGPoint(x: -dy, y: dx))
    }

    for k in 0..<lines {
        let u = -1 + 2 * CGFloat(k) / CGFloat(lines - 1)
        let d = u - lightFrom
        // Darkness across a lit cylinder, deepest at the far rim.
        var shade = abs(d) / (d < 0 ? (1 + lightFrom) : (1 - lightFrom))
        shade = pow(min(1, shade), 1.5)
        if d < 0 { shade *= 0.45 }               // the near rim only half-turns away
        let w = tone * shade * 2.3
        guard w > 0.22 else { continue }         // leaves the highlight as bare paper

        ctx.setStrokeColor(engColor(ink, min(0.94, 0.55 + shade * 0.4)))
        ctx.setLineWidth(w)
        ctx.beginPath()
        var started = false
        for i in 0..<spine.count {
            // Lines stop short of the very ends, as a burin lifts off.
            let f = CGFloat(i) / CGFloat(spine.count - 1)
            let fade = min(1, min(f, 1 - f) * 12)
            guard fade > 0.15 else { started = false; continue }
            let h = half[i] * (0.94 + 0.06 * fade)
            let pt = CGPoint(x: spine[i].x + normals[i].x * u * h,
                             y: spine[i].y + normals[i].y * u * h)
            if !started { ctx.move(to: pt); started = true } else { ctx.addLine(to: pt) }
        }
        ctx.strokePath()
    }

    // The two contour lines that bound the form: light on the lit side, heavy
    // on the shaded one.
    for side in [CGFloat(-1), CGFloat(1)] {
        ctx.beginPath()
        for i in 0..<spine.count {
            let pt = CGPoint(x: spine[i].x + normals[i].x * half[i] * side,
                             y: spine[i].y + normals[i].y * half[i] * side)
            if i == 0 { ctx.move(to: pt) } else { ctx.addLine(to: pt) }
        }
        let lit = side < 0
        ctx.setStrokeColor(engColor(ink, lit ? 0.62 : 0.94))
        ctx.setLineWidth(lit ? 0.9 : 2.1)
        ctx.strokePath()
    }
}

/// Radiating burin lines, for anything that throws light: a fire, a hot bar.
/// Rays vary in length, thin out along their run and leave gaps, so the glow
/// reads as engraved light rather than a drawn star.
func engraveRadiance(_ ctx: CGContext, at c: CGPoint, inner: CGFloat, outer: CGFloat,
                     rays: Int = 96, ink: Ink = inkBlack, bias: CGFloat = 0) {
    for i in 0..<rays {
        let a = CGFloat(i) / CGFloat(rays) * 6.283 + eRnd(-0.03, 0.03)
        // A slow swell around the circle leaves natural gaps.
        let swell = 0.42 + 0.58 * pow(max(0, sin(a * 2.3 + 1.1) * 0.5 + 0.5), 0.7)
        let up = bias > 0 ? (0.55 + 0.45 * max(0, sin(a))) : 1
        let r0 = inner * eRnd(0.92, 1.45)
        let r1 = r0 + (outer - inner) * swell * up * eRnd(0.45, 1.0)
        guard r1 > r0 + 4 else { continue }
        // Each ray is drawn as segments that thin and fade outward.
        let steps = 7
        for s in 0..<steps {
            let f0 = CGFloat(s) / CGFloat(steps)
            let f1 = CGFloat(s + 1) / CGFloat(steps)
            let fade = pow(1 - f0, 1.6)
            guard fade > 0.10 else { break }
            ctx.setStrokeColor(engColor(ink, 0.55 * fade))
            ctx.setLineWidth(0.35 + 1.25 * fade)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: c.x + cos(a) * (r0 + (r1 - r0) * f0),
                                 y: c.y + sin(a) * (r0 + (r1 - r0) * f0)))
            ctx.addLine(to: CGPoint(x: c.x + cos(a) * (r0 + (r1 - r0) * f1),
                                    y: c.y + sin(a) * (r0 + (r1 - r0) * f1)))
            ctx.strokePath()
        }
    }
}

/// A soft corner wash: nested triangles running out from one corner, each a
/// shade lighter, so the tone dies away instead of stopping at an edge.
func cornerWash(_ ctx: CGContext, _ rect: CGRect, corner: Int, tone: CGFloat,
                reach: CGFloat = 0.55, angle: CGFloat = 0.22) {
    let steps = 9
    for i in 0..<steps {
        let f = CGFloat(i) / CGFloat(steps - 1)
        let t = tone * pow(1 - f, 1.5)
        guard t > 0.04 else { continue }
        let w = rect.width * reach * (1 - f * 0.88)
        let h = rect.height * reach * (1 - f * 0.88)
        let cx: CGFloat = (corner == 0 || corner == 3) ? rect.minX : rect.maxX
        let cy: CGFloat = (corner < 2) ? rect.maxY : rect.minY
        let sx: CGFloat = (corner == 0 || corner == 3) ? 1 : -1
        let sy: CGFloat = (corner < 2) ? -1 : 1
        let tri = polyPath([CGPoint(x: cx, y: cy),
                            CGPoint(x: cx + sx * w, y: cy),
                            CGPoint(x: cx, y: cy + sy * h)])
        hatch(ctx, clip: tri, tone: t, baseAngle: angle,
              phase: CGPoint(x: cx, y: cy))
    }
}

/// Resamples a coarse centreline into a smooth one, so a specimen reads as a
/// forged curve rather than a chain of facets.
func smoothSpine(_ pts: [CGPoint], _ half: [CGFloat], factor: Int = 5) -> ([CGPoint], [CGFloat]) {
    guard pts.count > 2, pts.count == half.count else { return (pts, half) }
    var outP: [CGPoint] = []
    var outH: [CGFloat] = []
    for i in 0..<(pts.count - 1) {
        let p0 = pts[max(0, i - 1)], p1 = pts[i], p2 = pts[i + 1]
        let p3 = pts[min(pts.count - 1, i + 2)]
        let h1 = half[i], h2 = half[i + 1]
        for k in 0..<factor {
            let t = CGFloat(k) / CGFloat(factor)
            let t2 = t * t, t3 = t2 * t
            // Catmull-Rom.
            let x = 0.5 * ((2 * p1.x) + (-p0.x + p2.x) * t
                           + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2
                           + (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3)
            let y = 0.5 * ((2 * p1.y) + (-p0.y + p2.y) * t
                           + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2
                           + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3)
            outP.append(CGPoint(x: x, y: y))
            outH.append(h1 + (h2 - h1) * t)
        }
    }
    outP.append(pts[pts.count - 1])
    outH.append(half[half.count - 1])
    return (outP, outH)
}

// MARK: - Sheet furniture

/// Roman numerals, drawn as strokes so the plate can carry a number without
/// shipping a font or any translatable text.
func plateNumeral(_ ctx: CGContext, _ n: Int, at origin: CGPoint, size: CGFloat) {
    let numerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
                    "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX",
                    "XXI", "XXII", "XXIII", "XXIV", "XXV", "XXVI", "XXVII", "XXVIII", "XXIX", "XXX"]
    let s = numerals[max(0, min(numerals.count - 1, n - 1))]
    var x = origin.x
    let h = size
    let w = size * 0.42
    ctx.setStrokeColor(engColor(inkBlack, 0.72))
    ctx.setLineWidth(max(1.0, size * 0.07))
    for ch in s {
        switch ch {
        case "I":
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x + w * 0.5, y: origin.y))
            ctx.addLine(to: CGPoint(x: x + w * 0.5, y: origin.y + h))
            ctx.strokePath()
            // serifs
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x + w * 0.18, y: origin.y))
            ctx.addLine(to: CGPoint(x: x + w * 0.82, y: origin.y))
            ctx.move(to: CGPoint(x: x + w * 0.18, y: origin.y + h))
            ctx.addLine(to: CGPoint(x: x + w * 0.82, y: origin.y + h))
            ctx.strokePath()
            x += w
        case "V":
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x, y: origin.y + h))
            ctx.addLine(to: CGPoint(x: x + w * 0.75, y: origin.y))
            ctx.addLine(to: CGPoint(x: x + w * 1.5, y: origin.y + h))
            ctx.strokePath()
            x += w * 1.7
        case "X":
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x, y: origin.y))
            ctx.addLine(to: CGPoint(x: x + w * 1.4, y: origin.y + h))
            ctx.move(to: CGPoint(x: x + w * 1.4, y: origin.y))
            ctx.addLine(to: CGPoint(x: x, y: origin.y + h))
            ctx.strokePath()
            x += w * 1.6
        default: break
        }
        x += w * 0.22
    }
}

/// The engraved rule that separates a plate from its caption area.
func captionRule(_ ctx: CGContext, from a: CGPoint, to b: CGPoint) {
    ctx.setStrokeColor(engColor(inkBlack, 0.55))
    ctx.setLineWidth(1.6)
    ctx.beginPath(); ctx.move(to: a); ctx.addLine(to: b); ctx.strokePath()
    ctx.setLineWidth(0.7)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: a.x, y: a.y - 4))
    ctx.addLine(to: CGPoint(x: b.x, y: b.y - 4))
    ctx.strokePath()
    // A small lozenge at the centre, as printers used.
    let m = CGPoint(x: (a.x + b.x) / 2, y: a.y - 2)
    ctx.setFillColor(engColor(inkBlack, 0.6))
    ctx.beginPath()
    ctx.move(to: CGPoint(x: m.x, y: m.y + 5))
    ctx.addLine(to: CGPoint(x: m.x + 5, y: m.y))
    ctx.addLine(to: CGPoint(x: m.x, y: m.y - 5))
    ctx.addLine(to: CGPoint(x: m.x - 5, y: m.y))
    ctx.closePath()
    ctx.fillPath()
}

// MARK: - Path helpers

func rectPath(_ r: CGRect) -> CGPath {
    let p = CGMutablePath(); p.addRect(r); return p
}

func ellipsePath(_ r: CGRect) -> CGPath {
    let p = CGMutablePath(); p.addEllipse(in: r); return p
}

func polyPath(_ pts: [CGPoint]) -> CGPath {
    let p = CGMutablePath()
    guard let f = pts.first else { return p }
    p.move(to: f)
    for q in pts.dropFirst() { p.addLine(to: q) }
    p.closeSubpath()
    return p
}
