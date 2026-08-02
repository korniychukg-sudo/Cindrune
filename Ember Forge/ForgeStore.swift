import Foundation
import SwiftUI

struct ForgeSave: Codable {
    var xp: Int = 0
    var best: [String: FinishedPiece] = [:]      // projectID → best result so far
    var log: [FinishedPiece] = []                // most recent first, capped
    var forgedDays: [Int] = []
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var lastForgeDay: Int = 0
    var guidesRead: [String] = []
    var badges: [String] = []
    var quizBest: Int = 0
    var quizTaken: Int = 0
    var metalsUsed: [String] = []
    var commission: Commission? = nil
    var commissionsDelivered: Int = 0
    var totalStrikes: Int = 0
    var totalHeats: Int = 0
    var totalPieces: Int = 0
    var onboarded: Bool = false
    var soundOn: Bool = true
    var hapticsOn: Bool = true
}

final class ForgeStore: ObservableObject {

    @Published private(set) var save = ForgeSave()
    /// Set when a badge is earned so the UI can show a single celebration card.
    @Published var freshBadge: ForgeBadge? = nil

    private let key = "ember.forge.save.v1"

    init() {
        load()
        refreshCommission()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        if let decoded = try? JSONDecoder().decode(ForgeSave.self, from: data) {
            save = decoded
        }
    }

