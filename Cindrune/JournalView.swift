import SwiftUI

struct JournalView: View {
    @ObservedObject var store: ForgeStore

    @State private var tab = 0
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var badgeDetail: ForgeBadge? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    ScreenTitle(text: "Keeper's Journal",
                                sub: "What has come off this anvil, and when.")
                    Button(action: { showSettings = true }) {
                        GearMark(size: 18)
                            .padding(10)
                            .background(Circle().fill(Forge.stone))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                statGrid
                streakCard

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        PillButton(title: "Work Log", selected: tab == 0) { tab = 0 }
                        PillButton(title: "Awards", selected: tab == 1) { tab = 1 }
                        PillButton(title: "The Shop", selected: tab == 2) { tab = 2 }
                    }
                }

                switch tab {
                case 0: logTab
                case 1: awardsTab
                default: shopTab
                }
            }
            .frame(maxWidth: Forge.column(UIScreen.main.bounds.width))
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 34)
            .frame(maxWidth: .infinity)
        }
        .forgeBackground()
        .sheet(isPresented: $showSettings) {
            SettingsSheet(store: store,
                          onClose: { showSettings = false },
                          onAbout: {
                              showSettings = false
                              DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showAbout = true }
                          })
        }
        .sheet(isPresented: $showAbout) {
            AboutSheet(onClose: { showAbout = false })
        }
        .sheet(item: $badgeDetail) { b in
            ForgeSheet(title: b.name, onClose: { badgeDetail = nil }) {
                HStack {
                    Spacer()
                    BadgeCell(badge: b, earned: store.hasBadge(b.id))
                        .scaleEffect(1.35)
                        .padding(.vertical, 18)
                    Spacer()
                }
                Text(b.detail)
                    .font(Forge.body(14))
                    .foregroundColor(Forge.chalkDim)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
                Text(store.hasBadge(b.id) ? "Earned." : "Not yet earned.")
                    .font(Forge.label(12))
                    .foregroundColor(store.hasBadge(b.id) ? Forge.good : Forge.chalkFaint)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Stats

    private var statGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                StatTile(value: "\(store.save.totalPieces)", caption: "Pieces off the anvil")
                StatTile(value: "\(store.save.totalStrikes)", caption: "Hammer blows", tint: Forge.chalkDim)
                StatTile(value: "\(store.save.totalHeats)", caption: "Heats taken", tint: Forge.flame)
            }
            HStack(spacing: 8) {
                StatTile(value: "\(store.totalStars)/\(store.maxStars)", caption: "Stars", tint: Forge.spark)
                StatTile(value: "\(store.save.commissionsDelivered)", caption: "Orders delivered",
                         tint: Forge.quench)
                StatTile(value: "\(store.badgeCount)/\(Content.badges.count)", caption: "Awards")
            }
        }
    }

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeading(text: "Days at the fire")
                Spacer()
                Text("best \(store.save.bestStreak)")
                    .font(Forge.label(11))
                    .foregroundColor(Forge.chalkFaint)
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(store.liveStreak)")
                        .font(Forge.mono(26))
                        .foregroundColor(Forge.flame)
                    Text("day streak")
                        .font(Forge.body(10))
                        .foregroundColor(Forge.chalkFaint)
                }
                Spacer()
                ForgeCalendar(store: store)
            }
        }
        .forgeCard()
    }

    // MARK: Log

    private var logTab: some View {
        VStack(spacing: 10) {
            if store.save.log.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("The log is empty")
                        .font(Forge.heading(15))
                        .foregroundColor(Forge.chalk)
                    Text("Every finished piece is written down here with its stock, its stars and the day it was made.")
                        .font(Forge.body(12))
                        .foregroundColor(Forge.chalkDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .forgeCard()
            }
            ForEach(store.save.log) { piece in
                if let p = Content.project(piece.projectID) {
                    HStack(spacing: 11) {
                        MiniProfile(project: p)
                            .frame(width: 50, height: 36)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Forge.night))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(p.name)
                                .font(Forge.label(13))
                                .foregroundColor(Forge.chalk)
                            HStack(spacing: 6) {
                                Text(piece.metal.name)
                                    .font(Forge.body(10))
                                    .foregroundColor(Forge.chalkFaint)
                                if let t = piece.temper {
                                    Circle().fill(t.swatch).frame(width: 6, height: 6)
                                    Text(t.name)
                                        .font(Forge.body(10))
                                        .foregroundColor(Forge.chalkFaint)
                                }
                            }
                            Text("\(piece.strikes) blows · \(piece.heats) heats · \(DayKey.label(piece.dateKey))")
                                .font(Forge.body(10))
                                .foregroundColor(Forge.chalkFaint)
                        }
                        Spacer(minLength: 4)
                        VStack(alignment: .trailing, spacing: 5) {
                            StarRow(stars: piece.stars, size: 11)
                            QualityTag(quality: piece.quality)
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: Forge.corner, style: .continuous)
                        .fill(Forge.stone))
                    .overlay(RoundedRectangle(cornerRadius: Forge.corner, style: .continuous)
                        .stroke(Forge.slate, lineWidth: 1))
                }
            }
        }
    }

    // MARK: Awards

    private var awardsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(store.badgeCount) of \(Content.badges.count) earned")
                .font(Forge.body(11))
                .foregroundColor(Forge.chalkFaint)
            ColumnGrid(items: Content.badges, columns: Forge.wide ? 5 : 3, spacing: 12) { b in
                Button(action: {
                    ForgeSound.shared.play(.tap, volume: 0.4)
                    badgeDetail = b
                }) {
                    BadgeCell(badge: b, earned: store.hasBadge(b.id))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: Shop

    private var shopTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            SmithyScene(store: store, height: Forge.wide ? 320 : 236)
            Text("Finished work does not go in a drawer. It goes up in the shop — and the shop is where you will notice how far you have come.")
                .font(Forge.body(12))
                .foregroundColor(Forge.chalkDim)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Chapter.allCases) { c in
                let p = store.chapterProgress(c)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(c.name)
                            .font(Forge.heading(14))
                            .foregroundColor(Forge.chalk)
                        Spacer()
                        Text("\(p.done)/\(p.total)")
                            .font(Forge.mono(12))
                            .foregroundColor(Forge.brass)
                    }
                    ForgeBar(value: p.total > 0 ? Double(p.done) / Double(p.total) : 0,
                             tint: Forge.brass, height: 6)
                    HStack(spacing: 6) {
                        ForEach(Content.projects(in: c)) { proj in
                            let stars = store.stars(proj.id)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(stars > 0 ? Forge.brass.opacity(0.35 + Double(stars) * 0.2)
                                                : Forge.night)
                                .frame(height: 8)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .forgeCard(padding: 12)
            }
        }
    }
}

