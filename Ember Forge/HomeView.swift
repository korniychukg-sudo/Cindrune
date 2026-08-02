import SwiftUI

struct HomeView: View {
    @ObservedObject var store: ForgeStore
    let onStart: (ForgeProject?, Metal) -> Void
    let onOpenBook: () -> Void

    @State private var showRank = false
    @State private var showPhaseNote = false

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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Ember Forge")
                            .font(Forge.title(Forge.wide ? 32 : 27))
                            .foregroundColor(Forge.chalk)
                        Text(phase.name + " · " + rankLine)
                            .font(Forge.body(12))
                            .foregroundColor(Forge.chalkDim)
                    }
                    Spacer()
                    Button(action: { showRank = true }) {
                        VStack(spacing: 2) {
                            Text("\(store.save.xp)")
                                .font(Forge.mono(15))
                                .foregroundColor(Forge.brass)
                            Text("XP").font(Forge.label(9)).foregroundColor(Forge.chalkFaint)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Forge.stone))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Button(action: { withAnimation { showPhaseNote.toggle() } }) {
                    SmithyScene(store: store, height: Forge.wide ? 320 : 232)
                }
                .buttonStyle(PlainButtonStyle())

                if showPhaseNote {
                    Text(phase.caption)
                        .font(Forge.body(12))
                        .foregroundColor(Forge.chalkDim)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .forgeCard(padding: 12)
                }

                rankCard
                commissionCard

                if let next = nextUp {
                    nextCard(next)
                }

                statRow

                if store.save.log.isEmpty {
                    VStack(alignment: .leading, spacing: 7) {
                        SectionHeading(text: "Nothing on the walls yet")
                        Text("Finish a commission and it goes up in the shop: hooks on the wall, tools on the rack, a poker beside the hearth.")
                            .font(Forge.body(12))
                            .foregroundColor(Forge.chalkDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .forgeCard()
                } else {
                    recentWork
                }
            }
            .frame(maxWidth: Forge.column(UIScreen.main.bounds.width))
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 34)
            .frame(maxWidth: .infinity)
        }
        .forgeBackground()
        .onAppear {
            store.refreshCommission()
            ForgeSound.shared.startAmbient()
        }
        .onDisappear { ForgeSound.shared.stopAmbient() }
        .sheet(isPresented: $showRank) {
            RankSheet(store: store, onClose: { showRank = false })
        }
    }

    private var rankLine: String {
        store.rank.name
    }

    private var rankCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(store.rank.name)
                    .font(Forge.heading(17))
                    .foregroundColor(Forge.chalk)
                Spacer()
                if let next = store.nextRank {
                    Text("\(max(0, next.xp - store.save.xp)) XP to \(next.name)")
                        .font(Forge.body(11))
                        .foregroundColor(Forge.chalkFaint)
                } else {
                    Text("Top of the trade")
                        .font(Forge.body(11))
                        .foregroundColor(Forge.brass)
                }
            }
            ForgeBar(value: store.rankProgress, tint: Forge.ember, height: 8)
            Text(store.rank.unlocks)
                .font(Forge.body(11))
                .foregroundColor(Forge.chalkDim)
        }
        .forgeCard()
    }

    @ViewBuilder
    private var commissionCard: some View {
        if let c = store.commission, let p = Content.project(c.projectID) {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeading(text: "Today's order", trailing: DayKey.label(c.dateKey))
                HStack(alignment: .top, spacing: 12) {
                    MiniProfile(project: p)
                        .frame(width: 62, height: 46)
                        .background(RoundedRectangle(cornerRadius: 9).fill(Forge.night))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(c.customer)
                            .font(Forge.heading(15))
                            .foregroundColor(Forge.chalk)
                        Text(c.request)
                            .font(Forge.body(11))
                            .foregroundColor(Forge.chalkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                HStack(spacing: 8) {
                    Text(p.name)
                        .font(Forge.label(12))
                        .foregroundColor(Forge.brass)
                    MetalTag(metal: c.metal)
                    Spacer()
                    StarRow(stars: c.minStars, size: 11)
                }
                if c.delivered {
                    HStack(spacing: 7) {
                        CheckMark(size: 14)
                        Text("Delivered. Paid in full.")
                            .font(Forge.label(12))
                            .foregroundColor(Forge.good)
                    }
                } else {
                    ForgeButton(title: "Take the Order", kind: .primary) {
                        onStart(p, c.metal)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .forgeCard()
        }
    }

    private func nextCard(_ p: ForgeProject) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionHeading(text: "Next in the book", trailing: p.chapter.name)
            Text(p.name)
                .font(Forge.heading(17))
                .foregroundColor(Forge.chalk)
            Text(p.summary)
                .font(Forge.body(12))
                .foregroundColor(Forge.chalkDim)
                .fixedSize(horizontal: false, vertical: true)
            BlueprintView(project: p, height: 108)
            HStack(spacing: 10) {
                ForgeButton(title: "Open the Book", kind: .secondary) { onOpenBook() }
                ForgeButton(title: "Start", kind: .primary) { onStart(p, p.stock) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
    }

    private var statRow: some View {
        HStack(spacing: 8) {
            StatTile(value: "\(store.liveStreak)", caption: "Day streak", tint: Forge.flame)
            StatTile(value: "\(store.save.best.count)/\(Content.projects.count)", caption: "Pieces made")
            StatTile(value: "\(store.totalStars)", caption: "Stars", tint: Forge.spark)
            StatTile(value: "\(store.badgeCount)/\(Content.badges.count)", caption: "Awards",
                     tint: Forge.quench)
        }
    }

    private var recentWork: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(text: "Off the anvil lately")
            ForEach(store.save.log.prefix(4)) { piece in
                if let p = Content.project(piece.projectID) {
                    HStack(spacing: 11) {
                        MiniProfile(project: p)
                            .frame(width: 46, height: 34)
                            .background(RoundedRectangle(cornerRadius: 7).fill(Forge.night))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.name)
                                .font(Forge.label(13))
                                .foregroundColor(Forge.chalk)
                            Text("\(piece.metal.name) · \(DayKey.label(piece.dateKey))")
                                .font(Forge.body(10))
                                .foregroundColor(Forge.chalkFaint)
                        }
                        Spacer()
                        StarRow(stars: piece.stars, size: 11)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
    }
}

// MARK: - Rank sheet

struct RankSheet: View {
    @ObservedObject var store: ForgeStore
    let onClose: () -> Void

    var body: some View {
        ForgeSheet(title: "The Ladder", onClose: onClose) {
            Text("Every piece you finish pays experience, scaled by how well it came out and what it was made from.")
                .font(Forge.body(12))
                .foregroundColor(Forge.chalkDim)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(0..<Content.ranks.count, id: \.self) { i in
                let r = Content.ranks[i]
                let reached = store.rankIndex >= i
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(reached ? Forge.brass : Forge.stone)
                            .frame(width: 30, height: 30)
                        Text("\(i + 1)")
                            .font(Forge.mono(12))
                            .foregroundColor(reached ? Forge.night : Forge.chalkFaint)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(r.name)
                                .font(Forge.heading(14))
                                .foregroundColor(reached ? Forge.chalk : Forge.chalkFaint)
                            Spacer()
                            Text("\(r.xp) XP")
                                .font(Forge.mono(11))
                                .foregroundColor(Forge.chalkFaint)
                        }
                        Text(r.unlocks)
                            .font(Forge.body(11))
                            .foregroundColor(Forge.chalkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