    func persist() {
        if let data = try? JSONEncoder().encode(save) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func mutate(_ block: (inout ForgeSave) -> Void) {
        block(&save)
        persist()
    }

    // MARK: - Rank and unlocks

    var rankIndex: Int { Content.rankIndex(forXP: save.xp) }
    var rank: SmithRank { Content.ranks[rankIndex] }

    var nextRank: SmithRank? {
        rankIndex + 1 < Content.ranks.count ? Content.ranks[rankIndex + 1] : nil
    }

    /// Progress toward the next rank, 0…1.
    var rankProgress: Double {
        guard let next = nextRank else { return 1 }
        let floorXP = rank.xp
        let span = max(1, next.xp - floorXP)
        return min(1, max(0, Double(save.xp - floorXP) / Double(span)))
    }

    var unlockedTools: [ForgeTool] {
        ForgeTool.allCases.filter { $0.unlockRank <= rankIndex }
    }

    /// The rack the smith takes to the anvil. A commission always lends the tools
    /// its own drawing calls for, so progression never blocks a piece outright.
    func tools(for project: ForgeProject?) -> [ForgeTool] {
        var set = Set(unlockedTools)
        if let p = project {
            for f in p.features {
                switch f.kind {
                case .bend: set.insert(.bendFork)
                case .twist: set.insert(.twistWrench)
                case .hole: set.insert(.punch)
                case .taper: set.insert(.crossPeen)
                }
            }
        }
        return ForgeTool.allCases.filter { set.contains($0) }
    }

    var unlockedMetals: [Metal] {
        Metal.allCases.filter { $0.unlockRank <= rankIndex }
    }

    func isChapterOpen(_ chapter: Chapter) -> Bool {
        rankIndex >= Content.requiredRank(for: chapter)
    }

    func isProjectOpen(_ project: ForgeProject) -> Bool {
        guard isChapterOpen(project.chapter) else { return false }
        // Inside a chapter, commissions open in order once the previous one is done.
        let siblings = Content.projects(in: project.chapter)
        guard let idx = siblings.firstIndex(where: { $0.id == project.id }) else { return true }
        if idx == 0 { return true }
        return save.best[siblings[idx - 1].id] != nil
    }

    func best(_ projectID: String) -> FinishedPiece? { save.best[projectID] }

    func stars(_ projectID: String) -> Int { save.best[projectID]?.stars ?? 0 }

    var totalStars: Int { save.best.values.reduce(0) { $0 + $1.stars } }

    var maxStars: Int { Content.projects.count * 3 }

    func chapterProgress(_ chapter: Chapter) -> (done: Int, total: Int) {
        let list = Content.projects(in: chapter)
        let done = list.filter { save.best[$0.id] != nil }.count
        return (done, list.count)
    }

    // MARK: - Finishing a piece

    func record(project: ForgeProject, metal: Metal, score: ForgeScore, session: ForgeSession) {
        let today = DayKey.key()
        let piece = FinishedPiece(projectID: project.id,
                                  metal: metal,
                                  stars: score.stars,
                                  accuracy: score.total,
                                  integrity: session.piece.integrity,
                                  quality: score.quality,
                                  temper: session.temperLocked,
                                  hardened: session.hardened,
                                  strikes: session.strikeCount,
                                  heats: session.heatsUsed,
                                  dateKey: today)

        let gained = xpFor(score: score, metal: metal, project: project)

        mutate { s in
            s.xp += gained
            s.totalStrikes += session.strikeCount
            s.totalHeats += session.heatsUsed
            s.totalPieces += 1
            if let existing = s.best[project.id] {
                if piece.accuracy > existing.accuracy { s.best[project.id] = piece }
            } else {
                s.best[project.id] = piece
            }
            s.log.insert(piece, at: 0)
            if s.log.count > 60 { s.log.removeLast(s.log.count - 60) }
            if !s.metalsUsed.contains(metal.rawValue) { s.metalsUsed.append(metal.rawValue) }
            registerDay(today, into: &s)

            // Daily commission.
            if var c = s.commission, c.dateKey == today, !c.delivered,
               c.projectID == project.id, c.metal == metal, score.stars >= c.minStars {
                c.delivered = true
                s.commission = c
                s.commissionsDelivered += 1
                s.xp += 120
            }
        }
        evaluateBadges(lastScore: score, session: session, project: project)
    }

    private func xpFor(score: ForgeScore, metal: Metal, project: ForgeProject) -> Int {
        let base = 40.0 + Double(project.chapter.index) * 22.0
        let quality = 0.4 + score.total * 1.4
        return max(8, Int(base * quality * metal.valueFactor))
    }

    private func registerDay(_ day: Int, into s: inout ForgeSave) {
        guard s.lastForgeDay != day else { return }
        if s.lastForgeDay != 0 && DayKey.daysBetween(s.lastForgeDay, day) == 1 {
            s.currentStreak += 1
        } else {
            s.currentStreak = 1
        }
        s.bestStreak = max(s.bestStreak, s.currentStreak)
        s.lastForgeDay = day
        if !s.forgedDays.contains(day) {
            s.forgedDays.append(day)
            if s.forgedDays.count > 400 { s.forgedDays.removeFirst(s.forgedDays.count - 400) }
        }
    }

    /// The streak is only alive if the smith worked today or yesterday.
    var liveStreak: Int {
        guard save.lastForgeDay != 0 else { return 0 }
        let gap = DayKey.daysBetween(save.lastForgeDay, DayKey.key())
        return gap <= 1 ? save.currentStreak : 0
    }

    func hasForged(on day: Int) -> Bool { save.forgedDays.contains(day) }

    // MARK: - Daily commission

    func refreshCommission() {
        let today = DayKey.key()
        if let c = save.commission, c.dateKey == today { return }
        let open = Content.projects.filter { isChapterOpen($0.chapter) }
        let pool = open.isEmpty ? [Content.projects[0]] : open
        // Deterministic pick from the date so the order is stable through the day.
        let seed = today
        func pick(_ salt: Int, _ count: Int) -> Int {
            guard count > 0 else { return 0 }
            return ((seed &* 31 &+ salt) % count + count) % count
        }
        let project = pool[pick(7, pool.count)]
        let metals = unlockedMetals
        let metal = metals.isEmpty ? .mildSteel : metals[pick(3, metals.count)]
        let customer = Content.customers[pick(5, Content.customers.count)]
        let stars = (seed % 3 == 0) ? 3 : 2
        mutate { s in
            s.commission = Commission(dateKey: today,
                                      projectID: project.id,
                                      metal: metal,
                                      minStars: min(stars, 3),
                                      customer: customer.name,
                                      request: customer.ask,
                                      delivered: false)
        }
    }

    var commission: Commission? {
        guard let c = save.commission, c.dateKey == DayKey.key() else { return nil }
        return c
    }

    // MARK: - Almanac

    func markGuideRead(_ id: String) {
        guard !save.guidesRead.contains(id) else { return }
        mutate { $0.guidesRead.append(id) }
        evaluateBadges()
    }

    func isGuideRead(_ id: String) -> Bool { save.guidesRead.contains(id) }

    func recordQuiz(correct: Int) {
        mutate { s in
            s.quizTaken += 1
            s.quizBest = max(s.quizBest, correct)
            s.xp += correct * 12
        }
        evaluateBadges()
    }

    // MARK: - Settings

    func setSound(_ on: Bool) { mutate { $0.soundOn = on } }
    func setHaptics(_ on: Bool) { mutate { $0.hapticsOn = on } }
    func completeOnboarding() { mutate { $0.onboarded = true } }

    func resetEverything() {
        save = ForgeSave()
        save.onboarded = true
        persist()
        refreshCommission()
    }


    // MARK: - Badges

    func hasBadge(_ id: String) -> Bool { save.badges.contains(id) }

    var badgeCount: Int { save.badges.count }

    func award(_ id: String) {
        guard !save.badges.contains(id) else { return }
        mutate { $0.badges.append(id) }
        if let b = Content.badges.first(where: { $0.id == id }) {
            freshBadge = b
        }
    }

    /// Called after anything that could earn an award.
    func evaluateBadges(lastScore: ForgeScore? = nil,
                        session: ForgeSession? = nil,
                        project: ForgeProject? = nil) {
        if save.totalPieces >= 1 { award("first_piece") }
        if save.totalPieces >= 20 { award("twenty") }
        if save.best.values.contains(where: { $0.stars >= 3 }) { award("three_star") }
        if save.best.values.contains(where: { $0.quality == .pristine }) { award("pristine") }
        if save.best.values.contains(where: { $0.hardened && $0.temper != nil && $0.temper != .grey }) {
            if let p = save.best.values.first(where: { $0.hardened && $0.temper != nil }),
               let proj = Content.project(p.projectID), proj.idealTemper == p.temper {
                award("hardened")
            }
        }
        for chapter in Chapter.allCases {
            let p = chapterProgress(chapter)
            if p.total > 0 && p.done == p.total {
                switch chapter {
                case .firstHeats: award("chapter_first")
                case .tools: award("chapter_tools")
                case .hearth: award("chapter_hearth")
                case .ornament: award("chapter_ornament")
                case .masterworks: award("chapter_master")
                }
            }
        }
        if liveStreak >= 3 || save.bestStreak >= 3 { award("streak_3") }
        if save.bestStreak >= 7 { award("streak_7") }
        if save.commissionsDelivered >= 10 { award("commissions_10") }
        if save.metalsUsed.count >= Metal.allCases.count { award("all_metals") }
        if save.guidesRead.count >= Content.guides.count { award("almanac") }
        if save.quizBest >= 10 { award("quiz_perfect") }
        if save.forgedDays.count >= 1 { award("first_heat") }

        if let s = session, let p = project, let sc = lastScore, sc.stars > 0 {
            if s.strikeCount <= p.parStrikes { award("under_par") }
            if s.heatsUsed <= 1 { award("one_heat") }
            if s.piece.integrity >= 0.999 { award("no_crack") }
        }
    }
}
