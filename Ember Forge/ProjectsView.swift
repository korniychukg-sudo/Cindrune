import SwiftUI

/// The blueprint the commission is drawn on: the finished profile in white
/// chalk on a dark board, with the required shaping marked in blue.
struct BlueprintView: View {
    let project: ForgeProject
    var height: CGFloat = 120

    var body: some View {
        Canvas { ctx, size in
            let rect = CGRect(x: size.width * 0.07, y: size.height * 0.16,
                              width: size.width * 0.86, height: size.height * 0.60)

            // Board and grid.
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(Color(red: 0.086, green: 0.098, blue: 0.118)))
            for i in 0...10 {
                var v = Path()
                let x = size.width * Double(i) / 10
                v.move(to: CGPoint(x: x, y: 0)); v.addLine(to: CGPoint(x: x, y: size.height))
                ctx.stroke(v, with: .color(Forge.quench.opacity(0.10)), lineWidth: 0.6)
            }
            for i in 0...5 {
                var hLine = Path()
                let y = size.height * Double(i) / 5
                hLine.move(to: CGPoint(x: 0, y: y)); hLine.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(hLine, with: .color(Forge.quench.opacity(0.10)), lineWidth: 0.6)
            }

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

            ctx.fill(g.outline, with: .color(Forge.quench.opacity(0.18)))
            ctx.stroke(g.outline, with: .color(Forge.chalk.opacity(0.85)),
                       style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))

            // Feature call-outs.
            for f in target.features {
                let i = min(g.points.count - 1, ForgeJudge.index(for: f.at))
                guard i >= 0, i < g.points.count else { continue }
                let p = g.points[i]
                switch f.kind {
                case .hole:
                    let r: CGFloat = 4
                    ctx.stroke(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r,
                                                      width: r * 2, height: r * 2)),
                               with: .color(Forge.spark), lineWidth: 1.4)
                case .twist:
                    var marks = Path()
                    for k in 0..<4 {
                        let x = p.x - 9 + CGFloat(k) * 6
                        marks.move(to: CGPoint(x: x, y: p.y - 7))
                        marks.addLine(to: CGPoint(x: x + 4, y: p.y + 7))
                    }
                    ctx.stroke(marks, with: .color(Forge.spark.opacity(0.8)), lineWidth: 1.1)
                case .bend:
                    ctx.stroke(Path(ellipseIn: CGRect(x: p.x - 7, y: p.y - 7,
                                                      width: 14, height: 14)),
                               with: .color(Forge.brass.opacity(0.75)),
                               style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                case .taper:
                    var arrow = Path()
                    arrow.move(to: CGPoint(x: p.x - 10, y: p.y - 12))
                    arrow.addLine(to: CGPoint(x: p.x, y: p.y - 4))
                    ctx.stroke(arrow, with: .color(Forge.brass.opacity(0.75)), lineWidth: 1)
                }
            }

            // Stock note on the board.
            ctx.draw(Text("stock \(Int(project.barThickness))×\(Int(project.barWidth))×\(Int(project.barLength)) mm")
                        .font(Forge.mono(9))
                        .foregroundColor(Forge.quench.opacity(0.9)),
                     at: CGPoint(x: size.width * 0.07, y: size.height - 12), anchor: .leading)
        }
        .frame(height: height)
        .background(Color(red: 0.086, green: 0.098, blue: 0.118))
        .clipShape(RoundedRectangle(cornerRadius: Forge.cornerSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Forge.cornerSmall, style: .continuous)
                .stroke(Forge.quench.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - Commission book

struct ProjectsView: View {
    @ObservedObject var store: ForgeStore
    let onStart: (ForgeProject?, Metal) -> Void

    @State private var chapter: Chapter = .firstHeats
    @State private var detail: ForgeProject? = nil
    @State private var showFreeForge = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle(text: "Commission Book",
                            sub: "Twenty-four pieces, in the order a shop would teach them.")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Chapter.allCases) { c in
                            PillButton(title: c.name,
                                       selected: chapter == c,
                                       locked: !store.isChapterOpen(c)) {
                                chapter = c
                            }
                        }
                    }
                }

                chapterCard

                if store.isChapterOpen(chapter) {
                    VStack(spacing: 10) {
                        ForEach(Content.projects(in: chapter)) { p in
                            ProjectRow(project: p,
                                       open: store.isProjectOpen(p),
                                       best: store.best(p.id)) {
                                if store.isProjectOpen(p) { detail = p }
                            }
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            LockMark(size: 16)
                            Text("Not yet")
                                .font(Forge.heading(15))
                                .foregroundColor(Forge.chalk)
                        }
                        Text("The \(chapter.name) book opens at \(Content.ranks[Content.requiredRank(for: chapter)].name).")
                            .font(Forge.body(12))
                            .foregroundColor(Forge.chalkDim)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .forgeCard()
                }

                freeForgeCard
            }
            .frame(maxWidth: Forge.column(UIScreen.main.bounds.width))
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 34)
            .frame(maxWidth: .infinity)
        }
        .forgeBackground()
        .sheet(item: $detail) { p in
            ProjectDetailSheet(store: store, project: p,
                               onClose: { detail = nil },
                               onStart: { metal in
                                   detail = nil
                                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                       onStart(p, metal)
                                   }
                               })
        }
        .sheet(isPresented: $showFreeForge) {
            FreeForgeSheet(store: store,
                           onClose: { showFreeForge = false },
                           onStart: { metal in
                               showFreeForge = false
                               DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                   onStart(nil, metal)
                               }
                           })
        }
    }

    private var chapterCard: some View {
        let p = store.chapterProgress(chapter)
        return VStack(alignment: .leading, spacing: 10) {
            ForgePlate(name: chapter.art, height: Forge.wide ? 170 : 128)
            Text(chapter.blurb)
                .font(Forge.body(12))
                .foregroundColor(Forge.chalkDim)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                ForgeBar(value: p.total > 0 ? Double(p.done) / Double(p.total) : 0,
                         tint: Forge.brass, height: 7)
                Text("\(p.done)/\(p.total)")
                    .font(Forge.mono(12))
                    .foregroundColor(Forge.brass)
            }
        }
        .forgeCard()
    }

    private var freeForgeCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionHeading(text: "No commission")
            Text("Free Forge")
                .font(Forge.heading(17))
                .foregroundColor(Forge.chalk)
            Text("A plain bar, unlimited heats and no drawing to answer to. Good for learning what each tool actually does to the metal.")
                .font(Forge.body(12))
                .foregroundColor(Forge.chalkDim)
                .fixedSize(horizontal: false, vertical: true)
            ForgeButton(title: "Take a Bar", kind: .secondary) { showFreeForge = true }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
    }
}

