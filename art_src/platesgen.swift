import Foundation
import CoreGraphics

// Generates every bundled illustration for Ember Forge as a copperplate
// engraving. Compiled together with the app's own content tables, so the
// twenty-four piece plates are drawn from exactly the data the player forges
// against.
//
// Usage: platesgen <output-directory>

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

let PLATE_W = 1500
let PLATE_H = 960
let PIECE_W = 1000
let PIECE_H = 680

// MARK: - Sheet scaffolding

/// Lays a sheet, runs the subject inside the plate mark, then adds the plate
/// furniture: impression, caption rule and number.
func sheet(_ name: String, number: Int, seedValue: UInt64,
           w: Int = PLATE_W, h: Int = PLATE_H,
           subject: (CGContext, CGRect) -> Void) {
    eSeed(seedValue)
    let ctx = engCtx(w, h)
    let W = CGFloat(w), H = CGFloat(h)
    layPaper(ctx, w: w, h: h)
    let plate = CGRect(x: W * 0.055, y: H * 0.095, width: W * 0.89, height: H * 0.815)

    ctx.saveGState()
    ctx.addPath(rectPath(plate))
    ctx.clip()
    subject(ctx, plate)
    ctx.restoreGState()

    plateMark(ctx, plate)
    captionRule(ctx, from: CGPoint(x: plate.minX + 34, y: plate.minY - 24),
                to: CGPoint(x: plate.maxX - 34, y: plate.minY - 24))
    plateNumeral(ctx, number, at: CGPoint(x: plate.maxX - 92, y: plate.maxY - 52), size: 30)
    engSave(ctx, outDir, name)
}

/// The ground every subject stands on: a faint shadow pool and two corner washes.
func setting(_ ctx: CGContext, _ plate: CGRect, groundY: CGFloat, shadowWidth: CGFloat = 0.55) {
    cornerWash(ctx, plate, corner: 0, tone: 0.24, reach: 0.46)
    cornerWash(ctx, plate, corner: 1, tone: 0.18, reach: 0.40, angle: -0.34)
    stipple(ctx, clip: ellipsePath(CGRect(x: plate.midX - plate.width * shadowWidth / 2,
                                          y: groundY - 46,
                                          width: plate.width * shadowWidth, height: 92)),
            tone: 0.26, sizeRange: (0.7, 2.3))
}

// MARK: - Reusable engraved objects

func drawAnvil(_ ctx: CGContext, at c: CGPoint, scale: CGFloat, showHoles: Bool = false) {
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: c.x + x * scale, y: c.y + y * scale)
    }
    let body = [p(-210, 118), p(132, 118), p(268, 82), p(128, 52), p(78, 52),
                p(52, -62), p(108, -128), p(-168, -128), p(-112, -62),
                p(-140, 52), p(-210, 52)]
    hatch(ctx, clip: polyPath(body), tone: 0.56, baseAngle: 0.72)
    // The face is polished by work, so it stays nearly bare.
    hatch(ctx, clip: polyPath([p(-208, 96), p(130, 96), p(130, 116), p(-208, 116)]),
          tone: 0.12, baseAngle: 0.04)
    // The waist is deepest.
    hatch(ctx, clip: polyPath([p(-112, -62), p(52, -62), p(78, 40), p(-140, 40)]),
          tone: 0.30, baseAngle: -0.5)
    taperedOutline(ctx, body, weight: 2.7, lightAngle: 2.35)
    if showHoles {
        let hardy = CGRect(x: p(-150, 100).x, y: p(-150, 100).y, width: 34 * scale, height: 16 * scale)
        hatch(ctx, clip: rectPath(hardy), tone: 0.95, baseAngle: 0.9)
        let pritchel = CGRect(x: p(-96, 102).x, y: p(-96, 102).y, width: 20 * scale, height: 12 * scale)
        hatch(ctx, clip: ellipsePath(pritchel), tone: 0.95, baseAngle: 0.3)
    }
}

func drawStump(_ ctx: CGContext, under c: CGPoint, scale: CGFloat, groundY: CGFloat) {
    let w = 150 * scale
    let top = c.y - 128 * scale
    let box = [CGPoint(x: c.x - w, y: groundY), CGPoint(x: c.x + w, y: groundY),
               CGPoint(x: c.x + w * 0.92, y: top), CGPoint(x: c.x - w * 0.92, y: top)]
    hatch(ctx, clip: polyPath(box), tone: 0.34, baseAngle: 1.45, wobble: 2.2)
    // Vertical grain in the wood.
    ctx.setStrokeColor(engColor(inkBlack, 0.42))
    for i in 0..<11 {
        let f = CGFloat(i) / 10
        let x = c.x - w * 0.9 + w * 1.8 * f
        ctx.setLineWidth(eRnd(0.5, 1.5))
        ctx.beginPath()
        ctx.move(to: CGPoint(x: x, y: groundY))
        ctx.addLine(to: CGPoint(x: x + eRnd(-4, 4), y: top))
        ctx.strokePath()
    }
    taperedOutline(ctx, box, weight: 2.2, lightAngle: 2.3)
}

func drawHammer(_ ctx: CGContext, head: CGRect, handleTo: CGPoint, peen: Bool) {
    let h = head
    let shape: [CGPoint] = peen
        ? [CGPoint(x: h.minX, y: h.minY), CGPoint(x: h.maxX - h.width * 0.34, y: h.minY),
           CGPoint(x: h.maxX, y: h.midY), CGPoint(x: h.maxX - h.width * 0.34, y: h.maxY),
           CGPoint(x: h.minX, y: h.maxY)]
        : [CGPoint(x: h.minX, y: h.minY), CGPoint(x: h.maxX, y: h.minY),
           CGPoint(x: h.maxX, y: h.maxY), CGPoint(x: h.minX, y: h.maxY)]
    hatch(ctx, clip: polyPath(shape), tone: 0.60, baseAngle: 0.42)
    hatch(ctx, clip: rectPath(CGRect(x: h.minX, y: h.maxY - h.height * 0.22,
                                     width: h.width * 0.8, height: h.height * 0.22)),
          tone: 0.12, baseAngle: 0.1)
    taperedOutline(ctx, shape, weight: 2.4, lightAngle: 2.3)
    // Eye.
    let eye = CGRect(x: h.minX + h.width * 0.30, y: h.minY + h.height * 0.26,
                     width: h.width * 0.15, height: h.height * 0.48)
    hatch(ctx, clip: ellipsePath(eye), tone: 0.94, baseAngle: 0.9)
    // Handle as a wooden cylinder.
    let from = CGPoint(x: eye.midX, y: eye.midY)
    var spine: [CGPoint] = []
    var half: [CGFloat] = []
    for i in 0...16 {
        let f = CGFloat(i) / 16
        spine.append(CGPoint(x: from.x + (handleTo.x - from.x) * f,
                             y: from.y + (handleTo.y - from.y) * f))
        half.append(h.height * (0.20 + f * 0.06))
    }
    engraveCylinder(ctx, spine: spine, half: half, tone: 0.72, lightFrom: -0.4, lines: 14)
}

func drawTongs(_ ctx: CGContext, jaw: CGPoint, tail: CGPoint, open: CGFloat) {
    for side in [CGFloat(-1), CGFloat(1)] {
        var spine: [CGPoint] = []
        var half: [CGFloat] = []
        for i in 0...20 {
            let f = CGFloat(i) / 20
            let mid = CGPoint(x: (jaw.x + tail.x) / 2, y: (jaw.y + tail.y) / 2 + side * open * 2.2)
            let a = CGPoint(x: jaw.x, y: jaw.y + side * open)
            let x = pow(1 - f, 2) * a.x + 2 * (1 - f) * f * mid.x + f * f * tail.x
            let y = pow(1 - f, 2) * a.y + 2 * (1 - f) * f * mid.y + f * f * tail.y
            spine.append(CGPoint(x: x, y: y))
            half.append(7 - f * 2)
        }
        engraveCylinder(ctx, spine: spine, half: half, tone: 0.80, lines: 8)
    }
    let r: CGFloat = 11
    let rivet = CGRect(x: jaw.x + (tail.x - jaw.x) * 0.24 - r,
                       y: jaw.y + (tail.y - jaw.y) * 0.24 - r, width: r * 2, height: r * 2)
    hatch(ctx, clip: ellipsePath(rivet), tone: 0.66, baseAngle: 0.5)
}

/// A hot bar: the cylinder plus the light it throws.
func drawHotBar(_ ctx: CGContext, from a: CGPoint, to b: CGPoint,
                halfA: CGFloat, halfB: CGFloat, glowAt: CGFloat = 1.0, glowSize: CGFloat = 190) {
    var spine: [CGPoint] = []
    var half: [CGFloat] = []
    for i in 0...30 {
        let f = CGFloat(i) / 30
        spine.append(CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f))
        half.append(halfA + (halfB - halfA) * f)
    }
    // Hot steel is bright, so it carries less ink than cold iron.
    engraveCylinder(ctx, spine: spine, half: half, tone: 0.52, lightFrom: -0.5, lines: 22)
    let g = CGPoint(x: a.x + (b.x - a.x) * glowAt, y: a.y + (b.y - a.y) * glowAt)
    engraveRadiance(ctx, at: g, inner: max(14, halfB * 1.5), outer: glowSize, rays: 120, bias: 1)
}

