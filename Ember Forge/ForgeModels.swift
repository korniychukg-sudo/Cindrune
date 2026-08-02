import Foundation
import SwiftUI

// MARK: - Metals

enum Metal: String, Codable, CaseIterable, Identifiable {
    case mildSteel
    case wroughtIron
    case highCarbon
    case springSteel
    case patternWeld
    case meteoric

    var id: String { rawValue }

    var name: String {
        switch self {
        case .mildSteel: return "Mild Steel"
        case .wroughtIron: return "Wrought Iron"
        case .highCarbon: return "High Carbon Steel"
        case .springSteel: return "Spring Steel"
        case .patternWeld: return "Pattern-Welded Billet"
        case .meteoric: return "Meteoric Iron"
        }
    }

    var blurb: String {
        switch self {
        case .mildSteel:
            return "Forgiving, cheap and everywhere. Low carbon means it will not harden much, but it will also not crack while you learn."
        case .wroughtIron:
            return "The old material — fibrous, full of glassy slag stringers. It moves beautifully at a bright heat and splits if you work it cold."
        case .highCarbon:
            return "Holds an edge and holds a grudge. Narrow forging window, and it will crack if you strike it below a dull red."
        case .springSteel:
            return "Tough, springy, reluctant. It needs real heat and real force, and it punishes a rushed quench."
        case .patternWeld:
            return "Layers of two steels folded together. Work it gently at a welding heat and the pattern surfaces when you etch it."
        case .meteoric:
            return "Iron that fell out of the sky, laced with nickel. Rare, stubborn, and unmistakable once it is finished."
        }
    }

    /// Temperature band where the metal moves well.
    var forgingLow: Double {
        switch self {
        case .mildSteel: return 760
        case .wroughtIron: return 900
        case .highCarbon: return 820
        case .springSteel: return 870
        case .patternWeld: return 900
        case .meteoric: return 950
        }
    }

    var forgingHigh: Double {
        switch self {
        case .mildSteel: return 1300
        case .wroughtIron: return 1360
        case .highCarbon: return 1220
        case .springSteel: return 1260
        case .patternWeld: return 1300
        case .meteoric: return 1330
        }
    }

    /// Above this the metal starts to burn and lose material.
    var burnPoint: Double { forgingHigh + 60 }

    /// How readily it deforms per strike (1.0 = mild steel).
    var plasticity: Double {
        switch self {
        case .mildSteel: return 1.0
        case .wroughtIron: return 1.08
        case .highCarbon: return 0.86
        case .springSteel: return 0.74
        case .patternWeld: return 0.92
        case .meteoric: return 0.68
        }
    }

    /// Damage taken when struck below the forging window.
    var coldPenalty: Double {
        switch self {
        case .mildSteel: return 0.045
        case .wroughtIron: return 0.085
        case .highCarbon: return 0.130
        case .springSteel: return 0.110
        case .patternWeld: return 0.120
        case .meteoric: return 0.145
        }
    }

    /// Heat lost per second in still air, scaled by section.
    var coolRate: Double {
        switch self {
        case .mildSteel: return 1.00
        case .wroughtIron: return 0.95
        case .highCarbon: return 1.05
        case .springSteel: return 1.10
        case .patternWeld: return 1.02
        case .meteoric: return 0.88
        }
    }

    /// How much the finished piece is worth, and how much XP it returns.
    var valueFactor: Double {
        switch self {
        case .mildSteel: return 1.0
        case .wroughtIron: return 1.25
        case .highCarbon: return 1.5
        case .springSteel: return 1.7
        case .patternWeld: return 2.1
        case .meteoric: return 2.6
        }
    }

    /// Rank index at which the stock becomes available.
    var unlockRank: Int {
        switch self {
        case .mildSteel: return 0
        case .wroughtIron: return 1
        case .highCarbon: return 2
        case .springSteel: return 3
        case .patternWeld: return 4
        case .meteoric: return 5
        }
    }

    var barTint: Color {
        switch self {
        case .mildSteel: return Color(red: 0.463, green: 0.451, blue: 0.435)
        case .wroughtIron: return Color(red: 0.435, green: 0.400, blue: 0.361)
        case .highCarbon: return Color(red: 0.400, green: 0.396, blue: 0.404)
        case .springSteel: return Color(red: 0.365, green: 0.376, blue: 0.400)
        case .patternWeld: return Color(red: 0.451, green: 0.427, blue: 0.396)
        case .meteoric: return Color(red: 0.400, green: 0.416, blue: 0.443)
        }
    }

    /// Pattern-welded and meteoric stock shows a visible grain on the finished piece.
    var hasPattern: Bool { self == .patternWeld || self == .meteoric }
}

// MARK: - Tools

