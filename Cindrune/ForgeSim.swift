import Foundation
import SwiftUI

// MARK: - The bar itself

struct BarSegment {
    var thickness: Double   // mm, vertical section on the anvil
    var width: Double       // mm, across the anvil face
    var length: Double      // mm along the bar
}

/// A short-lived note about what a single hammer blow did.
struct StrikeReport {
    var moved: Double = 0          // how much section was displaced (0…1)
    var coldDamage: Double = 0
    var burnLoss: Double = 0
    var punched = false
    var bent = false
    var twisted = false
    var rejected: String? = nil    // why nothing happened
    var sparks: Int = 0
}

struct Workpiece {
    static let count = 14

    var segs: [BarSegment]
    var bend: [Double]        // degrees of direction change stored at each joint
    var twist: [Double]       // 0…1 how twisted each segment is
    var holes: [Bool]
    var integrity: Double = 1
    var scale: Double = 0     // fire scale on the surface, cosmetic
    var burnt: Double = 0

    init(length: Double, thickness: Double, width: Double) {
        let l = length / Double(Workpiece.count)
        segs = Array(repeating: BarSegment(thickness: thickness, width: width, length: l),
                     count: Workpiece.count)
        bend = Array(repeating: 0, count: Workpiece.count)
        twist = Array(repeating: 0, count: Workpiece.count)
        holes = Array(repeating: false, count: Workpiece.count)
    }

    var totalLength: Double { segs.reduce(0) { $0 + $1.length } }

    var volume: Double { segs.reduce(0) { $0 + $1.thickness * $1.width * $1.length } }

    /// Thickness and width sampled at `n` evenly spaced points along the bar.
    func sampled(_ n: Int) -> [(t: Double, w: Double)] {
        let total = totalLength
        guard total > 0 else { return Array(repeating: (t: 0, w: 0), count: n) }
        var out: [(t: Double, w: Double)] = []
        out.reserveCapacity(n)
        for i in 0..<n {
            let target = total * (Double(i) + 0.5) / Double(n)
            var run = 0.0
            var picked = segs[segs.count - 1]
            for s in segs {
                run += s.length
                if run >= target { picked = s; break }
            }
            out.append((t: picked.thickness, w: picked.width))
        }
        return out
    }
}

// MARK: - Target shape

struct TargetShape {
    let samples: [(t: Double, w: Double)]
    let totalLength: Double
    let features: [FeatureSpec]

    /// Builds a target that holds exactly the same volume of metal as the starting
    /// bar, so every commission is actually reachable by moving metal around.
    init(project: ForgeProject) {
        let n = Workpiece.count
        var raw: [(t: Double, w: Double)] = []
        raw.reserveCapacity(n)
        let keys = project.keys.sorted { $0.pos < $1.pos }
        for i in 0..<n {
            let p = (Double(i) + 0.5) / Double(n)
            raw.append(TargetShape.interpolate(keys, at: p))
        }
        let barVolume = project.barLength * project.barThickness * project.barWidth
        // Section area integrated over a unit length.
        let meanArea = raw.reduce(0) { $0 + $1.t * $1.w } / Double(n)
        let length = meanArea > 0 ? barVolume / meanArea : project.barLength
        samples = raw
        totalLength = length
        features = project.features
    }

    private static func interpolate(_ keys: [ProfileKey], at p: Double) -> (t: Double, w: Double) {
        guard let first = keys.first else { return (t: 10, w: 10) }
        if p <= first.pos { return (t: first.thickness, w: first.width) }
        guard let last = keys.last else { return (t: 10, w: 10) }
        if p >= last.pos { return (t: last.thickness, w: last.width) }
        for i in 0..<(keys.count - 1) {
            let a = keys[i], b = keys[i + 1]
            if p >= a.pos && p <= b.pos {
                let span = max(0.0001, b.pos - a.pos)
                let f = (p - a.pos) / span
                let e = f * f * (3 - 2 * f)   // smoothstep, so shoulders read as forged, not stepped
                return (t: a.thickness + (b.thickness - a.thickness) * e,
                        w: a.width + (b.width - a.width) * e)
            }
        }
        return (t: last.thickness, w: last.width)
    }
}

// MARK: - Scoring

