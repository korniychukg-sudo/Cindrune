import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Generates every illustration bundled with Ember Forge.
// Usage: artgen <output-directory>

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let space = CGColorSpaceCreateDeviceRGB()

// MARK: - Deterministic RNG

var seedState: UInt64 = 0x9E3779B97F4A7C15

func seed(_ v: UInt64) { seedState = v &* 0x2545F4914F6CDD1D &+ 0x9E3779B97F4A7C15 }

@discardableResult
func nextRand() -> UInt64 {
    seedState ^= seedState << 13
    seedState ^= seedState >> 7
    seedState ^= seedState << 17
    return seedState
}

func rnd() -> CGFloat { CGFloat(nextRand() % 1_000_000) / 1_000_000.0 }
func rnd(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * rnd() }
func rndInt(_ a: Int, _ b: Int) -> Int { a + Int(nextRand() % UInt64(max(1, b - a + 1))) }

// MARK: - Context helpers

typealias RGB = (CGFloat, CGFloat, CGFloat)

func makeCtx(_ w: Int, _ h: Int) -> CGContext {
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                        bytesPerRow: w * 4, space: space,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high
    return ctx
}

func save(_ ctx: CGContext, _ name: String) {
    guard let image = ctx.makeImage() else { return }
    let url = URL(fileURLWithPath: outDir).appendingPathComponent("\(name).png")
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL,
                                                     UTType.png.identifier as CFString, 1, nil)
    else { return }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(name).png")
}

func col(_ c: RGB, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [c.0, c.1, c.2, a])!
}

func fill(_ ctx: CGContext, _ c: RGB, _ a: CGFloat = 1) { ctx.setFillColor(col(c, a)) }
func line(_ ctx: CGContext, _ c: RGB, _ a: CGFloat = 1) { ctx.setStrokeColor(col(c, a)) }

// MARK: - Palette (matches ForgeTheme)

let cNight: RGB = (0.075, 0.063, 0.059)
let cSoot: RGB = (0.118, 0.098, 0.090)
let cStone: RGB = (0.169, 0.145, 0.133)
let cSlate: RGB = (0.259, 0.224, 0.200)
let cIron: RGB = (0.361, 0.337, 0.318)
let cSteel: RGB = (0.541, 0.529, 0.510)
let cPolish: RGB = (0.741, 0.741, 0.729)
let cEmberDeep: RGB = (0.541, 0.161, 0.055)
let cEmber: RGB = (0.831, 0.325, 0.078)
let cFlame: RGB = (0.949, 0.518, 0.129)
let cSpark: RGB = (0.996, 0.784, 0.361)
let cWhiteHot: RGB = (1.000, 0.949, 0.816)
let cBrass: RGB = (0.788, 0.635, 0.310)
let cBrassDim: RGB = (0.518, 0.412, 0.196)
let cQuench: RGB = (0.322, 0.494, 0.541)
let cWood: RGB = (0.239, 0.169, 0.110)
let cWoodDark: RGB = (0.160, 0.113, 0.074)
let cChalk: RGB = (0.918, 0.886, 0.831)
let cTemperStraw: RGB = (0.851, 0.729, 0.416)
let cTemperBronze: RGB = (0.714, 0.478, 0.259)
let cTemperPurple: RGB = (0.514, 0.404, 0.573)
let cTemperBlue: RGB = (0.310, 0.404, 0.596)

func heatColor(_ t: CGFloat) -> RGB {
    func mix(_ a: RGB, _ b: RGB, _ f: CGFloat) -> RGB {
        let f = max(0, min(1, f))
        return (a.0 + (b.0 - a.0) * f, a.1 + (b.1 - a.1) * f, a.2 + (b.2 - a.2) * f)
    }
    switch t {
    case ..<480: return mix((0.290, 0.278, 0.267), (0.404, 0.310, 0.271), (t - 20) / 460)
    case ..<650: return mix((0.404, 0.310, 0.271), (0.518, 0.129, 0.078), (t - 480) / 170)
    case ..<800: return mix((0.518, 0.129, 0.078), (0.741, 0.204, 0.078), (t - 650) / 150)
    case ..<950: return mix((0.741, 0.204, 0.078), (0.910, 0.400, 0.098), (t - 800) / 150)
    case ..<1150: return mix((0.910, 0.400, 0.098), (0.988, 0.663, 0.208), (t - 950) / 200)
    case ..<1320: return mix((0.988, 0.663, 0.208), (1.000, 0.898, 0.596), (t - 1150) / 170)
    default: return mix((1.000, 0.898, 0.596), (1.000, 1.000, 0.949), min(1, (t - 1320) / 180))
    }
}

// MARK: - Shared painting

func gradientFill(_ ctx: CGContext, rect: CGRect, colors: [(RGB, CGFloat)], locations: [CGFloat],
                  vertical: Bool = true) {
    let cgs = colors.map { col($0.0, $0.1) } as CFArray
    guard let g = CGGradient(colorsSpace: space, colors: cgs, locations: locations) else { return }
    ctx.saveGState()
    ctx.addRect(rect); ctx.clip()
    if vertical {
        ctx.drawLinearGradient(g, start: CGPoint(x: rect.midX, y: rect.maxY),
                               end: CGPoint(x: rect.midX, y: rect.minY), options: [])
    } else {
        ctx.drawLinearGradient(g, start: CGPoint(x: rect.minX, y: rect.midY),
                               end: CGPoint(x: rect.maxX, y: rect.midY), options: [])
    }
    ctx.restoreGState()
}

func glow(_ ctx: CGContext, at p: CGPoint, radius: CGFloat, colors: [(RGB, CGFloat)],
          locations: [CGFloat]) {
    let cgs = colors.map { col($0.0, $0.1) } as CFArray
    guard let g = CGGradient(colorsSpace: space, colors: cgs, locations: locations) else { return }
    ctx.drawRadialGradient(g, startCenter: p, startRadius: 0,
                           endCenter: p, endRadius: radius, options: [])
}

/// Warm soot grain over the whole frame. Also what gives the PNGs their weight.
func grain(_ ctx: CGContext, w: Int, h: Int, amount: CGFloat = 0.055, step: Int = 1) {
    for y in stride(from: 0, to: h, by: step) {
        for x in stride(from: 0, to: w, by: step) {
            let n = rnd()
            guard n > 0.42 else { continue }
            let a = (n - 0.42) / 0.58 * amount
            let warm = rnd() > 0.55
            fill(ctx, warm ? (0.62, 0.45, 0.28) : (0.05, 0.04, 0.04), a)
            ctx.fill(CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(step), height: CGFloat(step)))
        }
    }
}

func vignette(_ ctx: CGContext, w: Int, h: Int, strength: CGFloat = 0.62) {
    let cgs = [col((0, 0, 0), 0), col((0, 0, 0), strength)] as CFArray
    guard let g = CGGradient(colorsSpace: space, colors: cgs, locations: [0.35, 1]) else { return }
    ctx.drawRadialGradient(g,
                           startCenter: CGPoint(x: CGFloat(w) / 2, y: CGFloat(h) / 2),
                           startRadius: CGFloat(min(w, h)) * 0.22,
                           endCenter: CGPoint(x: CGFloat(w) / 2, y: CGFloat(h) / 2),
                           endRadius: CGFloat(max(w, h)) * 0.72, options: [])
}

func plankWall(_ ctx: CGContext, rect: CGRect, rows: Int = 9) {
    gradientFill(ctx, rect: rect,
                 colors: [(cSoot, 1), (cNight, 1)], locations: [0, 1])
    let hgt = rect.height / CGFloat(rows)
    for i in 0...rows {
        let y = rect.minY + CGFloat(i) * hgt
        fill(ctx, (0, 0, 0), 0.28)
        ctx.fill(CGRect(x: rect.minX, y: y, width: rect.width, height: 2))
        fill(ctx, (0.30, 0.24, 0.19), 0.10)
        ctx.fill(CGRect(x: rect.minX, y: y + 2, width: rect.width, height: 2))
        // Grain streaks.
        for _ in 0..<14 {
            let sx = rnd(rect.minX, rect.maxX)
            let sw = rnd(30, 190)
            fill(ctx, (0, 0, 0), rnd(0.04, 0.11))
            ctx.fill(CGRect(x: sx, y: y + rnd(4, hgt - 6), width: sw, height: rnd(1, 2.6)))
        }
    }
}

func brickField(_ ctx: CGContext, rect: CGRect, cols: Int, rows: Int) {
    fill(ctx, (0.20, 0.145, 0.115))
    ctx.fill(rect)
    let bw = rect.width / CGFloat(cols)
    let bh = rect.height / CGFloat(rows)
    for r in 0..<rows {
        for c in 0..<(cols + 1) {
            let offset: CGFloat = r % 2 == 0 ? 0 : -bw / 2
            let x = rect.minX + CGFloat(c) * bw + offset
            let y = rect.minY + CGFloat(r) * bh
            let b = CGRect(x: x + 2, y: y + 2, width: bw - 4, height: bh - 4)
                .intersection(rect)
            guard !b.isNull, b.width > 2 else { continue }
            let v = rnd(-0.03, 0.04)
            fill(ctx, (0.28 + v, 0.20 + v, 0.155 + v))
            ctx.fill(b)
            fill(ctx, (0, 0, 0), 0.14)
            ctx.fill(CGRect(x: b.minX, y: b.minY, width: b.width, height: 2))
        }
    }
}

/// The bar of steel, drawn hot, following a simple taper.
func hotBar(_ ctx: CGContext, from a: CGPoint, to b: CGPoint,
            thickA: CGFloat, thickB: CGFloat, tempA: CGFloat, tempB: CGFloat,
            glowScale: CGFloat = 1.0) {
    let steps = 40
    // Halo first.
    for k in stride(from: 3, through: 1, by: -1) {
        let spread = CGFloat(k) * 9 * glowScale
        for i in 0..<steps {
            let f = CGFloat(i) / CGFloat(steps - 1)
            let p = CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f)
            let th = thickA + (thickB - thickA) * f
            let t = tempA + (tempB - tempA) * f
            guard t > 480 else { continue }
            let c = heatColor(t)
            fill(ctx, c, 0.055 * (4 - CGFloat(k)) / 3)
            ctx.fillEllipse(in: CGRect(x: p.x - th / 2 - spread, y: p.y - th / 2 - spread,
                                       width: th + spread * 2, height: th + spread * 2))
        }
    }
    // Body.
    for i in 0..<steps {
        let f = CGFloat(i) / CGFloat(steps - 1)
        let p = CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f)
        let th = max(1.5, thickA + (thickB - thickA) * f)
        let t = tempA + (tempB - tempA) * f
        fill(ctx, heatColor(t))
        ctx.fill(CGRect(x: p.x - th / 2, y: p.y - th / 2, width: th * 1.4, height: th))
    }
}

