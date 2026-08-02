import SwiftUI

// The home tab is the workshop itself: a room wider than the screen that you
// drag through, drawn in three parallax layers and lit by the real clock.
// Everything in it that matters is a place you can touch.

enum WorkshopAction: Equatable {
    case commission          // the forge — today's order, or free forge once delivered
    case nextPiece           // the anvil — next unfinished commission
    case tools               // the rack
    case book                // the drawing on the bench
    case almanac             // the lectern
    case journal             // the ledger
    case gallery             // the wall of finished work
}

/// A touchable place in the room. `x` and `w` are fractions of the whole scene
/// width; `y` and `h` fractions of its height.
struct WorkshopSpot: Identifiable {
    let id: String
    let x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat
    let label: String
    let action: WorkshopAction

    func rect(sceneWidth: CGFloat, height: CGFloat) -> CGRect {
        CGRect(x: x * sceneWidth, y: (1 - y - h) * height,
               width: w * sceneWidth, height: h * height)
    }
}

enum WorkshopMap {
    /// How much wider than the screen the room is.
    static let span: CGFloat = 2.15

    static let spots: [WorkshopSpot] = [
        WorkshopSpot(id: "gallery", x: 0.020, y: 0.30, w: 0.150, h: 0.44,
                     label: "Finished work", action: .gallery),
        WorkshopSpot(id: "journal", x: 0.185, y: 0.10, w: 0.110, h: 0.26,
                     label: "The ledger", action: .journal),
        WorkshopSpot(id: "almanac", x: 0.305, y: 0.14, w: 0.105, h: 0.34,
                     label: "The almanac", action: .almanac),
        WorkshopSpot(id: "tools", x: 0.425, y: 0.44, w: 0.150, h: 0.30,
                     label: "Tool rack", action: .tools),
        WorkshopSpot(id: "book", x: 0.430, y: 0.08, w: 0.150, h: 0.28,
                     label: "Commission book", action: .book),
        WorkshopSpot(id: "anvil", x: 0.605, y: 0.06, w: 0.150, h: 0.36,
                     label: "The anvil", action: .nextPiece),
        WorkshopSpot(id: "forge", x: 0.790, y: 0.10, w: 0.190, h: 0.52,
                     label: "The forge", action: .commission)
    ]
}

struct WorkshopView: View {
    @ObservedObject var store: ForgeStore
    let onStart: (ForgeProject?, Metal) -> Void
    let onTab: (Int) -> Void

    @State private var pan: CGFloat = 0
    @State private var panStart: CGFloat = 0
    @State private var touched: WorkshopSpot? = nil
    @State private var showTools = false
    @State private var showGallery = false
    @State private var showRank = false

    private var phase: DayPhase { DayPhase.now() }

    private var nextUp: ForgeProject? {
        for c in Chapter.allCases where store.isChapterOpen(c) {
            for p in Content.projects(in: c) where store.best(p.id) == nil && store.isProjectOpen(p) {
                return p
            }
        }
        return nil
    }