// MARK: - Calendar strip

struct ForgeCalendar: View {
    @ObservedObject var store: ForgeStore

    private var days: [Int] {
        let cal = Calendar.current
        let today = Date()
        var out: [Int] = []
        for back in stride(from: 27, through: 0, by: -1) {
            if let d = cal.date(byAdding: .day, value: -back, to: today) {
                out.append(DayKey.key(for: d))
            }
        }
        return out
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            let all = days
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { col in
                        let i = row * 7 + col
                        if i < all.count {
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(store.hasForged(on: all[i]) ? Forge.ember : Forge.night)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2.5)
                                        .stroke(all[i] == DayKey.key() ? Forge.brass : Color.clear,
                                                lineWidth: 1.2)
                                )
                        }
                    }
                }
            }
            Text("last four weeks")
                .font(Forge.body(9))
                .foregroundColor(Forge.chalkFaint)
        }
    }
}

// MARK: - Settings

struct SettingsSheet: View {
    @ObservedObject var store: ForgeStore
    let onClose: () -> Void
    let onAbout: () -> Void

    @State private var confirmReset = false

    var body: some View {
        ForgeSheet(title: "Shop Settings", onClose: onClose) {
            VStack(spacing: 0) {
                ToggleRow(title: "Sound",
                          detail: "Hammer, fire and the ring of the anvil.",
                          isOn: store.save.soundOn) { on in
                    store.setSound(on)
                    ForgeSound.shared.enabled = on
                    if on { ForgeSound.shared.startAmbient() } else { ForgeSound.shared.stopAmbient() }
                }
                Divider().background(Forge.slate)
                ToggleRow(title: "Haptics",
                          detail: "A tap in the hand on every blow.",
                          isOn: store.save.hapticsOn) { on in
                    store.setHaptics(on)
                    ForgeSound.shared.hapticsEnabled = on
                }
            }
            .forgeCard(padding: 0)

            Button(action: { ForgeSound.shared.play(.tap, volume: 0.4); onAbout() }) {
                HStack {
                    Text("About Cindrune")
                        .font(Forge.label(14))
                        .foregroundColor(Forge.chalk)
                    Spacer()
                    ChevronMark(size: 13)
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: Forge.corner, style: .continuous)
                    .fill(Forge.stone))
                .overlay(RoundedRectangle(cornerRadius: Forge.corner, style: .continuous)
                    .stroke(Forge.slate, lineWidth: 1))
            }
            .buttonStyle(PlainButtonStyle())

            SupportRow()

            VStack(alignment: .leading, spacing: 9) {
                SectionHeading(text: "Start over")
                Text("Clears every finished piece, all experience, awards and streaks. There is no way back from this.")
                    .font(Forge.body(11))
                    .foregroundColor(Forge.chalkFaint)
                    .fixedSize(horizontal: false, vertical: true)
                if confirmReset {
                    HStack(spacing: 10) {
                        ForgeButton(title: "Cancel", kind: .secondary) { confirmReset = false }
                        ForgeButton(title: "Yes, clear it", kind: .danger) {
                            store.resetEverything()
                            confirmReset = false
                            onClose()
                        }
                    }
                } else {
                    ForgeButton(title: "Empty the Shop", kind: .quiet) { confirmReset = true }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .forgeCard()

            Text("Version 1.0 · everything on this device")
                .font(Forge.body(11))
                .foregroundColor(Forge.chalkFaint)
                .frame(maxWidth: .infinity)
        }
    }
}

struct ToggleRow: View {
    let title: String
    let detail: String
    let isOn: Bool
    let onChange: (Bool) -> Void