func sparkBurst(_ ctx: CGContext, at p: CGPoint, count: Int, spread: CGFloat, up: Bool = true) {
    for _ in 0..<count {
        let a = up ? rnd(0.15, 2.99) : rnd(0, 6.28)
        let d = rnd(spread * 0.15, spread)
        let e = CGPoint(x: p.x + cos(a) * d, y: p.y + sin(a) * d * (up ? 1 : 0.6))
        let len = rnd(4, 22)
        line(ctx, cSpark, rnd(0.30, 0.95))
        ctx.setLineWidth(rnd(0.8, 2.4))
        ctx.beginPath()
        ctx.move(to: e)
        ctx.addLine(to: CGPoint(x: e.x + cos(a) * len * 0.4, y: e.y + sin(a) * len))
        ctx.strokePath()
        fill(ctx, cWhiteHot, rnd(0.4, 0.95))
        let r = rnd(1, 3.2)
        ctx.fillEllipse(in: CGRect(x: e.x - r, y: e.y - r, width: r * 2, height: r * 2))
    }
}

func anvilSilhouette(_ ctx: CGContext, rect: CGRect, faceHighlight: CGFloat = 0.4) {
    let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
    ctx.beginPath()
    ctx.move(to: CGPoint(x: x, y: y + h * 0.72))
    ctx.addLine(to: CGPoint(x: x + w * 0.66, y: y + h * 0.72))
    ctx.addQuadCurve(to: CGPoint(x: x + w * 1.0, y: y + h * 0.60),
                     control: CGPoint(x: x + w * 0.94, y: y + h * 0.74))
    ctx.addQuadCurve(to: CGPoint(x: x + w * 0.64, y: y + h * 0.52),
                     control: CGPoint(x: x + w * 0.90, y: y + h * 0.50))
    ctx.addLine(to: CGPoint(x: x + w * 0.56, y: y + h * 0.52))
    ctx.addLine(to: CGPoint(x: x + w * 0.50, y: y + h * 0.24))
    ctx.addLine(to: CGPoint(x: x + w * 0.64, y: y))
    ctx.addLine(to: CGPoint(x: x + w * 0.14, y: y))
    ctx.addLine(to: CGPoint(x: x + w * 0.28, y: y + h * 0.24))
    ctx.addLine(to: CGPoint(x: x + w * 0.22, y: y + h * 0.52))
    ctx.addLine(to: CGPoint(x: x, y: y + h * 0.52))
    ctx.closePath()
    ctx.saveGState()
    ctx.clip()
    gradientFill(ctx, rect: rect, colors: [((0.09, 0.085, 0.082), 1), ((0.27, 0.26, 0.25), 1)],
                 locations: [0, 1])
    ctx.restoreGState()
    fill(ctx, cSpark, faceHighlight)
    ctx.fill(CGRect(x: x, y: y + h * 0.70, width: w * 0.66, height: h * 0.022))
}

func hammerHead(_ ctx: CGContext, rect: CGRect, peen: Bool) {
    ctx.saveGState()
    ctx.beginPath()
    if peen {
        ctx.move(to: CGPoint(x: rect.minX, y: rect.minY))
        ctx.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.30, y: rect.minY))
        ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        ctx.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.30, y: rect.maxY))
        ctx.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    } else {
        ctx.addRect(rect)
    }
    ctx.closePath()
    ctx.clip()
    gradientFill(ctx, rect: rect, colors: [((0.13, 0.125, 0.12), 1), ((0.40, 0.39, 0.38), 1)],
                 locations: [0, 1])
    ctx.restoreGState()
    // Eye.
    fill(ctx, cNight, 0.9)
    ctx.fill(CGRect(x: rect.minX + rect.width * 0.33, y: rect.minY + rect.height * 0.28,
                    width: rect.width * 0.16, height: rect.height * 0.44))
}

func woodHandle(_ ctx: CGContext, from a: CGPoint, to b: CGPoint, width: CGFloat) {
    line(ctx, cWood)
    ctx.setLineWidth(width)
    ctx.setLineCap(.round)
    ctx.beginPath(); ctx.move(to: a); ctx.addLine(to: b); ctx.strokePath()
    line(ctx, (0.34, 0.25, 0.16), 0.7)
    ctx.setLineWidth(width * 0.32)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: a.x - width * 0.18, y: a.y))
    ctx.addLine(to: CGPoint(x: b.x - width * 0.18, y: b.y))
    ctx.strokePath()
    ctx.setLineCap(.butt)
}

func tongs(_ ctx: CGContext, jaw: CGPoint, tail: CGPoint, open: CGFloat) {
    line(ctx, cIron)
    ctx.setLineWidth(9)
    ctx.setLineCap(.round)
    for s in [-1.0, 1.0] as [CGFloat] {
        ctx.beginPath()
        ctx.move(to: CGPoint(x: jaw.x, y: jaw.y + s * open))
        ctx.addQuadCurve(to: tail,
                         control: CGPoint(x: (jaw.x + tail.x) / 2, y: (jaw.y + tail.y) / 2 + s * open * 2.4))
        ctx.strokePath()
    }
    ctx.setLineCap(.butt)
    fill(ctx, cSlate)
    ctx.fillEllipse(in: CGRect(x: jaw.x + (tail.x - jaw.x) * 0.22 - 7,
                               y: jaw.y + (tail.y - jaw.y) * 0.22 - 7, width: 14, height: 14))
}

/// Text is avoided in illustrations (localisation), so labels are drawn as
/// small brass tick marks with leader lines instead.
func leader(_ ctx: CGContext, from a: CGPoint, to b: CGPoint) {
    line(ctx, cBrass, 0.7)
    ctx.setLineWidth(2)
    ctx.beginPath(); ctx.move(to: a); ctx.addLine(to: b); ctx.strokePath()
    fill(ctx, cBrass, 0.85)
    ctx.fillEllipse(in: CGRect(x: b.x - 5, y: b.y - 5, width: 10, height: 10))
}

// MARK: - Scene scaffolding

let W = 1800
let H = 1150

/// Common backdrop: plank wall, floor, forge glow from the right.
func shopBackdrop(_ ctx: CGContext, glowAt: CGPoint? = nil, glowStrength: CGFloat = 0.55) {
    let rect = CGRect(x: 0, y: 0, width: CGFloat(W), height: CGFloat(H))
    plankWall(ctx, rect: rect, rows: 10)
    // Floor.
    let floor = CGRect(x: 0, y: 0, width: CGFloat(W), height: CGFloat(H) * 0.24)
    gradientFill(ctx, rect: floor, colors: [((0.055, 0.045, 0.040), 1), ((0.135, 0.112, 0.098), 1)],
                 locations: [0, 1])
    for _ in 0..<160 {
        fill(ctx, (0, 0, 0), rnd(0.10, 0.32))
        ctx.fillEllipse(in: CGRect(x: rnd(0, CGFloat(W)), y: rnd(0, floor.height),
                                   width: rnd(2, 7), height: rnd(1.5, 4)))
    }
    if let p = glowAt {
        glow(ctx, at: p, radius: CGFloat(W) * 0.55,
             colors: [(cFlame, 0.34 * glowStrength), (cEmberDeep, 0.16 * glowStrength), (cNight, 0)],
             locations: [0, 0.42, 1])
    }
}

func finish(_ ctx: CGContext, grainAmount: CGFloat = 0.05) {
    vignette(ctx, w: W, h: H)
    grain(ctx, w: W, h: H, amount: grainAmount)
}

// MARK: - Guide illustrations

func guideHeat() {
    seed(101)
    let ctx = makeCtx(W, H)
    shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.22, y: CGFloat(H) * 0.42), glowStrength: 0.7)

    // A vertical ladder of heat swatches on the right.
    let swatches: [CGFloat] = [580, 720, 850, 980, 1120, 1280, 1420]
    for (i, t) in swatches.enumerated() {
        let y = CGFloat(H) * 0.14 + CGFloat(i) * CGFloat(H) * 0.105
        let r = CGRect(x: CGFloat(W) * 0.64, y: y, width: CGFloat(W) * 0.24, height: CGFloat(H) * 0.072)
        glow(ctx, at: CGPoint(x: r.midX, y: r.midY), radius: r.width * 0.75,
             colors: [(heatColor(t), 0.30), (cNight, 0)], locations: [0, 1])
        fill(ctx, heatColor(t))
        ctx.fill(r)
        line(ctx, cNight, 0.6); ctx.setLineWidth(3); ctx.stroke(r)
        leader(ctx, from: CGPoint(x: r.minX - 46, y: r.midY), to: CGPoint(x: r.minX - 12, y: r.midY))
    }

    // A bar held in tongs, glowing yellow at the tip.
    let jaw = CGPoint(x: CGFloat(W) * 0.30, y: CGFloat(H) * 0.46)
    hotBar(ctx, from: jaw, to: CGPoint(x: CGFloat(W) * 0.56, y: CGFloat(H) * 0.50),
           thickA: 34, thickB: 26, tempA: 900, tempB: 1330, glowScale: 1.5)
    tongs(ctx, jaw: jaw, tail: CGPoint(x: CGFloat(W) * 0.06, y: CGFloat(H) * 0.34), open: 17)
    sparkBurst(ctx, at: CGPoint(x: CGFloat(W) * 0.55, y: CGFloat(H) * 0.50), count: 26, spread: 130)

    finish(ctx)
    save(ctx, "guide_heat")
}

func guideCarbon() {
    seed(202)
    let ctx = makeCtx(W, H)
    shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.85, y: CGFloat(H) * 0.30), glowStrength: 0.4)

    // Three bar ends in section, with carbon shown as speckle density.
    let densities = [40, 200, 520]
    for (i, d) in densities.enumerated() {
        let cx = CGFloat(W) * (0.22 + CGFloat(i) * 0.28)
        let r = CGRect(x: cx - 165, y: CGFloat(H) * 0.30, width: 330, height: CGFloat(H) * 0.34)
        // Bar block.
        gradientFill(ctx, rect: r, colors: [((0.22, 0.215, 0.21), 1), ((0.47, 0.465, 0.455), 1)],
                     locations: [0, 1])
        line(ctx, cNight, 0.8); ctx.setLineWidth(4); ctx.stroke(r)
        // Cut face.
        let face = CGRect(x: r.minX, y: r.maxY - 6, width: r.width, height: 76)
        fill(ctx, (0.62, 0.615, 0.605))
        ctx.fill(face)
        for _ in 0..<d {
            fill(ctx, (0.10, 0.10, 0.10), rnd(0.30, 0.85))
            let s = rnd(2, 6)
            ctx.fillEllipse(in: CGRect(x: rnd(face.minX + 6, face.maxX - 10),
                                       y: rnd(face.minY + 6, face.maxY - 10),
                                       width: s, height: s))
        }
        line(ctx, cNight, 0.7); ctx.setLineWidth(3); ctx.stroke(face)
        // Spark test streaks above each bar.
        for _ in 0..<(8 + i * 16) {
            let a = rnd(0.5, 2.6)
            let len = rnd(60, 240)
            let s = CGPoint(x: cx + rnd(-70, 70), y: face.maxY + rnd(20, 60))
            line(ctx, cSpark, rnd(0.20, 0.7))
            ctx.setLineWidth(rnd(1, 2.4))
            ctx.beginPath(); ctx.move(to: s)
            ctx.addLine(to: CGPoint(x: s.x + cos(a) * len * 0.5, y: s.y + sin(a) * len))
            ctx.strokePath()
        }
    }
    finish(ctx)
    save(ctx, "guide_carbon")
}