    var body: some View {
        GeometryReader { geo in
            let sceneW = geo.size.width * WorkshopMap.span
            let maxPan = sceneW - geo.size.width

            ZStack(alignment: .top) {
                WorkshopCanvas(store: store, phase: phase, pan: pan,
                               sceneWidth: sceneW, highlighted: touched?.id)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                pan = min(0, max(-maxPan, panStart + v.translation.width))
                            }
                            .onEnded { v in
                                if abs(v.translation.width) < 12 && abs(v.translation.height) < 12 {
                                    tap(at: v.location, sceneW: sceneW, size: geo.size)
                                }
                                panStart = pan
                            }
                    )

                statusStrip
                    .padding(.horizontal, 14)
                    .padding(.top, 8)

                VStack {
                    Spacer()
                    if let t = touched {
                        BrassPlaque(text: t.label, sub: hint(for: t.action))
                            .scaleEffect(1.15)
                            .padding(.bottom, 22)
                            .transition(.opacity)
                    } else {
                        HStack(spacing: 7) {
                            ChevronMark(size: 11, color: Forge.chalkFaint, direction: 2)
                            Text("Drag through the shop · tap what you need")
                                .font(Forge.body(11))
                                .foregroundColor(Forge.chalkFaint)
                            ChevronMark(size: 11, color: Forge.chalkFaint, direction: 0)
                        }
                        .padding(.horizontal, 13).padding(.vertical, 7)
                        .background(Capsule().fill(Forge.night.opacity(0.72)))
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .forgeBackground()
        .onAppear {
            store.refreshCommission()
            ForgeSound.shared.startAmbient()
        }
        .onDisappear { ForgeSound.shared.stopAmbient() }
        .sheet(isPresented: $showTools) {
            ToolRackSheet(store: store, onClose: { showTools = false })
        }
        .sheet(isPresented: $showGallery) {
            GallerySheet(store: store, onClose: { showGallery = false })
        }
        .sheet(isPresented: $showRank) {
            RankSheet(store: store, onClose: { showRank = false })
        }
    }

    // MARK: Status

    private var statusStrip: some View {
        HStack(spacing: 10) {
            Button(action: { showRank = true }) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(store.rank.name)
                            .font(Forge.heading(14))
                            .foregroundColor(Forge.chalk)
                        Text(phase.name)
                            .font(Forge.body(10))
                            .foregroundColor(Forge.chalkFaint)
                    }
                    ForgeBar(value: store.rankProgress, tint: Forge.ember, height: 5)
                        .frame(width: 54)
                }
                .padding(.horizontal, 11).padding(.vertical, 7)
                .background(Capsule().fill(Forge.night.opacity(0.78)))
            }
            .buttonStyle(PlainButtonStyle())

            Spacer(minLength: 4)

            HStack(spacing: 12) {
                miniStat("\(store.liveStreak)", "days", Forge.flame)
                miniStat("\(store.save.best.count)", "made", Forge.brass)
                miniStat("\(store.badgeCount)", "awards", Forge.quench)
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Capsule().fill(Forge.night.opacity(0.78)))
        }
    }

    private func miniStat(_ v: String, _ c: String, _ tint: Color) -> some View {
        VStack(spacing: 0) {
            Text(v).font(Forge.mono(13)).foregroundColor(tint)
            Text(c).font(Forge.body(9)).foregroundColor(Forge.chalkFaint)
        }
    }

    private func hint(for action: WorkshopAction) -> String {
        switch action {
        case .commission:
            if let c = store.commission, !c.delivered,
               let p = Content.project(c.projectID) { return "Today: \(p.name)" }
            return "Free forge"
        case .nextPiece: return nextUp?.name ?? "Every commission finished"
        case .tools: return "\(store.unlockedTools.count) of \(ForgeTool.allCases.count) earned"
        case .book: return "\(store.save.best.count) of \(Content.projects.count) done"
        case .almanac: return "\(store.save.guidesRead.count) of \(Content.guides.count) read"
        case .journal: return "\(store.save.totalPieces) pieces logged"
        case .gallery: return "\(store.save.best.count) on the wall"
        }
    }

    // MARK: Interaction

    private func tap(at p: CGPoint, sceneW: CGFloat, size: CGSize) {
        let sceneX = p.x - pan
        for spot in WorkshopMap.spots {
            let r = spot.rect(sceneWidth: sceneW, height: size.height)
            if r.insetBy(dx: -10, dy: -10).contains(CGPoint(x: sceneX, y: p.y)) {
                ForgeSound.shared.play(.tap, volume: 0.5)
                ForgeSound.shared.bump(0)
                withAnimation(.easeOut(duration: 0.15)) { touched = spot }
                let picked = spot
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                    guard touched?.id == picked.id else { return }
                    withAnimation { touched = nil }
                    perform(picked.action)
                }
                return
            }
        }
        withAnimation { touched = nil }
    }

    private func perform(_ action: WorkshopAction) {
        switch action {
        case .commission:
            if let c = store.commission, !c.delivered, let p = Content.project(c.projectID) {
                onStart(p, c.metal)
            } else {
                onStart(nil, store.unlockedMetals.first ?? .mildSteel)
            }
        case .nextPiece:
            if let p = nextUp { onStart(p, p.stock) } else { onTab(1) }
        case .tools: showTools = true
        case .book: onTab(1)
        case .almanac: onTab(2)
        case .journal: onTab(3)
        case .gallery: showGallery = true
        }
    }
}

// MARK: - The room

struct WorkshopCanvas: View {
    @ObservedObject var store: ForgeStore
    let phase: DayPhase
    let pan: CGFloat
    let sceneWidth: CGFloat
    let highlighted: String?

