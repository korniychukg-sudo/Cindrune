import SwiftUI

struct AlmanacView: View {
    @ObservedObject var store: ForgeStore

    @State private var tab = 0
    @State private var guide: ForgeGuide? = nil
    @State private var showQuiz = false
    @State private var search = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle(text: "The Almanac",
                            sub: "Twelve guides, a heat chart, six stocks and twenty-eight terms.")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        PillButton(title: "Guides", selected: tab == 0) { tab = 0 }
                        PillButton(title: "Heat", selected: tab == 1) { tab = 1 }
                        PillButton(title: "Stocks", selected: tab == 2) { tab = 2 }
                        PillButton(title: "Terms", selected: tab == 3) { tab = 3 }
                        PillButton(title: "Quiz", selected: tab == 4) { tab = 4 }
                    }
                }

                switch tab {
                case 0: guidesTab
                case 1: heatTab
                case 2: stocksTab
                case 3: termsTab
                default: quizTab
                }
            }
            .frame(maxWidth: Forge.column(UIScreen.main.bounds.width))
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 34)
            .frame(maxWidth: .infinity)
        }
        .forgeBackground()
        .sheet(item: $guide) { g in
            GuideReader(guide: g, onClose: { guide = nil })
                .onAppear { store.markGuideRead(g.id) }
        }
        .sheet(isPresented: $showQuiz) {
            QuizSheet(store: store, onClose: { showQuiz = false })
        }
    }

    // MARK: Guides

    private var guidesTab: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(store.save.guidesRead.count) of \(Content.guides.count) read")
                    .font(Forge.body(11))
                    .foregroundColor(Forge.chalkFaint)
                Spacer()
            }
            ForEach(Content.guides) { g in
                Button(action: {
                    ForgeSound.shared.play(.tap, volume: 0.4)
                    guide = g
                }) {
                    VStack(alignment: .leading, spacing: 9) {
                        ForgePlate(name: g.art, height: Forge.wide ? 160 : 116, corner: Forge.cornerSmall)
                        HStack(alignment: .top, spacing: 8) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(g.title)
                                    .font(Forge.heading(16))
                                    .foregroundColor(Forge.chalk)
                                Text(g.standfirst)
                                    .font(Forge.body(11))
                                    .foregroundColor(Forge.chalkFaint)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 4)
                            if store.isGuideRead(g.id) {
                                CheckMark(size: 15)
                            } else {
                                ChevronMark(size: 13)
                            }
                        }
                    }
                    .forgeCard()
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: Heat chart

    private var heatTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 9) {
                SectionHeading(text: "Forging colours")
                HeatScaleChart()
                Text("Colour is the only thermometer a smith has at the anvil. Learn the ladder once and it works for every steel you will ever pick up.")
                    .font(Forge.body(12))
                    .foregroundColor(Forge.chalkDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .forgeCard()

            VStack(alignment: .leading, spacing: 10) {
                SectionHeading(text: "Tempering colours")
                ForEach(TemperColor.allCases) { t in
                    HStack(spacing: 11) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(t.swatch)
                            .frame(width: 44, height: 26)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Forge.slate, lineWidth: 1))
                        VStack(alignment: .leading, spacing: 1) {
                            HStack {
                                Text(t.name)
                                    .font(Forge.label(13))
                                    .foregroundColor(Forge.chalk)
                                Spacer()
                                Text(t.celsius)
                                    .font(Forge.mono(11))
                                    .foregroundColor(Forge.chalkFaint)
                            }
                            Text(t.use)
                                .font(Forge.body(11))
                                .foregroundColor(Forge.chalkFaint)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .forgeCard()

            VStack(alignment: .leading, spacing: 10) {
                SectionHeading(text: "Quenchants")
                ForEach(Quenchant.allCases) { q in
                    HStack(alignment: .top, spacing: 11) {
                        HeatDropMark(size: 20, color: q == .air ? Forge.steel : Forge.quench)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(q.name)
                                    .font(Forge.label(13))
                                    .foregroundColor(Forge.chalk)
                                Spacer()
                                Text("severity \(String(format: "%.2f", q.severity))")
                                    .font(Forge.mono(10))
                                    .foregroundColor(Forge.chalkFaint)
                            }
                            Text(q.note)
                                .font(Forge.body(11))
                                .foregroundColor(Forge.chalkFaint)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .forgeCard()
        }
    }

    // MARK: Stocks

    private var stocksTab: some View {
        VStack(spacing: 10) {
            ForEach(Metal.allCases) { m in
                let open = store.unlockedMetals.contains(m)
                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(m.barTint)
                            .frame(width: 38, height: 16)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Forge.slate, lineWidth: 1))
                        Text(m.name)
                            .font(Forge.heading(15))
                            .foregroundColor(open ? Forge.chalk : Forge.chalkFaint)
                        Spacer()
                        if !open { LockMark(size: 14) }
                    }
                    Text(m.blurb)
                        .font(Forge.body(12))
                        .foregroundColor(Forge.chalkDim)
                        .fixedSize(horizontal: false, vertical: true)

                    // Window drawn on the same colour scale used at the anvil.
                    MetalWindowBar(metal: m)

                    HStack(spacing: 8) {
                        StatTile(value: "\(Int(m.forgingLow))–\(Int(m.forgingHigh))",
                                 caption: "Window °C", tint: Forge.spark)
                        StatTile(value: String(format: "%.2f", m.plasticity),
                                 caption: "Moves like", tint: Forge.chalkDim)
                        StatTile(value: String(format: "×%.1f", m.valueFactor),
                                 caption: "Pays", tint: Forge.brass)
                    }
                    if !open {
                        Text("Comes into the shop at \(Content.ranks[m.unlockRank].name).")
                            .font(Forge.body(11))
                            .foregroundColor(Forge.brass)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .forgeCard()
            }
        }
    }

    // MARK: Terms

    private var termsTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            SearchField(text: $search, placeholder: "Search the terms")
            let list = Content.glossary.filter {
                search.isEmpty
                || $0.term.lowercased().contains(search.lowercased())
                || $0.meaning.lowercased().contains(search.lowercased())
            }
            if list.isEmpty {
                Text("Nothing under that word.")
                    .font(Forge.body(12))
                    .foregroundColor(Forge.chalkFaint)
                    .padding(.vertical, 20)
            }
            ForEach(list) { e in
                VStack(alignment: .leading, spacing: 3) {
                    Text(e.term)
                        .font(Forge.heading(14))
                        .foregroundColor(Forge.brass)
                    Text(e.meaning)
                        .font(Forge.body(12))
                        .foregroundColor(Forge.chalkDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .forgeCard(padding: 12)
            }
        }
    }

    // MARK: Quiz

    private var quizTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 9) {
                SectionHeading(text: "Ten questions")
                Text("Drawn fresh from a bank of thirty, with the reasoning shown after every answer.")
                    .font(Forge.body(12))
                    .foregroundColor(Forge.chalkDim)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    StatTile(value: "\(store.save.quizBest)/10", caption: "Best round", tint: Forge.spark)
                    StatTile(value: "\(store.save.quizTaken)", caption: "Rounds taken")
                }
                ForgeButton(title: "Start a Round", kind: .primary) { showQuiz = true }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .forgeCard()
        }
    }
}