func guideDrawing() {
    seed(303)
    let ctx = makeCtx(W, H)
    shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.86, y: CGFloat(H) * 0.36), glowStrength: 0.55)

    // Before: short and fat. After: long and tapered. Drawn as two states.
    hotBar(ctx, from: CGPoint(x: CGFloat(W) * 0.16, y: CGFloat(H) * 0.70),
           to: CGPoint(x: CGFloat(W) * 0.44, y: CGFloat(H) * 0.70),
           thickA: 64, thickB: 62, tempA: 780, tempB: 800, glowScale: 0.8)
    hotBar(ctx, from: CGPoint(x: CGFloat(W) * 0.10, y: CGFloat(H) * 0.36),
           to: CGPoint(x: CGFloat(W) * 0.74, y: CGFloat(H) * 0.34),
           thickA: 58, thickB: 12, tempA: 980, tempB: 1180, glowScale: 1.2)

    // Anvil under the second bar.
    anvilSilhouette(ctx, rect: CGRect(x: CGFloat(W) * 0.30, y: CGFloat(H) * 0.06,
                                      width: CGFloat(W) * 0.36, height: CGFloat(H) * 0.30),
                    faceHighlight: 0.5)

    // Cross peen mid-blow.
    let hx = CGFloat(W) * 0.58, hy = CGFloat(H) * 0.50
    hammerHead(ctx, rect: CGRect(x: hx, y: hy, width: 210, height: 78), peen: true)
    woodHandle(ctx, from: CGPoint(x: hx + 88, y: hy + 78),
               to: CGPoint(x: hx + 30, y: hy + 330), width: 26)
    sparkBurst(ctx, at: CGPoint(x: CGFloat(W) * 0.60, y: CGFloat(H) * 0.38), count: 34, spread: 190)

    // Direction arrows showing metal flowing along the bar.
    for s in [-1.0, 1.0] as [CGFloat] {
        let y = CGFloat(H) * 0.20
        line(ctx, cQuench, 0.75); ctx.setLineWidth(5)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: CGFloat(W) * 0.42, y: y))
        ctx.addLine(to: CGPoint(x: CGFloat(W) * (0.42 + s * 0.16), y: y))
        ctx.strokePath()
        ctx.beginPath()
        ctx.move(to: CGPoint(x: CGFloat(W) * (0.42 + s * 0.16), y: y))
        ctx.addLine(to: CGPoint(x: CGFloat(W) * (0.42 + s * 0.13), y: y + 22))
        ctx.addLine(to: CGPoint(x: CGFloat(W) * (0.42 + s * 0.13), y: y - 22))
        ctx.closePath(); fill(ctx, cQuench, 0.8); ctx.fillPath()
    }
    finish(ctx)
    save(ctx, "guide_drawing")
}

func guideAnvil() {
    seed(404)
    let ctx = makeCtx(W, H)
    shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.88, y: CGFloat(H) * 0.62), glowStrength: 0.4)

    let a = CGRect(x: CGFloat(W) * 0.14, y: CGFloat(H) * 0.24,
                   width: CGFloat(W) * 0.66, height: CGFloat(H) * 0.44)
    // Stump.
    let stump = CGRect(x: a.minX + a.width * 0.18, y: CGFloat(H) * 0.03,
                       width: a.width * 0.34, height: a.height * 0.52)
    gradientFill(ctx, rect: stump, colors: [(cWoodDark, 1), (cWood, 1)], locations: [0, 1])
    for i in 0..<9 {
        fill(ctx, (0, 0, 0), 0.18)
        ctx.fill(CGRect(x: stump.minX + CGFloat(i) * stump.width / 9, y: stump.minY,
                        width: 3, height: stump.height))
    }
    anvilSilhouette(ctx, rect: a, faceHighlight: 0.55)

    // Hardy and pritchel holes on the face.
    fill(ctx, cNight, 0.95)
    ctx.fill(CGRect(x: a.minX + a.width * 0.10, y: a.minY + a.height * 0.60, width: 46, height: 46))
    ctx.fillEllipse(in: CGRect(x: a.minX + a.width * 0.20, y: a.minY + a.height * 0.62,
                               width: 30, height: 30))

    // Leaders to horn, face, table, hardy, pritchel.
    let pts: [(CGPoint, CGPoint)] = [
        (CGPoint(x: a.maxX - 40, y: a.minY + a.height * 0.60), CGPoint(x: CGFloat(W) * 0.90, y: CGFloat(H) * 0.78)),
        (CGPoint(x: a.midX, y: a.minY + a.height * 0.74), CGPoint(x: CGFloat(W) * 0.52, y: CGFloat(H) * 0.90)),
        (CGPoint(x: a.minX + a.width * 0.12, y: a.minY + a.height * 0.63), CGPoint(x: CGFloat(W) * 0.10, y: CGFloat(H) * 0.88)),
        (CGPoint(x: a.minX + a.width * 0.21, y: a.minY + a.height * 0.64), CGPoint(x: CGFloat(W) * 0.24, y: CGFloat(H) * 0.92))
    ]
    for (from, to) in pts { leader(ctx, from: from, to: to) }

    finish(ctx)
    save(ctx, "guide_anvil")
}

func guideHammers() {
    seed(505)
    let ctx = makeCtx(W, H)
    shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.5, y: CGFloat(H) * 0.92), glowStrength: 0.30)

    // A rack rail with five hammers hanging.
    let railY = CGFloat(H) * 0.80
    gradientFill(ctx, rect: CGRect(x: CGFloat(W) * 0.05, y: railY, width: CGFloat(W) * 0.90, height: 26),
                 colors: [(cWoodDark, 1), (cWood, 1)], locations: [0, 1])

    let widths: [CGFloat] = [150, 190, 230, 200, 170]
    for i in 0..<5 {
        let cx = CGFloat(W) * (0.16 + CGFloat(i) * 0.17)
        let hw = widths[i]
        woodHandle(ctx, from: CGPoint(x: cx, y: railY),
                   to: CGPoint(x: cx + rnd(-8, 8), y: railY - CGFloat(H) * 0.34), width: 26)
        let head = CGRect(x: cx - hw / 2, y: railY - CGFloat(H) * 0.40,
                          width: hw, height: 84)
        hammerHead(ctx, rect: head, peen: i % 2 == 1)
        // Firelight on the face.
        fill(ctx, cFlame, 0.16)
        ctx.fill(CGRect(x: head.minX, y: head.minY, width: head.width, height: 8))
    }
    // Sparse embers drifting.
    for _ in 0..<40 {
        fill(ctx, cSpark, rnd(0.10, 0.55))
        let r = rnd(1.5, 4)
        ctx.fillEllipse(in: CGRect(x: rnd(0, CGFloat(W)), y: rnd(0, CGFloat(H) * 0.6),
                                   width: r, height: r))
    }
    finish(ctx)
    save(ctx, "guide_hammers")
}

func guideFuller() {
    seed(606)
    let ctx = makeCtx(W, H)
    shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.5, y: CGFloat(H) * 0.44), glowStrength: 0.75)

    anvilSilhouette(ctx, rect: CGRect(x: CGFloat(W) * 0.10, y: CGFloat(H) * 0.05,
                                      width: CGFloat(W) * 0.72, height: CGFloat(H) * 0.34),
                    faceHighlight: 0.55)
    // Bar with a fullered groove: two thick halves, one thin waist.
    hotBar(ctx, from: CGPoint(x: CGFloat(W) * 0.12, y: CGFloat(H) * 0.40),
           to: CGPoint(x: CGFloat(W) * 0.44, y: CGFloat(H) * 0.40),
           thickA: 56, thickB: 54, tempA: 1080, tempB: 1140, glowScale: 1.2)
    hotBar(ctx, from: CGPoint(x: CGFloat(W) * 0.44, y: CGFloat(H) * 0.40),
           to: CGPoint(x: CGFloat(W) * 0.52, y: CGFloat(H) * 0.40),
           thickA: 54, thickB: 22, tempA: 1140, tempB: 1230, glowScale: 1.6)
    hotBar(ctx, from: CGPoint(x: CGFloat(W) * 0.52, y: CGFloat(H) * 0.40),
           to: CGPoint(x: CGFloat(W) * 0.86, y: CGFloat(H) * 0.40),
           thickA: 22, thickB: 20, tempA: 1180, tempB: 1000, glowScale: 1.0)

    // The fuller: a rounded nose on a stem, sitting in the groove.
    let fx = CGFloat(W) * 0.50
    gradientFill(ctx, rect: CGRect(x: fx - 34, y: CGFloat(H) * 0.46, width: 68, height: CGFloat(H) * 0.26),
                 colors: [((0.16, 0.155, 0.15), 1), ((0.42, 0.41, 0.40), 1)], locations: [0, 1])
    fill(ctx, (0.34, 0.33, 0.32))
    ctx.fillEllipse(in: CGRect(x: fx - 44, y: CGFloat(H) * 0.41, width: 88, height: 62))
    woodHandle(ctx, from: CGPoint(x: fx, y: CGFloat(H) * 0.72),
               to: CGPoint(x: fx + 130, y: CGFloat(H) * 0.94), width: 22)
    sparkBurst(ctx, at: CGPoint(x: fx, y: CGFloat(H) * 0.42), count: 30, spread: 165)

    finish(ctx)
    save(ctx, "guide_fuller")
}

func guidePunching() {
    seed(707)
    let ctx = makeCtx(W, H)
    shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.46, y: CGFloat(H) * 0.42), glowStrength: 0.7)

    anvilSilhouette(ctx, rect: CGRect(x: CGFloat(W) * 0.08, y: CGFloat(H) * 0.04,
                                      width: CGFloat(W) * 0.74, height: CGFloat(H) * 0.34),
                    faceHighlight: 0.5)
    hotBar(ctx, from: CGPoint(x: CGFloat(W) * 0.12, y: CGFloat(H) * 0.40),
           to: CGPoint(x: CGFloat(W) * 0.80, y: CGFloat(H) * 0.40),
           thickA: 60, thickB: 58, tempA: 1240, tempB: 1180, glowScale: 1.5)

    // Punch driven into the bar.
    let px = CGFloat(W) * 0.40
    ctx.saveGState()
    ctx.beginPath()
    ctx.move(to: CGPoint(x: px - 30, y: CGFloat(H) * 0.78))
    ctx.addLine(to: CGPoint(x: px + 30, y: CGFloat(H) * 0.78))
    ctx.addLine(to: CGPoint(x: px + 17, y: CGFloat(H) * 0.42))
    ctx.addLine(to: CGPoint(x: px - 17, y: CGFloat(H) * 0.42))
    ctx.closePath()
    ctx.clip()
    gradientFill(ctx, rect: CGRect(x: px - 32, y: CGFloat(H) * 0.42, width: 64, height: CGFloat(H) * 0.38),
                 colors: [((0.42, 0.41, 0.40), 1), ((0.15, 0.145, 0.14), 1)], locations: [0, 1])
    ctx.restoreGState()
    // Glowing collar where it bites.
    glow(ctx, at: CGPoint(x: px, y: CGFloat(H) * 0.42), radius: 150,
         colors: [(cWhiteHot, 0.55), (cFlame, 0.20), (cNight, 0)], locations: [0, 0.4, 1])

    // A drift lying on the anvil beside it.
    ctx.saveGState()
    ctx.beginPath()
    ctx.move(to: CGPoint(x: CGFloat(W) * 0.58, y: CGFloat(H) * 0.30))
    ctx.addLine(to: CGPoint(x: CGFloat(W) * 0.66, y: CGFloat(H) * 0.34))
    ctx.addLine(to: CGPoint(x: CGFloat(W) * 0.80, y: CGFloat(H) * 0.31))
    ctx.addLine(to: CGPoint(x: CGFloat(W) * 0.80, y: CGFloat(H) * 0.26))
    ctx.addLine(to: CGPoint(x: CGFloat(W) * 0.66, y: CGFloat(H) * 0.23))
    ctx.closePath(); ctx.clip()
    gradientFill(ctx, rect: CGRect(x: CGFloat(W) * 0.56, y: CGFloat(H) * 0.22,
                                   width: CGFloat(W) * 0.26, height: CGFloat(H) * 0.14),
                 colors: [((0.18, 0.175, 0.17), 1), ((0.46, 0.45, 0.44), 1)], locations: [0, 1])
    ctx.restoreGState()

    sparkBurst(ctx, at: CGPoint(x: px, y: CGFloat(H) * 0.44), count: 40, spread: 210)
    finish(ctx)
    save(ctx, "guide_punching")
}