enum ForgeTool: String, Codable, CaseIterable, Identifiable {
    case hammer
    case crossPeen
    case fuller
    case punch
    case bendFork
    case twistWrench

    var id: String { rawValue }

    var name: String {
        switch self {
        case .hammer: return "Flat Hammer"
        case .crossPeen: return "Cross Peen"
        case .fuller: return "Fuller"
        case .punch: return "Punch"
        case .bendFork: return "Bending Fork"
        case .twistWrench: return "Twisting Wrench"
        }
    }

    var short: String {
        switch self {
        case .hammer: return "Flat"
        case .crossPeen: return "Peen"
        case .fuller: return "Fuller"
        case .punch: return "Punch"
        case .bendFork: return "Bend"
        case .twistWrench: return "Twist"
        }
    }

    var hint: String {
        switch self {
        case .hammer: return "Flattens where you strike and spreads the metal in every direction."
        case .crossPeen: return "Drives the metal lengthwise. This is how a bar is drawn out long and thin."
        case .fuller: return "Sinks a narrow groove and isolates a shoulder without moving the neighbours."
        case .punch: return "Drifts a hole straight through. Needs a bright heat and a steady hand."
        case .bendFork: return "Levers a bend into the bar. Cold bends crack; hot bends flow."
        case .twistWrench: return "Grips the bar and twists a length of it into a rope of square corners."
        }
    }

    /// Ranks required before the tool appears on the rack.
    var unlockRank: Int {
        switch self {
        case .hammer, .crossPeen, .bendFork: return 0
        case .punch, .fuller: return 1
        case .twistWrench: return 2
        }
    }
}

// MARK: - Quenchants and tempering

enum Quenchant: String, Codable, CaseIterable, Identifiable {
    case air, oil, water, brine

    var id: String { rawValue }

    var name: String {
        switch self {
        case .air: return "Still Air"
        case .oil: return "Oil"
        case .water: return "Water"
        case .brine: return "Brine"
        }
    }

    /// How fast the piece is pulled down through the hardening range.
    var severity: Double {
        switch self {
        case .air: return 0.15
        case .oil: return 0.55
        case .water: return 0.85
        case .brine: return 1.00
        }
    }

    var note: String {
        switch self {
        case .air: return "Barely hardens anything, but nothing ever cracks."
        case .oil: return "Slow and kind. The usual answer for high carbon and spring steel."
        case .water: return "Fast and dangerous. Full hardness, and a real chance of a crack."
        case .brine: return "The fastest quench in the shop. Only mild steel shrugs this off."
        }
    }
}

/// Oxide colours a polished piece runs through while it is tempered.
enum TemperColor: String, Codable, CaseIterable, Identifiable {
    case straw, bronze, purple, blue, grey

    var id: String { rawValue }

    var name: String {
        switch self {
        case .straw: return "Pale Straw"
        case .bronze: return "Bronze"
        case .purple: return "Purple"
        case .blue: return "Dark Blue"
        case .grey: return "Overrun Grey"
        }
    }

    var celsius: String {
        switch self {
        case .straw: return "205 °C"
        case .bronze: return "245 °C"
        case .purple: return "275 °C"
        case .blue: return "300 °C"
        case .grey: return "over 340 °C"
        }
    }

    var use: String {
        switch self {
        case .straw: return "Hard and brittle. Right for a scribe, a punch or a chisel edge."
        case .bronze: return "A working edge with some give. Knives and shears live here."
        case .purple: return "Tough over hard. Axes, hardy tools and anything that takes a shock."
        case .blue: return "Springy. Correct for a spring, a pin or a light hook."
        case .grey: return "You went past the useful range. The piece is soft again."
        }
    }

    var swatch: Color {
        switch self {
        case .straw: return Color(red: 0.851, green: 0.729, blue: 0.416)
        case .bronze: return Color(red: 0.714, green: 0.478, blue: 0.259)
        case .purple: return Color(red: 0.514, green: 0.404, blue: 0.573)
        case .blue: return Color(red: 0.310, green: 0.404, blue: 0.596)
        case .grey: return Color(red: 0.522, green: 0.522, blue: 0.514)
        }
    }
}

// MARK: - Target shape description

struct ProfileKey {
    let pos: Double        // 0…1 along the bar
    let thickness: Double  // mm
    let width: Double      // mm
}

enum FeatureKind: String, Codable {
    case bend, twist, hole, taper

    var name: String {
        switch self {
        case .bend: return "Bend"
        case .twist: return "Twist"
        case .hole: return "Punched Hole"
        case .taper: return "Taper"
        }
    }
}

struct FeatureSpec {
    let kind: FeatureKind
    let at: Double       // 0…1 along the bar
    let amount: Double   // degrees for bend/twist, unused otherwise
}

