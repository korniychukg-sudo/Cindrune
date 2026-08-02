import Foundation
import CoreGraphics

// A single test plate used to tune the engraving engine before the whole set
// is generated. Not shipped.

let probeDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let PW = 1500, PH = 960

eSeed(7)
let ctx = engCtx(PW, PH)
let W = CGFloat(PW), H = CGFloat(PH)

layPaper(ctx, w: PW, h: PH)
let plate = CGRect(x: W * 0.06, y: H * 0.09, width: W * 0.88, height: H * 0.82)

// An engraving lives on bare paper. Only the corners and the ground shadow
// carry any tone at all.
cornerWash(ctx, plate, corner: 0, tone: 0.26, reach: 0.52)
cornerWash(ctx, plate, corner: 1, tone: 0.20, reach: 0.44, angle: -0.30)
stipple(ctx, clip: ellipsePath(CGRect(x: W * 0.10, y: H * 0.20, width: W * 0.52, height: 130)),
        tone: 0.24, sizeRange: (0.7, 2.2))

// The anvil: a solid mass, so flat hatching plus a heavy contour.
let ax = W * 0.30, ay = H * 0.40
let anvil: [CGPoint] = [
    CGPoint(x: ax - 210, y: ay + 118), CGPoint(x: ax + 132, y: ay + 118),
    CGPoint(x: ax + 268, y: ay + 82), CGPoint(x: ax + 128, y: ay + 52),
    CGPoint(x: ax + 78, y: ay + 52), CGPoint(x: ax + 52, y: ay - 62),
    CGPoint(x: ax + 108, y: ay - 128), CGPoint(x: ax - 168, y: ay - 128),
    CGPoint(x: ax - 112, y: ay - 62), CGPoint(x: ax - 140, y: ay + 52),
    CGPoint(x: ax - 210, y: ay + 52)
]
hatch(ctx, clip: polyPath(anvil), tone: 0.58, baseAngle: 0.70)
// The face catches the light, so lift it.
hatch(ctx, clip: rectPath(CGRect(x: ax - 208, y: ay + 96, width: 338, height: 22)),
      tone: 0.14, baseAngle: 0.05)
taperedOutline(ctx, anvil, weight: 2.6, lightAngle: 2.3)

// A tapered bar lying on the face — the cylinder test.
var spine: [CGPoint] = []
var half: [CGFloat] = []
for i in 0...28 {
    let f = CGFloat(i) / 28
    spine.append(CGPoint(x: ax - 150 + f * 520, y: ay + 150 + sin(f * 3.0) * 5))
    half.append(52 - f * 34)
}
engraveCylinder(ctx, spine: spine, half: half, tone: 1.05, lightFrom: -0.42)

// Heat coming off the tip.
engraveRadiance(ctx, at: CGPoint(x: ax + 372, y: ay + 150), inner: 30, outer: 210, rays: 130, bias: 1)
stipple(ctx, clip: ellipsePath(CGRect(x: ax + 250, y: ay + 20, width: 300, height: 240)),
        tone: 0.16, sizeRange: (0.6, 1.6))

// Smoke drifting up the right side.
stipple(ctx, clip: ellipsePath(CGRect(x: W * 0.62, y: H * 0.46, width: 380, height: 420)),
        tone: 0.13, sizeRange: (0.8, 2.6))

plateMark(ctx, plate)
captionRule(ctx, from: CGPoint(x: plate.minX + 40, y: plate.minY - 26),
            to: CGPoint(x: plate.maxX - 40, y: plate.minY - 26))
plateNumeral(ctx, 7, at: CGPoint(x: plate.maxX - 78, y: plate.maxY - 54), size: 34)

engSave(ctx, probeDir, "probe_plate")
print("probe done")