func guideQuench() {
    seed(808)
    let ctx = makeCtx(W, H)
    shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.30, y: CGFloat(H) * 0.70), glowStrength: 0.5)

    // Four tubs.
    let tints: [RGB] = [(0.30, 0.28, 0.26), (0.26, 0.20, 0.11), cQuench, (0.40, 0.55, 0.58)]
    for i in 0..<4 {
        let cx = CGFloat(W) * (0.16 + CGFloat(i) * 0.23)
        let tub = CGRect(x: cx - 150, y: CGFloat(H) * 0.10, width: 300, height: CGFloat(H) * 0.34)
        gradientFill(ctx, rect: tub, colors: [(cWoodDark, 1), (cWood, 1)], locations: [0, 1])
        line(ctx, (0.42, 0.40, 0.38), 0.9); ctx.setLineWidth(9)
        ctx.stroke(CGRect(x: tub.minX, y: tub.minY + tub.height * 0.30, width: tub.width, height: 1))
        ctx.stroke(CGRect(x: tub.minX, y: tub.minY + tub.height * 0.70, width: tub.width, height: 1))
        // Liquid.
        let liq = CGRect(x: tub.minX + 14, y: tub.maxY - 60, width: tub.width - 28, height: 54)
        fill(ctx, tints[i], 0.85)
        ctx.fill(liq)
        fill(ctx, cChalk, 0.10)
        ctx.fillEllipse(in: CGRect(x: liq.minX, y: liq.maxY - 22, width: liq.width, height: 40))
    }

    // A blade going into the third tub, throwing steam.
    let bx = CGFloat(W) * 0.62
    hotBar(ctx, from: CGPoint(x: bx, y: CGFloat(H) * 0.86),
           to: CGPoint(x: bx - 30, y: CGFloat(H) * 0.34),
           thickA: 22, thickB: 44, tempA: 720, tempB: 1150, glowScale: 1.4)
    for _ in 0..<90 {
        fill(ctx, cChalk, rnd(0.03, 0.13))
        let r = rnd(14, 62)
        ctx.fillEllipse(in: CGRect(x: bx + rnd(-140, 140), y: rnd(CGFloat(H) * 0.40, CGFloat(H) * 0.95),
                                   width: r, height: r))
    }
    finish(ctx)
    save(ctx, "guide_quench")
}

func guideTemper() {
    seed(909)
    let ctx = makeCtx(W, H)
    shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.14, y: CGFloat(H) * 0.30), glowStrength: 0.45)

    // A polished blade with the colours running along it.
    let y = CGFloat(H) * 0.56
    let x0 = CGFloat(W) * 0.08, x1 = CGFloat(W) * 0.92
    let steps = 220
    let ramp: [RGB] = [(0.72, 0.71, 0.70), cTemperStraw, cTemperBronze, cTemperPurple, cTemperBlue,
                       (0.50, 0.50, 0.50)]
    for i in 0..<steps {
        let f = CGFloat(i) / CGFloat(steps - 1)
        let seg = f * CGFloat(ramp.count - 1)
        let a = ramp[Int(seg)]
        let b = ramp[min(ramp.count - 1, Int(seg) + 1)]
        let t = seg - CGFloat(Int(seg))
        let c: RGB = (a.0 + (b.0 - a.0) * t, a.1 + (b.1 - a.1) * t, a.2 + (b.2 - a.2) * t)
        let th = 96 - f * 40
        fill(ctx, c)
        ctx.fill(CGRect(x: x0 + (x1 - x0) * f, y: y - th / 2, width: (x1 - x0) / CGFloat(steps) + 2,
                        height: th))
        fill(ctx, cChalk, 0.10)
        ctx.fill(CGRect(x: x0 + (x1 - x0) * f, y: y + th / 2 - 12,
                        width: (x1 - x0) / CGFloat(steps) + 2, height: 10))
    }
    // Swatch chips underneath.
    let chips: [RGB] = [cTemperStraw, cTemperBronze, cTemperPurple, cTemperBlue]
    for (i, c) in chips.enumerated() {
        let r = CGRect(x: CGFloat(W) * (0.16 + CGFloat(i) * 0.19), y: CGFloat(H) * 0.16,
                       width: CGFloat(W) * 0.13, height: CGFloat(H) * 0.11)
        fill(ctx, c); ctx.fill(r)
        line(ctx, cNight, 0.7); ctx.setLineWidth(4); ctx.stroke(r)
        leader(ctx, from: CGPoint(x: r.midX, y: r.maxY + 4),
               to: CGPoint(x: r.midX, y: y - 60))
    }
    finish(ctx)
    save(ctx, "guide_temper")
}

func guideScale() {
    seed(1010)
    let ctx = makeCtx(W, H)
    shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.52, y: CGFloat(H) * 0.50), glowStrength: 0.95)

    // Two bars scarfed and about to be welded, at a white heat.
    hotBar(ctx, from: CGPoint(x: CGFloat(W) * 0.06, y: CGFloat(H) * 0.44),
           to: CGPoint(x: CGFloat(W) * 0.50, y: CGFloat(H) * 0.50),
           thickA: 52, thickB: 30, tempA: 1180, tempB: 1440, glowScale: 2.0)
    hotBar(ctx, from: CGPoint(x: CGFloat(W) * 0.94, y: CGFloat(H) * 0.44),
           to: CGPoint(x: CGFloat(W) * 0.50, y: CGFloat(H) * 0.50),
           thickA: 52, thickB: 30, tempA: 1180, tempB: 1440, glowScale: 2.0)
    glow(ctx, at: CGPoint(x: CGFloat(W) * 0.50, y: CGFloat(H) * 0.50), radius: 460,
         colors: [(cWhiteHot, 0.75), (cSpark, 0.30), (cNight, 0)], locations: [0, 0.35, 1])

    // Flakes of scale falling away.
    for _ in 0..<120 {
        let x = rnd(CGFloat(W) * 0.20, CGFloat(W) * 0.80)
        let yy = rnd(CGFloat(H) * 0.06, CGFloat(H) * 0.44)
        fill(ctx, (0.09, 0.08, 0.075), rnd(0.4, 0.95))
        ctx.saveGState()
        ctx.translateBy(x: x, y: yy)
        ctx.rotate(by: rnd(0, 6.28))
        ctx.fill(CGRect(x: -rnd(6, 18), y: -rnd(3, 8), width: rnd(12, 36), height: rnd(5, 14)))
        ctx.restoreGState()
    }
    sparkBurst(ctx, at: CGPoint(x: CGFloat(W) * 0.50, y: CGFloat(H) * 0.52), count: 70, spread: 380)
    finish(ctx, grainAmount: 0.045)
    save(ctx, "guide_scale")
}

func guideBending() {
    seed(1111)
    let ctx = makeCtx(W, H)
    shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.80, y: CGFloat(H) * 0.30), glowStrength: 0.45)

    anvilSilhouette(ctx, rect: CGRect(x: CGFloat(W) * 0.04, y: CGFloat(H) * 0.08,
                                      width: CGFloat(W) * 0.52, height: CGFloat(H) * 0.40),
                    faceHighlight: 0.5)
    // A bar bent over the anvil edge.
    hotBar(ctx, from: CGPoint(x: CGFloat(W) * 0.12, y: CGFloat(H) * 0.48),
           to: CGPoint(x: CGFloat(W) * 0.53, y: CGFloat(H) * 0.48),
           thickA: 34, thickB: 32, tempA: 900, tempB: 1120, glowScale: 1.1)
    hotBar(ctx, from: CGPoint(x: CGFloat(W) * 0.53, y: CGFloat(H) * 0.48),
           to: CGPoint(x: CGFloat(W) * 0.60, y: CGFloat(H) * 0.14),
           thickA: 32, thickB: 30, tempA: 1120, tempB: 860, glowScale: 1.0)

    // A finished scroll on the right, cooled to grey.
    let cx = CGFloat(W) * 0.79, cy = CGFloat(H) * 0.56
    line(ctx, cSteel, 0.95)
    ctx.setLineCap(.round)
    ctx.beginPath()
    var a: CGFloat = 0
    var r: CGFloat = 250
    ctx.move(to: CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r))
    while r > 16 {
        a += 0.16
        r *= 0.975
        ctx.addLine(to: CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r))
    }
    ctx.setLineWidth(22)
    ctx.strokePath()
    line(ctx, cPolish, 0.35)
    ctx.setLineWidth(6)
    ctx.beginPath()
    a = 0; r = 250
    ctx.move(to: CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r + 6))
    while r > 16 {
        a += 0.16; r *= 0.975
        ctx.addLine(to: CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r + 6))
    }
    ctx.strokePath()
    ctx.setLineCap(.butt)

    finish(ctx)
    save(ctx, "guide_bending")
}