func drawTub(_ ctx: CGContext, _ r: CGRect, liquidTone: CGFloat) {
    let body = [CGPoint(x: r.minX + r.width * 0.06, y: r.minY),
                CGPoint(x: r.maxX - r.width * 0.06, y: r.minY),
                CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)]
    hatch(ctx, clip: polyPath(body), tone: 0.34, baseAngle: 1.5, wobble: 1.8)
    taperedOutline(ctx, body, weight: 2.3, lightAngle: 2.3)
    // Staves and iron bands.
    ctx.setStrokeColor(engColor(inkBlack, 0.45))
    for i in 1..<7 {
        let f = CGFloat(i) / 7
        ctx.setLineWidth(0.9)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: r.minX + r.width * f, y: r.maxY))
        ctx.addLine(to: CGPoint(x: r.minX + r.width * 0.06 + r.width * 0.88 * f, y: r.minY))
        ctx.strokePath()
    }
    for f in [CGFloat(0.28), CGFloat(0.72)] {
        let y = r.minY + r.height * f
        let inset = r.width * 0.06 * (1 - f)
        ctx.setLineWidth(4.5)
        ctx.setStrokeColor(engColor(inkBlack, 0.72))
        ctx.beginPath()
        ctx.move(to: CGPoint(x: r.minX + inset, y: y))
        ctx.addLine(to: CGPoint(x: r.maxX - inset, y: y))
        ctx.strokePath()
    }
    // Liquid surface.
    let lip = CGRect(x: r.minX + r.width * 0.08, y: r.maxY - r.height * 0.10,
                     width: r.width * 0.84, height: r.height * 0.13)
    hatch(ctx, clip: ellipsePath(lip), tone: liquidTone, baseAngle: 0.06)
    taperedOutline(ctx, [CGPoint(x: lip.minX, y: lip.midY), CGPoint(x: lip.midX, y: lip.maxY),
                         CGPoint(x: lip.maxX, y: lip.midY), CGPoint(x: lip.midX, y: lip.minY)],
                   weight: 1.6, lightAngle: 2.3)
}

func drawBrick(_ ctx: CGContext, _ r: CGRect, cols: Int, rows: Int, tone: CGFloat) {
    hatch(ctx, clip: rectPath(r), tone: tone, baseAngle: 0.30)
    ctx.setStrokeColor(engColor(inkBlack, 0.55))
    ctx.setLineWidth(1.5)
    let bh = r.height / CGFloat(rows)
    for i in 0...rows {
        let y = r.minY + CGFloat(i) * bh
        ctx.beginPath()
        ctx.move(to: CGPoint(x: r.minX, y: y))
        ctx.addLine(to: CGPoint(x: r.maxX, y: y))
        ctx.strokePath()
    }
    let bw = r.width / CGFloat(cols)
    for row in 0..<rows {
        let off: CGFloat = row % 2 == 0 ? 0 : bw / 2
        for c in 0...cols {
            let x = r.minX + CGFloat(c) * bw + off
            guard x > r.minX, x < r.maxX else { continue }
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x, y: r.minY + CGFloat(row) * bh))
            ctx.addLine(to: CGPoint(x: x, y: r.minY + CGFloat(row + 1) * bh))
            ctx.strokePath()
        }
    }
}

func drawBench(_ ctx: CGContext, _ r: CGRect) {
    hatch(ctx, clip: rectPath(r), tone: 0.30, baseAngle: 0.06, wobble: 2.6)
    taperedOutline(ctx, [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY),
                         CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)],
                   weight: 2.4, lightAngle: 2.3)
    ctx.setStrokeColor(engColor(inkBlack, 0.34))
    for _ in 0..<22 {
        let y = eRnd(r.minY + 4, r.maxY - 4)
        ctx.setLineWidth(eRnd(0.5, 1.3))
        ctx.beginPath()
        ctx.move(to: CGPoint(x: eRnd(r.minX, r.midX), y: y))
        ctx.addLine(to: CGPoint(x: eRnd(r.midX, r.maxX), y: y + eRnd(-2, 2)))
        ctx.strokePath()
    }
}

func leaderLine(_ ctx: CGContext, from a: CGPoint, to b: CGPoint) {
    ctx.setStrokeColor(engColor(inkBlack, 0.62))
    ctx.setLineWidth(1.2)
    ctx.beginPath(); ctx.move(to: a); ctx.addLine(to: b); ctx.strokePath()
    ctx.setFillColor(engColor(inkBlack, 0.72))
    ctx.fillEllipse(in: CGRect(x: b.x - 4, y: b.y - 4, width: 8, height: 8))
    // A small serifed tick at the pointing end.
    ctx.setLineWidth(1.6)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: a.x - 7, y: a.y))
    ctx.addLine(to: CGPoint(x: a.x + 7, y: a.y))
    ctx.strokePath()
}

// MARK: - Guide plates

func plateHeat() {
    sheet("guide_heat", number: 1, seedValue: 101) { ctx, plate in
        setting(ctx, plate, groundY: plate.minY + 120, shadowWidth: 0.42)
        // A ladder of tone blocks: the heat scale, hottest at the top.
        for i in 0..<7 {
            let tone = CGFloat(i) * 0.13 + 0.06
            let y = plate.maxY - 96 - CGFloat(i) * (plate.height * 0.108)
            let r = CGRect(x: plate.maxX - plate.width * 0.30, y: y,
                           width: plate.width * 0.22, height: plate.height * 0.072)
            hatch(ctx, clip: rectPath(r), tone: tone, baseAngle: 0.55)
            taperedOutline(ctx, [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY),
                                 CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)],
                           weight: 1.7, lightAngle: 2.3)
            leaderLine(ctx, from: CGPoint(x: r.minX - 44, y: r.midY),
                       to: CGPoint(x: r.minX - 10, y: r.midY))
        }
        // The bar itself, gripped in tongs.
        let jaw = CGPoint(x: plate.minX + plate.width * 0.30, y: plate.midY + 26)
        drawHotBar(ctx, from: jaw, to: CGPoint(x: plate.minX + plate.width * 0.60, y: plate.midY + 12),
                   halfA: 28, halfB: 22, glowSize: 250)
        drawTongs(ctx, jaw: jaw, tail: CGPoint(x: plate.minX + 30, y: plate.midY + 120), open: 22)
    }
}

func plateCarbon() {
    sheet("guide_carbon", number: 2, seedValue: 202) { ctx, plate in
        setting(ctx, plate, groundY: plate.minY + 130, shadowWidth: 0.72)
        let densities: [CGFloat] = [0.10, 0.34, 0.72]
        for (i, d) in densities.enumerated() {
            let cx = plate.minX + plate.width * (0.22 + CGFloat(i) * 0.28)
            let bar = CGRect(x: cx - 118, y: plate.minY + plate.height * 0.24,
                             width: 236, height: plate.height * 0.40)
            hatch(ctx, clip: rectPath(bar), tone: 0.30, baseAngle: 1.5)
            taperedOutline(ctx, [CGPoint(x: bar.minX, y: bar.minY), CGPoint(x: bar.maxX, y: bar.minY),
                                 CGPoint(x: bar.maxX, y: bar.maxY), CGPoint(x: bar.minX, y: bar.maxY)],
                           weight: 2.5, lightAngle: 2.3)
            // The cut face, with carbon shown as stipple density.
            let face = CGRect(x: bar.minX, y: bar.maxY - 8, width: bar.width, height: 74)
            hatch(ctx, clip: rectPath(face), tone: 0.08, baseAngle: 0.2)
            stipple(ctx, clip: rectPath(face), tone: d, sizeRange: (1.1, 3.0))
            taperedOutline(ctx, [CGPoint(x: face.minX, y: face.minY), CGPoint(x: face.maxX, y: face.minY),
                                 CGPoint(x: face.maxX, y: face.maxY), CGPoint(x: face.minX, y: face.maxY)],
                           weight: 1.8, lightAngle: 2.3)
            // Spark test above: more carbon, more bursting sparks.
            for _ in 0..<(6 + i * 22) {
                let a = eRnd(0.6, 2.5)
                let len = eRnd(70, 240)
                let s = CGPoint(x: cx + eRnd(-80, 80), y: face.maxY + eRnd(16, 54))
                ctx.setStrokeColor(engColor(inkBlack, eRnd(0.25, 0.66)))
                ctx.setLineWidth(eRnd(0.5, 1.4))
                ctx.beginPath()
                ctx.move(to: s)
                ctx.addLine(to: CGPoint(x: s.x + cos(a) * len * 0.5, y: s.y + sin(a) * len))
                ctx.strokePath()
            }
        }
    }
}