struct ForgeScore {
    var profile: Double = 0
    var features: Double = 0
    var integrity: Double = 0
    var total: Double = 0
    var stars: Int = 0
    var quality: PieceQuality = .scrap
    var notes: [String] = []
}

enum ForgeJudge {

    static func score(piece: Workpiece, target: TargetShape, heatsUsed: Int, allowed: Int) -> ForgeScore {
        var out = ForgeScore()

        // Profile — how close each section is to what was asked for.
        let actual = piece.sampled(Workpiece.count)
        var acc = 0.0
        for i in 0..<Workpiece.count {
            let tgt = target.samples[i]
            let tErr = abs(actual[i].t - tgt.t) / max(1.0, tgt.t)
            let wErr = abs(actual[i].w - tgt.w) / max(1.0, tgt.w)
            let seg = 1 - min(1, tErr * 0.62 + wErr * 0.38)
            acc += max(0, seg)
        }
        out.profile = acc / Double(Workpiece.count)

        // Length matters too — you can hit every section and still be short.
        let lenErr = abs(piece.totalLength - target.totalLength) / max(1, target.totalLength)
        out.profile = max(0, out.profile - min(0.35, lenErr * 0.8))

        // Features.
        if target.features.isEmpty {
            out.features = out.profile
        } else {
            var f = 0.0
            for spec in target.features {
                f += featureScore(spec, in: piece)
            }
            out.features = f / Double(target.features.count)
        }

        out.integrity = piece.integrity

        var total = out.profile * 0.56 + out.features * 0.26 + out.integrity * 0.18
        if piece.burnt > 0.02 { total -= min(0.2, piece.burnt) }
        if heatsUsed > allowed { total -= 0.06 * Double(heatsUsed - allowed) }
        out.total = max(0, min(1, total))

        out.stars = out.total >= 0.85 ? 3 : (out.total >= 0.70 ? 2 : (out.total >= 0.55 ? 1 : 0))

        switch (out.total, piece.integrity) {
        case let (t, i) where t >= 0.92 && i >= 0.95: out.quality = .pristine
        case let (t, i) where t >= 0.82 && i >= 0.8: out.quality = .fine
        case let (t, _) where t >= 0.70: out.quality = .good
        case let (t, _) where t >= 0.52: out.quality = .serviceable
        default: out.quality = .scrap
        }

        if out.profile < 0.6 { out.notes.append("The section wanders away from the drawing — fuller the shoulders and draw the tip finer.") }
        if lenErr > 0.12 && piece.totalLength < target.totalLength {
            out.notes.append("Short by \(Int((target.totalLength - piece.totalLength).rounded())) mm. More peen work along the bar would have drawn it out.")
        }
        if lenErr > 0.12 && piece.totalLength > target.totalLength {
            out.notes.append("Over-length by \(Int((piece.totalLength - target.totalLength).rounded())) mm. You drew it thinner than the drawing wanted.")
        }
        if piece.integrity < 0.8 { out.notes.append("Cold-working left cracks in the bar. Back to the fire sooner next time.") }
        if piece.burnt > 0.02 { out.notes.append("The bar burned in the fire and lost metal. Watch for sparks off the stock.") }
        if out.features < 0.6 && !target.features.isEmpty { out.notes.append("The commission called for shaping the drawing shows in blue — check bends, twists and holes.") }
        if out.notes.isEmpty { out.notes.append("Clean work. The drawing and the bar agree.") }

        return out
    }

    private static func featureScore(_ spec: FeatureSpec, in piece: Workpiece) -> Double {
        let idx = index(for: spec.at)
        switch spec.kind {
        case .bend:
            let got = abs(piece.bend[idx]) + abs(piece.bend[max(0, idx - 1)]) * 0.5 + abs(piece.bend[min(Workpiece.count - 1, idx + 1)]) * 0.5
            let want = abs(spec.amount)
            guard want > 0 else { return 1 }
            return max(0, 1 - min(1, abs(got - want) / want))
        case .twist:
            let got = piece.twist[idx]
            return max(0, 1 - min(1, abs(got - 1) ))
        case .hole:
            if piece.holes[idx] { return 1 }
            if idx > 0 && piece.holes[idx - 1] { return 0.6 }
            if idx < Workpiece.count - 1 && piece.holes[idx + 1] { return 0.6 }
            return 0
        case .taper:
            // A taper is judged on the profile pass; treat it as satisfied when the
            // end section really is thinner than the middle.
            let end = piece.segs[idx].thickness
            let mid = piece.segs[Workpiece.count / 2].thickness
            guard mid > 0 else { return 0 }
            let ratio = end / mid
            return max(0, 1 - min(1, abs(ratio - 0.35) / 0.65))
        }
    }