func guideHistory() {
    seed(1212)
    let ctx = makeCtx(W, H)
    // A night sky above a low horizon, with a meteor and a distant forge glow.
    gradientFill(ctx, rect: CGRect(x: 0, y: 0, width: CGFloat(W), height: CGFloat(H)),
                 colors: [((0.055, 0.048, 0.055), 1), ((0.10, 0.09, 0.13), 1), ((0.05, 0.045, 0.06), 1)],
                 locations: [0, 0.55, 1])
    for _ in 0..<420 {
        fill(ctx, cChalk, rnd(0.05, 0.65))
        let r = rnd(1, 3.4)
        ctx.fillEllipse(in: CGRect(x: rnd(0, CGFloat(W)), y: rnd(CGFloat(H) * 0.38, CGFloat(H)),
                                   width: r, height: r))
    }
    // Meteor.
    let m = CGPoint(x: CGFloat(W) * 0.70, y: CGFloat(H) * 0.82)
    glow(ctx, at: m, radius: 320, colors: [(cWhiteHot, 0.55), (cFlame, 0.18), (cNight, 0)],
         locations: [0, 0.4, 1])
    line(ctx, cSpark, 0.8); ctx.setLineWidth(9); ctx.setLineCap(.round)
    ctx.beginPath(); ctx.move(to: m)
    ctx.addLine(to: CGPoint(x: m.x + 420, y: m.y + 250)); ctx.strokePath()
    ctx.setLineCap(.butt)

    // Horizon and a hut with a lit doorway.
    ctx.beginPath()
    ctx.move(to: CGPoint(x: 0, y: CGFloat(H) * 0.40))
    ctx.addCurve(to: CGPoint(x: CGFloat(W), y: CGFloat(H) * 0.34),
                 control1: CGPoint(x: CGFloat(W) * 0.35, y: CGFloat(H) * 0.46),
                 control2: CGPoint(x: CGFloat(W) * 0.70, y: CGFloat(H) * 0.28))
    ctx.addLine(to: CGPoint(x: CGFloat(W), y: 0))
    ctx.addLine(to: CGPoint(x: 0, y: 0))
    ctx.closePath()
    fill(ctx, (0.055, 0.048, 0.044)); ctx.fillPath()

    let hut = CGRect(x: CGFloat(W) * 0.20, y: CGFloat(H) * 0.30, width: 380, height: 210)
    fill(ctx, (0.035, 0.030, 0.028)); ctx.fill(hut)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: hut.minX - 40, y: hut.maxY))
    ctx.addLine(to: CGPoint(x: hut.midX, y: hut.maxY + 130))
    ctx.addLine(to: CGPoint(x: hut.maxX + 40, y: hut.maxY))
    ctx.closePath(); fill(ctx, (0.030, 0.026, 0.024)); ctx.fillPath()
    let door = CGRect(x: hut.midX - 55, y: hut.minY, width: 110, height: 140)
    glow(ctx, at: CGPoint(x: door.midX, y: door.midY), radius: 330,
         colors: [(cFlame, 0.55), (cEmberDeep, 0.20), (cNight, 0)], locations: [0, 0.4, 1])
    fill(ctx, cSpark, 0.85); ctx.fill(door)
    for _ in 0..<50 {
        fill(ctx, cSpark, rnd(0.15, 0.7))
        let r = rnd(2, 5)
        ctx.fillEllipse(in: CGRect(x: door.midX + rnd(-90, 90),
                                   y: rnd(door.maxY, CGFloat(H) * 0.72), width: r, height: r))
    }
    finish(ctx, grainAmount: 0.06)
    save(ctx, "guide_history")
}

// MARK: - Chapter banners

func chapterBanner(_ name: String, seedV: UInt64, painter: (CGContext) -> Void) {
    seed(seedV)
    let ctx = makeCtx(W, H)
    painter(ctx)
    finish(ctx)
    save(ctx, name)
}

func chaptersAll() {
    chapterBanner("chapter_first", seedV: 2001) { ctx in
        shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.85, y: CGFloat(H) * 0.40), glowStrength: 0.5)
        // A bench with nails and hooks scattered.
        let bench = CGRect(x: CGFloat(W) * 0.05, y: CGFloat(H) * 0.20,
                           width: CGFloat(W) * 0.90, height: CGFloat(H) * 0.14)
        gradientFill(ctx, rect: bench, colors: [(cWoodDark, 1), (cWood, 1)], locations: [0, 1])
        for _ in 0..<24 {
            let x = rnd(bench.minX + 60, bench.maxX - 60)
            let y = bench.maxY + rnd(4, 30)
            let l = rnd(60, 150)
            let ang = rnd(-0.5, 0.5)
            line(ctx, cSteel, rnd(0.6, 1.0))
            ctx.setLineWidth(rnd(7, 14))
            ctx.beginPath(); ctx.move(to: CGPoint(x: x, y: y))
            ctx.addLine(to: CGPoint(x: x + cos(ang) * l, y: y + sin(ang) * l))
            ctx.strokePath()
            fill(ctx, cIron)
            ctx.fillEllipse(in: CGRect(x: x - 12, y: y - 8, width: 26, height: 18))
        }
        // Three S hooks hanging above.
        for i in 0..<3 {
            let cx = CGFloat(W) * (0.30 + CGFloat(i) * 0.20)
            line(ctx, cSteel, 0.95); ctx.setLineWidth(20); ctx.setLineCap(.round)
            ctx.beginPath()
            ctx.addArc(center: CGPoint(x: cx, y: CGFloat(H) * 0.66), radius: 74,
                       startAngle: 2.2, endAngle: 5.9, clockwise: false)
            ctx.strokePath()
            ctx.beginPath()
            ctx.addArc(center: CGPoint(x: cx, y: CGFloat(H) * 0.52), radius: 74,
                       startAngle: 5.4, endAngle: 2.6, clockwise: true)
            ctx.strokePath()
            ctx.setLineCap(.butt)
        }
    }

    chapterBanner("chapter_tools", seedV: 2002) { ctx in
        shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.12, y: CGFloat(H) * 0.28), glowStrength: 0.45)
        let railY = CGFloat(H) * 0.78
        gradientFill(ctx, rect: CGRect(x: CGFloat(W) * 0.04, y: railY, width: CGFloat(W) * 0.92, height: 30),
                     colors: [(cWoodDark, 1), (cWood, 1)], locations: [0, 1])
        for i in 0..<7 {
            let cx = CGFloat(W) * (0.11 + CGFloat(i) * 0.13)
            let kind = i % 3
            if kind == 0 {
                woodHandle(ctx, from: CGPoint(x: cx, y: railY),
                           to: CGPoint(x: cx, y: railY - CGFloat(H) * 0.30), width: 24)
                hammerHead(ctx, rect: CGRect(x: cx - 80, y: railY - CGFloat(H) * 0.36,
                                             width: 160, height: 74), peen: i % 2 == 0)
            } else if kind == 1 {
                // A punch.
                ctx.saveGState()
                ctx.beginPath()
                ctx.move(to: CGPoint(x: cx - 26, y: railY - 20))
                ctx.addLine(to: CGPoint(x: cx + 26, y: railY - 20))
                ctx.addLine(to: CGPoint(x: cx + 10, y: railY - CGFloat(H) * 0.34))
                ctx.addLine(to: CGPoint(x: cx - 10, y: railY - CGFloat(H) * 0.34))
                ctx.closePath(); ctx.clip()
                gradientFill(ctx, rect: CGRect(x: cx - 30, y: railY - CGFloat(H) * 0.35,
                                               width: 60, height: CGFloat(H) * 0.36),
                             colors: [((0.16, 0.155, 0.15), 1), ((0.46, 0.45, 0.44), 1)],
                             locations: [0, 1])
                ctx.restoreGState()
            } else {
                // A chisel.
                ctx.saveGState()
                ctx.beginPath()
                ctx.move(to: CGPoint(x: cx - 42, y: railY - 14))
                ctx.addLine(to: CGPoint(x: cx + 42, y: railY - 14))
                ctx.addLine(to: CGPoint(x: cx + 20, y: railY - CGFloat(H) * 0.32))
                ctx.addLine(to: CGPoint(x: cx - 20, y: railY - CGFloat(H) * 0.32))
                ctx.closePath(); ctx.clip()
                gradientFill(ctx, rect: CGRect(x: cx - 45, y: railY - CGFloat(H) * 0.33,
                                               width: 90, height: CGFloat(H) * 0.34),
                             colors: [((0.20, 0.195, 0.19), 1), ((0.52, 0.51, 0.50), 1)],
                             locations: [0, 1])
                ctx.restoreGState()
            }
        }
    }

    chapterBanner("chapter_hearth", seedV: 2003) { ctx in
        shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.30, y: CGFloat(H) * 0.34), glowStrength: 1.0)
        // A stone hearth on the left with a real fire.
        brickField(ctx, rect: CGRect(x: 0, y: CGFloat(H) * 0.16,
                                     width: CGFloat(W) * 0.46, height: CGFloat(H) * 0.52),
                   cols: 7, rows: 6)
        let mouth = CGRect(x: CGFloat(W) * 0.07, y: CGFloat(H) * 0.18,
                           width: CGFloat(W) * 0.30, height: CGFloat(H) * 0.30)
        fill(ctx, cNight); ctx.fill(mouth)
        glow(ctx, at: CGPoint(x: mouth.midX, y: mouth.minY + 60), radius: 520,
             colors: [(cWhiteHot, 0.85), (cFlame, 0.40), (cEmberDeep, 0.14), (cNight, 0)],
             locations: [0, 0.28, 0.55, 1])
        for _ in 0..<70 {
            fill(ctx, cSpark, rnd(0.15, 0.75))
            let r = rnd(2, 6)
            ctx.fillEllipse(in: CGRect(x: mouth.midX + rnd(-200, 200),
                                       y: rnd(mouth.minY, CGFloat(H) * 0.95), width: r, height: r))
        }
        // Fireside set leaning on the right.
        for i in 0..<4 {
            let x = CGFloat(W) * (0.58 + CGFloat(i) * 0.09)
            line(ctx, cSteel, 0.9); ctx.setLineWidth(16); ctx.setLineCap(.round)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x, y: CGFloat(H) * 0.10))
            ctx.addLine(to: CGPoint(x: x + 90, y: CGFloat(H) * 0.76))
            ctx.strokePath()
            ctx.beginPath()
            ctx.addArc(center: CGPoint(x: x + 96, y: CGFloat(H) * 0.80), radius: 44,
                       startAngle: 1.2, endAngle: 5.6, clockwise: false)
            ctx.setLineWidth(14); ctx.strokePath()
            ctx.setLineCap(.butt)
        }
    }

    chapterBanner("chapter_ornament", seedV: 2004) { ctx in
        shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.88, y: CGFloat(H) * 0.66), glowStrength: 0.45)
        // A panel of scrollwork.
        func scroll(_ cx: CGFloat, _ cy: CGFloat, _ r0: CGFloat, _ flip: CGFloat, _ lw: CGFloat) {
            line(ctx, cSteel, 0.95)
            ctx.setLineWidth(lw); ctx.setLineCap(.round)
            ctx.beginPath()
            var a: CGFloat = 0, r = r0
            ctx.move(to: CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r * flip))
            while r > 12 {
                a += 0.15; r *= 0.972
                ctx.addLine(to: CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r * flip))
            }
            ctx.strokePath()
            ctx.setLineCap(.butt)
        }
        scroll(CGFloat(W) * 0.26, CGFloat(H) * 0.56, 210, 1, 20)
        scroll(CGFloat(W) * 0.52, CGFloat(H) * 0.44, 250, -1, 22)
        scroll(CGFloat(W) * 0.76, CGFloat(H) * 0.58, 190, 1, 18)
        // Connecting bar with a twist.
        line(ctx, cIron, 0.95); ctx.setLineWidth(26)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: CGFloat(W) * 0.10, y: CGFloat(H) * 0.28))
        ctx.addLine(to: CGPoint(x: CGFloat(W) * 0.92, y: CGFloat(H) * 0.28))
        ctx.strokePath()
        for i in 0..<26 {
            let x = CGFloat(W) * (0.34 + CGFloat(i) * 0.011)
            line(ctx, cNight, 0.45); ctx.setLineWidth(4)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x, y: CGFloat(H) * 0.28 - 13))
            ctx.addLine(to: CGPoint(x: x + 12, y: CGFloat(H) * 0.28 + 13))
            ctx.strokePath()
        }
    }

    chapterBanner("chapter_master", seedV: 2005) { ctx in
        shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.16, y: CGFloat(H) * 0.66), glowStrength: 0.7)
        let bench = CGRect(x: CGFloat(W) * 0.02, y: CGFloat(H) * 0.10,
                           width: CGFloat(W) * 0.96, height: CGFloat(H) * 0.22)
        gradientFill(ctx, rect: bench, colors: [(cWoodDark, 1), (cWood, 1)], locations: [0, 1])
        for _ in 0..<40 {
            fill(ctx, (0, 0, 0), rnd(0.05, 0.16))
            ctx.fill(CGRect(x: rnd(bench.minX, bench.maxX), y: rnd(bench.minY, bench.maxY),
                            width: rnd(40, 260), height: rnd(1.5, 4)))
        }
        let top = bench.maxY

        // Axe head: heavy poll, drifted eye, bit fanning out and down to an edge.
        let ax = CGFloat(W) * 0.30
        ctx.saveGState()
        ctx.beginPath()
        ctx.move(to: CGPoint(x: ax - 200, y: top + 60))
        ctx.addLine(to: CGPoint(x: ax - 200, y: top + 230))
        ctx.addLine(to: CGPoint(x: ax - 60, y: top + 246))
        ctx.addCurve(to: CGPoint(x: ax + 250, y: top + 320),
                     control1: CGPoint(x: ax + 60, y: top + 262),
                     control2: CGPoint(x: ax + 170, y: top + 300))
        ctx.addCurve(to: CGPoint(x: ax + 250, y: top + 10),
                     control1: CGPoint(x: ax + 330, y: top + 210),
                     control2: CGPoint(x: ax + 330, y: top + 120))
        ctx.addCurve(to: CGPoint(x: ax - 60, y: top + 44),
                     control1: CGPoint(x: ax + 170, y: top + 30),
                     control2: CGPoint(x: ax + 60, y: top + 28))
        ctx.closePath(); ctx.clip()
        gradientFill(ctx, rect: CGRect(x: ax - 210, y: top, width: 560, height: 340),
                     colors: [((0.16, 0.155, 0.15), 1), ((0.60, 0.595, 0.585), 1)], locations: [0, 1])
        // A bright edge along the bit.
        fill(ctx, cPolish, 0.75)
        ctx.fill(CGRect(x: ax + 230, y: top, width: 40, height: 340))
        ctx.restoreGState()
        // The eye, punched and drifted.
        fill(ctx, cNight, 0.94)
        ctx.fillEllipse(in: CGRect(x: ax - 150, y: top + 96, width: 108, height: 130))
        line(ctx, (0.50, 0.49, 0.48), 0.5); ctx.setLineWidth(5)
        ctx.strokeEllipse(in: CGRect(x: ax - 150, y: top + 96, width: 108, height: 130))

        // A pattern-welded blade lying flat on the bench beside it.
        let bx = CGFloat(W) * 0.72, by = top + 70
        ctx.saveGState()
        ctx.beginPath()
        ctx.move(to: CGPoint(x: bx - 360, y: by - 22))
        ctx.addLine(to: CGPoint(x: bx - 190, y: by - 30))
        ctx.addLine(to: CGPoint(x: bx - 170, y: by - 62))
        ctx.addLine(to: CGPoint(x: bx + 300, y: by - 40))
        ctx.addLine(to: CGPoint(x: bx + 386, y: by))
        ctx.addLine(to: CGPoint(x: bx + 300, y: by + 40))
        ctx.addLine(to: CGPoint(x: bx - 170, y: by + 62))
        ctx.addLine(to: CGPoint(x: bx - 190, y: by + 30))
        ctx.addLine(to: CGPoint(x: bx - 360, y: by + 22))
        ctx.closePath(); ctx.clip()
        gradientFill(ctx, rect: CGRect(x: bx - 370, y: by - 70, width: 770, height: 140),
                     colors: [((0.26, 0.255, 0.25), 1), ((0.76, 0.755, 0.745), 1)], locations: [0, 1])
        for i in 0..<46 {
            let x = bx - 170 + CGFloat(i) * 12
            line(ctx, cNight, rnd(0.07, 0.24)); ctx.setLineWidth(rnd(2, 6))
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x, y: by - 60))
            ctx.addQuadCurve(to: CGPoint(x: x + 14, y: by + 60),
                             control: CGPoint(x: x + rnd(-18, 18), y: by))
            ctx.strokePath()
        }
        ctx.restoreGState()
        // Grip wrap on the tang.
        for i in 0..<9 {
            line(ctx, (0.32, 0.22, 0.14), 0.9); ctx.setLineWidth(11)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: bx - 350 + CGFloat(i) * 19, y: by - 24))
            ctx.addLine(to: CGPoint(x: bx - 338 + CGFloat(i) * 19, y: by + 24))
            ctx.strokePath()
        }
        // Shadows so nothing floats.
        fill(ctx, (0, 0, 0), 0.32)
        ctx.fillEllipse(in: CGRect(x: ax - 210, y: top - 26, width: 500, height: 54))
        ctx.fillEllipse(in: CGRect(x: bx - 360, y: top - 20, width: 740, height: 42))
    }
}