func plateDrawing() {
    sheet("guide_drawing", number: 3, seedValue: 303) { ctx, plate in
        let ground = plate.minY + plate.height * 0.20
        setting(ctx, plate, groundY: ground)
        drawAnvil(ctx, at: CGPoint(x: plate.midX - 30, y: ground + 130), scale: 0.90)
        // Before: short and thick, above.
        var spine: [CGPoint] = []
        var half: [CGFloat] = []
        for i in 0...20 {
            let f = CGFloat(i) / 20
            spine.append(CGPoint(x: plate.minX + plate.width * (0.14 + f * 0.26),
                                 y: plate.maxY - plate.height * 0.20))
            half.append(46)
        }
        engraveCylinder(ctx, spine: spine, half: half, tone: 0.74, lines: 20)
        // After: long and tapered, on the anvil.
        drawHotBar(ctx, from: CGPoint(x: plate.minX + plate.width * 0.10, y: ground + 262),
                   to: CGPoint(x: plate.minX + plate.width * 0.78, y: ground + 254),
                   halfA: 42, halfB: 11, glowSize: 150)
        // A cross peen mid-blow.
        drawHammer(ctx, head: CGRect(x: plate.midX + 40, y: ground + 330, width: 214, height: 76),
                   handleTo: CGPoint(x: plate.midX + 40, y: plate.maxY - 30), peen: true)
        // Arrows: metal flows along the bar.
        for s in [CGFloat(-1), CGFloat(1)] {
            let y = ground + 120
            let x0 = plate.midX + 20
            ctx.setStrokeColor(engColor(inkBlack, 0.62))
            ctx.setLineWidth(2.4)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x0, y: y))
            ctx.addLine(to: CGPoint(x: x0 + s * plate.width * 0.15, y: y))
            ctx.strokePath()
            let tip = CGPoint(x: x0 + s * plate.width * 0.15, y: y)
            ctx.beginPath()
            ctx.move(to: tip)
            ctx.addLine(to: CGPoint(x: tip.x - s * 18, y: y + 11))
            ctx.addLine(to: CGPoint(x: tip.x - s * 18, y: y - 11))
            ctx.closePath()
            ctx.setFillColor(engColor(inkBlack, 0.7))
            ctx.fillPath()
        }
    }
}

func plateAnvil() {
    sheet("guide_anvil", number: 4, seedValue: 404) { ctx, plate in
        let ground = plate.minY + plate.height * 0.12
        setting(ctx, plate, groundY: ground, shadowWidth: 0.62)
        let c = CGPoint(x: plate.midX - 20, y: ground + 300)
        drawStump(ctx, under: c, scale: 1.05, groundY: ground)
        drawAnvil(ctx, at: c, scale: 1.05, showHoles: true)
        leaderLine(ctx, from: CGPoint(x: plate.maxX - 120, y: c.y + 90),
                   to: CGPoint(x: c.x + 250, y: c.y + 88))
        leaderLine(ctx, from: CGPoint(x: plate.minX + 90, y: c.y + 180),
                   to: CGPoint(x: c.x - 60, y: c.y + 126))
        leaderLine(ctx, from: CGPoint(x: plate.minX + 90, y: c.y - 60),
                   to: CGPoint(x: c.x - 140, y: c.y + 40))
        leaderLine(ctx, from: CGPoint(x: plate.maxX - 150, y: c.y - 90),
                   to: CGPoint(x: c.x - 132, y: c.y + 112))
    }
}

func plateHammers() {
    sheet("guide_hammers", number: 5, seedValue: 505) { ctx, plate in
        cornerWash(ctx, plate, corner: 0, tone: 0.20, reach: 0.42)
        cornerWash(ctx, plate, corner: 1, tone: 0.16, reach: 0.38, angle: -0.34)
        let railY = plate.maxY - plate.height * 0.14
        let rail = CGRect(x: plate.minX + 40, y: railY, width: plate.width - 80, height: 26)
        drawBench(ctx, rail)
        let widths: [CGFloat] = [150, 196, 232, 200, 168]
        for i in 0..<5 {
            let cx = plate.minX + plate.width * (0.15 + CGFloat(i) * 0.175)
            let hw = widths[i]
            let head = CGRect(x: cx - hw / 2, y: railY - plate.height * 0.44,
                              width: hw, height: 86)
            drawHammer(ctx, head: head, handleTo: CGPoint(x: cx + eRnd(-6, 6), y: railY),
                       peen: i % 2 == 1)
        }
    }
}

func plateFuller() {
    sheet("guide_fuller", number: 6, seedValue: 606) { ctx, plate in
        let ground = plate.minY + plate.height * 0.14
        setting(ctx, plate, groundY: ground)
        drawAnvil(ctx, at: CGPoint(x: plate.midX - 60, y: ground + 150), scale: 0.95)
        // A bar with a groove sunk into it: thick, waisted, thick again.
        let y = ground + 300
        drawHotBar(ctx, from: CGPoint(x: plate.minX + plate.width * 0.10, y: y),
                   to: CGPoint(x: plate.midX - 10, y: y), halfA: 44, halfB: 40, glowAt: 0, glowSize: 80)
        drawHotBar(ctx, from: CGPoint(x: plate.midX - 10, y: y),
                   to: CGPoint(x: plate.midX + 60, y: y), halfA: 40, halfB: 17, glowAt: 1, glowSize: 170)
        drawHotBar(ctx, from: CGPoint(x: plate.midX + 60, y: y),
                   to: CGPoint(x: plate.maxX - plate.width * 0.08, y: y),
                   halfA: 17, halfB: 15, glowAt: 0, glowSize: 60)
        // The fuller sitting in the groove.
        let fx = plate.midX + 26
        var spine: [CGPoint] = []
        var half: [CGFloat] = []
        for i in 0...14 {
            let f = CGFloat(i) / 14
            spine.append(CGPoint(x: fx, y: y + 56 + f * (plate.height * 0.30)))
            half.append(30 - f * 6)
        }
        engraveCylinder(ctx, spine: spine, half: half, tone: 0.76, lines: 16)
        let nose = CGRect(x: fx - 42, y: y + 22, width: 84, height: 54)
        hatch(ctx, clip: ellipsePath(nose), tone: 0.52, baseAngle: 0.3)
        taperedOutline(ctx, (0..<24).map { i -> CGPoint in
            let a = CGFloat(i) / 24 * 6.283
            return CGPoint(x: nose.midX + cos(a) * nose.width / 2,
                           y: nose.midY + sin(a) * nose.height / 2)
        }, weight: 2.0, lightAngle: 2.3)
    }
}

func platePunching() {
    sheet("guide_punching", number: 7, seedValue: 707) { ctx, plate in
        let ground = plate.minY + plate.height * 0.12
        setting(ctx, plate, groundY: ground)
        drawAnvil(ctx, at: CGPoint(x: plate.midX - 40, y: ground + 140), scale: 0.95, showHoles: true)
        let y = ground + 292
        drawHotBar(ctx, from: CGPoint(x: plate.minX + plate.width * 0.08, y: y),
                   to: CGPoint(x: plate.maxX - plate.width * 0.14, y: y),
                   halfA: 48, halfB: 44, glowAt: 0.42, glowSize: 210)
        // The punch driven in.
        let px = plate.minX + plate.width * 0.42
        let punch = [CGPoint(x: px - 34, y: plate.maxY - 40), CGPoint(x: px + 34, y: plate.maxY - 40),
                     CGPoint(x: px + 19, y: y + 6), CGPoint(x: px - 19, y: y + 6)]
        hatch(ctx, clip: polyPath(punch), tone: 0.58, baseAngle: 1.4)
        hatch(ctx, clip: polyPath([CGPoint(x: px - 30, y: plate.maxY - 40),
                                   CGPoint(x: px - 12, y: plate.maxY - 40),
                                   CGPoint(x: px - 6, y: y + 6), CGPoint(x: px - 17, y: y + 6)]),
              tone: 0.10, baseAngle: 1.4)
        taperedOutline(ctx, punch, weight: 2.6, lightAngle: 2.3)
        // A drift lying beside it.
        let dx = plate.maxX - plate.width * 0.20
        var ds: [CGPoint] = []
        var dh: [CGFloat] = []
        for i in 0...16 {
            let f = CGFloat(i) / 16
            ds.append(CGPoint(x: dx - 150 + f * 300, y: ground + 96 + sin(f * 3) * 3))
            dh.append(12 + sin(f * 3.14) * 18)
        }
        engraveCylinder(ctx, spine: ds, half: dh, tone: 0.74, lines: 16)
    }
}

func plateQuench() {
    sheet("guide_quench", number: 8, seedValue: 808) { ctx, plate in
        let ground = plate.minY + plate.height * 0.10
        setting(ctx, plate, groundY: ground, shadowWidth: 0.86)
        let tones: [CGFloat] = [0.10, 0.62, 0.34, 0.24]
        for i in 0..<4 {
            let cx = plate.minX + plate.width * (0.15 + CGFloat(i) * 0.235)
            drawTub(ctx, CGRect(x: cx - 132, y: ground, width: 264, height: plate.height * 0.40),
                    liquidTone: tones[i])
        }
        // A blade going into the third tub, throwing steam.
        let bx = plate.minX + plate.width * 0.62
        drawHotBar(ctx, from: CGPoint(x: bx + 40, y: plate.maxY - 60),
                   to: CGPoint(x: bx - 20, y: ground + plate.height * 0.30),
                   halfA: 15, halfB: 34, glowAt: 1, glowSize: 210)
        stipple(ctx, clip: ellipsePath(CGRect(x: bx - 190, y: ground + plate.height * 0.22,
                                              width: 380, height: plate.height * 0.62)),
                tone: 0.11, sizeRange: (1.0, 3.4))
    }
}

