import SwiftUI

// MARK: - Geometry shared by the renderer and the hit test

struct BarGeometry {
    var points: [CGPoint] = []      // centreline, already fitted to the stage
    var halfT: [CGFloat] = []       // half thickness at each point, in points
    var widthScale: [CGFloat] = []  // 0…1 how wide that section is, for shading
    var outline = Path()

    /// Builds a centreline that follows the accumulated bends, offsets it by the
    /// local half-thickness, and fits the result into `rect`.
    static func build(segments: [BarSegment], bends: [Double], in rect: CGRect,
                      spread: Double = 1.0) -> BarGeometry {
        var g = BarGeometry()
        guard !segments.isEmpty else { return g }

        // Real metal does not fold at a point: a bend levered in at one spot
        // spreads into its neighbours. Smear each stored angle over five joints,
        // preserving the total, so a 150° hook reads as a curve and not a spike.
        var smoothed = [Double](repeating: 0, count: segments.count)
        let kernel: [Double] = [0.12, 0.20, 0.36, 0.20, 0.12]
        for i in segments.indices {
            let amount = i < bends.count ? bends[i] : 0
            guard amount != 0 else { continue }
            for (k, weight) in kernel.enumerated() {
                let j = max(0, min(segments.count - 1, i + k - 2))
                smoothed[j] += amount * weight
            }
        }

        // Walk the centreline in millimetres.
        var pts: [CGPoint] = []
        var half: [CGFloat] = []
        var widths: [CGFloat] = []
        var angle: Double = 0
        var cursor = CGPoint(x: 0, y: 0)
        pts.append(cursor)
        half.append(CGFloat(segments[0].thickness / 2))
        widths.append(CGFloat(segments[0].width))

        for i in segments.indices {
            let bendHere = smoothed[i] * Double.pi / 180 * spread
            angle += bendHere
            let l = segments[i].length
            cursor = CGPoint(x: cursor.x + CGFloat(cos(angle) * l),
                             y: cursor.y + CGFloat(sin(angle) * l))
            pts.append(cursor)
            half.append(CGFloat(segments[i].thickness / 2))
            widths.append(CGFloat(segments[i].width))
        }

        // Fit into the stage.
        var minX = pts[0].x, maxX = pts[0].x, minY = pts[0].y, maxY = pts[0].y
        for (i, p) in pts.enumerated() {
            let h = half[i]
            minX = min(minX, p.x - h); maxX = max(maxX, p.x + h)
            minY = min(minY, p.y - h); maxY = max(maxY, p.y + h)
        }
        let bw = max(1, maxX - minX), bh = max(1, maxY - minY)
        let scale = min(rect.width / bw, rect.height / bh)
        let offX = rect.midX - (minX + bw / 2) * scale
        let offY = rect.midY - (minY + bh / 2) * scale

        g.points = pts.map { CGPoint(x: $0.x * scale + offX, y: $0.y * scale + offY) }
        g.halfT = half.map { max(1.2, $0 * scale) }
        let maxW = widths.max() ?? 1
        g.widthScale = widths.map { maxW > 0 ? $0 / maxW : 1 }

        // Offset outline.
        var top: [CGPoint] = []
        var bottom: [CGPoint] = []
        for i in g.points.indices {
            let prev = g.points[max(0, i - 1)]
            let next = g.points[min(g.points.count - 1, i + 1)]
            var dx = next.x - prev.x, dy = next.y - prev.y
            let len = max(0.0001, sqrt(dx * dx + dy * dy))
            dx /= len; dy /= len
            let nx = -dy, ny = dx
            let h = g.halfT[i]
            top.append(CGPoint(x: g.points[i].x + nx * h, y: g.points[i].y + ny * h))
            bottom.append(CGPoint(x: g.points[i].x - nx * h, y: g.points[i].y - ny * h))
        }
        var path = Path()
        if let first = top.first {
            path.move(to: first)
            for p in top.dropFirst() { path.addLine(to: p) }
            for p in bottom.reversed() { path.addLine(to: p) }
            path.closeSubpath()
        }
        g.outline = path
        return g
    }