// MARK: - Onboarding

func onboardingAll() {
    chapterBanner("onboard_fire", seedV: 3001) { ctx in
        shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.5, y: CGFloat(H) * 0.36), glowStrength: 1.1)
        brickField(ctx, rect: CGRect(x: CGFloat(W) * 0.10, y: CGFloat(H) * 0.10,
                                     width: CGFloat(W) * 0.80, height: CGFloat(H) * 0.34),
                   cols: 9, rows: 4)
        let bed = CGRect(x: CGFloat(W) * 0.22, y: CGFloat(H) * 0.22,
                         width: CGFloat(W) * 0.56, height: CGFloat(H) * 0.22)
        fill(ctx, (0.05, 0.04, 0.038)); ctx.fillEllipse(in: bed)
        glow(ctx, at: CGPoint(x: bed.midX, y: bed.midY), radius: bed.width * 0.62,
             colors: [(cWhiteHot, 0.95), (cSpark, 0.55), (cEmber, 0.25), (cNight, 0)],
             locations: [0, 0.25, 0.55, 1])
        for _ in 0..<70 {
            fill(ctx, (0.05, 0.045, 0.042), rnd(0.35, 0.8))
            let s = rnd(18, 52)
            ctx.fillEllipse(in: CGRect(x: rnd(bed.minX, bed.maxX - s),
                                       y: rnd(bed.minY, bed.maxY - s * 0.7),
                                       width: s, height: s * 0.72))
        }
        hotBar(ctx, from: CGPoint(x: CGFloat(W) * 0.16, y: CGFloat(H) * 0.30),
               to: CGPoint(x: CGFloat(W) * 0.62, y: CGFloat(H) * 0.33),
               thickA: 40, thickB: 38, tempA: 780, tempB: 1350, glowScale: 1.8)
        for _ in 0..<120 {
            fill(ctx, cSpark, rnd(0.10, 0.85))
            let r = rnd(2, 7)
            ctx.fillEllipse(in: CGRect(x: bed.midX + rnd(-420, 420),
                                       y: rnd(bed.maxY - 40, CGFloat(H) * 0.98),
                                       width: r, height: r))
        }
    }

    chapterBanner("onboard_strike", seedV: 3002) { ctx in
        shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.46, y: CGFloat(H) * 0.44), glowStrength: 0.9)
        anvilSilhouette(ctx, rect: CGRect(x: CGFloat(W) * 0.10, y: CGFloat(H) * 0.06,
                                          width: CGFloat(W) * 0.70, height: CGFloat(H) * 0.36),
                        faceHighlight: 0.6)
        hotBar(ctx, from: CGPoint(x: CGFloat(W) * 0.14, y: CGFloat(H) * 0.42),
               to: CGPoint(x: CGFloat(W) * 0.78, y: CGFloat(H) * 0.42),
               thickA: 48, thickB: 24, tempA: 1240, tempB: 1080, glowScale: 1.6)
        let hx = CGFloat(W) * 0.42
        hammerHead(ctx, rect: CGRect(x: hx - 130, y: CGFloat(H) * 0.47, width: 260, height: 92),
                   peen: false)
        woodHandle(ctx, from: CGPoint(x: hx, y: CGFloat(H) * 0.56),
                   to: CGPoint(x: hx - 90, y: CGFloat(H) * 0.96), width: 32)
        sparkBurst(ctx, at: CGPoint(x: hx, y: CGFloat(H) * 0.45), count: 90, spread: 420)
        glow(ctx, at: CGPoint(x: hx, y: CGFloat(H) * 0.44), radius: 300,
             colors: [(cWhiteHot, 0.45), (cNight, 0)], locations: [0, 1])
    }

    chapterBanner("onboard_shape", seedV: 3003) { ctx in
        // A blueprint board propped on the bench.
        gradientFill(ctx, rect: CGRect(x: 0, y: 0, width: CGFloat(W), height: CGFloat(H)),
                     colors: [(cNight, 1), (cSoot, 1)], locations: [0, 1])
        let board = CGRect(x: CGFloat(W) * 0.07, y: CGFloat(H) * 0.12,
                           width: CGFloat(W) * 0.86, height: CGFloat(H) * 0.74)
        fill(ctx, (0.086, 0.098, 0.118)); ctx.fill(board)
        line(ctx, cQuench, 0.16); ctx.setLineWidth(2)
        for i in 0...26 {
            let x = board.minX + board.width * CGFloat(i) / 26
            ctx.beginPath(); ctx.move(to: CGPoint(x: x, y: board.minY))
            ctx.addLine(to: CGPoint(x: x, y: board.maxY)); ctx.strokePath()
        }
        for i in 0...16 {
            let y = board.minY + board.height * CGFloat(i) / 16
            ctx.beginPath(); ctx.move(to: CGPoint(x: board.minX, y: y))
            ctx.addLine(to: CGPoint(x: board.maxX, y: y)); ctx.strokePath()
        }
        // The drawing: a tapered, hooked bar.
        line(ctx, cChalk, 0.92); ctx.setLineWidth(6); ctx.setLineCap(.round)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: board.minX + 120, y: board.midY + 70))
        ctx.addLine(to: CGPoint(x: board.maxX - 420, y: board.midY + 40))
        ctx.addQuadCurve(to: CGPoint(x: board.maxX - 160, y: board.midY - 130),
                         control: CGPoint(x: board.maxX - 130, y: board.midY + 30))
        ctx.strokePath()
        ctx.beginPath()
        ctx.move(to: CGPoint(x: board.minX + 120, y: board.midY - 70))
        ctx.addLine(to: CGPoint(x: board.maxX - 420, y: board.midY - 24))
        ctx.addQuadCurve(to: CGPoint(x: board.maxX - 250, y: board.midY - 140),
                         control: CGPoint(x: board.maxX - 250, y: board.midY - 10))
        ctx.strokePath()
        ctx.setLineCap(.butt)
        // Dimension marks in brass.
        for i in 0..<5 {
            let x = board.minX + 200 + CGFloat(i) * 260
            leader(ctx, from: CGPoint(x: x, y: board.midY + 110),
                   to: CGPoint(x: x, y: board.minY + 70))
        }
        // Chalk dust and a stub of soapstone.
        for _ in 0..<220 {
            fill(ctx, cChalk, rnd(0.02, 0.10))
            let r = rnd(1, 5)
            ctx.fillEllipse(in: CGRect(x: rnd(board.minX, board.maxX),
                                       y: rnd(board.minY, board.maxY), width: r, height: r))
        }
    }

    chapterBanner("onboard_shop", seedV: 3004) { ctx in
        shopBackdrop(ctx, glowAt: CGPoint(x: CGFloat(W) * 0.76, y: CGFloat(H) * 0.44), glowStrength: 1.15)

        // Window on the left, dusk outside.
        let win = CGRect(x: CGFloat(W) * 0.05, y: CGFloat(H) * 0.52,
                         width: CGFloat(W) * 0.19, height: CGFloat(H) * 0.32)
        gradientFill(ctx, rect: win, colors: [((0.24, 0.20, 0.33), 1), ((0.58, 0.38, 0.42), 1)],
                     locations: [0, 1])
        // Hills through the glass.
        ctx.saveGState(); ctx.addRect(win); ctx.clip()
        ctx.beginPath()
        ctx.move(to: CGPoint(x: win.minX, y: win.minY))
        ctx.addQuadCurve(to: CGPoint(x: win.maxX, y: win.minY + win.height * 0.30),
                         control: CGPoint(x: win.midX, y: win.minY + win.height * 0.44))
        ctx.addLine(to: CGPoint(x: win.maxX, y: win.minY))
        ctx.closePath(); fill(ctx, (0.10, 0.08, 0.11)); ctx.fillPath()
        ctx.restoreGState()
        line(ctx, cWoodDark); ctx.setLineWidth(22); ctx.stroke(win)
        line(ctx, cWoodDark); ctx.setLineWidth(13)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: win.midX, y: win.minY)); ctx.addLine(to: CGPoint(x: win.midX, y: win.maxY))
        ctx.move(to: CGPoint(x: win.minX, y: win.midY)); ctx.addLine(to: CGPoint(x: win.maxX, y: win.midY))
        ctx.strokePath()

        // Chimney hood over the forge.
        ctx.beginPath()
        ctx.move(to: CGPoint(x: CGFloat(W) * 0.58, y: CGFloat(H) * 0.62))
        ctx.addLine(to: CGPoint(x: CGFloat(W), y: CGFloat(H) * 0.62))
        ctx.addLine(to: CGPoint(x: CGFloat(W) * 0.97, y: CGFloat(H)))
        ctx.addLine(to: CGPoint(x: CGFloat(W) * 0.72, y: CGFloat(H)))
        ctx.closePath()
        fill(ctx, (0.095, 0.083, 0.077)); ctx.fillPath()
        line(ctx, (0.03, 0.026, 0.024), 0.8); ctx.setLineWidth(4); ctx.strokePath()

        // Brick back of the forge, then the fire pot standing in front of it.
        brickField(ctx, rect: CGRect(x: CGFloat(W) * 0.60, y: CGFloat(H) * 0.30,
                                     width: CGFloat(W) * 0.38, height: CGFloat(H) * 0.32),
                   cols: 7, rows: 4)
        let pot = CGRect(x: CGFloat(W) * 0.62, y: CGFloat(H) * 0.16,
                         width: CGFloat(W) * 0.34, height: CGFloat(H) * 0.22)
        gradientFill(ctx, rect: pot, colors: [((0.10, 0.085, 0.078), 1), ((0.23, 0.175, 0.145), 1)],
                     locations: [0, 1])
        line(ctx, (0.04, 0.035, 0.032), 0.9); ctx.setLineWidth(6); ctx.stroke(pot)

        // Coal bed sunk into the pot, white-hot at the middle.
        let bed = CGRect(x: pot.minX + pot.width * 0.12, y: pot.maxY - 46,
                         width: pot.width * 0.76, height: 92)
        fill(ctx, (0.045, 0.038, 0.035)); ctx.fillEllipse(in: bed)
        glow(ctx, at: CGPoint(x: bed.midX, y: bed.midY), radius: bed.width * 0.70,
             colors: [(cWhiteHot, 0.95), (cSpark, 0.55), (cEmber, 0.22), (cNight, 0)],
             locations: [0, 0.22, 0.52, 1])
        for _ in 0..<46 {
            fill(ctx, (0.05, 0.045, 0.042), rnd(0.35, 0.85))
            let s = rnd(14, 38)
            ctx.fillEllipse(in: CGRect(x: rnd(bed.minX, bed.maxX - s),
                                       y: rnd(bed.minY + 6, bed.maxY - s * 0.6),
                                       width: s, height: s * 0.7))
        }
        // A bar lying in the coals.
        hotBar(ctx, from: CGPoint(x: CGFloat(W) * 0.56, y: bed.midY - 8),
               to: CGPoint(x: bed.midX + 40, y: bed.midY + 6),
               thickA: 26, thickB: 26, tempA: 760, tempB: 1330, glowScale: 1.4)

        // Anvil on its stump, centre stage.
        let stump = CGRect(x: CGFloat(W) * 0.355, y: CGFloat(H) * 0.05,
                           width: CGFloat(W) * 0.13, height: CGFloat(H) * 0.19)
        gradientFill(ctx, rect: stump, colors: [(cWoodDark, 1), (cWood, 1)], locations: [0, 1])
        for i in 0..<8 {
            fill(ctx, (0, 0, 0), 0.16)
            ctx.fill(CGRect(x: stump.minX + CGFloat(i) * stump.width / 8, y: stump.minY,
                            width: 3, height: stump.height))
        }
        anvilSilhouette(ctx, rect: CGRect(x: CGFloat(W) * 0.29, y: CGFloat(H) * 0.22,
                                          width: CGFloat(W) * 0.28, height: CGFloat(H) * 0.21),
                        faceHighlight: 0.65)

        // Slack tub beside the anvil.
        let tub = CGRect(x: CGFloat(W) * 0.50, y: CGFloat(H) * 0.05,
                         width: CGFloat(W) * 0.09, height: CGFloat(H) * 0.15)
        gradientFill(ctx, rect: tub, colors: [(cWoodDark, 1), (cWood, 1)], locations: [0, 1])
        line(ctx, (0.40, 0.38, 0.36), 0.85); ctx.setLineWidth(7)
        ctx.stroke(CGRect(x: tub.minX, y: tub.minY + tub.height * 0.35, width: tub.width, height: 1))
        fill(ctx, cQuench, 0.55)
        ctx.fillEllipse(in: CGRect(x: tub.minX + 8, y: tub.maxY - 22, width: tub.width - 16, height: 30))

        // Tool rack on the wall.
        gradientFill(ctx, rect: CGRect(x: CGFloat(W) * 0.29, y: CGFloat(H) * 0.70,
                                       width: CGFloat(W) * 0.25, height: 22),
                     colors: [(cWoodDark, 1), (cWood, 1)], locations: [0, 1])
        for i in 0..<4 {
            let cx = CGFloat(W) * (0.32 + CGFloat(i) * 0.06)
            woodHandle(ctx, from: CGPoint(x: cx, y: CGFloat(H) * 0.70),
                       to: CGPoint(x: cx, y: CGFloat(H) * 0.56), width: 15)
            hammerHead(ctx, rect: CGRect(x: cx - 46, y: CGFloat(H) * 0.51, width: 92, height: 40),
                       peen: i % 2 == 0)
        }

        // A beam across the ceiling with finished hooks hanging off it.
        gradientFill(ctx, rect: CGRect(x: 0, y: CGFloat(H) * 0.93, width: CGFloat(W) * 0.58, height: 30),
                     colors: [(cWoodDark, 1), (cWood, 1)], locations: [0, 1])
        for i in 0..<4 {
            let cx = CGFloat(W) * (0.10 + CGFloat(i) * 0.075)
            line(ctx, cSteel, 0.85); ctx.setLineWidth(12); ctx.setLineCap(.round)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: cx, y: CGFloat(H) * 0.93))
            ctx.addLine(to: CGPoint(x: cx, y: CGFloat(H) * 0.88))
            ctx.strokePath()
            ctx.beginPath()
            ctx.addArc(center: CGPoint(x: cx, y: CGFloat(H) * 0.855), radius: 30,
                       startAngle: 1.1, endAngle: 5.4, clockwise: false)
            ctx.strokePath()
            ctx.beginPath()
            ctx.addArc(center: CGPoint(x: cx, y: CGFloat(H) * 0.80), radius: 30,
                       startAngle: 4.2, endAngle: 2.0, clockwise: true)
            ctx.strokePath()
            ctx.setLineCap(.butt)
        }

        // Embers rising off the fire.
        for _ in 0..<110 {
            fill(ctx, cSpark, rnd(0.10, 0.70))
            let r = rnd(2, 6)
            ctx.fillEllipse(in: CGRect(x: bed.midX + rnd(-280, 280),
                                       y: rnd(bed.maxY, CGFloat(H) * 0.98), width: r, height: r))
        }
    }
}