// MARK: - Projects

enum Chapter: String, Codable, CaseIterable, Identifiable {
    case firstHeats, tools, hearth, ornament, masterworks

    var id: String { rawValue }

    var name: String {
        switch self {
        case .firstHeats: return "First Heats"
        case .tools: return "Tools of the Trade"
        case .hearth: return "Hearth and Home"
        case .ornament: return "Ornament"
        case .masterworks: return "Masterworks"
        }
    }

    var blurb: String {
        switch self {
        case .firstHeats: return "Nails, hooks and the honest habit of putting the bar back in the fire."
        case .tools: return "The shop makes its own tools. Everything here you will use again."
        case .hearth: return "Ironwork that lives beside a fire and gets handled every day."
        case .ornament: return "Where the bar stops being useful and starts being looked at."
        case .masterworks: return "Long pieces, tight tolerances, and no second heats to waste."
        }
    }

    var art: String {
        switch self {
        case .firstHeats: return "chapter_first"
        case .tools: return "chapter_tools"
        case .hearth: return "chapter_hearth"
        case .ornament: return "chapter_ornament"
        case .masterworks: return "chapter_master"
        }
    }

    var index: Int { Chapter.allCases.firstIndex(of: self) ?? 0 }
}

/// Where a finished piece takes up residence in the smithy scene.
enum ShopSpot: String, Codable {
    case wallRack, toolRack, doorFrame, benchTop, hearthSide, ceilingHook, shelf, floor
}

struct ForgeProject: Identifiable {
    let id: String
    let name: String
    let chapter: Chapter
    let order: Int
    let stock: Metal            // the stock the commission is written for
    let barLength: Double       // mm of the starting bar
    let barThickness: Double
    let barWidth: Double
    let keys: [ProfileKey]
    let features: [FeatureSpec]
    let parStrikes: Int
    let heatsAllowed: Int
    let summary: String
    let lore: String
    let spot: ShopSpot
    let needsHardening: Bool
    let idealTemper: TemperColor?
}

// MARK: - Ranks

struct SmithRank {
    let name: String
    let xp: Int
    let unlocks: String
}

// MARK: - Finished work

enum PieceQuality: String, Codable {
    case scrap, serviceable, good, fine, pristine

    var name: String {
        switch self {
        case .scrap: return "Scrap"
        case .serviceable: return "Serviceable"
        case .good: return "Good"
        case .fine: return "Fine"
        case .pristine: return "Pristine"
        }
    }

    var tint: Color {
        switch self {
        case .scrap: return Forge.chalkFaint
        case .serviceable: return Forge.steel
        case .good: return Forge.quench
        case .fine: return Forge.brass
        case .pristine: return Forge.spark
        }
    }
}

struct FinishedPiece: Codable, Identifiable {
    var id: String { projectID + "-" + String(dateKey) }
    let projectID: String
    let metal: Metal
    let stars: Int
    let accuracy: Double
    let integrity: Double
    let quality: PieceQuality
    let temper: TemperColor?
    let hardened: Bool
    let strikes: Int
    let heats: Int
    let dateKey: Int
}

// MARK: - Badges

struct ForgeBadge: Identifiable {
    let id: String
    let name: String
    let detail: String
    let art: String
}

// MARK: - Almanac

struct ForgeGuide: Identifiable {
    let id: String
    let title: String
    let standfirst: String
    let art: String
    let paragraphs: [String]
}

struct GlossaryEntry: Identifiable {
    var id: String { term }
    let term: String
    let meaning: String
}

struct QuizQuestion: Identifiable {
    var id: String { prompt }
    let prompt: String
    let options: [String]
    let answer: Int
    let because: String
}

// MARK: - Daily commission

struct Commission: Codable, Equatable {
    let dateKey: Int
    let projectID: String
    let metal: Metal
    let minStars: Int
    let customer: String
    let request: String
    var delivered: Bool
}

// MARK: - Date helpers

enum DayKey {
    static func key(for date: Date = Date()) -> Int {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return (c.year ?? 2000) * 10_000 + (c.month ?? 1) * 100 + (c.day ?? 1)
    }

    static func date(from key: Int) -> Date {
        var c = DateComponents()
        c.year = key / 10_000
        c.month = (key / 100) % 100
        c.day = key % 100
        return Calendar.current.date(from: c) ?? Date()
    }

    static func label(_ key: Int) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "d MMM yyyy"
        return f.string(from: date(from: key))
    }

    static func daysBetween(_ a: Int, _ b: Int) -> Int {
        let cal = Calendar.current
        let d1 = cal.startOfDay(for: date(from: a))
        let d2 = cal.startOfDay(for: date(from: b))
        return cal.dateComponents([.day], from: d1, to: d2).day ?? 0
    }
}