    private var earnedSpots: Set<ShopSpot> {
        var out: Set<ShopSpot> = []
        for p in Content.projects where store.best(p.id) != nil { out.insert(p.spot) }
        return out
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: false)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                draw(&ctx, size: size, t: t)
            }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let H = size.height
        let W = sceneWidth
        let spots = earnedSpots
        let flicker = 0.84 + 0.16 * sin(t * 3.3) * cos(t * 1.9)

        // Layers move at different rates, which is what sells the depth.
        let back = pan * 0.55
        let mid = pan
        let front = pan * 1.22

        // ── Ground ─────────────────────────────────────────────────────
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .linearGradient(Gradient(colors: [
                    Color(red: 0.104, green: 0.086, blue: 0.078),
                    Color(red: 0.055, green: 0.045, blue: 0.041)
                 ]), startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: H)))

        // ── Back layer: wall, window, beams ────────────────────────────
        var b = ctx
        b.translateBy(x: back, y: 0)
        drawWall(&b, W: W, H: H, phase: phase)
        drawWindow(&b, x: W * 0.115, H: H, phase: phase, t: t)
        drawBeams(&b, W: W, H: H)

        // ── Mid layer: the furniture of the shop ───────────────────────
        var m = ctx
        m.translateBy(x: mid, y: 0)
        drawFinishedWall(&m, x: W * 0.020, W: W, H: H, store: store)
        drawDesk(&m, x: W * 0.185, W: W, H: H)
        drawLectern(&m, x: W * 0.305, W: W, H: H)
        drawToolRack(&m, x: W * 0.425, W: W, H: H, store: store)
        drawBench(&m, x: W * 0.430, W: W, H: H)
        drawAnvilBlock(&m, x: W * 0.605, W: W, H: H, glow: flicker)
        drawForge(&m, x: W * 0.790, W: W, H: H, level: flicker, t: t)
        if spots.contains(.hearthSide) { drawFiresideSet(&m, x: W * 0.735, H: H) }
        if spots.contains(.ceilingHook) { drawHangingWork(&m, x: W * 0.545, H: H, t: t) }

        // ── Front layer: props and light ───────────────────────────────
        var f = ctx
        f.translateBy(x: front, y: 0)
        drawFloorProps(&f, W: W, H: H, spots: spots)

        // Firelight washes across everything from the forge.
        let firePoint = CGPoint(x: W * 0.875 + mid, y: H * 0.52)
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .radialGradient(Gradient(colors: [
                    Forge.ember.opacity(0.20 * flicker), Color.clear
                 ]), center: firePoint, startRadius: 0, endRadius: size.width * 0.85))

        drawMotes(&ctx, size: size, t: t, phase: phase)

        // Corner darkening.
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .radialGradient(Gradient(colors: [
                    Color.clear, Color.black.opacity(0.58)
                 ]), center: CGPoint(x: size.width / 2, y: H / 2),
                 startRadius: size.width * 0.26, endRadius: size.width * 0.86))

        // Touch highlight.
        if let id = highlighted,
           let spot = WorkshopMap.spots.first(where: { $0.id == id }) {
            let r = spot.rect(sceneWidth: W, height: H).offsetBy(dx: mid, dy: 0)
            ctx.stroke(Path(roundedRect: r.insetBy(dx: -6, dy: -6), cornerRadius: 10),
                       with: .color(Forge.spark.opacity(0.75)),
                       style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
        }
    }

    // MARK: Back layer

    private func drawWall(_ ctx: inout GraphicsContext, W: CGFloat, H: CGFloat, phase: DayPhase) {
        ctx.fill(Path(CGRect(x: 0, y: 0, width: W, height: H)),
                 with: .linearGradient(Gradient(colors: [
                    Color(red: 0.128, green: 0.106, blue: 0.094),
                    Color(red: 0.072, green: 0.059, blue: 0.052)
                 ]), startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: H)))
        for i in 0...13 {
            let y = H * Double(i) / 13.0
            var line = Path()
            line.move(to: CGPoint(x: 0, y: y))
            line.addLine(to: CGPoint(x: W, y: y))
            ctx.stroke(line, with: .color(Color.black.opacity(0.26)), lineWidth: 1.4)
            var hi = Path()
            hi.move(to: CGPoint(x: 0, y: y + 2))
            hi.addLine(to: CGPoint(x: W, y: y + 2))
            ctx.stroke(hi, with: .color(Color.white.opacity(0.026)), lineWidth: 1)
        }
        // Soot creeping up the wall behind the fire.
        ctx.fill(Path(CGRect(x: W * 0.70, y: 0, width: W * 0.30, height: H)),
                 with: .radialGradient(Gradient(colors: [
                    Color.black.opacity(0.45), Color.clear
                 ]), center: CGPoint(x: W * 0.88, y: H * 0.10),
                 startRadius: 0, endRadius: H * 0.75))
    }

    private func drawWindow(_ ctx: inout GraphicsContext, x: CGFloat, H: CGFloat,
                            phase: DayPhase, t: Double) {
        let rect = CGRect(x: x, y: H * 0.12, width: H * 0.30, height: H * 0.30)
        ctx.fill(Path(roundedRect: rect, cornerRadius: 3),
                 with: .linearGradient(Gradient(colors: phase.windowSky),
                                       startPoint: CGPoint(x: rect.minX, y: rect.minY),
                                       endPoint: CGPoint(x: rect.minX, y: rect.maxY)))
        if phase == .night {
            for i in 0..<12 {
                let fx = Double((i * 37) % 100) / 100
                let fy = Double((i * 61) % 100) / 100
                let tw = 0.35 + 0.65 * abs(sin(t * 1.05 + Double(i)))
                ctx.fill(Path(ellipseIn: CGRect(x: rect.minX + rect.width * (0.07 + fx * 0.86),
                                                y: rect.minY + rect.height * (0.06 + fy * 0.55),
                                                width: 2, height: 2)),
                         with: .color(Color.white.opacity(0.8 * tw)))
            }
        }
        var hills = Path()
        hills.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        hills.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),
                           control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.52))
        hills.closeSubpath()
        ctx.fill(hills, with: .color(Color.black.opacity(0.45)))

        ctx.stroke(Path(roundedRect: rect, cornerRadius: 3),
                   with: .color(Color(red: 0.20, green: 0.15, blue: 0.11)), lineWidth: 7)
        var bars = Path()
        bars.move(to: CGPoint(x: rect.midX, y: rect.minY))
        bars.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        bars.move(to: CGPoint(x: rect.minX, y: rect.midY))
        bars.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        ctx.stroke(bars, with: .color(Color(red: 0.18, green: 0.14, blue: 0.10)), lineWidth: 4)

        // A shaft of daylight falling into the room.
        if phase.daylight > 0.2 {
            var shaft = Path()
            shaft.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            shaft.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            shaft.addLine(to: CGPoint(x: rect.maxX + H * 0.30, y: H))
            shaft.addLine(to: CGPoint(x: rect.minX + H * 0.16, y: H))
            shaft.closeSubpath()
            ctx.fill(shaft, with: .linearGradient(Gradient(colors: [
                Color.white.opacity(0.085 * phase.daylight), Color.clear
            ]), startPoint: CGPoint(x: rect.midX, y: rect.maxY),
            endPoint: CGPoint(x: rect.midX, y: H)))
        }
    }

    private func drawBeams(_ ctx: inout GraphicsContext, W: CGFloat, H: CGFloat) {
        ctx.fill(Path(CGRect(x: 0, y: 0, width: W, height: H * 0.052)),
                 with: .linearGradient(Gradient(colors: [
                    Color(red: 0.20, green: 0.145, blue: 0.096),
                    Color(red: 0.128, green: 0.090, blue: 0.058)
                 ]), startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: H * 0.052)))
        for i in 0..<7 {
            let x = W * (0.06 + Double(i) * 0.145)
            ctx.fill(Path(CGRect(x: x, y: 0, width: H * 0.035, height: H * 0.10)),
                     with: .color(Color(red: 0.16, green: 0.115, blue: 0.075)))
        }
    }

    // MARK: Mid layer

    private func drawFinishedWall(_ ctx: inout GraphicsContext, x: CGFloat, W: CGFloat,
                                  H: CGFloat, store: ForgeStore) {
        let boardW = W * 0.150
        let board = CGRect(x: x, y: H * 0.26, width: boardW, height: H * 0.44)
        ctx.fill(Path(roundedRect: board, cornerRadius: 4),
                 with: .linearGradient(Gradient(colors: [
                    Color(red: 0.212, green: 0.152, blue: 0.098),
                    Color(red: 0.135, green: 0.095, blue: 0.060)
                 ]), startPoint: CGPoint(x: board.minX, y: board.minY),
                 endPoint: CGPoint(x: board.maxX, y: board.maxY)))
        ctx.stroke(Path(roundedRect: board, cornerRadius: 4),
                   with: .color(Color.black.opacity(0.5)), lineWidth: 2)

        // Every finished piece gets a peg and a hanging silhouette.
        let done = Content.projects.filter { store.best($0.id) != nil }
        let cols = 4
        for (i, p) in done.prefix(16).enumerated() {
            let col = i % cols, row = i / cols
            let cx = board.minX + board.width * (0.16 + Double(col) * 0.23)
            let cy = board.minY + board.height * (0.14 + Double(row) * 0.24)
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 3, y: cy - 3, width: 6, height: 6)),
                     with: .color(Color(red: 0.42, green: 0.39, blue: 0.36)))
            let s = board.width * 0.19
            let cell = CGRect(x: cx - s / 2, y: cy + 4, width: s, height: s * 0.8)
            drawPieceGlyph(&ctx, project: p, in: cell)
        }
        if done.isEmpty {
            ctx.draw(Text("nothing hung yet").font(Forge.body(9))
                        .foregroundColor(Forge.chalkFaint),
                     at: CGPoint(x: board.midX, y: board.midY), anchor: .center)
        }
    }

    /// A tiny silhouette of a finished piece, from its own profile data.
    private func drawPieceGlyph(_ ctx: inout GraphicsContext, project: ForgeProject, in rect: CGRect) {
        let target = TargetShape(project: project)
        var segs: [BarSegment] = []
        let segLen = target.totalLength / Double(Workpiece.count)
        for s in target.samples {
            segs.append(BarSegment(thickness: s.t, width: s.w, length: segLen))
        }
        var bends = [Double](repeating: 0, count: Workpiece.count)
        for f in target.features where f.kind == .bend {
            bends[ForgeJudge.index(for: f.at)] += f.amount
        }
        let g = BarGeometry.build(segments: segs, bends: bends, in: rect)
        ctx.fill(g.outline, with: .color(Color(red: 0.46, green: 0.44, blue: 0.42)))
        ctx.stroke(g.outline, with: .color(Color.black.opacity(0.55)), lineWidth: 0.7)
    }

    private func drawDesk(_ ctx: inout GraphicsContext, x: CGFloat, W: CGFloat, H: CGFloat) {
        let w = W * 0.110
        let top = CGRect(x: x, y: H * 0.64, width: w, height: H * 0.035)
        ctx.fill(Path(top), with: .color(Color(red: 0.212, green: 0.152, blue: 0.098)))
        for s in [0.12, 0.82] {
            ctx.fill(Path(CGRect(x: x + w * s, y: top.maxY, width: w * 0.07, height: H * 0.26)),
                     with: .color(Color(red: 0.155, green: 0.110, blue: 0.070)))
        }
        // The ledger, open on the desk.
        let book = CGRect(x: x + w * 0.16, y: H * 0.585, width: w * 0.68, height: H * 0.055)
        ctx.fill(Path(roundedRect: book, cornerRadius: 2),
                 with: .color(Color(red: 0.78, green: 0.74, blue: 0.66)))
        ctx.stroke(Path(roundedRect: book, cornerRadius: 2),
                   with: .color(Color(red: 0.30, green: 0.22, blue: 0.14)), lineWidth: 2)
        for i in 0..<4 {
            var l = Path()
            let y = book.minY + book.height * (0.25 + Double(i) * 0.18)
            l.move(to: CGPoint(x: book.minX + 5, y: y))
            l.addLine(to: CGPoint(x: book.maxX - 5, y: y))
            ctx.stroke(l, with: .color(Color.black.opacity(0.3)), lineWidth: 0.8)
        }
    }

    private func drawLectern(_ ctx: inout GraphicsContext, x: CGFloat, W: CGFloat, H: CGFloat) {
        let w = W * 0.105
        var stand = Path()
        stand.move(to: CGPoint(x: x + w * 0.5, y: H * 0.86))
        stand.addLine(to: CGPoint(x: x + w * 0.5, y: H * 0.60))
        ctx.stroke(stand, with: .color(Color(red: 0.185, green: 0.132, blue: 0.086)), lineWidth: 9)
        ctx.fill(Path(ellipseIn: CGRect(x: x + w * 0.22, y: H * 0.845, width: w * 0.56, height: H * 0.035)),
                 with: .color(Color(red: 0.165, green: 0.118, blue: 0.076)))
        // The almanac, open on it.
        var page = Path()
        page.move(to: CGPoint(x: x, y: H * 0.585))
        page.addLine(to: CGPoint(x: x + w, y: H * 0.585))
        page.addLine(to: CGPoint(x: x + w * 0.92, y: H * 0.475))
        page.addLine(to: CGPoint(x: x + w * 0.08, y: H * 0.475))
        page.closeSubpath()
        ctx.fill(page, with: .linearGradient(Gradient(colors: [
            Color(red: 0.86, green: 0.82, blue: 0.73), Color(red: 0.72, green: 0.68, blue: 0.60)
        ]), startPoint: CGPoint(x: x, y: H * 0.475), endPoint: CGPoint(x: x, y: H * 0.585)))
        ctx.stroke(page, with: .color(Color.black.opacity(0.45)), lineWidth: 1.4)
        var spine = Path()
        spine.move(to: CGPoint(x: x + w * 0.5, y: H * 0.585))
        spine.addLine(to: CGPoint(x: x + w * 0.5, y: H * 0.475))
        ctx.stroke(spine, with: .color(Color.black.opacity(0.4)), lineWidth: 2)
    }

    private func drawToolRack(_ ctx: inout GraphicsContext, x: CGFloat, W: CGFloat,
                              H: CGFloat, store: ForgeStore) {
        let w = W * 0.150
        let rail = CGRect(x: x, y: H * 0.30, width: w, height: H * 0.022)
        ctx.fill(Path(rail), with: .color(Color(red: 0.206, green: 0.148, blue: 0.094)))
        let tools = store.unlockedTools
        for (i, _) in tools.enumerated() {
            let cx = rail.minX + w * (0.11 + Double(i) * 0.155)
            ctx.fill(Path(roundedRect: CGRect(x: cx, y: rail.maxY, width: 4, height: H * 0.10),
                          cornerRadius: 2),
                     with: .color(Color(red: 0.31, green: 0.22, blue: 0.14)))
            ctx.fill(Path(roundedRect: CGRect(x: cx - 8, y: rail.maxY + H * 0.10,
                                              width: 20, height: H * 0.035),
                          cornerRadius: 2),
                     with: .linearGradient(Gradient(colors: [
                        Color(red: 0.40, green: 0.39, blue: 0.38),
                        Color(red: 0.22, green: 0.21, blue: 0.21)
                     ]), startPoint: CGPoint(x: cx, y: rail.maxY + H * 0.10),
                     endPoint: CGPoint(x: cx, y: rail.maxY + H * 0.135)))
        }
    }

    private func drawBench(_ ctx: inout GraphicsContext, x: CGFloat, W: CGFloat, H: CGFloat) {
        let w = W * 0.150
        let top = CGRect(x: x, y: H * 0.66, width: w, height: H * 0.04)
        ctx.fill(Path(top), with: .linearGradient(Gradient(colors: [
            Color(red: 0.225, green: 0.162, blue: 0.104),
            Color(red: 0.150, green: 0.106, blue: 0.068)
        ]), startPoint: CGPoint(x: 0, y: top.minY), endPoint: CGPoint(x: 0, y: top.maxY)))
        for s in [0.08, 0.86] {
            ctx.fill(Path(CGRect(x: x + w * s, y: top.maxY, width: w * 0.06, height: H * 0.24)),
                     with: .color(Color(red: 0.150, green: 0.106, blue: 0.068)))
        }
        // A drawing pinned to the bench.
        let sheet = CGRect(x: x + w * 0.14, y: H * 0.60, width: w * 0.70, height: H * 0.055)
        ctx.fill(Path(sheet), with: .color(Color(red: 0.80, green: 0.77, blue: 0.69)))
        ctx.stroke(Path(sheet), with: .color(Color.black.opacity(0.35)), lineWidth: 1)
        var draw = Path()
        draw.move(to: CGPoint(x: sheet.minX + 8, y: sheet.midY))
        draw.addLine(to: CGPoint(x: sheet.maxX - 22, y: sheet.midY - 3))
        draw.addQuadCurve(to: CGPoint(x: sheet.maxX - 8, y: sheet.midY + 10),
                          control: CGPoint(x: sheet.maxX - 4, y: sheet.midY - 4))
        ctx.stroke(draw, with: .color(Color.black.opacity(0.55)), lineWidth: 1.6)
    }

    private func drawAnvilBlock(_ ctx: inout GraphicsContext, x: CGFloat, W: CGFloat,
                                H: CGFloat, glow: Double) {
        let w = W * 0.150
        let baseY = H * 0.78
        let cx = x + w * 0.5
        // Stump.
        let stump = CGRect(x: cx - w * 0.24, y: baseY, width: w * 0.48, height: H * 0.20)
        ctx.fill(Path(roundedRect: stump, cornerRadius: 3),
                 with: .linearGradient(Gradient(colors: [
                    Color(red: 0.225, green: 0.158, blue: 0.100),
                    Color(red: 0.130, green: 0.090, blue: 0.056)
                 ]), startPoint: CGPoint(x: stump.minX, y: 0), endPoint: CGPoint(x: stump.maxX, y: 0)))
        for i in 0..<5 {
            var g = Path()
            let gx = stump.minX + stump.width * Double(i) / 5 + 4
            g.move(to: CGPoint(x: gx, y: stump.minY))
            g.addLine(to: CGPoint(x: gx, y: stump.maxY))
            ctx.stroke(g, with: .color(Color.black.opacity(0.24)), lineWidth: 1.2)
        }
        // Anvil.
        var a = Path()
        a.move(to: CGPoint(x: cx - w * 0.34, y: baseY - H * 0.115))
        a.addLine(to: CGPoint(x: cx + w * 0.20, y: baseY - H * 0.115))
        a.addQuadCurve(to: CGPoint(x: cx + w * 0.46, y: baseY - H * 0.072),
                       control: CGPoint(x: cx + w * 0.44, y: baseY - H * 0.118))
        a.addQuadCurve(to: CGPoint(x: cx + w * 0.17, y: baseY - H * 0.058),
                       control: CGPoint(x: cx + w * 0.40, y: baseY - H * 0.046))
        a.addLine(to: CGPoint(x: cx + w * 0.09, y: baseY - H * 0.058))
        a.addLine(to: CGPoint(x: cx + w * 0.05, y: baseY - H * 0.016))
        a.addLine(to: CGPoint(x: cx + w * 0.20, y: baseY))
        a.addLine(to: CGPoint(x: cx - w * 0.26, y: baseY))
        a.addLine(to: CGPoint(x: cx - w * 0.11, y: baseY - H * 0.016))
        a.addLine(to: CGPoint(x: cx - w * 0.15, y: baseY - H * 0.058))
        a.addLine(to: CGPoint(x: cx - w * 0.34, y: baseY - H * 0.058))
        a.closeSubpath()
        ctx.fill(a, with: .linearGradient(Gradient(colors: [
            Color(red: 0.44, green: 0.42, blue: 0.41),
            Color(red: 0.17, green: 0.16, blue: 0.16)
        ]), startPoint: CGPoint(x: 0, y: baseY - H * 0.115), endPoint: CGPoint(x: 0, y: baseY)))
        var face = Path()
        face.move(to: CGPoint(x: cx - w * 0.34, y: baseY - H * 0.112))
        face.addLine(to: CGPoint(x: cx + w * 0.20, y: baseY - H * 0.112))
        ctx.stroke(face, with: .color(Forge.spark.opacity(0.55 * glow)), lineWidth: 2.4)
    }

    private func drawForge(_ ctx: inout GraphicsContext, x: CGFloat, W: CGFloat,
                           H: CGFloat, level: Double, t: Double) {
        let w = W * 0.190
        // Hood.
        var hood = Path()
        hood.move(to: CGPoint(x: x - w * 0.06, y: H * 0.36))
        hood.addLine(to: CGPoint(x: x + w * 1.04, y: H * 0.36))
        hood.addLine(to: CGPoint(x: x + w * 0.86, y: H * 0.03))
        hood.addLine(to: CGPoint(x: x + w * 0.16, y: H * 0.03))
        hood.closeSubpath()
        ctx.fill(hood, with: .linearGradient(Gradient(colors: [
            Color(red: 0.150, green: 0.128, blue: 0.116),
            Color(red: 0.085, green: 0.072, blue: 0.065)
        ]), startPoint: CGPoint(x: 0, y: H * 0.03), endPoint: CGPoint(x: 0, y: H * 0.36)))
        ctx.stroke(hood, with: .color(Color.black.opacity(0.55)), lineWidth: 2)

        // Brick pot.
        let pot = CGRect(x: x, y: H * 0.38, width: w, height: H * 0.30)
        ctx.fill(Path(roundedRect: pot, cornerRadius: 5),
                 with: .color(Color(red: 0.225, green: 0.160, blue: 0.128)))
        let rows = 4, cols = 5
        for r in 0..<rows {
            for c in 0...cols {
                let off: CGFloat = r % 2 == 0 ? 0 : pot.width / CGFloat(cols) / 2
                let bw = pot.width / CGFloat(cols) - 3
                let bh = pot.height / CGFloat(rows) - 3
                let bx = pot.minX + CGFloat(c) * pot.width / CGFloat(cols) + off
                let by = pot.minY + CGFloat(r) * pot.height / CGFloat(rows)
                guard bx + bw < pot.maxX else { continue }
                ctx.fill(Path(roundedRect: CGRect(x: bx + 1.5, y: by + 1.5, width: bw, height: bh),
                              cornerRadius: 1.5),
                         with: .color(Color(red: 0.272, green: 0.192, blue: 0.152).opacity(0.85)))
            }
        }

        // The coal bed and its light.
        let bed = CGRect(x: pot.minX + w * 0.14, y: pot.minY + pot.height * 0.14,
                         width: w * 0.72, height: pot.height * 0.40)
        ctx.fill(Path(ellipseIn: bed), with: .color(Color(red: 0.055, green: 0.045, blue: 0.040)))
        ctx.fill(Path(ellipseIn: bed.insetBy(dx: -bed.width * 0.5, dy: -bed.height * 1.4)),
                 with: .radialGradient(Gradient(colors: [
                    Forge.white.opacity(0.85 * level),
                    Forge.flame.opacity(0.55 * level),
                    Forge.emberDeep.opacity(0.22 * level),
                    Color.clear
                 ]), center: CGPoint(x: bed.midX, y: bed.midY),
                 startRadius: 0, endRadius: bed.width * 0.85))
        for i in 0..<20 {
            let a = Double(i) * 0.79
            let rr = 0.20 + Double((i * 31) % 60) / 100 * 0.30
            let s = bed.width * 0.09
            ctx.fill(Path(roundedRect: CGRect(x: bed.midX + cos(a) * bed.width * rr - s / 2,
                                              y: bed.midY + sin(a) * bed.height * rr - s * 0.35,
                                              width: s, height: s * 0.7), cornerRadius: 2),
                     with: .color(Color.black.opacity(0.55)))
        }

        // Bellows handle, breathing slowly.
        var lever = Path()
        let swing = sin(t * 0.7) * 4
        lever.move(to: CGPoint(x: pot.maxX + w * 0.10, y: pot.midY + swing))
        lever.addLine(to: CGPoint(x: pot.maxX - w * 0.05, y: pot.midY + H * 0.06 + swing * 0.4))
        ctx.stroke(lever, with: .color(Color(red: 0.28, green: 0.20, blue: 0.13)), lineWidth: 6)

        // Embers rising into the hood.
        for i in 0..<26 {
            let seed = Double(i) * 12.9898
            let speed = 0.14 + seed.truncatingRemainder(dividingBy: 0.10)
            let life = (t * speed + Double(i) / 26).truncatingRemainder(dividingBy: 1)
            let drift = sin(t * 0.9 + seed) * w * 0.06
            let ex = bed.midX + (seed.truncatingRemainder(dividingBy: 0.6) - 0.3) * bed.width + drift
            let ey = bed.midY - life * H * 0.34
            let fade = (1 - life) * level
            guard fade > 0.03 else { continue }
            let r = 1.2 + (1 - life) * 2.0
            ctx.fill(Path(ellipseIn: CGRect(x: ex, y: ey, width: r, height: r)),
                     with: .color(Forge.spark.opacity(0.9 * fade)))
        }
    }

    private func drawFiresideSet(_ ctx: inout GraphicsContext, x: CGFloat, H: CGFloat) {
        for i in 0..<3 {
            let px = x + Double(i) * 14
            var rod = Path()
            rod.move(to: CGPoint(x: px, y: H * 0.98))
            rod.addLine(to: CGPoint(x: px + 26, y: H * 0.52))
            ctx.stroke(rod, with: .color(Color(red: 0.40, green: 0.38, blue: 0.36)),
                       style: StrokeStyle(lineWidth: 3, lineCap: .round))
            var curl = Path()
            curl.addArc(center: CGPoint(x: px + 28, y: H * 0.505), radius: H * 0.018,
                        startAngle: .degrees(70), endAngle: .degrees(330), clockwise: false)
            ctx.stroke(curl, with: .color(Color(red: 0.40, green: 0.38, blue: 0.36)), lineWidth: 2.6)
        }
    }

    private func drawHangingWork(_ ctx: inout GraphicsContext, x: CGFloat, H: CGFloat, t: Double) {
        for i in 0..<3 {
            let px = x + Double(i) * 26
            let sway = sin(t * 0.55 + Double(i) * 1.3) * 2
            var chain = Path()
            chain.move(to: CGPoint(x: px, y: H * 0.052))
            chain.addLine(to: CGPoint(x: px + sway, y: H * 0.16))
            ctx.stroke(chain, with: .color(Color(red: 0.33, green: 0.31, blue: 0.29)), lineWidth: 1.6)
            var s = Path()
            s.addArc(center: CGPoint(x: px + sway, y: H * 0.185), radius: H * 0.026,
                     startAngle: .degrees(120), endAngle: .degrees(340), clockwise: false)
            s.addArc(center: CGPoint(x: px + sway, y: H * 0.234), radius: H * 0.026,
                     startAngle: .degrees(200), endAngle: .degrees(20), clockwise: true)
            ctx.stroke(s, with: .color(Color(red: 0.42, green: 0.40, blue: 0.38)),
                       style: StrokeStyle(lineWidth: 2.8, lineCap: .round))
        }
    }

    // MARK: Front layer

    private func drawFloorProps(_ ctx: inout GraphicsContext, W: CGFloat, H: CGFloat,
                                spots: Set<ShopSpot>) {
        // Floor.
        ctx.fill(Path(CGRect(x: 0, y: H * 0.86, width: W, height: H * 0.14)),
                 with: .linearGradient(Gradient(colors: [
                    Color(red: 0.118, green: 0.098, blue: 0.086),
                    Color(red: 0.062, green: 0.050, blue: 0.044)
                 ]), startPoint: CGPoint(x: 0, y: H * 0.86), endPoint: CGPoint(x: 0, y: H)))
        for i in 0..<70 {
            let fx = Double((i * 73) % 100) / 100
            let fy = Double((i * 47) % 100) / 100
            ctx.fill(Path(ellipseIn: CGRect(x: W * fx, y: H * (0.87 + fy * 0.12),
                                            width: 2.6, height: 1.6)),
                     with: .color(Color.black.opacity(0.4)))
        }
        // Slack tub beside the anvil.
        let tub = CGRect(x: W * 0.700, y: H * 0.80, width: W * 0.045, height: H * 0.16)
        ctx.fill(Path(roundedRect: tub, cornerRadius: 3),
                 with: .color(Color(red: 0.185, green: 0.130, blue: 0.082)))
        ctx.fill(Path(ellipseIn: CGRect(x: tub.minX + 3, y: tub.minY + 2,
                                        width: tub.width - 6, height: tub.height * 0.22)),
                 with: .color(Forge.quench.opacity(0.5)))
        var band = Path()
        band.move(to: CGPoint(x: tub.minX, y: tub.midY))
        band.addLine(to: CGPoint(x: tub.maxX, y: tub.midY))
        ctx.stroke(band, with: .color(Color(red: 0.34, green: 0.32, blue: 0.30)), lineWidth: 2)

        // Coal scuttle by the forge.
        let scuttle = CGRect(x: W * 0.965, y: H * 0.83, width: W * 0.036, height: H * 0.12)
        ctx.fill(Path(roundedRect: scuttle, cornerRadius: 4),
                 with: .color(Color(red: 0.140, green: 0.125, blue: 0.115)))
        ctx.fill(Path(ellipseIn: CGRect(x: scuttle.minX + 2, y: scuttle.minY,
                                        width: scuttle.width - 4, height: scuttle.height * 0.3)),
                 with: .color(Color.black.opacity(0.8)))

        if spots.contains(.floor) {
            let cx = W * 0.360, cy = H * 0.945
            var ring = Path()
            ring.addEllipse(in: CGRect(x: cx - 16, y: cy - 7, width: 32, height: 14))
            ctx.stroke(ring, with: .color(Color(red: 0.38, green: 0.36, blue: 0.34)), lineWidth: 2)
        }
    }

    private func drawMotes(_ ctx: inout GraphicsContext, size: CGSize, t: Double, phase: DayPhase) {
        let n = 34
        for i in 0..<n {
            let seed = Double(i) * 7.13
            let sp = 0.02 + seed.truncatingRemainder(dividingBy: 0.03)
            let ph = (t * sp + Double(i) / Double(n)).truncatingRemainder(dividingBy: 1)
            let x = size.width * ((seed.truncatingRemainder(dividingBy: 1.0)))
            let y = size.height * (1 - ph)
            let drift = sin(t * 0.4 + seed) * 14
            let a = 0.10 + 0.22 * abs(sin(t * 0.6 + seed)) * (phase.daylight + 0.3)
            ctx.fill(Path(ellipseIn: CGRect(x: x + drift, y: y, width: 2.0, height: 2.0)),
                     with: .color(Color.white.opacity(a)))
        }
    }
}