// MARK: - Badges

let BS = 512

func badge(_ name: String, seedV: UInt64, tint: RGB, emblem: (CGContext, CGFloat) -> Void) {
    seed(seedV)
    let ctx = makeCtx(BS, BS)
    let f = CGFloat(BS)
    fill(ctx, cNight); ctx.fill(CGRect(x: 0, y: 0, width: f, height: f))
    glow(ctx, at: CGPoint(x: f / 2, y: f * 0.54), radius: f * 0.62,
         colors: [(tint, 0.42), ((tint.0 * 0.4, tint.1 * 0.4, tint.2 * 0.4), 0.18), (cNight, 0)],
         locations: [0, 0.5, 1])
    // Rim.
    line(ctx, cBrassDim, 0.8); ctx.setLineWidth(f * 0.022)
    ctx.strokeEllipse(in: CGRect(x: f * 0.07, y: f * 0.07, width: f * 0.86, height: f * 0.86))
    line(ctx, cBrass, 0.35); ctx.setLineWidth(f * 0.008)
    ctx.strokeEllipse(in: CGRect(x: f * 0.13, y: f * 0.13, width: f * 0.74, height: f * 0.74))

    emblem(ctx, f)

    // Small sparks around the emblem.
    for _ in 0..<14 {
        fill(ctx, cSpark, rnd(0.15, 0.6))
        let r = rnd(2, 6)
        let a = rnd(0, 6.28), d = rnd(f * 0.28, f * 0.40)
        ctx.fillEllipse(in: CGRect(x: f / 2 + cos(a) * d - r, y: f / 2 + sin(a) * d - r,
                                   width: r * 2, height: r * 2))
    }
    vignette(ctx, w: BS, h: BS, strength: 0.5)
    grain(ctx, w: BS, h: BS, amount: 0.06)
    save(ctx, name)
}