func plateTemper() {
    sheet("guide_temper", number: 9, seedValue: 909) { ctx, plate in
        cornerWash(ctx, plate, corner: 0, tone: 0.18, reach: 0.40)
        cornerWash(ctx, plate, corner: 1, tone: 0.14, reach: 0.36, angle: -0.34)
        // A blade whose oxide colours run along it, shown as a tone ramp.
        let y = plate.minY + plate.height * 0.40
        let x0 = plate.minX + plate.width * 0.06
        let x1 = plate.maxX - plate.width * 0.06
        let bands = 30
        for i in 0..<bands {
            let f = CGFloat(i) / CGFloat(bands - 1)
            let th = 54 - f * 24
            let r = CGRect(x: x0 + (x1 - x0) * f, y: y - th, width: (x1 - x0) / CGFloat(bands) + 2,
                           height: th * 2)
            hatch(ctx, clip: rectPath(r), tone: 0.08 + pow(f, 1.3) * 0.72, baseAngle: 1.5)
        }
        taperedOutline(ctx, [CGPoint(x: x0, y: y - 54), CGPoint(x: x1, y: y - 30),
                             CGPoint(x: x1 + 40, y: y), CGPoint(x: x1, y: y + 30),
                             CGPoint(x: x0, y: y + 54)], weight: 2.4, lightAngle: 2.3)
        // Four swatch squares above, from pale to deep.
        for i in 0..<4 {
            let r = CGRect(x: plate.minX + plate.width * (0.12 + CGFloat(i) * 0.20),
                           y: plate.maxY - plate.height * 0.30,
                           width: plate.width * 0.13, height: plate.height * 0.16)
            hatch(ctx, clip: rectPath(r), tone: 0.14 + CGFloat(i) * 0.22, baseAngle: 0.62)
            taperedOutline(ctx, [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY),
                                 CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)],
                           weight: 1.8, lightAngle: 2.3)
            leaderLine(ctx, from: CGPoint(x: r.midX, y: r.minY - 12),
                       to: CGPoint(x: r.midX, y: y + 70))
        }
    }
}

func plateScale() {
    sheet("guide_scale", number: 10, seedValue: 1010) { ctx, plate in
        setting(ctx, plate, groundY: plate.minY + 120, shadowWidth: 0.5)
        // Two scarfed bars meeting at a welding heat.
        drawHotBar(ctx, from: CGPoint(x: plate.minX + plate.width * 0.04, y: plate.midY - 40),
                   to: CGPoint(x: plate.midX, y: plate.midY), halfA: 44, halfB: 22,
                   glowAt: 1, glowSize: 300)
        drawHotBar(ctx, from: CGPoint(x: plate.maxX - plate.width * 0.04, y: plate.midY - 40),
                   to: CGPoint(x: plate.midX, y: plate.midY), halfA: 44, halfB: 22,
                   glowAt: 1, glowSize: 300)
        engraveRadiance(ctx, at: CGPoint(x: plate.midX, y: plate.midY), inner: 40, outer: 420,
                        rays: 190, bias: 1)
        // Flakes of scale spinning off.
        for _ in 0..<90 {
            let x = eRnd(plate.minX + 120, plate.maxX - 120)
            let yy = eRnd(plate.midY + 30, plate.maxY - 40)
            ctx.saveGState()
            ctx.translateBy(x: x, y: yy)
            ctx.rotate(by: eRnd(0, 6.283))
            let f = CGRect(x: -eRnd(7, 20), y: -eRnd(3, 9), width: eRnd(14, 40), height: eRnd(6, 17))
            hatch(ctx, clip: rectPath(f), tone: 0.72, baseAngle: 0.5)
            ctx.restoreGState()
        }
    }
}

func plateBending() {
    sheet("guide_bending", number: 11, seedValue: 1111) { ctx, plate in
        let ground = plate.minY + plate.height * 0.14
        setting(ctx, plate, groundY: ground)
        drawAnvil(ctx, at: CGPoint(x: plate.minX + plate.width * 0.26, y: ground + 150), scale: 0.85)
        // A bar bent over the far edge.
        var spine: [CGPoint] = []
        var half: [CGFloat] = []
        for i in 0...26 {
            let f = CGFloat(i) / 26
            let bend = max(0, (f - 0.55) / 0.45)
            spine.append(CGPoint(x: plate.minX + plate.width * (0.08 + f * 0.34) + bend * 40,
                                 y: ground + 268 + pow(bend, 1.6) * plate.height * 0.40))
            half.append(26 - f * 4)
        }
        engraveCylinder(ctx, spine: spine, half: half, tone: 0.66, lines: 16)
        // A finished scroll on the right.
        let cx = plate.maxX - plate.width * 0.22, cy = plate.midY + 20
        var sp: [CGPoint] = []
        var sh: [CGFloat] = []
        var a: CGFloat = 0, r: CGFloat = 210
        while r > 16 {
            sp.append(CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r))
            sh.append(16)
            a += 0.14
            r *= 0.976
        }
        engraveCylinder(ctx, spine: sp, half: sh, tone: 0.72, lines: 10)
    }
}

func plateHistory() {
    sheet("guide_history", number: 12, seedValue: 1212) { ctx, plate in
        // A night sky rendered in stipple, the way engravers did darkness.
        stipple(ctx, clip: rectPath(CGRect(x: plate.minX, y: plate.midY,
                                           width: plate.width, height: plate.maxY - plate.midY)),
                tone: 0.30, sizeRange: (0.7, 2.0))
        hatchRamp(ctx, clip: rectPath(CGRect(x: plate.minX, y: plate.midY + plate.height * 0.14,
                                             width: plate.width, height: plate.height * 0.32)),
                  from: 0.06, to: 0.34, vertical: true, baseAngle: 0.1)
        // Hills.
        let hills = [CGPoint(x: plate.minX, y: plate.minY),
                     CGPoint(x: plate.minX, y: plate.midY - 30),
                     CGPoint(x: plate.midX - 200, y: plate.midY + 40),
                     CGPoint(x: plate.midX + 260, y: plate.midY - 60),
                     CGPoint(x: plate.maxX, y: plate.midY + 10),
                     CGPoint(x: plate.maxX, y: plate.minY)]
        hatch(ctx, clip: polyPath(hills), tone: 0.44, baseAngle: -0.24)
        taperedOutline(ctx, hills, weight: 2.0, lightAngle: 2.3)
        // The smithy, with its door throwing light.
        let hut = CGRect(x: plate.minX + plate.width * 0.20, y: plate.midY - 40, width: 330, height: 190)
        hatch(ctx, clip: rectPath(hut), tone: 0.66, baseAngle: 1.5)
        let roof = [CGPoint(x: hut.minX - 40, y: hut.maxY), CGPoint(x: hut.midX, y: hut.maxY + 120),
                    CGPoint(x: hut.maxX + 40, y: hut.maxY)]
        hatch(ctx, clip: polyPath(roof), tone: 0.72, baseAngle: 0.9)
        taperedOutline(ctx, roof, weight: 2.2, lightAngle: 2.3)
        let door = CGRect(x: hut.midX - 48, y: hut.minY, width: 96, height: 128)
        hatch(ctx, clip: rectPath(door), tone: 0.05, baseAngle: 0.2)
        engraveRadiance(ctx, at: CGPoint(x: door.midX, y: door.midY), inner: 62, outer: 300, rays: 140)
        // The meteor: iron that fell out of the sky.
        let m = CGPoint(x: plate.maxX - plate.width * 0.22, y: plate.maxY - plate.height * 0.16)
        engraveRadiance(ctx, at: m, inner: 16, outer: 150, rays: 90)
        ctx.setStrokeColor(engColor(inkBlack, 0.62))
        for k in 0..<7 {
            ctx.setLineWidth(2.6 - CGFloat(k) * 0.3)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: m.x + CGFloat(k) * 34, y: m.y - CGFloat(k) * 22))
            ctx.addLine(to: CGPoint(x: m.x + CGFloat(k + 1) * 34, y: m.y - CGFloat(k + 1) * 22))
            ctx.strokePath()
        }
    }
}

// MARK: - Chapter plates

func chapterFirst() {
    sheet("chapter_first", number: 1, seedValue: 2001) { ctx, plate in
        let benchY = plate.minY + plate.height * 0.24
        setting(ctx, plate, groundY: benchY, shadowWidth: 0.8)
        drawBench(ctx, CGRect(x: plate.minX + 30, y: benchY, width: plate.width - 60,
                              height: plate.height * 0.13))
        // Nails scattered on it.
        for _ in 0..<16 {
            let x = eRnd(plate.minX + 90, plate.maxX - 90)
            let y = benchY + plate.height * 0.13 + eRnd(4, 26)
            let ang = eRnd(-0.4, 0.4)
            let len = eRnd(70, 150)
            var sp: [CGPoint] = []
            var sh: [CGFloat] = []
            for i in 0...10 {
                let f = CGFloat(i) / 10
                sp.append(CGPoint(x: x + cos(ang) * len * f, y: y + sin(ang) * len * f))
                sh.append(9 - f * 7)
            }
            engraveCylinder(ctx, spine: sp, half: sh, tone: 0.78, lines: 7)
            hatch(ctx, clip: ellipsePath(CGRect(x: x - 15, y: y - 10, width: 30, height: 20)),
                  tone: 0.62, baseAngle: 0.4)
        }
        // S hooks hanging above.
        for i in 0..<3 {
            let cx = plate.minX + plate.width * (0.28 + CGFloat(i) * 0.22)
            let cy = plate.maxY - plate.height * 0.30
            var sp: [CGPoint] = []
            var sh: [CGFloat] = []
            for k in 0...30 {
                let f = CGFloat(k) / 30
                let a = 2.3 + f * 3.4
                let side: CGFloat = f < 0.5 ? 1 : -1
                let r: CGFloat = 74
                sp.append(CGPoint(x: cx + cos(a) * r, y: cy + side * 74 + sin(a) * r * side))
                sh.append(11)
            }
            engraveCylinder(ctx, spine: sp, half: sh, tone: 0.74, lines: 8)
        }
    }
}

