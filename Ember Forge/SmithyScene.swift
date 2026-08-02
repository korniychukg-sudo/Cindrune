import SwiftUI

// The smithy the smith actually works in. It follows the real clock, and it
// fills up with the work that has been finished: tools land on the rack, hooks
// go up on the wall, the poker leans by the hearth.

enum DayPhase {
    case dawn, day, dusk, night

    static func now(_ date: Date = Date()) -> DayPhase {
        let h = Calendar.current.component(.hour, from: date)
        switch h {
        case 5..<8: return .dawn
        case 8..<17: return .day
        case 17..<21: return .dusk
        default: return .night
        }
    }

    var windowSky: [Color] {
        switch self {
        case .dawn: return [Color(red: 0.86, green: 0.60, blue: 0.42),
                            Color(red: 0.55, green: 0.45, blue: 0.50)]
        case .day: return [Color(red: 0.62, green: 0.75, blue: 0.82),
                           Color(red: 0.78, green: 0.82, blue: 0.80)]
        case .dusk: return [Color(red: 0.51, green: 0.34, blue: 0.40),
                            Color(red: 0.28, green: 0.24, blue: 0.36)]
        case .night: return [Color(red: 0.09, green: 0.11, blue: 0.20),
                             Color(red: 0.05, green: 0.06, blue: 0.12)]
        }
    }

    /// How much daylight leaks into the shop.
    var daylight: Double {
        switch self {
        case .dawn: return 0.45
        case .day: return 0.85
        case .dusk: return 0.30
        case .night: return 0.05
        }
    }

    var name: String {
        switch self {
        case .dawn: return "Dawn"
        case .day: return "Daylight"
        case .dusk: return "Dusk"
        case .night: return "Night"
        }
    }

    var caption: String {
        switch self {
        case .dawn: return "The fire is banked and the shop is cold. First heat of the day."
        case .day: return "Full daylight through the window. Good light for measuring, poor light for reading heat."
        case .dusk: return "The light is going. This is when the colours in the fire start to make sense."
        case .night: return "Only the coals now. Every heat reads true in the dark."
        }
    }
}

struct SmithyScene: View {
    @ObservedObject var store: ForgeStore
    var height: CGFloat = 250
    /// When true the scene draws the extra glow of a fire being worked.
    var stoked: Bool = false

    private var earnedSpots: Set<ShopSpot> {
        var out: Set<ShopSpot> = []
        for p in Content.projects where store.best(p.id) != nil {
            out.insert(p.spot)
        }
        return out
    }

    private var finishedCount: Int { store.save.best.count }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = DayPhase.now(timeline.date)
            Canvas { ctx, size in
                draw(ctx: &ctx, size: size, t: t, phase: phase)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(Forge.night)
        .clipShape(RoundedRectangle(cornerRadius: Forge.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Forge.corner, style: .continuous)
                .stroke(Forge.slate, lineWidth: 1)
        )
    }

    // MARK: - Drawing