func badgesAll() {
    func star(_ ctx: CGContext, _ f: CGFloat, _ scale: CGFloat, _ c: RGB) {
        let cx = f / 2, cy = f / 2
        ctx.beginPath()
        for i in 0..<10 {
            let r = i % 2 == 0 ? f * 0.22 * scale : f * 0.095 * scale
            let a = -CGFloat.pi / 2 + CGFloat(i) * CGFloat.pi / 5
            let p = CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r)
            if i == 0 { ctx.move(to: p) } else { ctx.addLine(to: p) }
        }
        ctx.closePath(); fill(ctx, c); ctx.fillPath()
    }
    func ring(_ ctx: CGContext, _ f: CGFloat, _ r: CGFloat, _ lw: CGFloat, _ c: RGB, _ a: CGFloat = 1) {
        line(ctx, c, a); ctx.setLineWidth(lw)
        ctx.strokeEllipse(in: CGRect(x: f / 2 - r, y: f / 2 - r, width: r * 2, height: r * 2))
    }
    func bar(_ ctx: CGContext, _ f: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: RGB, _ dy: CGFloat = 0) {
        fill(ctx, c)
        ctx.fill(CGRect(x: f / 2 - w / 2, y: f / 2 - h / 2 + dy, width: w, height: h))
    }

    badge("badge_first_heat", seedV: 4001, tint: cEmber) { ctx, f in
        glow(ctx, at: CGPoint(x: f / 2, y: f / 2), radius: f * 0.30,
             colors: [(cWhiteHot, 0.9), (cFlame, 0.5), (cNight, 0)], locations: [0, 0.4, 1])
        bar(ctx, f, f * 0.44, f * 0.07, heatColor(1250))
    }
    badge("badge_first_piece", seedV: 4002, tint: cBrass) { ctx, f in
        anvilSilhouette(ctx, rect: CGRect(x: f * 0.22, y: f * 0.30, width: f * 0.56, height: f * 0.34),
                        faceHighlight: 0.7)
    }
    badge("badge_three_star", seedV: 4003, tint: cSpark) { ctx, f in
        for (i, dx) in [-f * 0.20, 0, f * 0.20].enumerated() {
            ctx.saveGState(); ctx.translateBy(x: dx, y: i == 1 ? f * 0.04 : 0)
            star(ctx, f, i == 1 ? 0.72 : 0.55, cSpark); ctx.restoreGState()
        }
    }
    badge("badge_pristine", seedV: 4004, tint: cPolish) { ctx, f in
        ring(ctx, f, f * 0.24, f * 0.030, cPolish)
        star(ctx, f, 0.62, cWhiteHot)
    }
    badge("badge_chapter_first", seedV: 4005, tint: cEmber) { ctx, f in
        for i in 0..<3 {
            line(ctx, cSteel, 0.95); ctx.setLineWidth(f * 0.045); ctx.setLineCap(.round)
            let x = f / 2 + CGFloat(i - 1) * f * 0.15
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x, y: f * 0.68))
            ctx.addLine(to: CGPoint(x: x, y: f * 0.34))
            ctx.strokePath()
            fill(ctx, cIron)
            ctx.fillEllipse(in: CGRect(x: x - f * 0.05, y: f * 0.66, width: f * 0.10, height: f * 0.05))
            ctx.setLineCap(.butt)
        }
    }
    badge("badge_chapter_tools", seedV: 4006, tint: cBrass) { ctx, f in
        hammerHead(ctx, rect: CGRect(x: f * 0.24, y: f * 0.52, width: f * 0.52, height: f * 0.13),
                   peen: true)
        woodHandle(ctx, from: CGPoint(x: f * 0.45, y: f * 0.52),
                   to: CGPoint(x: f * 0.40, y: f * 0.26), width: f * 0.055)
    }
    badge("badge_chapter_hearth", seedV: 4007, tint: cFlame) { ctx, f in
        glow(ctx, at: CGPoint(x: f / 2, y: f * 0.44), radius: f * 0.28,
             colors: [(cWhiteHot, 0.85), (cFlame, 0.45), (cNight, 0)], locations: [0, 0.4, 1])
        for i in 0..<3 {
            line(ctx, cSteel, 0.95); ctx.setLineWidth(f * 0.035); ctx.setLineCap(.round)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: f * (0.34 + CGFloat(i) * 0.11), y: f * 0.72))
            ctx.addLine(to: CGPoint(x: f * (0.40 + CGFloat(i) * 0.11), y: f * 0.30))
            ctx.strokePath()
            ctx.setLineCap(.butt)
        }
    }
    badge("badge_chapter_ornament", seedV: 4008, tint: cQuench) { ctx, f in
        line(ctx, cSteel, 0.95); ctx.setLineWidth(f * 0.040); ctx.setLineCap(.round)
        ctx.beginPath()
        var a: CGFloat = 0, r = f * 0.26
        ctx.move(to: CGPoint(x: f / 2 + cos(a) * r, y: f / 2 + sin(a) * r))
        while r > f * 0.03 { a += 0.16; r *= 0.968
            ctx.addLine(to: CGPoint(x: f / 2 + cos(a) * r, y: f / 2 + sin(a) * r)) }
        ctx.strokePath(); ctx.setLineCap(.butt)
    }
    badge("badge_chapter_master", seedV: 4009, tint: cSpark) { ctx, f in
        ctx.saveGState()
        ctx.beginPath()
        ctx.move(to: CGPoint(x: f * 0.26, y: f * 0.42))
        ctx.addLine(to: CGPoint(x: f * 0.40, y: f * 0.46))
        ctx.addCurve(to: CGPoint(x: f * 0.76, y: f * 0.50),
                     control1: CGPoint(x: f * 0.58, y: f * 0.62),
                     control2: CGPoint(x: f * 0.74, y: f * 0.60))
        ctx.addCurve(to: CGPoint(x: f * 0.40, y: f * 0.54),
                     control1: CGPoint(x: f * 0.74, y: f * 0.40),
                     control2: CGPoint(x: f * 0.58, y: f * 0.38))
        ctx.closePath(); ctx.clip()
        gradientFill(ctx, rect: CGRect(x: f * 0.20, y: f * 0.34, width: f * 0.60, height: f * 0.32),
                     colors: [((0.20, 0.195, 0.19), 1), ((0.68, 0.675, 0.665), 1)], locations: [0, 1])
        ctx.restoreGState()
    }
    badge("badge_hardened", seedV: 4010, tint: cTemperPurple) { ctx, f in
        for (i, c) in [cTemperStraw, cTemperBronze, cTemperPurple, cTemperBlue].enumerated() {
            fill(ctx, c)
            ctx.fill(CGRect(x: f * 0.24, y: f * (0.30 + CGFloat(i) * 0.10),
                            width: f * 0.52, height: f * 0.085))
        }
    }
    badge("badge_no_crack", seedV: 4011, tint: cQuench) { ctx, f in
        ring(ctx, f, f * 0.24, f * 0.035, cQuench)
        bar(ctx, f, f * 0.42, f * 0.06, cSteel)
    }
    badge("badge_under_par", seedV: 4012, tint: cBrass) { ctx, f in
        for i in 0..<3 {
            hammerHead(ctx, rect: CGRect(x: f * 0.28, y: f * (0.30 + CGFloat(i) * 0.15),
                                         width: f * 0.44, height: f * 0.085), peen: false)
        }
    }
    badge("badge_one_heat", seedV: 4013, tint: cFlame) { ctx, f in
        glow(ctx, at: CGPoint(x: f / 2, y: f / 2), radius: f * 0.32,
             colors: [(cWhiteHot, 0.95), (cFlame, 0.4), (cNight, 0)], locations: [0, 0.42, 1])
        ring(ctx, f, f * 0.20, f * 0.030, cSpark)
    }
    badge("badge_twenty", seedV: 4014, tint: cBrass) { ctx, f in
        for r in 0..<4 {
            for c in 0..<5 {
                fill(ctx, cSteel, 0.9)
                ctx.fill(CGRect(x: f * (0.26 + CGFloat(c) * 0.10), y: f * (0.30 + CGFloat(r) * 0.10),
                                width: f * 0.06, height: f * 0.055))
            }
        }
    }
    badge("badge_streak_3", seedV: 4015, tint: cEmber) { ctx, f in
        for i in 0..<3 {
            glow(ctx, at: CGPoint(x: f * (0.32 + CGFloat(i) * 0.18), y: f / 2), radius: f * 0.14,
                 colors: [(cFlame, 0.85), (cNight, 0)], locations: [0, 1])
        }
    }
    badge("badge_streak_7", seedV: 4016, tint: cFlame) { ctx, f in
        for i in 0..<7 {
            let a = CGFloat(i) / 7 * 6.28
            glow(ctx, at: CGPoint(x: f / 2 + cos(a) * f * 0.22, y: f / 2 + sin(a) * f * 0.22),
                 radius: f * 0.11, colors: [(cFlame, 0.85), (cNight, 0)], locations: [0, 1])
        }
    }
    badge("badge_commissions", seedV: 4017, tint: cBrass) { ctx, f in
        fill(ctx, (0.80, 0.76, 0.68), 0.92)
        ctx.fill(CGRect(x: f * 0.30, y: f * 0.26, width: f * 0.40, height: f * 0.48))
        for i in 0..<5 {
            fill(ctx, cNight, 0.55)
            ctx.fill(CGRect(x: f * 0.35, y: f * (0.34 + CGFloat(i) * 0.075),
                            width: f * 0.30, height: f * 0.020))
        }
    }
    badge("badge_all_metals", seedV: 4018, tint: cSteel) { ctx, f in
        let tints: [RGB] = [(0.463, 0.451, 0.435), (0.435, 0.400, 0.361), (0.400, 0.396, 0.404),
                            (0.365, 0.376, 0.400), (0.451, 0.427, 0.396), (0.400, 0.416, 0.443)]
        for (i, c) in tints.enumerated() {
            fill(ctx, c)
            ctx.fill(CGRect(x: f * 0.24, y: f * (0.26 + CGFloat(i) * 0.08),
                            width: f * 0.52, height: f * 0.06))
        }
    }
    badge("badge_almanac", seedV: 4019, tint: cQuench) { ctx, f in
        fill(ctx, (0.22, 0.17, 0.12))
        ctx.fill(CGRect(x: f * 0.26, y: f * 0.28, width: f * 0.48, height: f * 0.44))
        fill(ctx, (0.82, 0.78, 0.70), 0.9)
        ctx.fill(CGRect(x: f * 0.29, y: f * 0.31, width: f * 0.42, height: f * 0.38))
        fill(ctx, (0.22, 0.17, 0.12))
        ctx.fill(CGRect(x: f * 0.49, y: f * 0.28, width: f * 0.02, height: f * 0.44))
    }
    badge("badge_quiz", seedV: 4020, tint: cSpark) { ctx, f in
        ring(ctx, f, f * 0.22, f * 0.035, cSpark)
        line(ctx, cWhiteHot, 0.95); ctx.setLineWidth(f * 0.045); ctx.setLineCap(.round)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: f * 0.36, y: f * 0.50))
        ctx.addLine(to: CGPoint(x: f * 0.46, y: f * 0.40))
        ctx.addLine(to: CGPoint(x: f * 0.66, y: f * 0.62))
        ctx.strokePath(); ctx.setLineCap(.butt)
    }
}

// MARK: - Run

guideHeat()
guideCarbon()
guideDrawing()
guideAnvil()
guideHammers()
guideFuller()
guidePunching()
guideQuench()
guideTemper()
guideScale()
guideBending()
guideHistory()
chaptersAll()
onboardingAll()
badgesAll()
print("done")