    /// Nearest centreline index to a tap, expressed as 0…1 along the bar.
    func position(nearest point: CGPoint) -> Double {
        guard points.count > 1 else { return 0.5 }
        var bestIdx = 0
        var bestD = CGFloat.greatestFiniteMagnitude
        for (i, p) in points.enumerated() {
            let d = (p.x - point.x) * (p.x - point.x) + (p.y - point.y) * (p.y - point.y)
            if d < bestD { bestD = d; bestIdx = i }
        }
        return Double(bestIdx) / Double(points.count - 1)
    }
}

// MARK: - The forging screen

struct AnvilView: View {
    @ObservedObject var store: ForgeStore
    let project: ForgeProject?
    let metal: Metal
    let onExit: () -> Void
    let onRetry: () -> Void

    @StateObject private var session: ForgeSession
    @State private var showResult = false
    @State private var showGhost = true
    @State private var toastText: String? = nil

    private let ticker = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    init(store: ForgeStore, project: ForgeProject?, metal: Metal,
         onExit: @escaping () -> Void, onRetry: @escaping () -> Void) {
        self.store = store
        self.project = project
        self.metal = metal
        self.onExit = onExit
        self.onRetry = onRetry
        _session = StateObject(wrappedValue: ForgeSession(project: project,
                                                          metal: metal,
                                                          tools: store.tools(for: project),
                                                          freeForge: project == nil))
    }