    static func index(for pos: Double) -> Int {
        max(0, min(Workpiece.count - 1, Int(pos * Double(Workpiece.count))))
    }
}

// MARK: - Session

enum ForgePhase: Equatable {
    case fire        // stock is in the coals, heating
    case anvil       // stock is on the anvil, cooling, taking blows
    case quenching   // choosing and performing the quench
    case tempering   // running the colours
    case finished
}

final class ForgeSession: ObservableObject {

    // Configuration
    let project: ForgeProject?
    let metal: Metal
    let target: TargetShape?
    let freeForge: Bool
    let heatsAllowed: Int
    let availableTools: [ForgeTool]

    // Live state
    @Published var piece: Workpiece
    @Published var temperature: Double = 20
    @Published var fireTemperature: Double = 720
    @Published var bellows: Double = 0            // 0…1, decays back down
    @Published var phase: ForgePhase = .fire
    @Published var tool: ForgeTool = .hammer
    @Published var strikeCount = 0
    @Published var heatsUsed = 1
    @Published var lastReport: StrikeReport? = nil
    @Published var powerPhase: Double = 0         // sweeping 0…1 power meter
    @Published var hammerFall: Double = 0         // 0…1 animation of the blow
    @Published var struckIndex: Int? = nil
    @Published var quenchant: Quenchant = .oil
    @Published var quenchTemp: Double = 0
    @Published var hardened = false
    @Published var quenchCracked = false
    @Published var temperRun: Double = 0          // 0…1 through the colour run
    @Published var temperLocked: TemperColor? = nil
    @Published var score: ForgeScore? = nil
    @Published var sparkSeeds: [SparkSeed] = []
    @Published var toast: String? = nil

    private var powerRising = true

    init(project: ForgeProject?, metal: Metal, tools: [ForgeTool], freeForge: Bool) {
        self.project = project
        self.metal = metal
        self.freeForge = freeForge
        self.availableTools = tools.isEmpty ? [.hammer] : tools
        if let p = project {
            self.piece = Workpiece(length: p.barLength, thickness: p.barThickness, width: p.barWidth)
            self.target = TargetShape(project: p)
            self.heatsAllowed = freeForge ? 99 : p.heatsAllowed
        } else {
            self.piece = Workpiece(length: 160, thickness: 12, width: 12)
            self.target = nil
            self.heatsAllowed = 99
        }
        self.tool = self.availableTools.first ?? .hammer
    }

    var heatsLeft: Int { max(0, heatsAllowed - heatsUsed) }

    var inWindow: Bool { temperature >= metal.forgingLow && temperature <= metal.forgingHigh }

    var burning: Bool { temperature > metal.burnPoint }

    var heatAdvice: String {
        if burning { return "Burning — pull it out" }
        if temperature > metal.forgingHigh { return "Too hot to strike" }
        if inWindow { return "Forging heat" }
        if temperature > metal.forgingLow - 180 { return "Going off colour" }
        if temperature > 480 { return "Too cold — it will crack" }
        return "Black cold"
    }

    // MARK: Ticking