func chapterTools() {
    sheet("chapter_tools", number: 2, seedValue: 2002) { ctx, plate in
        cornerWash(ctx, plate, corner: 0, tone: 0.20, reach: 0.44)
        cornerWash(ctx, plate, corner: 1, tone: 0.16, reach: 0.38, angle: -0.34)
        let railY = plate.minY + plate.height * 0.16
        drawBench(ctx, CGRect(x: plate.minX + 40, y: railY, width: plate.width - 80, height: 30))
        for i in 0..<7 {
            let cx = plate.minX + plate.width * (0.11 + CGFloat(i) * 0.13)
            let kind = i % 3
            if kind == 0 {
                drawHammer(ctx, head: CGRect(x: cx - 82, y: railY + plate.height * 0.42,
                                             width: 164, height: 76),
                           handleTo: CGPoint(x: cx, y: railY + 40), peen: i % 2 == 0)
            } else {
                // A punch or a chisel: a tapered square bar.
                var sp: [CGPoint] = []
                var sh: [CGFloat] = []
                for k in 0...16 {
                    let f = CGFloat(k) / 16
                    sp.append(CGPoint(x: cx, y: railY + 40 + f * plate.height * 0.46))
                    sh.append(kind == 1 ? 15 + f * 12 : 34 - f * 12)
                }
                engraveCylinder(ctx, spine: sp, half: sh, tone: 0.74, lines: 14)
            }
        }
    }
}

func chapterHearth() {
    sheet("chapter_hearth", number: 3, seedValue: 2003) { ctx, plate in
        let ground = plate.minY + plate.height * 0.10
        setting(ctx, plate, groundY: ground, shadowWidth: 0.7)
        drawBrick(ctx, CGRect(x: plate.minX, y: ground, width: plate.width * 0.52,
                              height: plate.height * 0.66), cols: 7, rows: 6, tone: 0.26)
        let mouth = CGRect(x: plate.minX + plate.width * 0.06, y: ground + 40,
                           width: plate.width * 0.34, height: plate.height * 0.40)
        hatch(ctx, clip: rectPath(mouth), tone: 0.06, baseAngle: 0.2)
        taperedOutline(ctx, [CGPoint(x: mouth.minX, y: mouth.minY), CGPoint(x: mouth.maxX, y: mouth.minY),
                             CGPoint(x: mouth.maxX, y: mouth.maxY), CGPoint(x: mouth.minX, y: mouth.maxY)],
                       weight: 2.6, lightAngle: 2.3)
        engraveRadiance(ctx, at: CGPoint(x: mouth.midX, y: mouth.minY + 70), inner: 46,
                        outer: 420, rays: 190, bias: 1)
        // The fireside set leaning to the right.
        for i in 0..<4 {
            let x = plate.minX + plate.width * (0.60 + CGFloat(i) * 0.09)
            var sp: [CGPoint] = []
            var sh: [CGFloat] = []
            for k in 0...20 {
                let f = CGFloat(k) / 20
                sp.append(CGPoint(x: x + f * 76, y: ground + 30 + f * plate.height * 0.66))
                sh.append(11)
            }
            engraveCylinder(ctx, spine: sp, half: sh, tone: 0.72, lines: 8)
            // A curled handle at the top.
            var cs: [CGPoint] = []
            var ch: [CGFloat] = []
            var a: CGFloat = 1.1
            var r: CGFloat = 46
            while a < 5.6 {
                cs.append(CGPoint(x: x + 76 + cos(a) * r, y: ground + 30 + plate.height * 0.66 + sin(a) * r))
                ch.append(10)
                a += 0.2; r *= 0.985
            }
            engraveCylinder(ctx, spine: cs, half: ch, tone: 0.70, lines: 7)
        }
    }
}

func chapterOrnament() {
    sheet("chapter_ornament", number: 4, seedValue: 2004) { ctx, plate in
        cornerWash(ctx, plate, corner: 0, tone: 0.18, reach: 0.42)
        cornerWash(ctx, plate, corner: 3, tone: 0.16, reach: 0.38, angle: -0.3)
        func scroll(_ cx: CGFloat, _ cy: CGFloat, _ r0: CGFloat, _ flip: CGFloat, _ th: CGFloat) {
            var sp: [CGPoint] = []
            var sh: [CGFloat] = []
            var a: CGFloat = 0, r = r0
            while r > 12 {
                sp.append(CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r * flip))
                sh.append(th)
                a += 0.13; r *= 0.974
            }
            engraveCylinder(ctx, spine: sp, half: sh, tone: 0.72, lines: 9)
        }
        scroll(plate.minX + plate.width * 0.24, plate.midY - 40, 190, 1, 13)
        scroll(plate.midX + 20, plate.midY + 60, 220, -1, 14)
        scroll(plate.maxX - plate.width * 0.22, plate.midY - 30, 170, 1, 12)
        // A twisted bar running across.
        var sp: [CGPoint] = []
        var sh: [CGFloat] = []
        for i in 0...40 {
            let f = CGFloat(i) / 40
            sp.append(CGPoint(x: plate.minX + 40 + f * (plate.width - 80),
                              y: plate.maxY - plate.height * 0.20))
            sh.append(19)
        }
        engraveCylinder(ctx, spine: sp, half: sh, tone: 0.66, lines: 14)
        ctx.setStrokeColor(engColor(inkBlack, 0.62))
        for i in 0..<30 {
            let x = plate.minX + plate.width * (0.30 + CGFloat(i) * 0.014)
            ctx.setLineWidth(1.6)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x, y: plate.maxY - plate.height * 0.20 - 18))
            ctx.addLine(to: CGPoint(x: x + 15, y: plate.maxY - plate.height * 0.20 + 18))
            ctx.strokePath()
        }
    }
}

func chapterMaster() {
    sheet("chapter_master", number: 5, seedValue: 2005) { ctx, plate in
        let benchY = plate.minY + plate.height * 0.18
        setting(ctx, plate, groundY: benchY, shadowWidth: 0.86)
        drawBench(ctx, CGRect(x: plate.minX + 24, y: benchY, width: plate.width - 48,
                              height: plate.height * 0.16))
        let top = benchY + plate.height * 0.16
        // An axe head: a wedge with a drifted eye.
        let ax = plate.minX + plate.width * 0.30
        let axe = [CGPoint(x: ax - 190, y: top + 40), CGPoint(x: ax - 190, y: top + 200),
                   CGPoint(x: ax - 60, y: top + 214), CGPoint(x: ax + 130, y: top + 262),
                   CGPoint(x: ax + 226, y: top + 150), CGPoint(x: ax + 130, y: top + 24),
                   CGPoint(x: ax - 60, y: top + 28)]
        hatch(ctx, clip: polyPath(axe), tone: 0.48, baseAngle: 0.55)
        hatch(ctx, clip: polyPath([CGPoint(x: ax + 150, y: top + 40), CGPoint(x: ax + 226, y: top + 150),
                                   CGPoint(x: ax + 150, y: top + 250)]), tone: 0.10, baseAngle: 0.2)
        taperedOutline(ctx, axe, weight: 2.8, lightAngle: 2.35)
        let eye = CGRect(x: ax - 150, y: top + 88, width: 96, height: 116)
        hatch(ctx, clip: ellipsePath(eye), tone: 0.92, baseAngle: 0.7)
        // A pattern-welded blade beside it.
        let bx = plate.maxX - plate.width * 0.28
        var sp: [CGPoint] = []
        var sh: [CGFloat] = []
        for i in 0...30 {
            let f = CGFloat(i) / 30
            sp.append(CGPoint(x: bx - 300 + f * 600, y: top + 110))
            sh.append(f < 0.22 ? 14 : 46 - pow((f - 0.22) / 0.78, 2) * 42)
        }
        engraveCylinder(ctx, spine: sp, half: sh, tone: 0.54, lines: 22)
        // The pattern in the steel.
        ctx.setStrokeColor(engColor(inkBlack, 0.36))
        for i in 0..<40 {
            let x = bx - 230 + CGFloat(i) * 14
            ctx.setLineWidth(eRnd(0.7, 2.0))
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x, y: top + 66))
            ctx.addCurve(to: CGPoint(x: x + 12, y: top + 154),
                         control1: CGPoint(x: x + eRnd(-16, 16), y: top + 96),
                         control2: CGPoint(x: x + eRnd(-16, 16), y: top + 126))
            ctx.strokePath()
        }
    }
}

// MARK: - Onboarding plates

func onboardFire() {
    sheet("onboard_fire", number: 1, seedValue: 3001) { ctx, plate in
        drawBrick(ctx, CGRect(x: plate.minX, y: plate.minY, width: plate.width,
                              height: plate.height * 0.46), cols: 10, rows: 4, tone: 0.22)
        let bed = CGRect(x: plate.minX + plate.width * 0.16, y: plate.minY + plate.height * 0.24,
                         width: plate.width * 0.68, height: plate.height * 0.30)
        hatch(ctx, clip: ellipsePath(bed), tone: 0.10, baseAngle: 0.3)
        engraveRadiance(ctx, at: CGPoint(x: bed.midX, y: bed.midY), inner: 60,
                        outer: plate.width * 0.44, rays: 220, bias: 1)
        // Lumps of coal around the heart of the fire.
        for _ in 0..<44 {
            let a = eRnd(0, 6.283)
            let rr = eRnd(0.30, 1.0)
            let c = CGPoint(x: bed.midX + cos(a) * bed.width * 0.46 * rr,
                            y: bed.midY + sin(a) * bed.height * 0.46 * rr)
            let s = eRnd(16, 46)
            hatch(ctx, clip: ellipsePath(CGRect(x: c.x - s / 2, y: c.y - s / 2 * 0.8,
                                                width: s, height: s * 0.8)),
                  tone: 0.62 + rr * 0.28, baseAngle: eRnd(0, 1.5))
        }
        drawHotBar(ctx, from: CGPoint(x: plate.minX + plate.width * 0.06, y: bed.midY - 20),
                   to: CGPoint(x: bed.midX + 60, y: bed.midY + 10),
                   halfA: 26, halfB: 26, glowAt: 1, glowSize: 230)
        // Sparks going up.
        for _ in 0..<70 {
            let x = bed.midX + eRnd(-plate.width * 0.30, plate.width * 0.30)
            let y = eRnd(bed.maxY - 30, plate.maxY - 20)
            let r = eRnd(1.6, 4.4)
            ctx.setFillColor(engColor(inkBlack, eRnd(0.2, 0.6)))
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r))
        }
    }
}