    var body: some View {
        ZStack {
            Forge.soot.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                topBar
                heatStrip
                stage
                controls
            }
            .frame(maxWidth: Forge.wide ? 760 : .infinity)
            .frame(maxWidth: .infinity)

            if let t = toastText {
                VStack {
                    Spacer()
                    ForgeToast(text: t)
                        .padding(.bottom, 130)
                }
                .transition(.opacity)
            }

            if showResult, let s = session.score {
                ResultOverlay(score: s, session: session, project: project, metal: metal,
                              onAgain: { restart() }, onDone: { onExit() })
                    .transition(.opacity)
            } else if showResult && project == nil {
                FreeForgeOverlay(session: session, onAgain: { restart() }, onDone: { onExit() })
                    .transition(.opacity)
            }
        }
        .onReceive(ticker) { _ in
            session.tick(1.0 / 30.0)
            if session.phase == .tempering { session.advanceTemper(1.0 / 30.0) }
            if let t = session.toast {
                showToast(t)
                session.toast = nil
            }
            if session.phase == .finished && !showResult {
                withAnimation { showResult = true }
                if let s = session.score, let p = project {
                    store.record(project: p, metal: metal, score: s, session: session)
                    ForgeSound.shared.play(.chime, volume: 0.7)
                }
            }
        }
        .onAppear { ForgeSound.shared.startAmbient() }
        .onDisappear { ForgeSound.shared.stopAmbient() }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: { ForgeSound.shared.play(.tap, volume: 0.4); onExit() }) {
                HStack(spacing: 5) {
                    ChevronMark(size: 13, color: Forge.chalkDim, direction: 2)
                    Text("Shop").font(Forge.label(13)).foregroundColor(Forge.chalkDim)
                }
                .padding(.vertical, 7).padding(.horizontal, 11)
                .background(Capsule().fill(Forge.stone))
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 1) {
                Text(project?.name ?? "Free Forge")
                    .font(Forge.heading(16))
                    .foregroundColor(Forge.chalk)
                    .lineLimit(1)
                Text(metal.name)
                    .font(Forge.body(11))
                    .foregroundColor(Forge.chalkFaint)
            }
            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 1) {
                Text(session.freeForge ? "Free" : "Heat \(session.heatsUsed)/\(session.heatsAllowed)")
                    .font(Forge.mono(12))
                    .foregroundColor(session.heatsLeft == 0 && !session.freeForge ? Forge.warn : Forge.brass)
                Text("\(session.strikeCount) blows")
                    .font(Forge.body(10))
                    .foregroundColor(Forge.chalkFaint)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    // MARK: Heat gauge

    private var heatStrip: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let w = geo.size.width
                let lo = CGFloat((metal.forgingLow - 20) / 1480)
                let hi = CGFloat((metal.forgingHigh - 20) / 1480)
                let burn = CGFloat((metal.burnPoint - 20) / 1480)
                let now = CGFloat(max(0, min(1, (session.temperature - 20) / 1480)))
                ZStack(alignment: .leading) {
                    // Colour scale of the whole range.
                    HStack(spacing: 0) {
                        ForEach(0..<40, id: \.self) { i in
                            Rectangle()
                                .fill(HeatColor.color(for: 20 + Double(i) / 39 * 1480))
                                .frame(width: w / 40)
                        }
                    }
                    .frame(height: 14)
                    .clipShape(Capsule())
                    .opacity(0.85)

                    // Forging window brackets.
                    Rectangle()
                        .fill(Color.white.opacity(0.0))
                        .frame(width: (hi - lo) * w, height: 14)
                        .overlay(
                            Rectangle().stroke(Forge.chalk.opacity(0.85), lineWidth: 1.4)
                        )
                        .offset(x: lo * w)

                    // Burning line.
                    Rectangle()
                        .fill(Forge.warn)
                        .frame(width: 2, height: 20)
                        .offset(x: burn * w - 1)

                    // Current temperature marker.
                    Capsule()
                        .fill(Forge.chalk)
                        .frame(width: 3, height: 24)
                        .offset(x: max(0, min(w - 3, now * w)))
                        .shadow(color: HeatColor.color(for: session.temperature).opacity(0.9),
                                radius: 5)
                }
                .frame(height: 26)
            }
            .frame(height: 26)

            HStack {
                Text(session.heatAdvice)
                    .font(Forge.label(12))
                    .foregroundColor(session.burning ? Forge.warn
                                     : (session.inWindow ? Forge.spark : Forge.chalkDim))
                Spacer()
                Text("\(Int(session.temperature)) °C")
                    .font(Forge.mono(12))
                    .foregroundColor(Forge.chalkDim)
                Text("· window \(Int(metal.forgingLow))–\(Int(metal.forgingHigh))")
                    .font(Forge.body(10))
                    .foregroundColor(Forge.chalkFaint)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: Stage

    private var stage: some View {
        GeometryReader { geo in
            let rect = CGRect(x: geo.size.width * 0.06,
                              y: geo.size.height * 0.18,
                              width: geo.size.width * 0.88,
                              height: geo.size.height * 0.58)
            ZStack {
                // Backdrop changes with where the work is.
                stageBackdrop(size: geo.size)

                Canvas { ctx, size in
                    let g = BarGeometry.build(segments: session.piece.segs,
                                              bends: session.piece.bend,
                                              in: rect)
                    // Target ghost — only on the anvil, where it is any use.
                    if showGhost, session.phase == .anvil, let target = session.target {
                        let gh = ghostGeometry(target: target, in: rect)
                        ctx.stroke(gh.outline,
                                   with: .color(Forge.quench.opacity(0.55)),
                                   style: StrokeStyle(lineWidth: 1.6, dash: [5, 4]))
                    }

                    drawBar(&ctx, g: g, size: size)
                    drawSparks(&ctx, size: size)
                    drawHammer(&ctx, g: g, size: size)
                }
                .contentShape(Rectangle())
                .gesture(
                    // iOS 15 has no location-carrying tap, so a zero-distance
                    // drag stands in for one.
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in handleTap(location: value.location, rect: rect) }
                )

                // Power meter sits under the bar while at the anvil.
                if session.phase == .anvil {
                    VStack {
                        Spacer()
                        powerMeter
                            .padding(.horizontal, 26)
                            .padding(.bottom, 2)
                    }
                }
            }
        }
    }

    private func ghostGeometry(target: TargetShape, in rect: CGRect) -> BarGeometry {
        var segs: [BarSegment] = []
        let segLen = target.totalLength / Double(Workpiece.count)
        for s in target.samples {
            segs.append(BarSegment(thickness: s.t, width: s.w, length: segLen))
        }
        var bends = [Double](repeating: 0, count: Workpiece.count)
        for f in target.features where f.kind == .bend {
            let i = ForgeJudge.index(for: f.at)
            bends[i] += f.amount
        }
        return BarGeometry.build(segments: segs, bends: bends, in: rect)
    }

    @ViewBuilder
    private func stageBackdrop(size: CGSize) -> some View {
        ZStack {
            if session.phase == .fire {
                CoalBedBackdrop(level: 0.6 + session.bellows * 0.4)
            } else if session.phase == .quenching {
                QuenchBackdrop(quenchant: session.quenchant)
            } else {
                AnvilFaceBackdrop(glow: HeatColor.glow(for: session.temperature))
            }
        }
    }

    private var powerMeter: some View {
        VStack(spacing: 3) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Forge.night)
                    // The strong band the smith is aiming for.
                    Capsule()
                        .fill(Forge.brassDim.opacity(0.55))
                        .frame(width: geo.size.width * 0.28)
                        .offset(x: geo.size.width * 0.66)
                    Capsule()
                        .fill(LinearGradient(colors: [Forge.emberDeep, Forge.spark],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(4, geo.size.width * CGFloat(session.powerPhase)))
                }
            }
            .frame(height: 9)
            Text("Tap the bar to strike — power follows the sweep")
                .font(Forge.body(10))
                .foregroundColor(Forge.chalkFaint)
        }
    }

    // MARK: Bar rendering

    private func drawBar(_ ctx: inout GraphicsContext, g: BarGeometry, size: CGSize) {
        guard !g.points.isEmpty else { return }
        let temp = session.temperature
        let glow = HeatColor.glow(for: temp)
        let bodyColor: Color = session.phase == .finished || session.phase == .tempering
            ? (session.temperLocked?.swatch ?? metal.barTint)
            : HeatColor.color(for: temp)

        // Heat halo, drawn through a copy of the context so the blur does not
        // leak into everything that follows.
        if glow > 0.02 {
            var halo = ctx
            halo.addFilter(.blur(radius: 14))
            halo.fill(g.outline, with: .color(bodyColor.opacity(0.55 * glow)))
        }

        ctx.fill(g.outline, with: .color(bodyColor))

        // Top highlight along the bar.
        var hi = Path()
        for (i, p) in g.points.enumerated() {
            let y = p.y - g.halfT[i] * 0.45
            if i == 0 { hi.move(to: CGPoint(x: p.x, y: y)) } else { hi.addLine(to: CGPoint(x: p.x, y: y)) }
        }
        ctx.stroke(hi, with: .color(Color.white.opacity(0.16 + glow * 0.30)),
                   style: StrokeStyle(lineWidth: 1.6, lineCap: .round))

        // Fire scale speckles once it has seen a few heats.
        if session.piece.scale > 0.05 {
            for i in stride(from: 0, to: g.points.count, by: 1) {
                let p = g.points[i]
                let n = Int((p.x + p.y) * 7) % 5
                guard n < 2 else { continue }
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - 1, y: p.y - 1, width: 2.2, height: 2.2)),
                         with: .color(Color.black.opacity(0.25 * session.piece.scale)))
            }
        }

        // Twists shown as chevrons across the section.
        for i in session.piece.twist.indices where session.piece.twist[i] > 0.05 {
            guard i + 1 < g.points.count else { continue }
            let a = g.points[i], b = g.points[i + 1]
            let n = Int(3 + session.piece.twist[i] * 5)
            for k in 0..<n {
                let f = (Double(k) + 0.5) / Double(n)
                let x = a.x + (b.x - a.x) * CGFloat(f)
                let y = a.y + (b.y - a.y) * CGFloat(f)
                let h = g.halfT[i] * 0.85
                var tick = Path()
                tick.move(to: CGPoint(x: x - h * 0.5, y: y - h))
                tick.addLine(to: CGPoint(x: x + h * 0.5, y: y + h))
                ctx.stroke(tick, with: .color(Color.black.opacity(0.28)), lineWidth: 1)
            }
        }

        // Punched holes.
        for i in session.piece.holes.indices where session.piece.holes[i] {
            guard i < g.points.count else { continue }
            let p = g.points[i]
            let r = max(2.0, g.halfT[i] * 0.72)
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                     with: .color(Forge.night.opacity(0.92)))
        }

        // Cracks appear as integrity is lost.
        if session.piece.integrity < 0.985 {
            let cracks = Int((1 - session.piece.integrity) * 16)
            for k in 0..<max(0, cracks) {
                let idx = (k * 5 + 3) % max(1, g.points.count)
                let p = g.points[idx]
                let h = g.halfT[idx]
                var c = Path()
                c.move(to: CGPoint(x: p.x - 2, y: p.y - h))
                c.addLine(to: CGPoint(x: p.x + 1.5, y: p.y - h * 0.15))
                c.addLine(to: CGPoint(x: p.x - 1, y: p.y + h * 0.45))
                ctx.stroke(c, with: .color(Color.black.opacity(0.72)), lineWidth: 1.2)
            }
        }

        // Outline last so the silhouette stays crisp.
        ctx.stroke(g.outline, with: .color(Color.black.opacity(0.45)), lineWidth: 1)
    }

    private func drawHammer(_ ctx: inout GraphicsContext, g: BarGeometry, size: CGSize) {
        guard session.hammerFall > 0.01, let idx = session.struckIndex,
              idx < g.points.count else { return }
        let p = g.points[idx]
        let lift = CGFloat(1 - session.hammerFall) * 4 + CGFloat(session.hammerFall) * 46
        let head = CGRect(x: p.x - 17, y: p.y - g.halfT[idx] - lift - 13, width: 34, height: 13)
        ctx.fill(Path(roundedRect: head, cornerRadius: 2.5),
                 with: .color(Color(red: 0.30, green: 0.29, blue: 0.28)))
        ctx.fill(Path(roundedRect: CGRect(x: p.x - 3, y: head.minY - 30, width: 6, height: 32),
                      cornerRadius: 2),
                 with: .color(Color(red: 0.35, green: 0.26, blue: 0.16)))
    }

    private func drawSparks(_ ctx: inout GraphicsContext, size: CGSize) {
        for s in session.sparkSeeds {
            let f = 1 - s.life / max(0.01, s.maxLife)
            guard f > 0 else { continue }
            let x = CGFloat(s.x) * size.width
            let y = CGFloat(s.y) * size.height
            let r = CGFloat(s.size) * CGFloat(0.4 + f * 0.6)
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                     with: .color(Forge.spark.opacity(0.9 * f)))
        }
    }

    // MARK: Interaction

    private func handleTap(location: CGPoint, rect: CGRect) {
        switch session.phase {
        case .fire:
            session.pumpBellows()
            ForgeSound.shared.play(.bellows, volume: 0.5)
            ForgeSound.shared.bump(0)
        case .anvil:
            let g = BarGeometry.build(segments: session.piece.segs,
                                      bends: session.piece.bend, in: rect)
            let pos = g.position(nearest: location)
            let report = session.strike(at: pos)
            if let reason = report.rejected {
                showToast(reason)
                ForgeSound.shared.play(.hitCold, volume: 0.6)
                ForgeSound.shared.bump(2)
            } else if report.coldDamage > 0.001 {
                ForgeSound.shared.play(.crack, volume: 0.7)
                ForgeSound.shared.bump(2)
                showToast("Cold blow — that left a crack.")
            } else if report.punched {
                ForgeSound.shared.play(.punch, volume: 0.8)
                ForgeSound.shared.bump(2)
            } else if report.twisted {
                ForgeSound.shared.play(.twist, volume: 0.7)
                ForgeSound.shared.bump(1)
            } else if report.bent {
                ForgeSound.shared.play(.ring, volume: 0.6)
                ForgeSound.shared.bump(1)
            } else {
                ForgeSound.shared.play(.hitHot, volume: 0.85)
                ForgeSound.shared.bump(1)
            }
        default:
            break
        }
    }

    private func showToast(_ text: String) {
        withAnimation { toastText = text }
        let stamp = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if toastText == stamp { withAnimation { toastText = nil } }
        }
    }


    private func restart() {
        showResult = false
        onRetry()
    }

    // MARK: Controls

    @ViewBuilder
    private var controls: some View {
        VStack(spacing: 10) {
            switch session.phase {
            case .fire:
                fireControls
            case .anvil:
                anvilControls
            case .quenching:
                quenchControls
            case .tempering:
                temperControls
            case .finished:
                EmptyView()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    private var fireControls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                FlameMark(size: 15)
                Text("Fire \(Int(session.fireTemperature)) °C")
                    .font(Forge.mono(12)).foregroundColor(Forge.chalkDim)
                Spacer()
                Text("Bellows")
                    .font(Forge.body(11)).foregroundColor(Forge.chalkFaint)
                ForgeBar(value: session.bellows, tint: Forge.flame, height: 6)
                    .frame(width: 90)
            }
            Text("Tap the coals to work the bellows. Pull the bar out when the colour is right.")
                .font(Forge.body(11))
                .foregroundColor(Forge.chalkFaint)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 10) {
                ForgeButton(title: "Work the Bellows", kind: .secondary) {
                    session.pumpBellows()
                    ForgeSound.shared.play(.bellows, volume: 0.5)
                }
                ForgeButton(title: "To the Anvil", kind: .primary) {
                    session.toAnvil()
                    ForgeSound.shared.play(.ring, volume: 0.5)
                }
            }
        }
    }

    private var anvilControls: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(session.availableTools) { t in
                        Button(action: {
                            session.tool = t
                            ForgeSound.shared.play(.tap, volume: 0.4)
                        }) {
                            VStack(spacing: 4) {
                                ToolGlyph(tool: t, size: 24,
                                          color: session.tool == t ? Forge.night : Forge.chalkDim)
                                Text(t.short)
                                    .font(Forge.label(10))
                                    .foregroundColor(session.tool == t ? Forge.night : Forge.chalkDim)
                            }
                            .frame(width: 62, height: 58)
                            .background(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(session.tool == t ? Forge.brass : Forge.stone)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .stroke(session.tool == t ? Forge.spark.opacity(0.5) : Forge.slate,
                                            lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 1)
            }

            Text(session.tool.hint)
                .font(Forge.body(11))
                .foregroundColor(Forge.chalkFaint)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                ForgeButton(title: session.freeForge ? "Back to Fire"
                                                     : "Back to Fire (\(session.heatsLeft) left)",
                            kind: .secondary,
                            enabled: session.freeForge || session.heatsLeft > 0) {
                    session.backToFire()
                }
                ForgeButton(title: project == nil ? "Put It Down" : "Finish Piece", kind: .primary) {
                    if project == nil {
                        session.skipQuench()
                        withAnimation { showResult = true }
                    } else {
                        session.beginQuench()
                    }
                }
            }

            if showGhostToggleNeeded {
                Button(action: { withAnimation { showGhost.toggle() } }) {
                    HStack(spacing: 6) {
                        Text(showGhost ? "Hide the drawing" : "Show the drawing")
                            .font(Forge.body(11))
                            .foregroundColor(Forge.quench)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var showGhostToggleNeeded: Bool { session.target != nil }

    private var quenchControls: some View {
        VStack(spacing: 10) {
            Text("The piece is at \(Int(session.temperature)) °C. Above about 760 °C a carbon steel will harden.")
                .font(Forge.body(12))
                .foregroundColor(Forge.chalkDim)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                ForEach(Quenchant.allCases) { q in
                    Button(action: {
                        ForgeSound.shared.play(.quench, volume: 0.8)
                        ForgeSound.shared.bump(1)
                        session.doQuench(q)
                    }) {
                        VStack(spacing: 3) {
                            HeatDropMark(size: 17,
                                         color: q == .air ? Forge.steel : Forge.quench)
                            Text(q.name)
                                .font(Forge.label(10))
                                .foregroundColor(Forge.chalk)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(Forge.stone))
                        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(Forge.slate, lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            Text(session.quenchant.note)
                .font(Forge.body(10))
                .foregroundColor(Forge.chalkFaint)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForgeButton(title: "Skip the quench", kind: .quiet) { session.skipQuench() }
        }
    }

    private var temperControls: some View {
        VStack(spacing: 10) {
            Text("Hardened. Now polish and run the colours — quench again at the right shade.")
                .font(Forge.body(12))
                .foregroundColor(Forge.chalkDim)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    LinearGradient(colors: [TemperColor.straw.swatch, TemperColor.bronze.swatch,
                                            TemperColor.purple.swatch, TemperColor.blue.swatch,
                                            TemperColor.grey.swatch],
                                   startPoint: .leading, endPoint: .trailing)
                        .clipShape(Capsule())
                    Capsule()
                        .fill(Forge.chalk)
                        .frame(width: 3, height: 26)
                        .offset(x: max(0, min(geo.size.width - 3,
                                              CGFloat(session.temperRun) * geo.size.width)))
                }
            }
            .frame(height: 20)

            HStack {
                Text(session.currentTemperColor.name)
                    .font(Forge.label(13))
                    .foregroundColor(session.currentTemperColor.swatch)
                Text("· \(session.currentTemperColor.celsius)")
                    .font(Forge.body(11))
                    .foregroundColor(Forge.chalkFaint)
                Spacer()
                if let want = project?.idealTemper {
                    Text("Wanted: \(want.name)")
                        .font(Forge.body(11))
                        .foregroundColor(Forge.brass)
                }
            }
            Text(session.currentTemperColor.use)
                .font(Forge.body(11))
                .foregroundColor(Forge.chalkFaint)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            ForgeButton(title: "Quench Now", kind: .primary) {
                ForgeSound.shared.play(.quench, volume: 0.7)
                ForgeSound.shared.bump(1)
                session.lockTemper()
            }
        }
    }
}

// MARK: - Backdrops

struct CoalBedBackdrop: View {
    var level: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: false)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let w = size.width, h = size.height
                ctx.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(Forge.night))
                let bed = CGRect(x: w * 0.10, y: h * 0.44, width: w * 0.80, height: h * 0.44)
                ctx.fill(Path(ellipseIn: bed), with: .color(Color(red: 0.09, green: 0.07, blue: 0.06)))
                let f = level * (0.85 + 0.15 * sin(t * 3.4))
                ctx.fill(Path(ellipseIn: bed.insetBy(dx: bed.width * 0.08, dy: bed.height * 0.12)),
                         with: .radialGradient(Gradient(colors: [
                            Forge.white.opacity(0.95 * f),
                            Forge.flame.opacity(0.8 * f),
                            Forge.emberDeep.opacity(0.5 * f),
                            Color.clear
                         ]), center: CGPoint(x: bed.midX, y: bed.midY + bed.height * 0.1),
                         startRadius: 0, endRadius: bed.width * 0.5))
                // Coal lumps.
                for i in 0..<22 {
                    let a = Double(i) * 0.83
                    let rr = 0.18 + Double((i * 31) % 70) / 100 * 0.32
                    let x = bed.midX + cos(a) * bed.width * rr
                    let y = bed.midY + sin(a) * bed.height * rr * 0.8
                    let s = 5.0 + Double((i * 17) % 5)
                    ctx.fill(Path(roundedRect: CGRect(x: x, y: y, width: s, height: s * 0.78),
                                  cornerRadius: 2),
                             with: .color(Color.black.opacity(0.55)))
                }
            }
        }
    }
}