    /// Advances the simulation. Called from a display timer at ~30 Hz.
    func tick(_ dt: Double) {
        // Power meter sweeps whenever the smith is at the anvil.
        if phase == .anvil {
            let speed = 1.55
            if powerRising {
                powerPhase += dt * speed
                if powerPhase >= 1 { powerPhase = 1; powerRising = false }
            } else {
                powerPhase -= dt * speed
                if powerPhase <= 0 { powerPhase = 0; powerRising = true }
            }
        }

        if hammerFall > 0 { hammerFall = max(0, hammerFall - dt * 5.5) }

        // Bellows decay, fire follows the bellows.
        bellows = max(0, bellows - dt * 0.34)
        let fireTarget = 760 + bellows * 640
        fireTemperature += (fireTarget - fireTemperature) * min(1, dt * 1.6)

        switch phase {
        case .fire:
            // Section drives how quickly heat soaks in.
            let section = max(4, averageSection())
            let rate = 1.9 / (0.5 + section / 12)
            temperature += (fireTemperature - temperature) * min(1, dt * rate * 0.55)
            if temperature > metal.burnPoint {
                let over = (temperature - metal.burnPoint) / 100
                let loss = over * dt * 0.045
                piece.burnt += loss
                piece.integrity = max(0, piece.integrity - loss * 0.6)
                shrinkFromBurning(loss)
                if Int(temperature) % 3 == 0 { emitSparks(6) }
            }
            piece.scale = min(1, piece.scale + dt * 0.02 * max(0, (temperature - 800) / 500))

        case .anvil:
            let section = max(3, averageSection())
            let rate = 0.052 * metal.coolRate * (14 / (4 + section))
            temperature = 20 + (temperature - 20) * exp(-rate * dt * 1.1)

        case .quenching:
            let drop = 900 * quenchant.severity * dt
            temperature = max(30, temperature - drop)

        case .tempering, .finished:
            break
        }

        if temperature < 20 { temperature = 20 }
        agingSparks(dt)
    }

    private func averageSection() -> Double {
        let s = piece.segs
        guard !s.isEmpty else { return 10 }
        return s.reduce(0) { $0 + ($1.thickness + $1.width) / 2 } / Double(s.count)
    }

    private func shrinkFromBurning(_ loss: Double) {
        let f = 1 - loss * 0.5
        for i in piece.segs.indices {
            piece.segs[i].thickness *= f
            piece.segs[i].width *= f
        }
    }

    // MARK: Fire and anvil

    func pumpBellows() {
        bellows = min(1, bellows + 0.30)
        emitSparks(4)
    }

    func toAnvil() {
        guard phase == .fire else { return }
        phase = .anvil
        powerPhase = 0
        powerRising = true
    }

    func backToFire() {
        guard phase == .anvil else { return }
        if !freeForge && heatsLeft == 0 {
            toast = "No heats left on this commission."
            return
        }
        heatsUsed += 1
        phase = .fire
    }

    // MARK: Striking

    /// `at` is 0…1 along the bar. Returns a description of the blow.
    @discardableResult
    func strike(at pos: Double) -> StrikeReport {
        guard phase == .anvil else { return StrikeReport(rejected: "Not on the anvil") }
        var report = StrikeReport()
        let idx = ForgeJudge.index(for: pos)
        struckIndex = idx
        hammerFall = 1
        strikeCount += 1

        let power = 0.35 + powerPhase * 0.65       // where the sweeping meter was
        let heatF = heatFactor()

        if burning {
            report.rejected = "The bar is burning — it crumbles under the hammer."
            piece.integrity = max(0, piece.integrity - 0.06)
            piece.burnt += 0.03
            report.burnLoss = 0.03
            report.sparks = 14
            emitSparks(14)
            lastReport = report
            return report
        }

        switch tool {
        case .hammer, .crossPeen, .fuller:
            applyForming(idx: idx, power: power, heat: heatF, report: &report)
        case .punch:
            applyPunch(idx: idx, power: power, heat: heatF, report: &report)
        case .bendFork:
            applyBend(idx: idx, power: power, heat: heatF, report: &report)
        case .twistWrench:
            applyTwist(idx: idx, power: power, heat: heatF, report: &report)
        }

        // Every blow sheds heat into the anvil.
        temperature = max(20, temperature - 6 - power * 10)
        let s = report.sparks + (temperature > 900 ? 6 : 2)
        emitSparks(s)
        report.sparks = s
        lastReport = report
        return report
    }

    /// 0 when the metal will not move, 1 in the middle of the forging window.
    private func heatFactor() -> Double {
        let lo = metal.forgingLow, hi = metal.forgingHigh
        if temperature >= lo && temperature <= hi {
            let mid = (lo + hi) / 2
            let half = (hi - lo) / 2
            let d = abs(temperature - mid) / max(1, half)
            return 0.82 + 0.18 * (1 - d)
        }
        if temperature > hi { return 0.9 }
        let fade = (temperature - (lo - 240)) / 240
        return max(0, min(0.8, fade * 0.8))
    }

    private func coldDamage(_ power: Double) -> Double {
        guard temperature < metal.forgingLow else { return 0 }
        let below = (metal.forgingLow - temperature) / metal.forgingLow
        return metal.coldPenalty * below * (0.5 + power)
    }