func onboardStrike() {
    sheet("onboard_strike", number: 2, seedValue: 3002) { ctx, plate in
        let ground = plate.minY + plate.height * 0.10
        setting(ctx, plate, groundY: ground)
        drawAnvil(ctx, at: CGPoint(x: plate.midX - 60, y: ground + 150), scale: 1.0)
        drawHotBar(ctx, from: CGPoint(x: plate.minX + plate.width * 0.08, y: ground + 300),
                   to: CGPoint(x: plate.maxX - plate.width * 0.10, y: ground + 296),
                   halfA: 40, halfB: 20, glowAt: 0.5, glowSize: 260)
        drawHammer(ctx, head: CGRect(x: plate.midX - 140, y: ground + 380, width: 280, height: 96),
                   handleTo: CGPoint(x: plate.midX - 210, y: plate.maxY - 26), peen: false)
        // Sparks flying from the blow.
        for _ in 0..<120 {
            let a = eRnd(0.2, 2.94)
            let d = eRnd(30, 330)
            let p = CGPoint(x: plate.midX + cos(a) * d, y: ground + 300 + sin(a) * d * 0.8)
            ctx.setStrokeColor(engColor(inkBlack, eRnd(0.25, 0.7)))
            ctx.setLineWidth(eRnd(0.6, 1.8))
            ctx.beginPath()
            ctx.move(to: p)
            ctx.addLine(to: CGPoint(x: p.x + cos(a) * 22, y: p.y + sin(a) * 22))
            ctx.strokePath()
        }
    }
}

func onboardShape() {
    sheet("onboard_shape", number: 3, seedValue: 3003) { ctx, plate in
        // A technical drawing: the plate is the drawing.
        let y = plate.midY
        let x0 = plate.minX + plate.width * 0.08
        let x1 = plate.maxX - plate.width * 0.14
        // The outline of a hooked, tapered bar, drawn in fine line only.
        ctx.setStrokeColor(engColor(inkBlack, 0.9))
        ctx.setLineWidth(2.6)
        for s in [CGFloat(-1), CGFloat(1)] {
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x0, y: y + s * 52))
            ctx.addLine(to: CGPoint(x: x1 - 260, y: y + s * 34))
            ctx.addQuadCurve(to: CGPoint(x: x1, y: y + s * 130),
                             control: CGPoint(x: x1 + 60, y: y + s * 20))
            ctx.strokePath()
        }
        // Centre line, dashed the way a draughtsman would.
        ctx.setStrokeColor(engColor(inkBlack, 0.45))
        ctx.setLineWidth(1.2)
        var x = x0 - 30
        while x < x1 + 40 {
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x, y: y))
            ctx.addLine(to: CGPoint(x: x + 22, y: y))
            ctx.strokePath()
            x += 34
        }
        // Dimension arrows underneath.
        for i in 0..<4 {
            let dx0 = x0 + (x1 - x0) * CGFloat(i) / 4
            let dx1 = x0 + (x1 - x0) * CGFloat(i + 1) / 4
            let dy = y - plate.height * (0.22 + CGFloat(i % 2) * 0.06)
            ctx.setStrokeColor(engColor(inkBlack, 0.6))
            ctx.setLineWidth(1.4)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: dx0, y: dy)); ctx.addLine(to: CGPoint(x: dx1, y: dy))
            ctx.move(to: CGPoint(x: dx0, y: dy - 12)); ctx.addLine(to: CGPoint(x: dx0, y: dy + 12))
            ctx.move(to: CGPoint(x: dx1, y: dy - 12)); ctx.addLine(to: CGPoint(x: dx1, y: dy + 12))
            ctx.strokePath()
            leaderLine(ctx, from: CGPoint(x: (dx0 + dx1) / 2, y: dy - 10),
                       to: CGPoint(x: (dx0 + dx1) / 2, y: y - 60))
        }
        // Section view in the corner.
        let sec = CGRect(x: plate.minX + plate.width * 0.10, y: plate.maxY - plate.height * 0.28,
                         width: 130, height: 130)
        hatch(ctx, clip: rectPath(sec), tone: 0.42, baseAngle: 0.78)
        taperedOutline(ctx, [CGPoint(x: sec.minX, y: sec.minY), CGPoint(x: sec.maxX, y: sec.minY),
                             CGPoint(x: sec.maxX, y: sec.maxY), CGPoint(x: sec.minX, y: sec.maxY)],
                       weight: 2.2, lightAngle: 2.3)
    }
}

func onboardShop() {
    sheet("onboard_shop", number: 4, seedValue: 3004) { ctx, plate in
        let ground = plate.minY + plate.height * 0.08
        cornerWash(ctx, plate, corner: 0, tone: 0.22, reach: 0.40)
        cornerWash(ctx, plate, corner: 1, tone: 0.20, reach: 0.40, angle: -0.34)
        // Window on the left.
        let win = CGRect(x: plate.minX + plate.width * 0.05, y: plate.midY + 30,
                         width: plate.width * 0.17, height: plate.height * 0.30)
        hatch(ctx, clip: rectPath(win), tone: 0.06, baseAngle: 0.2)
        taperedOutline(ctx, [CGPoint(x: win.minX, y: win.minY), CGPoint(x: win.maxX, y: win.minY),
                             CGPoint(x: win.maxX, y: win.maxY), CGPoint(x: win.minX, y: win.maxY)],
                       weight: 4.0, lightAngle: 2.3)
        ctx.setStrokeColor(engColor(inkBlack, 0.8))
        ctx.setLineWidth(4)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: win.midX, y: win.minY)); ctx.addLine(to: CGPoint(x: win.midX, y: win.maxY))
        ctx.move(to: CGPoint(x: win.minX, y: win.midY)); ctx.addLine(to: CGPoint(x: win.maxX, y: win.midY))
        ctx.strokePath()
        // Forge on the right, with the hood above it.
        drawBrick(ctx, CGRect(x: plate.maxX - plate.width * 0.36, y: ground + plate.height * 0.10,
                              width: plate.width * 0.36, height: plate.height * 0.32),
                  cols: 6, rows: 4, tone: 0.24)
        let hood = [CGPoint(x: plate.maxX - plate.width * 0.42, y: plate.midY + plate.height * 0.10),
                    CGPoint(x: plate.maxX, y: plate.midY + plate.height * 0.10),
                    CGPoint(x: plate.maxX, y: plate.maxY),
                    CGPoint(x: plate.maxX - plate.width * 0.26, y: plate.maxY)]
        hatch(ctx, clip: polyPath(hood), tone: 0.40, baseAngle: 1.2)
        taperedOutline(ctx, hood, weight: 2.4, lightAngle: 2.3)
        let bed = CGRect(x: plate.maxX - plate.width * 0.32, y: ground + plate.height * 0.20,
                         width: plate.width * 0.26, height: 76)
        hatch(ctx, clip: ellipsePath(bed), tone: 0.08, baseAngle: 0.2)
        engraveRadiance(ctx, at: CGPoint(x: bed.midX, y: bed.midY), inner: 44,
                        outer: plate.width * 0.30, rays: 170, bias: 1)
        // Anvil on its stump, centre.
        let c = CGPoint(x: plate.midX - 40, y: ground + 250)
        drawStump(ctx, under: c, scale: 0.8, groundY: ground)
        drawAnvil(ctx, at: c, scale: 0.8)
        // A rack of tools on the wall.
        let railY = plate.maxY - plate.height * 0.20
        drawBench(ctx, CGRect(x: plate.minX + plate.width * 0.28, y: railY,
                              width: plate.width * 0.26, height: 20))
        for i in 0..<4 {
            let cx = plate.minX + plate.width * (0.31 + CGFloat(i) * 0.062)
            drawHammer(ctx, head: CGRect(x: cx - 44, y: railY - plate.height * 0.13,
                                         width: 88, height: 40),
                       handleTo: CGPoint(x: cx, y: railY), peen: i % 2 == 0)
        }
        setting(ctx, plate, groundY: ground, shadowWidth: 0.5)
    }
}

// MARK: - Piece plates, generated from the app's own commission data