struct AnvilFaceBackdrop: View {
    var glow: Double

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Forge.night))
            let face = CGRect(x: w * 0.04, y: h * 0.60, width: w * 0.92, height: h * 0.16)
            ctx.fill(Path(roundedRect: face, cornerRadius: 4),
                     with: .linearGradient(Gradient(colors: [
                        Color(red: 0.27, green: 0.26, blue: 0.25),
                        Color(red: 0.14, green: 0.13, blue: 0.13)
                     ]), startPoint: CGPoint(x: 0, y: face.minY),
                     endPoint: CGPoint(x: 0, y: face.maxY)))
            // Base under the face.
            let base = CGRect(x: w * 0.22, y: face.maxY, width: w * 0.56, height: h * 0.22)
            ctx.fill(Path(base), with: .color(Color(red: 0.12, green: 0.11, blue: 0.11)))
            // Firelight thrown onto the face.
            ctx.fill(Path(roundedRect: face, cornerRadius: 4),
                     with: .radialGradient(Gradient(colors: [
                        Forge.flame.opacity(0.28 * glow), Color.clear
                     ]), center: CGPoint(x: face.midX, y: face.minY),
                     startRadius: 0, endRadius: face.width * 0.5))
        }
    }
}

struct QuenchBackdrop: View {
    var quenchant: Quenchant

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: false)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let w = size.width, h = size.height
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Forge.night))
                let liquid = CGRect(x: 0, y: h * 0.55, width: w, height: h * 0.45)
                ctx.fill(Path(liquid),
                         with: .color(quenchant == .oil
                                      ? Color(red: 0.20, green: 0.16, blue: 0.10)
                                      : Forge.quench.opacity(0.5)))
                for i in 0..<16 {
                    let x = w * Double((i * 37) % 100) / 100
                    let rise = (t * 0.6 + Double(i) * 0.13).truncatingRemainder(dividingBy: 1)
                    let y = liquid.minY - rise * h * 0.4
                    let r = 3.0 + rise * 5
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                             with: .color(Color.white.opacity(0.14 * (1 - rise))))
                }
            }
        }
    }
}