    private func applyForming(idx: Int, power: Double, heat: Double, report: inout StrikeReport) {
        // Calibrated so a commission that has to be drawn out two or three times
        // its starting length is reachable inside its par strikes.
        let base: Double
        switch tool {
        case .fuller: base = 0.240
        case .crossPeen: base = 0.200
        default: base = 0.140
        }
        let e = base * power * heat * metal.plasticity
        guard e > 0.0015 else {
            report.rejected = "Nothing moves. The bar is stone cold."
            let dmg = coldDamage(power)
            piece.integrity = max(0, piece.integrity - dmg)
            report.coldDamage = dmg
            return
        }

        let spread: [(Int, Double)]
        switch tool {
        case .fuller:
            spread = [(idx, 1.0)]
        case .crossPeen:
            spread = [(idx, 1.0), (idx - 1, 0.30), (idx + 1, 0.30)]
        default:
            spread = [(idx, 1.0), (idx - 1, 0.38), (idx + 1, 0.38), (idx - 2, 0.12), (idx + 2, 0.12)]
        }

        for (i, weight) in spread {
            guard i >= 0 && i < piece.segs.count else { continue }
            var seg = piece.segs[i]
            let hit = e * weight
            let newT = max(0.7, seg.thickness * (1 - hit))
            guard newT < seg.thickness else { continue }
            let k = seg.thickness / newT      // volume must go somewhere
            seg.thickness = newT
            switch tool {
            case .crossPeen:
                seg.length *= k
            case .fuller:
                seg.width *= pow(k, 0.72)
                seg.length *= pow(k, 0.28)
            default:
                seg.width *= sqrt(k)
                seg.length *= sqrt(k)
            }
            piece.segs[i] = seg
            report.moved += hit * weight
        }

        let dmg = coldDamage(power)
        if dmg > 0 {
            piece.integrity = max(0, piece.integrity - dmg)
            report.coldDamage = dmg
        }
    }

    private func applyPunch(idx: Int, power: Double, heat: Double, report: inout StrikeReport) {
        guard temperature >= metal.forgingLow + 60 else {
            report.rejected = "A punch needs a bright heat. Back in the fire."
            let dmg = coldDamage(power) * 1.6
            piece.integrity = max(0, piece.integrity - dmg)
            report.coldDamage = dmg
            return
        }
        guard power > 0.55 else {
            report.rejected = "Too light. The punch only marked the surface."
            return
        }
        if piece.holes[idx] {
            report.rejected = "There is already a hole there."
            return
        }
        piece.holes[idx] = true
        // Punching swells the metal around the hole.
        piece.segs[idx].width *= 1.06
        piece.segs[idx].thickness *= 0.97
        report.punched = true
        report.sparks = 8
    }

    private func applyBend(idx: Int, power: Double, heat: Double, report: inout StrikeReport) {
        let amount = 26 * power * max(0.12, heat)
        piece.bend[idx] += amount
        report.bent = true
        if temperature < metal.forgingLow {
            let dmg = coldDamage(power) * 1.35
            piece.integrity = max(0, piece.integrity - dmg)
            report.coldDamage = dmg
        }
    }

    private func applyTwist(idx: Int, power: Double, heat: Double, report: inout StrikeReport) {
        guard temperature >= metal.forgingLow else {
            report.rejected = "Cold metal will not take a twist. It tears."
            let dmg = coldDamage(power) * 1.5
            piece.integrity = max(0, piece.integrity - dmg)
            report.coldDamage = dmg
            return
        }
        let amount = 0.42 * power
        for i in max(0, idx - 1)...min(Workpiece.count - 1, idx + 1) {
            piece.twist[i] = min(1, piece.twist[i] + amount * (i == idx ? 1 : 0.6))
        }
        report.twisted = true
    }

    // MARK: Finishing

    func beginQuench() {
        guard phase == .anvil else { return }
        phase = .quenching
        quenchTemp = temperature
    }