// MARK: - Sheets reached from the room

struct ToolRackSheet: View {
    @ObservedObject var store: ForgeStore
    let onClose: () -> Void

    var body: some View {
        ForgeSheet(title: "The Rack", onClose: onClose) {
            Text("Tools come to the rack as your standing in the trade grows. A commission always lends you whatever its drawing calls for, earned or not.")
                .font(Forge.body(13))
                .foregroundColor(Forge.chalkDim)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(ForgeTool.allCases) { t in
                let open = store.unlockedTools.contains(t)
                HStack(alignment: .top, spacing: 12) {
                    ToolGlyph(tool: t, size: 26, color: open ? Forge.brass : Forge.chalkFaint)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(t.name)
                                .font(Forge.heading(14))
                                .foregroundColor(open ? Forge.chalk : Forge.chalkFaint)
                            Spacer()
                            if !open { LockMark(size: 13) }
                        }
                        Text(t.hint)
                            .font(Forge.body(11))
                            .foregroundColor(Forge.chalkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                        if !open {
                            Text("Comes to the rack at \(Content.ranks[t.unlockRank].name).")
                                .font(Forge.body(10))
                                .foregroundColor(Forge.brass)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .forgeCard(padding: 12)
            }
        }
    }
}

struct GallerySheet: View {
    @ObservedObject var store: ForgeStore
    let onClose: () -> Void

    @State private var shown: ForgeProject? = nil

    private var done: [ForgeProject] {
        Content.projects.filter { store.best($0.id) != nil }
    }

    var body: some View {
        ForgeSheet(title: "Finished Work", onClose: onClose) {
            if done.isEmpty {
                Text("The wall is bare. Everything you finish is hung here, with the plate it was drawn from.")
                    .font(Forge.body(13))
                    .foregroundColor(Forge.chalkDim)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("\(done.count) of \(Content.projects.count) hung.")
                    .font(Forge.body(12))
                    .foregroundColor(Forge.chalkFaint)
                ForEach(done) { p in
                    VStack(alignment: .leading, spacing: 9) {
                        ForgePlate(name: "piece_\(p.id)", height: Forge.wide ? 240 : 178,
                                   corner: Forge.cornerSmall)
                        HStack {
                            Text(p.name)
                                .font(Forge.heading(15))
                                .foregroundColor(Forge.chalk)
                            Spacer()
                            if let b = store.best(p.id) {
                                StarRow(stars: b.stars, size: 12)
                                QualityTag(quality: b.quality)
                            }
                        }
                        if let b = store.best(p.id) {
                            Text("\(b.metal.name) · \(b.strikes) blows · \(b.heats) heats · \(DayKey.label(b.dateKey))")
                                .font(Forge.body(10))
                                .foregroundColor(Forge.chalkFaint)
                        }
                    }
                    .forgeCard()
                }
            }
        }
    }
}