/// Lays the finished piece out from its target profile, exactly as the game
/// judges it, and engraves it as a specimen on its own plate.
func piecePlates() {
    for (index, project) in Content.projects.enumerated() {
        sheet("piece_\(project.id)", number: index + 1, seedValue: UInt64(5000 + index),
              w: PIECE_W, h: PIECE_H) { ctx, plate in
            cornerWash(ctx, plate, corner: 0, tone: 0.16, reach: 0.40)
            cornerWash(ctx, plate, corner: 1, tone: 0.13, reach: 0.36, angle: -0.34)

            let target = TargetShape(project: project)
            let n = Workpiece.count
            let segLen = target.totalLength / Double(n)
            var bends = [Double](repeating: 0, count: n)
            for f in target.features where f.kind == .bend {
                bends[ForgeJudge.index(for: f.at)] += f.amount
            }
            // Spread each bend over five joints, as the app's renderer does.
            var smooth = [Double](repeating: 0, count: n)
            let kernel: [Double] = [0.12, 0.20, 0.36, 0.20, 0.12]
            for i in 0..<n where bends[i] != 0 {
                for (k, wgt) in kernel.enumerated() {
                    let j = max(0, min(n - 1, i + k - 2))
                    smooth[j] += bends[i] * wgt
                }
            }
            // Walk the centreline.
            var pts: [CGPoint] = []
            var half: [CGFloat] = []
            var angle = 0.0
            var cur = CGPoint(x: 0, y: 0)
            pts.append(cur)
            half.append(CGFloat(target.samples[0].t / 2))
            for i in 0..<n {
                angle += smooth[i] * Double.pi / 180
                cur = CGPoint(x: cur.x + CGFloat(cos(angle) * segLen),
                              y: cur.y + CGFloat(sin(angle) * segLen))
                pts.append(cur)
                half.append(CGFloat(target.samples[i].t / 2))
            }
            // Fit into the plate.
            var minX = pts[0].x, maxX = pts[0].x, minY = pts[0].y, maxY = pts[0].y
            for (i, p) in pts.enumerated() {
                minX = min(minX, p.x - half[i]); maxX = max(maxX, p.x + half[i])
                minY = min(minY, p.y - half[i]); maxY = max(maxY, p.y + half[i])
            }
            let box = plate.insetBy(dx: plate.width * 0.10, dy: plate.height * 0.16)
            let scale = min(box.width / max(1, maxX - minX), box.height / max(1, maxY - minY))
            let ox = box.midX - (minX + (maxX - minX) / 2) * scale
            let oy = box.midY - (minY + (maxY - minY) / 2) * scale
            let rawSpine = pts.map { CGPoint(x: $0.x * scale + ox, y: $0.y * scale + oy) }
            let rawRadii = half.map { max(2.2, $0 * scale) }
            let (spine, radii) = smoothSpine(rawSpine, rawRadii, factor: 6)

            // A shadow under the specimen so it sits on the page.
            stipple(ctx, clip: ellipsePath(CGRect(x: box.minX, y: box.minY - 10,
                                                  width: box.width, height: 70)),
                    tone: 0.18, sizeRange: (0.7, 2.0))

            engraveCylinder(ctx, spine: spine, half: radii, tone: 0.78, lightFrom: -0.44, lines: 22)

            // Punched holes read as dark eyes in the specimen.
            for f in target.features where f.kind == .hole {
                let i = min(spine.count - 1, ForgeJudge.index(for: f.at))
                let r = max(4, radii[i] * 0.62)
                hatch(ctx, clip: ellipsePath(CGRect(x: spine[i].x - r, y: spine[i].y - r,
                                                    width: r * 2, height: r * 2)),
                      tone: 0.94, baseAngle: 0.6)
            }
            // Twists get the corkscrew ticks a graver would cut.
            for f in target.features where f.kind == .twist {
                let i = ForgeJudge.index(for: f.at)
                ctx.setStrokeColor(engColor(inkBlack, 0.68))
                for k in -8...8 {
                    let j = max(1, min(spine.count - 2, i + k / 3))
                    let h = radii[j]
                    let x = spine[j].x + CGFloat(k) * 3.5
                    ctx.setLineWidth(1.3)
                    ctx.beginPath()
                    ctx.move(to: CGPoint(x: x - h * 0.4, y: spine[j].y - h))
                    ctx.addLine(to: CGPoint(x: x + h * 0.4, y: spine[j].y + h))
                    ctx.strokePath()
                }
            }
        }
    }
}

// MARK: - Award medals

/// The awards stay struck brass rather than paper: a medal in the hand reads
/// differently from a plate on the bench, and the contrast is the point.
func medal(_ name: String, seedValue: UInt64, emblem: (CGContext, CGFloat) -> Void) {
    eSeed(seedValue)
    let S = 512
    let f = CGFloat(S)
    let ctx = engCtx(S, S)
    // Dark ground, so the medal reads against the app's soot background.
    ctx.setFillColor(engColor((0.086, 0.071, 0.063), 1))
    ctx.fill(CGRect(x: 0, y: 0, width: f, height: f))
    // The disc.
    if let g = CGGradient(colorsSpace: engSpace,
                          colors: [engColor((0.847, 0.702, 0.400), 1),
                                   engColor((0.612, 0.478, 0.220), 1),
                                   engColor((0.322, 0.243, 0.106), 1)] as CFArray,
                          locations: [0, 0.62, 1]) {
        ctx.saveGState()
        ctx.addEllipse(in: CGRect(x: f * 0.08, y: f * 0.08, width: f * 0.84, height: f * 0.84))
        ctx.clip()
        ctx.drawRadialGradient(g, startCenter: CGPoint(x: f * 0.36, y: f * 0.66), startRadius: 0,
                               endCenter: CGPoint(x: f * 0.5, y: f * 0.5), endRadius: f * 0.62,
                               options: [])
        ctx.restoreGState()
    }
    // Engraved relief inside the disc.
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: f * 0.12, y: f * 0.12, width: f * 0.76, height: f * 0.76))
    ctx.clip()
    emblem(ctx, f)
    ctx.restoreGState()
    // Milled rim.
    ctx.setStrokeColor(engColor((0.933, 0.831, 0.573), 0.75))
    ctx.setLineWidth(f * 0.016)
    ctx.strokeEllipse(in: CGRect(x: f * 0.085, y: f * 0.085, width: f * 0.83, height: f * 0.83))
    ctx.setStrokeColor(engColor((0.243, 0.180, 0.078), 0.85))
    ctx.setLineWidth(f * 0.010)
    ctx.strokeEllipse(in: CGRect(x: f * 0.135, y: f * 0.135, width: f * 0.73, height: f * 0.73))
    for i in 0..<72 {
        let a = CGFloat(i) / 72 * 6.283
        ctx.setStrokeColor(engColor((0.278, 0.204, 0.086), 0.5))
        ctx.setLineWidth(1.6)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: f / 2 + cos(a) * f * 0.415, y: f / 2 + sin(a) * f * 0.415))
        ctx.addLine(to: CGPoint(x: f / 2 + cos(a) * f * 0.445, y: f / 2 + sin(a) * f * 0.445))
        ctx.strokePath()
    }
    engSave(ctx, outDir, name)
}