// MARK: - Result overlays

struct ResultOverlay: View {
    let score: ForgeScore
    @ObservedObject var session: ForgeSession
    let project: ForgeProject?
    let metal: Metal
    let onAgain: () -> Void
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 14) {
                    Spacer(minLength: 44)
                    Text(project?.name ?? "Free Forge")
                        .font(Forge.title(23))
                        .foregroundColor(Forge.chalk)
                    StarRow(stars: score.stars, size: 24)
                    QualityTag(quality: score.quality)

                    HStack(spacing: 8) {
                        StatTile(value: "\(Int(score.profile * 100))%", caption: "Profile")
                        StatTile(value: "\(Int(score.features * 100))%", caption: "Shaping",
                                 tint: Forge.quench)
                        StatTile(value: "\(Int(score.integrity * 100))%", caption: "Soundness",
                                 tint: score.integrity > 0.9 ? Forge.good : Forge.warn)
                    }

                    HStack(spacing: 8) {
                        StatTile(value: "\(session.strikeCount)", caption: "Blows", tint: Forge.chalkDim)
                        StatTile(value: "\(session.heatsUsed)", caption: "Heats", tint: Forge.chalkDim)
                        StatTile(value: session.hardened
                                 ? (session.temperLocked?.name ?? "Hard") : "Soft",
                                 caption: "Finish",
                                 tint: session.temperLocked?.swatch ?? Forge.chalkDim)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeading(text: "The master's word")
                        ForEach(score.notes, id: \.self) { n in
                            HStack(alignment: .top, spacing: 8) {
                                Circle().fill(Forge.brass).frame(width: 5, height: 5)
                                    .padding(.top, 6)
                                Text(n)
                                    .font(Forge.body(12))
                                    .foregroundColor(Forge.chalkDim)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .forgeCard()

                    ForgeButton(title: "Back to the Shop", kind: .primary) { onDone() }
                    ForgeButton(title: "Forge It Again", kind: .secondary) { onAgain() }
                }
                .frame(maxWidth: 460)
                .padding(20)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct FreeForgeOverlay: View {
    @ObservedObject var session: ForgeSession
    let onAgain: () -> Void
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).edgesIgnoringSafeArea(.all)
            VStack(spacing: 14) {
                Text("Off the Anvil")
                    .font(Forge.title(23))
                    .foregroundColor(Forge.chalk)
                Text("No drawing to measure against — but the bar is what you made it.")
                    .font(Forge.body(12))
                    .foregroundColor(Forge.chalkDim)
                    .multilineTextAlignment(.center)
                HStack(spacing: 8) {
                    StatTile(value: "\(session.strikeCount)", caption: "Blows")
                    StatTile(value: "\(session.heatsUsed)", caption: "Heats", tint: Forge.quench)
                    StatTile(value: "\(Int(session.piece.integrity * 100))%", caption: "Soundness",
                             tint: session.piece.integrity > 0.9 ? Forge.good : Forge.warn)
                }
                ForgeButton(title: "Back to the Shop", kind: .primary) { onDone() }
                ForgeButton(title: "Another Bar", kind: .secondary) { onAgain() }
            }
            .frame(maxWidth: 420)
            .padding(20)
        }
    }
}