    private func draw(ctx: inout GraphicsContext, size: CGSize, t: Double, phase: DayPhase) {
        let w = size.width, h = size.height
        let spots = earnedSpots
        let flicker = 0.82 + 0.18 * sin(t * 3.1) * cos(t * 1.7)
        let fireLevel = (stoked ? 1.0 : 0.72) * flicker

        // Back wall.
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .linearGradient(Gradient(colors: [
                    Color(red: 0.115, green: 0.096, blue: 0.086),
                    Color(red: 0.070, green: 0.058, blue: 0.052)
                 ]), startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: h)))

        // Wall planks.
        for i in 0...9 {
            let y = h * Double(i) / 9.5
            var line = Path()
            line.move(to: CGPoint(x: 0, y: y))
            line.addLine(to: CGPoint(x: w, y: y))
            ctx.stroke(line, with: .color(Color.black.opacity(0.22)), lineWidth: 1)
        }

        // Daylight wash from the window side.
        ctx.fill(Path(CGRect(x: 0, y: 0, width: w * 0.5, height: h)),
                 with: .radialGradient(Gradient(colors: [
                    Color.white.opacity(0.10 * phase.daylight),
                    Color.clear
                 ]), center: CGPoint(x: w * 0.17, y: h * 0.30),
                 startRadius: 0, endRadius: w * 0.42))

        drawWindow(&ctx, w: w, h: h, phase: phase, t: t)
        drawForge(&ctx, w: w, h: h, level: fireLevel, t: t)
        drawFloor(&ctx, w: w, h: h)
        drawAnvil(&ctx, w: w, h: h, glow: fireLevel)
        drawSlackTub(&ctx, w: w, h: h)

        if spots.contains(.toolRack) { drawToolRack(&ctx, w: w, h: h) }
        if spots.contains(.wallRack) { drawWallHooks(&ctx, w: w, h: h) }
        if spots.contains(.ceilingHook) { drawHangingWork(&ctx, w: w, h: h, t: t) }
        if spots.contains(.hearthSide) { drawFiresideSet(&ctx, w: w, h: h) }
        if spots.contains(.shelf) { drawShelf(&ctx, w: w, h: h) }
        if spots.contains(.benchTop) { drawBenchClutter(&ctx, w: w, h: h) }
        if spots.contains(.floor) { drawTrivet(&ctx, w: w, h: h) }
        if spots.contains(.doorFrame) {
            drawDoorIron(&ctx, w: w, h: h,
                         lit: phase == .dusk || phase == .night, t: t)
        }

        drawEmbers(&ctx, w: w, h: h, t: t, level: fireLevel)

        // Warm firelight vignette over everything.
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .radialGradient(Gradient(colors: [
                    Forge.ember.opacity(0.16 * fireLevel),
                    Color.clear
                 ]), center: CGPoint(x: w * 0.79, y: h * 0.55),
                 startRadius: 0, endRadius: w * 0.62))

        // Corner darkening keeps the scene from looking flat.
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .radialGradient(Gradient(colors: [
                    Color.clear, Color.black.opacity(0.55)
                 ]), center: CGPoint(x: w * 0.5, y: h * 0.5),
                 startRadius: w * 0.28, endRadius: w * 0.78))

        // A quiet count of what is on the walls.
        if finishedCount > 0 {
            let text = Text("\(finishedCount) of \(Content.projects.count) hung in the shop")
                .font(Forge.label(10))
                .foregroundColor(Forge.chalkFaint)
            ctx.draw(text, at: CGPoint(x: w * 0.5, y: h - 16), anchor: .center)
        }
    }

    private func drawWindow(_ ctx: inout GraphicsContext, w: Double, h: Double,
                            phase: DayPhase, t: Double) {
        let rect = CGRect(x: w * 0.06, y: h * 0.10, width: w * 0.21, height: h * 0.34)
        ctx.fill(Path(roundedRect: rect, cornerRadius: 3),
                 with: .linearGradient(Gradient(colors: phase.windowSky),
                                       startPoint: CGPoint(x: rect.minX, y: rect.minY),
                                       endPoint: CGPoint(x: rect.minX, y: rect.maxY)))

        // Stars at night.
        if phase == .night {
            for i in 0..<9 {
                let fx = Double((i * 37) % 100) / 100
                let fy = Double((i * 61) % 100) / 100
                let tw = 0.4 + 0.6 * abs(sin(t * 1.1 + Double(i)))
                let p = CGPoint(x: rect.minX + rect.width * (0.08 + fx * 0.84),
                                y: rect.minY + rect.height * (0.08 + fy * 0.6))
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - 1, y: p.y - 1, width: 2, height: 2)),
                         with: .color(Color.white.opacity(0.75 * tw)))
            }
        }

        // Hills outside.
        var hills = Path()
        hills.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        hills.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.72))
        hills.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.78),
                           control: CGPoint(x: rect.minX + rect.width * 0.26,
                                            y: rect.minY + rect.height * 0.62))
        hills.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.70),
                           control: CGPoint(x: rect.minX + rect.width * 0.76,
                                            y: rect.minY + rect.height * 0.86))
        hills.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        hills.closeSubpath()
        ctx.fill(hills, with: .color(Color.black.opacity(0.42)))

        // Frame and glazing bars.
        ctx.stroke(Path(roundedRect: rect, cornerRadius: 3),
                   with: .color(Color(red: 0.22, green: 0.17, blue: 0.13)), lineWidth: 5)
        var bars = Path()
        bars.move(to: CGPoint(x: rect.midX, y: rect.minY))
        bars.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        bars.move(to: CGPoint(x: rect.minX, y: rect.midY))
        bars.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        ctx.stroke(bars, with: .color(Color(red: 0.20, green: 0.15, blue: 0.11)), lineWidth: 3)
    }

    private func drawForge(_ ctx: inout GraphicsContext, w: Double, h: Double,
                           level: Double, t: Double) {
        // Chimney hood.
        var hood = Path()
        hood.move(to: CGPoint(x: w * 0.62, y: h * 0.30))
        hood.addLine(to: CGPoint(x: w * 0.98, y: h * 0.30))
        hood.addLine(to: CGPoint(x: w * 0.92, y: h * 0.02))
        hood.addLine(to: CGPoint(x: w * 0.72, y: h * 0.02))
        hood.closeSubpath()
        ctx.fill(hood, with: .color(Color(red: 0.145, green: 0.125, blue: 0.115)))
        ctx.stroke(hood, with: .color(Color.black.opacity(0.5)), lineWidth: 1.5)

        // Brick fire pot.
        let pot = CGRect(x: w * 0.63, y: h * 0.46, width: w * 0.33, height: h * 0.26)
        ctx.fill(Path(roundedRect: pot, cornerRadius: 5),
                 with: .color(Color(red: 0.24, green: 0.17, blue: 0.14)))
        for r in 0..<3 {
            for c in 0..<5 {
                let bx = pot.minX + 4 + Double(c) * (pot.width - 8) / 5 + (r % 2 == 0 ? 0 : 5)
                let by = pot.minY + 4 + Double(r) * (pot.height - 8) / 3
                let brick = CGRect(x: bx, y: by,
                                   width: (pot.width - 8) / 5 - 3,
                                   height: (pot.height - 8) / 3 - 3)
                if brick.maxX < pot.maxX - 2 {
                    ctx.fill(Path(roundedRect: brick, cornerRadius: 1.5),
                             with: .color(Color(red: 0.29, green: 0.20, blue: 0.16).opacity(0.8)))
                }
            }
        }

        // Coal bed.
        let bed = CGRect(x: pot.minX + pot.width * 0.14, y: pot.minY + pot.height * 0.16,
                         width: pot.width * 0.72, height: pot.height * 0.42)
        ctx.fill(Path(ellipseIn: bed), with: .color(Color(red: 0.10, green: 0.08, blue: 0.07)))
        ctx.fill(Path(ellipseIn: bed.insetBy(dx: bed.width * 0.10, dy: bed.height * 0.16)),
                 with: .radialGradient(Gradient(colors: [
                    Forge.white.opacity(0.95 * level),
                    Forge.flame.opacity(0.85 * level),
                    Forge.emberDeep.opacity(0.55 * level),
                    Color.clear
                 ]), center: CGPoint(x: bed.midX, y: bed.midY),
                 startRadius: 0, endRadius: bed.width * 0.55))

        // Glow spilling onto the hood.
        ctx.fill(Path(ellipseIn: CGRect(x: bed.midX - bed.width * 0.7,
                                        y: bed.midY - bed.height * 2.4,
                                        width: bed.width * 1.4, height: bed.height * 3.0)),
                 with: .radialGradient(Gradient(colors: [
                    Forge.ember.opacity(0.22 * level), Color.clear
                 ]), center: CGPoint(x: bed.midX, y: bed.midY),
                 startRadius: 0, endRadius: bed.width * 0.8))

        // Bellows nozzle and lever.
        var lever = Path()
        let swing = sin(t * 0.8) * 3
        lever.move(to: CGPoint(x: w * 0.985, y: h * 0.52 + swing))
        lever.addLine(to: CGPoint(x: w * 0.90, y: h * 0.60 + swing * 0.5))
        ctx.stroke(lever, with: .color(Color(red: 0.30, green: 0.22, blue: 0.15)), lineWidth: 4)
    }

    private func drawFloor(_ ctx: inout GraphicsContext, w: Double, h: Double) {
        let floor = CGRect(x: 0, y: h * 0.74, width: w, height: h * 0.26)
        ctx.fill(Path(floor), with: .linearGradient(Gradient(colors: [
            Color(red: 0.135, green: 0.112, blue: 0.098),
            Color(red: 0.085, green: 0.070, blue: 0.062)
        ]), startPoint: CGPoint(x: 0, y: floor.minY), endPoint: CGPoint(x: 0, y: floor.maxY)))
        // Scattered scale on the flagstones.
        for i in 0..<28 {
            let fx = Double((i * 73) % 100) / 100
            let fy = Double((i * 47) % 100) / 100
            let p = CGPoint(x: w * fx, y: floor.minY + floor.height * (0.12 + fy * 0.8))
            ctx.fill(Path(ellipseIn: CGRect(x: p.x, y: p.y, width: 2.2, height: 1.4)),
                     with: .color(Color.black.opacity(0.35)))
        }
    }

    private func drawAnvil(_ ctx: inout GraphicsContext, w: Double, h: Double, glow: Double) {
        let baseY = h * 0.84
        let cx = w * 0.44
        // Stump.
        var stump = Path()
        stump.addRoundedRect(in: CGRect(x: cx - w * 0.075, y: baseY - h * 0.02,
                                        width: w * 0.15, height: h * 0.16),
                             cornerSize: CGSize(width: 3, height: 3))
        ctx.fill(stump, with: .color(Color(red: 0.24, green: 0.17, blue: 0.11)))
        for i in 0..<4 {
            var g = Path()
            let x = cx - w * 0.075 + w * 0.03 * Double(i) + 6
            g.move(to: CGPoint(x: x, y: baseY - h * 0.01))
            g.addLine(to: CGPoint(x: x, y: baseY + h * 0.13))
            ctx.stroke(g, with: .color(Color.black.opacity(0.22)), lineWidth: 1)
        }
        // Anvil.
        var a = Path()
        a.move(to: CGPoint(x: cx - w * 0.10, y: baseY - h * 0.09))
        a.addLine(to: CGPoint(x: cx + w * 0.06, y: baseY - h * 0.09))
        a.addQuadCurve(to: CGPoint(x: cx + w * 0.135, y: baseY - h * 0.055),
                       control: CGPoint(x: cx + w * 0.125, y: baseY - h * 0.095))
        a.addQuadCurve(to: CGPoint(x: cx + w * 0.05, y: baseY - h * 0.045),
                       control: CGPoint(x: cx + w * 0.11, y: baseY - h * 0.035))
        a.addLine(to: CGPoint(x: cx + w * 0.02, y: baseY - h * 0.045))
        a.addLine(to: CGPoint(x: cx + w * 0.005, y: baseY - h * 0.012))
        a.addLine(to: CGPoint(x: cx + w * 0.055, y: baseY))
        a.addLine(to: CGPoint(x: cx - w * 0.075, y: baseY))
        a.addLine(to: CGPoint(x: cx - w * 0.025, y: baseY - h * 0.012))
        a.addLine(to: CGPoint(x: cx - w * 0.045, y: baseY - h * 0.045))
        a.addLine(to: CGPoint(x: cx - w * 0.10, y: baseY - h * 0.045))
        a.closeSubpath()
        ctx.fill(a, with: .linearGradient(Gradient(colors: [
            Color(red: 0.42, green: 0.40, blue: 0.39),
            Color(red: 0.19, green: 0.18, blue: 0.17)
        ]), startPoint: CGPoint(x: 0, y: baseY - h * 0.09), endPoint: CGPoint(x: 0, y: baseY)))
        // Firelight catching the face.
        var face = Path()
        face.move(to: CGPoint(x: cx - w * 0.10, y: baseY - h * 0.088))
        face.addLine(to: CGPoint(x: cx + w * 0.06, y: baseY - h * 0.088))
        ctx.stroke(face, with: .color(Forge.spark.opacity(0.55 * glow)), lineWidth: 2.4)
    }

    private func drawSlackTub(_ ctx: inout GraphicsContext, w: Double, h: Double) {
        let tub = CGRect(x: w * 0.575, y: h * 0.82, width: w * 0.10, height: h * 0.13)
        ctx.fill(Path(roundedRect: tub, cornerRadius: 3),
                 with: .color(Color(red: 0.21, green: 0.15, blue: 0.10)))
        ctx.fill(Path(ellipseIn: CGRect(x: tub.minX + 2, y: tub.minY + 1,
                                        width: tub.width - 4, height: tub.height * 0.30)),
                 with: .color(Forge.quench.opacity(0.55)))
        var band = Path()
        band.move(to: CGPoint(x: tub.minX, y: tub.midY))
        band.addLine(to: CGPoint(x: tub.maxX, y: tub.midY))
        ctx.stroke(band, with: .color(Color(red: 0.32, green: 0.30, blue: 0.28)), lineWidth: 2)
    }

    private func drawToolRack(_ ctx: inout GraphicsContext, w: Double, h: Double) {
        let y = h * 0.30
        var shelf = Path()
        shelf.addRect(CGRect(x: w * 0.31, y: y, width: w * 0.24, height: 4))
        ctx.fill(shelf, with: .color(Color(red: 0.26, green: 0.19, blue: 0.13)))
        // Hammers and punches hanging.
        for i in 0..<4 {
            let x = w * (0.335 + Double(i) * 0.055)
            var handle = Path()
            handle.addRoundedRect(in: CGRect(x: x, y: y + 4, width: 3, height: h * 0.11),
                                  cornerSize: CGSize(width: 1.5, height: 1.5))
            ctx.fill(handle, with: .color(Color(red: 0.33, green: 0.24, blue: 0.15)))
            var head = Path()
            head.addRoundedRect(in: CGRect(x: x - 5, y: y + h * 0.13, width: 13, height: 6),
                                cornerSize: CGSize(width: 1.5, height: 1.5))
            ctx.fill(head, with: .color(Color(red: 0.36, green: 0.35, blue: 0.34)))
        }
    }

    private func drawWallHooks(_ ctx: inout GraphicsContext, w: Double, h: Double) {
        for i in 0..<3 {
            let x = w * (0.075 + Double(i) * 0.055)
            let y = h * 0.53
            var hook = Path()
            hook.move(to: CGPoint(x: x, y: y))
            hook.addLine(to: CGPoint(x: x, y: y + h * 0.05))
            hook.addQuadCurve(to: CGPoint(x: x + 9, y: y + h * 0.085),
                              control: CGPoint(x: x, y: y + h * 0.09))
            ctx.stroke(hook, with: .color(Color(red: 0.34, green: 0.32, blue: 0.30)),
                       style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
        }
    }

    private func drawHangingWork(_ ctx: inout GraphicsContext, w: Double, h: Double, t: Double) {
        for i in 0..<3 {
            let x = w * (0.335 + Double(i) * 0.06)
            let sway = sin(t * 0.6 + Double(i) * 1.4) * 1.6
            var chain = Path()
            chain.move(to: CGPoint(x: x, y: 0))
            chain.addLine(to: CGPoint(x: x + sway, y: h * 0.10))
            ctx.stroke(chain, with: .color(Color(red: 0.30, green: 0.28, blue: 0.26)), lineWidth: 1.4)
            // S hook.
            var s = Path()
            s.addArc(center: CGPoint(x: x + sway, y: h * 0.125), radius: h * 0.023,
                     startAngle: .degrees(120), endAngle: .degrees(340), clockwise: false)
            s.addArc(center: CGPoint(x: x + sway, y: h * 0.168), radius: h * 0.023,
                     startAngle: .degrees(200), endAngle: .degrees(20), clockwise: true)
            ctx.stroke(s, with: .color(Color(red: 0.37, green: 0.35, blue: 0.33)),
                       style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        }
    }

    private func drawFiresideSet(_ ctx: inout GraphicsContext, w: Double, h: Double) {
        for i in 0..<3 {
            let x = w * (0.575 + Double(i) * 0.022)
            var rod = Path()
            rod.move(to: CGPoint(x: x, y: h * 0.94))
            rod.addLine(to: CGPoint(x: x + w * 0.02, y: h * 0.52))
            ctx.stroke(rod, with: .color(Color(red: 0.35, green: 0.33, blue: 0.31)),
                       style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            var curl = Path()
            curl.addArc(center: CGPoint(x: x + w * 0.021, y: h * 0.505), radius: h * 0.018,
                        startAngle: .degrees(70), endAngle: .degrees(330), clockwise: false)
            ctx.stroke(curl, with: .color(Color(red: 0.35, green: 0.33, blue: 0.31)), lineWidth: 2)
        }
    }

    private func drawShelf(_ ctx: inout GraphicsContext, w: Double, h: Double) {
        let y = h * 0.60
        ctx.fill(Path(CGRect(x: w * 0.055, y: y, width: w * 0.15, height: 3.5)),
                 with: .color(Color(red: 0.25, green: 0.18, blue: 0.12)))
        // A leaf fob and a candle spike standing on it.
        var leaf = Path()
        leaf.move(to: CGPoint(x: w * 0.075, y: y))
        leaf.addQuadCurve(to: CGPoint(x: w * 0.092, y: y - h * 0.045),
                          control: CGPoint(x: w * 0.064, y: y - h * 0.03))
        leaf.addQuadCurve(to: CGPoint(x: w * 0.075, y: y),
                          control: CGPoint(x: w * 0.103, y: y - h * 0.02))
        ctx.fill(leaf, with: .color(Color(red: 0.36, green: 0.33, blue: 0.30)))
        var spike = Path()
        spike.move(to: CGPoint(x: w * 0.14, y: y))
        spike.addLine(to: CGPoint(x: w * 0.14, y: y - h * 0.075))
        ctx.stroke(spike, with: .color(Color(red: 0.34, green: 0.32, blue: 0.30)), lineWidth: 2.2)
        ctx.fill(Path(ellipseIn: CGRect(x: w * 0.128, y: y - 4, width: w * 0.024, height: 5)),
                 with: .color(Color(red: 0.34, green: 0.32, blue: 0.30)))
    }

    private func drawBenchClutter(_ ctx: inout GraphicsContext, w: Double, h: Double) {
        let bench = CGRect(x: w * 0.02, y: h * 0.66, width: w * 0.20, height: h * 0.06)
        ctx.fill(Path(roundedRect: bench, cornerRadius: 2),
                 with: .color(Color(red: 0.23, green: 0.17, blue: 0.11)))
        for i in 0..<5 {
            let x = bench.minX + 8 + Double(i) * 9
            var nail = Path()
            nail.move(to: CGPoint(x: x, y: bench.minY - 1))
            nail.addLine(to: CGPoint(x: x + 3, y: bench.minY - 7))
            ctx.stroke(nail, with: .color(Color(red: 0.38, green: 0.36, blue: 0.34)), lineWidth: 1.6)
        }
    }

    private func drawTrivet(_ ctx: inout GraphicsContext, w: Double, h: Double) {
        let cx = w * 0.24, cy = h * 0.93
        var ring = Path()
        ring.addEllipse(in: CGRect(x: cx - w * 0.035, y: cy - h * 0.02,
                                   width: w * 0.07, height: h * 0.035))
        ctx.stroke(ring, with: .color(Color(red: 0.34, green: 0.32, blue: 0.30)), lineWidth: 2)
        for i in 0..<3 {
            let a = Double(i) * 2 * Double.pi / 3 + 0.4
            var leg = Path()
            leg.move(to: CGPoint(x: cx + cos(a) * w * 0.033, y: cy))
            leg.addLine(to: CGPoint(x: cx + cos(a) * w * 0.042, y: cy + h * 0.035))
            ctx.stroke(leg, with: .color(Color(red: 0.32, green: 0.30, blue: 0.28)), lineWidth: 1.8)
        }
    }

    private func drawDoorIron(_ ctx: inout GraphicsContext, w: Double, h: Double,
                              lit: Bool, t: Double) {
        // A bracket by the door with a lantern that lights after dusk.
        let x = w * 0.285, y = h * 0.20
        var arm = Path()
        arm.move(to: CGPoint(x: x, y: y))
        arm.addLine(to: CGPoint(x: x + w * 0.045, y: y))
        arm.addQuadCurve(to: CGPoint(x: x + w * 0.055, y: y + h * 0.035),
                         control: CGPoint(x: x + w * 0.06, y: y + h * 0.01))
        ctx.stroke(arm, with: .color(Color(red: 0.33, green: 0.31, blue: 0.29)),
                   style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        let lantern = CGRect(x: x + w * 0.041, y: y + h * 0.035, width: w * 0.028, height: h * 0.055)
        ctx.fill(Path(roundedRect: lantern, cornerRadius: 2),
                 with: .color(Color(red: 0.20, green: 0.17, blue: 0.14)))
        if lit {
            let f = 0.75 + 0.25 * sin(t * 4.3)
            ctx.fill(Path(roundedRect: lantern.insetBy(dx: 1.5, dy: 2), cornerRadius: 1.5),
                     with: .color(Forge.spark.opacity(0.85 * f)))
            ctx.fill(Path(ellipseIn: lantern.insetBy(dx: -18, dy: -18)),
                     with: .radialGradient(Gradient(colors: [
                        Forge.spark.opacity(0.30 * f), Color.clear
                     ]), center: CGPoint(x: lantern.midX, y: lantern.midY),
                     startRadius: 0, endRadius: 26))
        }
    }

    private func drawEmbers(_ ctx: inout GraphicsContext, w: Double, h: Double,
                            t: Double, level: Double) {
        let count = 20
        for i in 0..<count {
            let seed = Double(i) * 12.9898
            let speed = 0.16 + (seed.truncatingRemainder(dividingBy: 0.09))
            let life = (t * speed + Double(i) / Double(count)).truncatingRemainder(dividingBy: 1)
            let drift = sin(t * 0.9 + seed) * w * 0.03
            let x = w * (0.70 + (seed.truncatingRemainder(dividingBy: 0.22))) + drift
            let y = h * 0.60 - life * h * 0.58
            let fade = (1 - life) * level
            guard fade > 0.02 else { continue }
            let r = 1.0 + (1 - life) * 1.6
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                     with: .color(Forge.spark.opacity(0.85 * fade)))
        }
    }
}