// MARK: - Heat scale chart

struct HeatScaleChart: View {
    private let marks: [(Double, String)] = [
        (540, "Faint red"), (700, "Dull red"), (800, "Cherry"),
        (950, "Orange"), (1100, "Light orange"), (1250, "Yellow"), (1400, "White")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(0..<48, id: \.self) { i in
                        Rectangle()
                            .fill(HeatColor.color(for: 400 + Double(i) / 47 * 1050))
                            .frame(width: geo.size.width / 48)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .frame(height: 30)

            VStack(spacing: 5) {
                ForEach(0..<marks.count, id: \.self) { i in
                    HStack(spacing: 9) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(HeatColor.color(for: marks[i].0))
                            .frame(width: 22, height: 12)
                        Text(marks[i].1)
                            .font(Forge.body(12))
                            .foregroundColor(Forge.chalkDim)
                        Spacer()
                        Text("\(Int(marks[i].0)) °C")
                            .font(Forge.mono(11))
                            .foregroundColor(Forge.chalkFaint)
                    }
                }
            }
        }
    }
}

struct MetalWindowBar: View {
    let metal: Metal

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let lo = CGFloat((metal.forgingLow - 400) / 1100)
            let hi = CGFloat((metal.forgingHigh - 400) / 1100)
            let burn = CGFloat((metal.burnPoint - 400) / 1100)
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    ForEach(0..<40, id: \.self) { i in
                        Rectangle()
                            .fill(HeatColor.color(for: 400 + Double(i) / 39 * 1100))
                            .frame(width: w / 40)
                    }
                }
                .frame(height: 14)
                .clipShape(Capsule())
                .opacity(0.75)

                Rectangle()
                    .stroke(Forge.chalk, lineWidth: 1.4)
                    .frame(width: max(2, (hi - lo) * w), height: 14)
                    .offset(x: max(0, lo * w))

                Rectangle()
                    .fill(Forge.warn)
                    .frame(width: 2, height: 19)
                    .offset(x: max(0, min(w - 2, burn * w)))
            }
            .frame(height: 20)
        }
        .frame(height: 20)
    }
}

// MARK: - Search

struct SearchField: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 9) {
            Canvas { ctx, s in
                let r = min(s.width, s.height) * 0.32
                let c = CGPoint(x: s.width * 0.44, y: s.height * 0.44)
                ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                           with: .color(Forge.chalkFaint), lineWidth: 1.6)
                var tail = Path()
                tail.move(to: CGPoint(x: c.x + r * 0.72, y: c.y + r * 0.72))
                tail.addLine(to: CGPoint(x: s.width * 0.86, y: s.height * 0.86))
                ctx.stroke(tail, with: .color(Forge.chalkFaint),
                           style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            }
            .frame(width: 16, height: 16)