// MARK: - Rows

struct ProjectRow: View {
    let project: ForgeProject
    let open: Bool
    let best: FinishedPiece?
    let action: () -> Void

    var body: some View {
        Button(action: {
            ForgeSound.shared.play(.tap, volume: 0.4)
            action()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Forge.night)
                        .frame(width: 58, height: 44)
                    if open {
                        MiniProfile(project: project)
                            .frame(width: 52, height: 38)
                    } else {
                        LockMark(size: 15)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(project.name)
                        .font(Forge.heading(15))
                        .foregroundColor(open ? Forge.chalk : Forge.chalkFaint)
                    Text(open ? project.summary : "Finish the piece before this one first.")
                        .font(Forge.body(11))
                        .foregroundColor(Forge.chalkFaint)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 5) {
                    StarRow(stars: best?.stars ?? 0, size: 11)
                    if let b = best {
                        Text(b.quality.name)
                            .font(Forge.label(9))
                            .foregroundColor(b.quality.tint)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: Forge.corner, style: .continuous)
                    .fill(Forge.stone)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Forge.corner, style: .continuous)
                    .stroke(best != nil ? Forge.brassDim : Forge.slate, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!open)
    }
}

/// A tiny silhouette of the finished piece, used in list rows.
struct MiniProfile: View {
    let project: ForgeProject

    var body: some View {
        Canvas { ctx, size in
            let rect = CGRect(x: 2, y: 2, width: size.width - 4, height: size.height - 4)
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
            ctx.fill(g.outline, with: .color(project.stock.barTint))
            ctx.stroke(g.outline, with: .color(Color.black.opacity(0.5)), lineWidth: 0.8)
        }
    }
}

// MARK: - Detail sheet

struct ProjectDetailSheet: View {
    @ObservedObject var store: ForgeStore
    let project: ForgeProject
    let onClose: () -> Void
    let onStart: (Metal) -> Void

    @State private var metal: Metal

    init(store: ForgeStore, project: ForgeProject,
         onClose: @escaping () -> Void, onStart: @escaping (Metal) -> Void) {
        self.store = store
        self.project = project
        self.onClose = onClose
        self.onStart = onStart
        _metal = State(initialValue: project.stock)
    }

    private var usableMetals: [Metal] {
        let unlocked = store.unlockedMetals
        return unlocked.contains(project.stock) ? unlocked : [project.stock] + unlocked
    }