    var body: some View {
        Button(action: {
            ForgeSound.shared.play(.tap, volume: 0.4)
            onChange(!isOn)
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Forge.label(14))
                        .foregroundColor(Forge.chalk)
                    Text(detail)
                        .font(Forge.body(11))
                        .foregroundColor(Forge.chalkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? Forge.ember : Forge.night)
                        .frame(width: 46, height: 27)
                    Circle()
                        .fill(Forge.chalk)
                        .frame(width: 21, height: 21)
                        .padding(.horizontal, 3)
                }
                .overlay(Capsule().stroke(Forge.slate, lineWidth: 1).frame(width: 46, height: 27))
            }
            .padding(14)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// The one address Cindrune knows. Tapping it hands the URL to the system
/// browser; nothing is ever loaded inside the app.
enum CindruneSupport {
    static let url = URL(string: "https://www.termsfeed.com/live/1f393bf4-2a57-4d3d-a9cf-a7fa73f1c8dc")!

    static func open() {
        UIApplication.shared.open(url)
    }
}

struct SupportRow: View {
    var body: some View {
        Button(action: {
            ForgeSound.shared.play(.tap, volume: 0.4)
            CindruneSupport.open()
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Support")
                        .font(Forge.label(14))
                        .foregroundColor(Forge.chalk)
                    Text("Questions, or the privacy policy. Opens in your browser.")
                        .font(Forge.body(11))
                        .foregroundColor(Forge.chalkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                ExternalMark(size: 15)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: Forge.corner, style: .continuous)
                .fill(Forge.stone))
            .overlay(RoundedRectangle(cornerRadius: Forge.corner, style: .continuous)
                .stroke(Forge.slate, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// An arrow leaving a box — the standard "this goes outside the app" mark,
/// drawn rather than borrowed from the system set.
struct ExternalMark: View {
    var size: CGFloat = 15
    var color: Color = Forge.brass

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            var box = Path()
            box.move(to: CGPoint(x: w * 0.56, y: h * 0.12))
            box.addLine(to: CGPoint(x: w * 0.12, y: h * 0.12))
            box.addLine(to: CGPoint(x: w * 0.12, y: h * 0.88))
            box.addLine(to: CGPoint(x: w * 0.88, y: h * 0.88))
            box.addLine(to: CGPoint(x: w * 0.88, y: h * 0.44))
            ctx.stroke(box, with: .color(color),
                       style: StrokeStyle(lineWidth: max(1.2, w * 0.10),
                                          lineCap: .round, lineJoin: .round))
            var arrow = Path()
            arrow.move(to: CGPoint(x: w * 0.46, y: h * 0.54))
            arrow.addLine(to: CGPoint(x: w * 0.92, y: h * 0.08))
            arrow.move(to: CGPoint(x: w * 0.62, y: h * 0.08))
            arrow.addLine(to: CGPoint(x: w * 0.92, y: h * 0.08))
            arrow.addLine(to: CGPoint(x: w * 0.92, y: h * 0.38))
            ctx.stroke(arrow, with: .color(color),
                       style: StrokeStyle(lineWidth: max(1.2, w * 0.10),
                                          lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct AboutSheet: View {
    let onClose: () -> Void

    var body: some View {
        ForgeSheet(title: "About", onClose: onClose) {
            Text("Cindrune")
                .font(Forge.title(24))
                .foregroundColor(Forge.chalk)
            Text("A small blacksmith's shop that runs entirely on this device. There is no account, no network connection, no advertising and no tracking. Everything you make is stored locally and nothing leaves the phone.")
                .font(Forge.body(13))
                .foregroundColor(Forge.chalkDim)
                .fixedSize(horizontal: false, vertical: true)
            HammerRule()
            Text("On the metallurgy")
                .font(Forge.heading(15))
                .foregroundColor(Forge.brass)
            Text("The heat colours, forging windows, quench severities and tempering colours in this app follow real published values for plain carbon and low-alloy steels. The simulation is deliberately simplified — volume is conserved, heat is lost to air and to the anvil, and cold-working damages the bar — but it is not a substitute for instruction. Real forging involves fire, molten scale and steel at over a thousand degrees, and should be learned in person from someone who knows how.")
                .font(Forge.body(13))
                .foregroundColor(Forge.chalkDim)
                .fixedSize(horizontal: false, vertical: true)
            HammerRule()
            Text("Every illustration, sound and animation in Cindrune was generated for it. Version 1.0.")
                .font(Forge.body(12))
                .foregroundColor(Forge.chalkFaint)
                .fixedSize(horizontal: false, vertical: true)
            HammerRule()
            SupportRow()
        }
    }
}