            TextField(placeholder, text: $text)
                .font(Forge.body(13))
                .foregroundColor(Forge.chalk)
                .accentColor(Forge.brass)
                .disableAutocorrection(true)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    CrossMark(size: 13)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Forge.stone))
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
            .stroke(Forge.slate, lineWidth: 1))
    }
}

// MARK: - Guide reader

struct GuideReader: View {
    let guide: ForgeGuide
    let onClose: () -> Void

    var body: some View {
        ForgeSheet(title: guide.title, onClose: onClose) {
            ForgePlate(name: guide.art, height: Forge.wide ? 210 : 165)
            Text(guide.standfirst)
                .font(Forge.heading(15))
                .foregroundColor(Forge.brass)
                .fixedSize(horizontal: false, vertical: true)
            HammerRule()
            ForEach(0..<guide.paragraphs.count, id: \.self) { i in
                Text(guide.paragraphs[i])
                    .font(Forge.body(14))
                    .foregroundColor(Forge.chalkDim)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Quiz

struct QuizSheet: View {
    @ObservedObject var store: ForgeStore
    let onClose: () -> Void

    @State private var questions: [QuizQuestion] = []
    @State private var index = 0
    @State private var picked: Int? = nil
    @State private var correct = 0
    @State private var done = false

    var body: some View {
        ForgeSheet(title: "Trade Questions", onClose: onClose) {
            if done {
                VStack(spacing: 14) {
                    Text("\(correct) out of \(questions.count)")
                        .font(Forge.title(28))
                        .foregroundColor(Forge.brass)
                    Text(verdict)
                        .font(Forge.body(13))
                        .foregroundColor(Forge.chalkDim)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    ForgeButton(title: "Another Round", kind: .secondary) { newRound() }
                    ForgeButton(title: "Close the Book", kind: .primary) { onClose() }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
            } else if index < questions.count {
                let q = questions[index]
                HStack {
                    Text("Question \(index + 1) of \(questions.count)")
                        .font(Forge.label(11))
                        .foregroundColor(Forge.chalkFaint)
                    Spacer()
                    Text("\(correct) right")
                        .font(Forge.label(11))
                        .foregroundColor(Forge.brass)
                }
                ForgeBar(value: Double(index) / Double(max(1, questions.count)),
                         tint: Forge.brass, height: 5)

                Text(q.prompt)
                    .font(Forge.heading(17))
                    .foregroundColor(Forge.chalk)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(0..<q.options.count, id: \.self) { i in
                    Button(action: { pick(i, q: q) }) {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .stroke(optionStroke(i, q: q), lineWidth: 1.5)
                                    .frame(width: 20, height: 20)
                                if picked != nil && i == q.answer { CheckMark(size: 12) }
                                if picked == i && i != q.answer { CrossMark(size: 11, color: Forge.warn) }
                            }
                            Text(q.options[i])
                                .font(Forge.body(13))
                                .foregroundColor(Forge.chalk)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 4)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(optionFill(i, q: q)))
                        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(optionStroke(i, q: q), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(picked != nil)
                }

                if picked != nil {
                    Text(q.because)
                        .font(Forge.body(12))
                        .foregroundColor(Forge.chalkDim)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 11).fill(Forge.night.opacity(0.5)))
                    ForgeButton(title: index + 1 < questions.count ? "Next" : "Finish",
                                kind: .primary) { advance() }
                }
            }
        }
        .onAppear { if questions.isEmpty { newRound() } }
    }

    private var verdict: String {
        switch correct {
        case 10: return "Every one. You could run the shop."
        case 8...9: return "Only a hammer's width off. Solid trade knowledge."
        case 5...7: return "A working understanding, with some gaps at the fire."
        default: return "Worth another read of the guides before the next round."
        }
    }

    private func newRound() {
        questions = Array(Content.quiz.shuffled().prefix(10))
        index = 0
        picked = nil
        correct = 0
        done = false
    }

    private func pick(_ i: Int, q: QuizQuestion) {
        guard picked == nil else { return }
        picked = i
        if i == q.answer {
            correct += 1
            ForgeSound.shared.play(.chime, volume: 0.5)
            ForgeSound.shared.bump(0)
        } else {
            ForgeSound.shared.play(.hitCold, volume: 0.4)
            ForgeSound.shared.bump(1)
        }
    }

    private func advance() {
        if index + 1 < questions.count {
            index += 1
            picked = nil
        } else {
            done = true
            store.recordQuiz(correct: correct)
        }
    }

    private func optionFill(_ i: Int, q: QuizQuestion) -> Color {
        guard let p = picked else { return Forge.stone }
        if i == q.answer { return Forge.good.opacity(0.18) }
        if i == p { return Forge.warn.opacity(0.16) }
        return Forge.stone
    }

    private func optionStroke(_ i: Int, q: QuizQuestion) -> Color {
        guard let p = picked else { return Forge.slate }
        if i == q.answer { return Forge.good }
        if i == p { return Forge.warn }
        return Forge.slate
    }
}