func medalsAll() {
    let dark: Ink = (0.243, 0.173, 0.071)

    func star(_ ctx: CGContext, _ f: CGFloat, _ s: CGFloat, _ dx: CGFloat, _ dy: CGFloat) {
        var pts: [CGPoint] = []
        for i in 0..<10 {
            let r = i % 2 == 0 ? f * 0.20 * s : f * 0.085 * s
            let a = -CGFloat.pi / 2 + CGFloat(i) * CGFloat.pi / 5
            pts.append(CGPoint(x: f / 2 + dx + cos(a) * r, y: f / 2 + dy + sin(a) * r))
        }
        hatch(ctx, clip: polyPath(pts), tone: 0.52, baseAngle: 0.6, ink: dark)
        taperedOutline(ctx, pts, weight: 2.4, lightAngle: 2.3, ink: dark)
    }
    func bar(_ ctx: CGContext, _ f: CGFloat, _ w: CGFloat, _ h: CGFloat, _ dy: CGFloat, _ tone: CGFloat) {
        let r = CGRect(x: f / 2 - w / 2, y: f / 2 - h / 2 + dy, width: w, height: h)
        hatch(ctx, clip: rectPath(r), tone: tone, baseAngle: 0.5, ink: dark)
        taperedOutline(ctx, [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY),
                             CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)],
                       weight: 2.0, lightAngle: 2.3, ink: dark)
    }
    func ring(_ ctx: CGContext, _ f: CGFloat, _ r: CGFloat, _ lw: CGFloat) {
        ctx.setStrokeColor(engColor(dark, 0.8))
        ctx.setLineWidth(lw)
        ctx.strokeEllipse(in: CGRect(x: f / 2 - r, y: f / 2 - r, width: r * 2, height: r * 2))
    }
    func anvilEmblem(_ ctx: CGContext, _ f: CGFloat) {
        let c = CGPoint(x: f * 0.5, y: f * 0.46)
        let s = f / 620
        let body = [CGPoint(x: c.x - 210 * s, y: c.y + 118 * s), CGPoint(x: c.x + 132 * s, y: c.y + 118 * s),
                    CGPoint(x: c.x + 268 * s, y: c.y + 82 * s), CGPoint(x: c.x + 128 * s, y: c.y + 52 * s),
                    CGPoint(x: c.x + 78 * s, y: c.y + 52 * s), CGPoint(x: c.x + 52 * s, y: c.y - 62 * s),
                    CGPoint(x: c.x + 108 * s, y: c.y - 128 * s), CGPoint(x: c.x - 168 * s, y: c.y - 128 * s),
                    CGPoint(x: c.x - 112 * s, y: c.y - 62 * s), CGPoint(x: c.x - 140 * s, y: c.y + 52 * s),
                    CGPoint(x: c.x - 210 * s, y: c.y + 52 * s)]
        hatch(ctx, clip: polyPath(body), tone: 0.50, baseAngle: 0.7, ink: dark)
        taperedOutline(ctx, body, weight: 2.6, lightAngle: 2.3, ink: dark)
    }
    func flameEmblem(_ ctx: CGContext, _ f: CGFloat, _ n: Int) {
        for i in 0..<n {
            let a = CGFloat(i) / CGFloat(n) * 6.283
            let r = n == 1 ? CGFloat(0) : f * 0.20
            engraveRadiance(ctx, at: CGPoint(x: f / 2 + cos(a) * r, y: f / 2 + sin(a) * r),
                            inner: f * 0.03, outer: f * (n == 1 ? 0.30 : 0.11),
                            rays: 60, ink: dark, bias: 1)
        }
    }

    medal("badge_first_heat", seedValue: 4001) { c, f in flameEmblem(c, f, 1); bar(c, f, f * 0.44, f * 0.07, 0, 0.34) }
    medal("badge_first_piece", seedValue: 4002) { c, f in anvilEmblem(c, f) }
    medal("badge_three_star", seedValue: 4003) { c, f in
        star(c, f, 0.62, -f * 0.19, 0); star(c, f, 0.80, 0, f * 0.03); star(c, f, 0.62, f * 0.19, 0)
    }
    medal("badge_pristine", seedValue: 4004) { c, f in ring(c, f, f * 0.25, f * 0.02); star(c, f, 0.72, 0, 0) }
    medal("badge_chapter_first", seedValue: 4005) { c, f in
        for i in 0..<3 {
            let x = f / 2 + CGFloat(i - 1) * f * 0.15
            var sp: [CGPoint] = []; var sh: [CGFloat] = []
            for k in 0...10 {
                let g = CGFloat(k) / 10
                sp.append(CGPoint(x: x, y: f * 0.68 - g * f * 0.34)); sh.append(f * 0.022 * (1 - g * 0.8))
            }
            engraveCylinder(c, spine: sp, half: sh, tone: 0.7, ink: dark, lines: 7)
        }
    }
    medal("badge_chapter_tools", seedValue: 4006) { c, f in
        drawHammerMedal(c, f)
    }
    medal("badge_chapter_hearth", seedValue: 4007) { c, f in
        flameEmblem(c, f, 1)
        for i in 0..<3 {
            var sp: [CGPoint] = []; var sh: [CGFloat] = []
            for k in 0...10 {
                let g = CGFloat(k) / 10
                sp.append(CGPoint(x: f * (0.34 + CGFloat(i) * 0.11) + g * f * 0.05,
                                  y: f * 0.72 - g * f * 0.42)); sh.append(f * 0.016)
            }
            engraveCylinder(c, spine: sp, half: sh, tone: 0.7, ink: dark, lines: 6)
        }
    }
    medal("badge_chapter_ornament", seedValue: 4008) { c, f in
        var sp: [CGPoint] = []; var sh: [CGFloat] = []
        var a: CGFloat = 0, r = f * 0.26
        while r > f * 0.03 { sp.append(CGPoint(x: f / 2 + cos(a) * r, y: f / 2 + sin(a) * r))
            sh.append(f * 0.018); a += 0.15; r *= 0.968 }
        engraveCylinder(c, spine: sp, half: sh, tone: 0.72, ink: dark, lines: 8)
    }
    medal("badge_chapter_master", seedValue: 4009) { c, f in
        let axe = [CGPoint(x: f * 0.26, y: f * 0.40), CGPoint(x: f * 0.26, y: f * 0.60),
                   CGPoint(x: f * 0.46, y: f * 0.64), CGPoint(x: f * 0.74, y: f * 0.50),
                   CGPoint(x: f * 0.46, y: f * 0.36)]
        hatch(c, clip: polyPath(axe), tone: 0.48, baseAngle: 0.55, ink: dark)
        taperedOutline(c, axe, weight: 2.4, lightAngle: 2.3, ink: dark)
        hatch(c, clip: ellipsePath(CGRect(x: f * 0.30, y: f * 0.44, width: f * 0.10, height: f * 0.12)),
              tone: 0.92, baseAngle: 0.7, ink: dark)
    }
    medal("badge_hardened", seedValue: 4010) { c, f in
        for i in 0..<4 {
            bar(c, f, f * 0.50, f * 0.075, f * (0.16 - CGFloat(i) * 0.105), 0.16 + CGFloat(i) * 0.22)
        }
    }
    medal("badge_no_crack", seedValue: 4011) { c, f in ring(c, f, f * 0.25, f * 0.028); bar(c, f, f * 0.42, f * 0.06, 0, 0.30) }
    medal("badge_under_par", seedValue: 4012) { c, f in
        for i in 0..<3 { bar(c, f, f * 0.44, f * 0.085, f * (0.16 - CGFloat(i) * 0.16), 0.40) }
    }
    medal("badge_one_heat", seedValue: 4013) { c, f in flameEmblem(c, f, 1); ring(c, f, f * 0.21, f * 0.024) }
    medal("badge_twenty", seedValue: 4014) { c, f in
        for r in 0..<4 { for col in 0..<5 {
            let rr = CGRect(x: f * (0.27 + CGFloat(col) * 0.10), y: f * (0.30 + CGFloat(r) * 0.10),
                            width: f * 0.06, height: f * 0.055)
            hatch(c, clip: rectPath(rr), tone: 0.5, baseAngle: 0.6, ink: dark)
        } }
    }
    medal("badge_streak_3", seedValue: 4015) { c, f in flameEmblem(c, f, 3) }
    medal("badge_streak_7", seedValue: 4016) { c, f in flameEmblem(c, f, 7) }
    medal("badge_commissions", seedValue: 4017) { c, f in
        let r = CGRect(x: f * 0.30, y: f * 0.26, width: f * 0.40, height: f * 0.48)
        hatch(c, clip: rectPath(r), tone: 0.14, baseAngle: 0.2, ink: dark)
        taperedOutline(c, [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY),
                           CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)],
                       weight: 2.2, lightAngle: 2.3, ink: dark)
        for i in 0..<5 {
            bar(c, f, f * 0.30, f * 0.018, f * (0.18 - CGFloat(i) * 0.075), 0.6)
        }
    }
    medal("badge_all_metals", seedValue: 4018) { c, f in
        for i in 0..<6 { bar(c, f, f * 0.52, f * 0.055, f * (0.20 - CGFloat(i) * 0.08), 0.14 + CGFloat(i) * 0.13) }
    }
    medal("badge_almanac", seedValue: 4019) { c, f in
        let r = CGRect(x: f * 0.26, y: f * 0.30, width: f * 0.48, height: f * 0.42)
        hatch(c, clip: rectPath(r), tone: 0.12, baseAngle: 0.2, ink: dark)
        taperedOutline(c, [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY),
                           CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)],
                       weight: 2.4, lightAngle: 2.3, ink: dark)
        ctxLine(c, CGPoint(x: r.midX, y: r.minY), CGPoint(x: r.midX, y: r.maxY), 3.4, dark)
    }
    medal("badge_quiz", seedValue: 4020) { c, f in
        ring(c, f, f * 0.23, f * 0.03)
        ctxLine(c, CGPoint(x: f * 0.36, y: f * 0.50), CGPoint(x: f * 0.46, y: f * 0.40), 5, dark)
        ctxLine(c, CGPoint(x: f * 0.46, y: f * 0.40), CGPoint(x: f * 0.66, y: f * 0.62), 5, dark)
    }
}

func ctxLine(_ ctx: CGContext, _ a: CGPoint, _ b: CGPoint, _ w: CGFloat, _ ink: Ink) {
    ctx.setStrokeColor(engColor(ink, 0.85))
    ctx.setLineWidth(w)
    ctx.beginPath(); ctx.move(to: a); ctx.addLine(to: b); ctx.strokePath()
}

func drawHammerMedal(_ ctx: CGContext, _ f: CGFloat) {
    let dark: Ink = (0.243, 0.173, 0.071)
    let head = CGRect(x: f * 0.24, y: f * 0.52, width: f * 0.52, height: f * 0.13)
    let shape = [CGPoint(x: head.minX, y: head.minY), CGPoint(x: head.maxX - head.width * 0.3, y: head.minY),
                 CGPoint(x: head.maxX, y: head.midY), CGPoint(x: head.maxX - head.width * 0.3, y: head.maxY),
                 CGPoint(x: head.minX, y: head.maxY)]
    hatch(ctx, clip: polyPath(shape), tone: 0.50, baseAngle: 0.45, ink: dark)
    taperedOutline(ctx, shape, weight: 2.4, lightAngle: 2.3, ink: dark)
    var sp: [CGPoint] = []
    var sh: [CGFloat] = []
    for k in 0...12 {
        let g = CGFloat(k) / 12
        sp.append(CGPoint(x: f * 0.42 - g * f * 0.05, y: f * 0.56 - g * f * 0.30))
        sh.append(f * 0.026)
    }
    engraveCylinder(ctx, spine: sp, half: sh, tone: 0.72, ink: dark, lines: 9)
}

// MARK: - Run

plateHeat(); plateCarbon(); plateDrawing(); plateAnvil()
plateHammers(); plateFuller(); platePunching(); plateQuench()
plateTemper(); plateScale(); plateBending(); plateHistory()
chapterFirst(); chapterTools(); chapterHearth(); chapterOrnament(); chapterMaster()
onboardFire(); onboardStrike(); onboardShape(); onboardShop()
piecePlates()
medalsAll()
print("plates done")