    var body: some View {
        ForgeSheet(title: project.name, onClose: onClose) {
            BlueprintView(project: project, height: 150)

            Text(project.summary)
                .font(Forge.body(13))
                .foregroundColor(Forge.chalk)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                StatTile(value: "\(project.heatsAllowed)", caption: "Heats allowed", tint: Forge.flame)
                StatTile(value: "\(project.parStrikes)", caption: "Par blows", tint: Forge.brass)
                StatTile(value: project.needsHardening ? "Yes" : "No", caption: "Hardened",
                         tint: project.needsHardening ? Forge.quench : Forge.chalkDim)
            }

            if !project.features.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    SectionHeading(text: "Shaping called for")
                    ForEach(0..<project.features.count, id: \.self) { i in
                        let f = project.features[i]
                        HStack(spacing: 8) {
                            Circle().fill(Forge.quench).frame(width: 5, height: 5)
                            Text(featureLine(f))
                                .font(Forge.body(12))
                                .foregroundColor(Forge.chalkDim)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .forgeCard()
            }

            VStack(alignment: .leading, spacing: 8) {
                SectionHeading(text: "Stock")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(usableMetals) { m in
                            PillButton(title: m.name, selected: metal == m) { metal = m }
                        }
                    }
                }
                Text(metal.blurb)
                    .font(Forge.body(11))
                    .foregroundColor(Forge.chalkFaint)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    Text("Window \(Int(metal.forgingLow))–\(Int(metal.forgingHigh)) °C")
                        .font(Forge.mono(11))
                        .foregroundColor(Forge.chalkDim)
                    Text("Burns at \(Int(metal.burnPoint)) °C")
                        .font(Forge.mono(11))
                        .foregroundColor(Forge.warn.opacity(0.9))
                }
                if metal != project.stock {
                    Text("The commission was written for \(project.stock.name). Another stock still counts, and pays differently.")
                        .font(Forge.body(11))
                        .foregroundColor(Forge.brass)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .forgeCard()

            if let temper = project.idealTemper {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 4).fill(temper.swatch)
                        .frame(width: 26, height: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Draw the temper to \(temper.name)")
                            .font(Forge.label(12))
                            .foregroundColor(Forge.chalk)
                        Text(temper.use)
                            .font(Forge.body(11))
                            .foregroundColor(Forge.chalkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .forgeCard()
            }

            VStack(alignment: .leading, spacing: 7) {
                SectionHeading(text: "From the shop's notes")
                Text(project.lore)
                    .font(Forge.body(12))
                    .foregroundColor(Forge.chalkDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .forgeCard()

            if let b = store.best(project.id) {
                VStack(alignment: .leading, spacing: 7) {
                    SectionHeading(text: "Best so far", trailing: DayKey.label(b.dateKey))
                    HStack(spacing: 10) {
                        StarRow(stars: b.stars, size: 14)
                        QualityTag(quality: b.quality)
                        Spacer()
                        MetalTag(metal: b.metal)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .forgeCard()
            }

            ForgeButton(title: "Light the Fire", kind: .primary) { onStart(metal) }
        }
    }

    private func featureLine(_ f: FeatureSpec) -> String {
        switch f.kind {
        case .bend: return "Bend about \(Int(f.amount))° at \(Int(f.at * 100))% along the bar"
        case .twist: return "Twist the bar at \(Int(f.at * 100))% along"
        case .hole: return "Punch a hole at \(Int(f.at * 100))% along"
        case .taper: return "Taper the end to a fine point"
        }
    }
}

// MARK: - Free forge sheet

struct FreeForgeSheet: View {
    @ObservedObject var store: ForgeStore
    let onClose: () -> Void
    let onStart: (Metal) -> Void

    @State private var metal: Metal = .mildSteel

    var body: some View {
        ForgeSheet(title: "Free Forge", onClose: onClose) {
            Text("No drawing, no score, no limit on heats. The bar starts square and goes wherever you take it.")
                .font(Forge.body(13))
                .foregroundColor(Forge.chalkDim)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                SectionHeading(text: "Stock")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.unlockedMetals) { m in
                            PillButton(title: m.name, selected: metal == m) { metal = m }
                        }
                    }
                }
                Text(metal.blurb)
                    .font(Forge.body(11))
                    .foregroundColor(Forge.chalkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .forgeCard()

            VStack(alignment: .leading, spacing: 7) {
                SectionHeading(text: "What to try")
                ForEach(store.unlockedTools) { t in
                    HStack(alignment: .top, spacing: 9) {
                        ToolGlyph(tool: t, size: 18, color: Forge.brass)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(t.name)
                                .font(Forge.label(12))
                                .foregroundColor(Forge.chalk)
                            Text(t.hint)
                                .font(Forge.body(11))
                                .foregroundColor(Forge.chalkFaint)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .forgeCard()

            ForgeButton(title: "Take a Bar", kind: .primary) { onStart(metal) }
        }
    }
}