    func doQuench(_ q: Quenchant) {
        quenchant = q
        quenchTemp = temperature
        // Hardening only happens if there is carbon to harden and the piece was
        // above the critical temperature when it went in.
        let critical = 760.0
        let canHarden = metal != .wroughtIron && metal != .mildSteel
        if temperature >= critical && q.severity >= 0.4 && canHarden {
            hardened = true
            // Severe quenchants crack the tough steels.
            let risk = (q.severity - 0.45) * 1.5 * (metal == .springSteel ? 1.3 : 1.0)
            let thin = piece.segs.map { $0.thickness }.min() ?? 10
            let thinRisk = thin < 4 ? 0.25 : 0
            if Double.random(in: 0...1) < max(0, risk * 0.55 + thinRisk) {
                quenchCracked = true
                piece.integrity = max(0, piece.integrity - 0.32)
            }
        } else if temperature >= critical && q.severity >= 0.4 && !canHarden {
            hardened = false
        }
        temperature = 40
        phase = hardened ? .tempering : .finished
        if phase == .finished { finish() }
    }

    func skipQuench() {
        hardened = false
        temperature = 40
        phase = .finished
        finish()
    }

    func advanceTemper(_ dt: Double) {
        guard phase == .tempering, temperLocked == nil else { return }
        temperRun = min(1.0, temperRun + dt * 0.155)
    }

    var currentTemperColor: TemperColor {
        switch temperRun {
        case ..<0.22: return .straw
        case ..<0.44: return .bronze
        case ..<0.64: return .purple
        case ..<0.84: return .blue
        default: return .grey
        }
    }

    func lockTemper() {
        guard phase == .tempering, temperLocked == nil else { return }
        temperLocked = currentTemperColor
        phase = .finished
        finish()
    }

    private func finish() {
        guard let target = target else {
            score = nil
            return
        }
        var s = ForgeJudge.score(piece: piece, target: target, heatsUsed: heatsUsed, allowed: heatsAllowed)
        if let p = project {
            if p.needsHardening && !hardened {
                s.total = max(0, s.total - 0.10)
                s.notes.append("This one wanted hardening. Left soft, it will not hold an edge.")
            }
            if let want = p.idealTemper, let got = temperLocked {
                if got == .grey {
                    s.total = max(0, s.total - 0.10)
                    s.notes.append("The colours ran past blue into grey — the temper is gone.")
                } else if got != want {
                    s.total = max(0, s.total - 0.05)
                    s.notes.append("Drawn to \(got.name); this piece wanted \(want.name).")
                } else {
                    s.total = min(1, s.total + 0.03)
                    s.notes.append("Caught the colour exactly at \(want.name).")
                }
            }
            if quenchCracked {
                s.notes.append("A quench crack opened along the bar. Oil would have been gentler.")
            }
            s.stars = s.total >= 0.85 ? 3 : (s.total >= 0.70 ? 2 : (s.total >= 0.55 ? 1 : 0))
        }
        score = s
    }

    // MARK: Sparks

    struct SparkSeed: Identifiable {
        let id = UUID()
        var x: Double
        var y: Double
        var vx: Double
        var vy: Double
        var life: Double
        var maxLife: Double
        var size: Double
    }

    func emitSparks(_ n: Int) {
        guard n > 0 else { return }
        var new: [SparkSeed] = []
        for _ in 0..<n {
            let a = Double.random(in: -2.6 ... -0.5)
            let speed = Double.random(in: 0.25...1.0)
            new.append(SparkSeed(x: Double.random(in: 0.35...0.65),
                                 y: Double.random(in: 0.42...0.58),
                                 vx: cos(a) * speed,
                                 vy: sin(a) * speed,
                                 life: 0,
                                 maxLife: Double.random(in: 0.45...1.1),
                                 size: Double.random(in: 1.4...3.6)))
        }
        sparkSeeds.append(contentsOf: new)
        if sparkSeeds.count > 130 { sparkSeeds.removeFirst(sparkSeeds.count - 130) }
    }

    private func agingSparks(_ dt: Double) {
        guard !sparkSeeds.isEmpty else { return }
        for i in sparkSeeds.indices {
            sparkSeeds[i].life += dt
            sparkSeeds[i].x += sparkSeeds[i].vx * dt * 0.18
            sparkSeeds[i].y += sparkSeeds[i].vy * dt * 0.18
            sparkSeeds[i].vy += dt * 0.55       // sparks arc back down
        }
        sparkSeeds.removeAll { $0.life >= $0.maxLife }
    }
}
