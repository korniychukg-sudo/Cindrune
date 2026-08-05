import Foundation

// Everything Cindrune ships as written content: the commission book, the
// ranks, the awards and the almanac.
enum Content {

    // MARK: - Ranks

    static let ranks: [SmithRank] = [
        SmithRank(name: "Striker", xp: 0,
                  unlocks: "Flat hammer, cross peen, bending fork, mild steel"),
        SmithRank(name: "Apprentice", xp: 200,
                  unlocks: "Punch, fuller, wrought iron stock"),
        SmithRank(name: "Improver", xp: 600,
                  unlocks: "Twisting wrench, high carbon steel"),
        SmithRank(name: "Journeyman", xp: 1_200,
                  unlocks: "Spring steel, the Hearth and Home commissions"),
        SmithRank(name: "Smith", xp: 2_000,
                  unlocks: "Pattern-welded billet"),
        SmithRank(name: "Master Smith", xp: 3_100,
                  unlocks: "Meteoric iron, the Masterworks commissions"),
        SmithRank(name: "Shop Master", xp: 4_500,
                  unlocks: "Standing of the shop"),
        SmithRank(name: "Forgewright", xp: 6_200,
                  unlocks: "The top of the trade")
    ]

    static func rankIndex(forXP xp: Int) -> Int {
        var idx = 0
        for (i, r) in ranks.enumerated() where xp >= r.xp { idx = i }
        return idx
    }

    // MARK: - Projects

    private static let firstHeatsBook: [ForgeProject] = [
        // ── First Heats ───────────────────────────────────────────────
        ForgeProject(
            id: "nail", name: "Square Nail", chapter: .firstHeats, order: 0,
            stock: .mildSteel, barLength: 110, barThickness: 9, barWidth: 9,
            keys: [ProfileKey(pos: 0.00, thickness: 8.6, width: 15),
                   ProfileKey(pos: 0.12, thickness: 7.5, width: 8),
                   ProfileKey(pos: 0.60, thickness: 6, width: 6),
                   ProfileKey(pos: 1.00, thickness: 1.6, width: 1.6)],
            features: [FeatureSpec(kind: .taper, at: 0.95, amount: 0)],
            parStrikes: 28, heatsAllowed: 3,
            summary: "A four-sided nail drawn to a clean point under a flat head.",
            lore: "Before wire nails, every nail in a building was made one at a time by a nailer working piece rates. A good hand could turn out a thousand in a day, and the taper you are drawing here is the same one they drew.",
            spot: .benchTop, needsHardening: false, idealTemper: nil),

        ForgeProject(
            id: "shook", name: "S Hook", chapter: .firstHeats, order: 1,
            stock: .mildSteel, barLength: 140, barThickness: 8, barWidth: 8,
            keys: [ProfileKey(pos: 0.00, thickness: 3.0, width: 5),
                   ProfileKey(pos: 0.18, thickness: 6.5, width: 7),
                   ProfileKey(pos: 0.82, thickness: 6.5, width: 7),
                   ProfileKey(pos: 1.00, thickness: 3.0, width: 5)],
            features: [FeatureSpec(kind: .bend, at: 0.16, amount: 150),
                       FeatureSpec(kind: .bend, at: 0.84, amount: 150)],
            parStrikes: 40, heatsAllowed: 4,
            summary: "Two tapered ends curled the opposite way. The first thing every shop makes.",
            lore: "An S hook is the smith's handshake. It shows whether you can taper evenly, bend to a matched radius, and finish both ends the same on a single bar.",
            spot: .ceilingHook, needsHardening: false, idealTemper: nil),

        ForgeProject(
            id: "chainlink", name: "Chain Link", chapter: .firstHeats, order: 2,
            stock: .mildSteel, barLength: 120, barThickness: 8, barWidth: 8,
            keys: [ProfileKey(pos: 0.00, thickness: 4.5, width: 6),
                   ProfileKey(pos: 0.50, thickness: 6.0, width: 6.5),
                   ProfileKey(pos: 1.00, thickness: 4.5, width: 6)],
            features: [FeatureSpec(kind: .bend, at: 0.25, amount: 92),
                       FeatureSpec(kind: .bend, at: 0.75, amount: 92)],
            parStrikes: 48, heatsAllowed: 5,
            summary: "A bar scarfed at both ends and bent round until the ends meet.",
            lore: "Chain was sold by the fathom and made link by link, each one bent round the last. The weak point is never the bar — it is the joint, which is why the ends are thinned before they close.",
            spot: .wallRack, needsHardening: false, idealTemper: nil),

        ForgeProject(
            id: "coatpeg", name: "Coat Peg", chapter: .firstHeats, order: 3,
            stock: .mildSteel, barLength: 130, barThickness: 10, barWidth: 10,
            keys: [ProfileKey(pos: 0.00, thickness: 9, width: 14),
                   ProfileKey(pos: 0.22, thickness: 7, width: 10),
                   ProfileKey(pos: 0.78, thickness: 6, width: 8),
                   ProfileKey(pos: 1.00, thickness: 8, width: 12)],
            features: [FeatureSpec(kind: .hole, at: 0.06, amount: 0),
                       FeatureSpec(kind: .bend, at: 0.30, amount: 88)],
            parStrikes: 28, heatsAllowed: 4,
            summary: "A flat plate for the wall, a right-angle bend, and a swelled end that keeps a coat on.",
            lore: "The flare at the tip is not decoration. Upsetting the end into a small ball is what stops a heavy coat sliding off in the night.",
            spot: .wallRack, needsHardening: false, idealTemper: nil),

        ForgeProject(
            id: "leaffob", name: "Leaf Key Fob", chapter: .firstHeats, order: 4,
            stock: .mildSteel, barLength: 100, barThickness: 8, barWidth: 8,
            keys: [ProfileKey(pos: 0.00, thickness: 5, width: 5),
                   ProfileKey(pos: 0.35, thickness: 3.4, width: 4),
                   ProfileKey(pos: 0.55, thickness: 2.2, width: 16),
                   ProfileKey(pos: 0.80, thickness: 1.8, width: 19),
                   ProfileKey(pos: 1.00, thickness: 1.4, width: 6)],
            features: [FeatureSpec(kind: .hole, at: 0.04, amount: 0)],
            parStrikes: 52, heatsAllowed: 5,
            summary: "A stem drawn thin, then the end spread wide and flat into a leaf.",
            lore: "Spreading a leaf teaches the difference between the flat face and the peen. The face makes it thin; only the peen makes it wide in the direction you want.",
            spot: .shelf, needsHardening: false, idealTemper: nil)
    ]

    private static let toolsBook: [ForgeProject] = [
        // ── Tools of the Trade ────────────────────────────────────────
        ForgeProject(
            id: "centerpunch", name: "Center Punch", chapter: .tools, order: 0,
            stock: .highCarbon, barLength: 120, barThickness: 11, barWidth: 11,
            keys: [ProfileKey(pos: 0.00, thickness: 10, width: 10),
                   ProfileKey(pos: 0.55, thickness: 9.5, width: 9.5),
                   ProfileKey(pos: 0.85, thickness: 5, width: 5),
                   ProfileKey(pos: 1.00, thickness: 1.5, width: 1.5)],
            features: [FeatureSpec(kind: .taper, at: 0.96, amount: 0)],
            parStrikes: 28, heatsAllowed: 4,
            summary: "A stout body with a short, sharp taper. Hardened, then drawn to straw.",
            lore: "A punch takes hammer blows on one end and gives them to steel on the other. Too soft and the point folds; too hard and it shatters. Straw is the compromise every shop settles on.",
            spot: .toolRack, needsHardening: true, idealTemper: .straw),

        ForgeProject(
            id: "coldchisel", name: "Cold Chisel", chapter: .tools, order: 1,
            stock: .highCarbon, barLength: 130, barThickness: 12, barWidth: 12,
            keys: [ProfileKey(pos: 0.00, thickness: 11, width: 11),
                   ProfileKey(pos: 0.60, thickness: 10, width: 11),
                   ProfileKey(pos: 0.88, thickness: 4, width: 15),
                   ProfileKey(pos: 1.00, thickness: 1.2, width: 17)],
            features: [FeatureSpec(kind: .taper, at: 0.95, amount: 0)],
            parStrikes: 32, heatsAllowed: 4,
            summary: "The body stays square; the last part flares into a wide, thin cutting edge.",
            lore: "A chisel edge is ground to sixty degrees for cold steel and thirty for hot. Get the forging right and the grinder only has to tidy up.",
            spot: .toolRack, needsHardening: true, idealTemper: .bronze),

        ForgeProject(
            id: "drift", name: "Drift Punch", chapter: .tools, order: 2,
            stock: .springSteel, barLength: 150, barThickness: 12, barWidth: 12,
            keys: [ProfileKey(pos: 0.00, thickness: 8, width: 8),
                   ProfileKey(pos: 0.30, thickness: 11.4, width: 12),
                   ProfileKey(pos: 0.55, thickness: 11.8, width: 13),
                   ProfileKey(pos: 0.80, thickness: 9, width: 9),
                   ProfileKey(pos: 1.00, thickness: 5, width: 5)],
            features: [FeatureSpec(kind: .taper, at: 0.92, amount: 0)],
            parStrikes: 30, heatsAllowed: 5,
            summary: "Fat in the middle, tapered at both ends. It opens a punched hole to size.",
            lore: "A punch makes the hole; a drift decides its shape. Drive the drift through from both sides and the hole comes out straight instead of trumpeted.",
            spot: .toolRack, needsHardening: true, idealTemper: .purple),

        ForgeProject(
            id: "scribe", name: "Scribe Point", chapter: .tools, order: 3,
            stock: .highCarbon, barLength: 110, barThickness: 8, barWidth: 8,
            keys: [ProfileKey(pos: 0.00, thickness: 6, width: 6),
                   ProfileKey(pos: 0.30, thickness: 6, width: 6),
                   ProfileKey(pos: 0.70, thickness: 4, width: 4),
                   ProfileKey(pos: 1.00, thickness: 0.9, width: 0.9)],
            features: [FeatureSpec(kind: .twist, at: 0.35, amount: 1),
                       FeatureSpec(kind: .taper, at: 0.97, amount: 0)],
            parStrikes: 52, heatsAllowed: 5,
            summary: "A long fine needle with a twisted grip so it cannot roll off the bench.",
            lore: "The twist is not ornament here. A round scribe rolls; a twisted one stays where you put it, and your thumb always knows which way it is pointing.",
            spot: .toolRack, needsHardening: true, idealTemper: .straw),

        ForgeProject(
            id: "hammerhead", name: "Hammer Head", chapter: .tools, order: 4,
            stock: .springSteel, barLength: 130, barThickness: 20, barWidth: 20,
            keys: [ProfileKey(pos: 0.00, thickness: 19.6, width: 22),
                   ProfileKey(pos: 0.35, thickness: 18.5, width: 19),
                   ProfileKey(pos: 0.62, thickness: 17, width: 17),
                   ProfileKey(pos: 0.86, thickness: 10, width: 20),
                   ProfileKey(pos: 1.00, thickness: 5, width: 22)],
            features: [FeatureSpec(kind: .hole, at: 0.42, amount: 0)],
            parStrikes: 32, heatsAllowed: 6,
            summary: "A flat face at one end, a cross peen at the other, and an eye punched through the middle.",
            lore: "Making your own hammer is the old test of a finished apprentice. The eye must be punched and drifted, never drilled, so the grain flows round it instead of being cut through.",
            spot: .toolRack, needsHardening: true, idealTemper: .purple)
    ]

    private static let hearthBook: [ForgeProject] = [
        // ── Hearth and Home ───────────────────────────────────────────
        ForgeProject(
            id: "poker", name: "Fire Poker", chapter: .hearth, order: 0,
            stock: .wroughtIron, barLength: 200, barThickness: 11, barWidth: 11,
            keys: [ProfileKey(pos: 0.00, thickness: 4, width: 8),
                   ProfileKey(pos: 0.10, thickness: 8, width: 8),
                   ProfileKey(pos: 0.45, thickness: 7.5, width: 7.5),
                   ProfileKey(pos: 0.86, thickness: 5, width: 5),
                   ProfileKey(pos: 1.00, thickness: 2.0, width: 2.0)],
            features: [FeatureSpec(kind: .bend, at: 0.06, amount: 300),
                       FeatureSpec(kind: .twist, at: 0.30, amount: 1),
                       FeatureSpec(kind: .taper, at: 0.96, amount: 0)],
            parStrikes: 72, heatsAllowed: 7,
            summary: "A long bar with a scrolled handle, a twisted shaft and a hooked point.",
            lore: "Every fireside set starts with a poker, and every poker is really a lesson in keeping a long bar straight while you work only one end of it at a time.",
            spot: .hearthSide, needsHardening: false, idealTemper: nil),

        ForgeProject(
            id: "pothook", name: "Pot Hook", chapter: .hearth, order: 1,
            stock: .wroughtIron, barLength: 170, barThickness: 10, barWidth: 10,
            keys: [ProfileKey(pos: 0.00, thickness: 3.5, width: 9),
                   ProfileKey(pos: 0.16, thickness: 7, width: 8),
                   ProfileKey(pos: 0.70, thickness: 7, width: 8),
                   ProfileKey(pos: 0.90, thickness: 5, width: 6),
                   ProfileKey(pos: 1.00, thickness: 2.4, width: 3.5)],
            features: [FeatureSpec(kind: .hole, at: 0.05, amount: 0),
                       FeatureSpec(kind: .bend, at: 0.88, amount: 190)],
            parStrikes: 50, heatsAllowed: 5,
            summary: "Flat and punched at the top, a long shank, then a deep hook that will not let go.",
            lore: "A cooking hook has to hold a full iron pot over open coals for hours. The hook is closed further than looks necessary, because the one that opens is the one that scalds somebody.",
            spot: .hearthSide, needsHardening: false, idealTemper: nil),

        ForgeProject(
            id: "toastfork", name: "Toasting Fork", chapter: .hearth, order: 2,
            stock: .mildSteel, barLength: 190, barThickness: 9, barWidth: 9,
            keys: [ProfileKey(pos: 0.00, thickness: 3.0, width: 12),
                   ProfileKey(pos: 0.14, thickness: 5, width: 6),
                   ProfileKey(pos: 0.62, thickness: 5, width: 6),
                   ProfileKey(pos: 0.88, thickness: 3.4, width: 10),
                   ProfileKey(pos: 1.00, thickness: 2.0, width: 12)],
            features: [FeatureSpec(kind: .twist, at: 0.40, amount: 1),
                       FeatureSpec(kind: .bend, at: 0.10, amount: 200)],
            parStrikes: 60, heatsAllowed: 6,
            summary: "A curled handle, a twisted middle and a flattened, split end for the tines.",
            lore: "The twist does real work on a long-handled fireside tool: it stiffens a thin bar against bending, which is why it turns up on everything that has to reach into a fire.",
            spot: .hearthSide, needsHardening: false, idealTemper: nil),

        ForgeProject(
            id: "ashrake", name: "Ash Rake", chapter: .hearth, order: 3,
            stock: .wroughtIron, barLength: 200, barThickness: 12, barWidth: 12,
            keys: [ProfileKey(pos: 0.00, thickness: 4, width: 9),
                   ProfileKey(pos: 0.12, thickness: 8, width: 8),
                   ProfileKey(pos: 0.72, thickness: 7, width: 7),
                   ProfileKey(pos: 0.90, thickness: 3.2, width: 24),
                   ProfileKey(pos: 1.00, thickness: 2.6, width: 30)],
            features: [FeatureSpec(kind: .bend, at: 0.88, amount: 84),
                       FeatureSpec(kind: .bend, at: 0.06, amount: 260)],
            parStrikes: 54, heatsAllowed: 6,
            summary: "A wide flat blade turned at right angles to a long twisted shaft.",
            lore: "Raking a forge out at the end of a day is the last job before the doors close. The blade is set at an angle so the ash comes toward you instead of piling against the fire pot.",
            spot: .hearthSide, needsHardening: false, idealTemper: nil),

        ForgeProject(
            id: "trivetarm", name: "Trivet Arm", chapter: .hearth, order: 4,
            stock: .mildSteel, barLength: 165, barThickness: 11, barWidth: 11,
            keys: [ProfileKey(pos: 0.00, thickness: 3.2, width: 18),
                   ProfileKey(pos: 0.20, thickness: 6, width: 9),
                   ProfileKey(pos: 0.55, thickness: 6, width: 9),
                   ProfileKey(pos: 0.80, thickness: 5, width: 8),
                   ProfileKey(pos: 1.00, thickness: 3.0, width: 14)],
            features: [FeatureSpec(kind: .hole, at: 0.06, amount: 0),
                       FeatureSpec(kind: .bend, at: 0.72, amount: 120),
                       FeatureSpec(kind: .twist, at: 0.38, amount: 1)],
            parStrikes: 50, heatsAllowed: 5,
            summary: "One of three matching legs: a riveted pad, a twisted stem and a footed curl.",
            lore: "Trivets are made in threes and they must match, which is why smiths make a template out of soft wire before the first one goes in the fire.",
            spot: .floor, needsHardening: false, idealTemper: nil)
    ]

    private static let ornamentBook: [ForgeProject] = [
        // ── Ornament ──────────────────────────────────────────────────
        ForgeProject(
            id: "candlespike", name: "Candle Spike", chapter: .ornament, order: 0,
            stock: .wroughtIron, barLength: 150, barThickness: 12, barWidth: 12,
            keys: [ProfileKey(pos: 0.00, thickness: 3.0, width: 26),
                   ProfileKey(pos: 0.18, thickness: 9, width: 10),
                   ProfileKey(pos: 0.58, thickness: 8, width: 8),
                   ProfileKey(pos: 0.84, thickness: 5, width: 5),
                   ProfileKey(pos: 1.00, thickness: 1.6, width: 1.6)],
            features: [FeatureSpec(kind: .twist, at: 0.42, amount: 1),
                       FeatureSpec(kind: .taper, at: 0.96, amount: 0)],
            parStrikes: 42, heatsAllowed: 5,
            summary: "A dished base, a twisted column and a spike sharp enough to take a candle.",
            lore: "A pricket holds a candle on a spike instead of in a socket, which is older and far less fussy about what size candle you have.",
            spot: .shelf, needsHardening: false, idealTemper: nil),

        ForgeProject(
            id: "cloakpin", name: "Cloak Pin", chapter: .ornament, order: 1,
            stock: .highCarbon, barLength: 130, barThickness: 6, barWidth: 6,
            keys: [ProfileKey(pos: 0.00, thickness: 2.0, width: 20),
                   ProfileKey(pos: 0.20, thickness: 4, width: 6),
                   ProfileKey(pos: 0.60, thickness: 3.4, width: 4),
                   ProfileKey(pos: 1.00, thickness: 1.1, width: 1.1)],
            features: [FeatureSpec(kind: .bend, at: 0.14, amount: 320),
                       FeatureSpec(kind: .taper, at: 0.97, amount: 0)],
            parStrikes: 56, heatsAllowed: 5,
            summary: "A spread and scrolled head over a long springy needle.",
            lore: "The Vikings closed a cloak with a pin like this and no clasp at all — pass it through the cloth twice and the tension of the wool does the rest.",
            spot: .shelf, needsHardening: true, idealTemper: .blue),

        ForgeProject(
            id: "doorring", name: "Door Ring", chapter: .ornament, order: 2,
            stock: .wroughtIron, barLength: 210, barThickness: 12, barWidth: 12,
            keys: [ProfileKey(pos: 0.00, thickness: 4, width: 8),
                   ProfileKey(pos: 0.14, thickness: 8, width: 9),
                   ProfileKey(pos: 0.50, thickness: 9, width: 10),
                   ProfileKey(pos: 0.86, thickness: 8, width: 9),
                   ProfileKey(pos: 1.00, thickness: 4, width: 8)],
            features: [FeatureSpec(kind: .bend, at: 0.25, amount: 130),
                       FeatureSpec(kind: .bend, at: 0.50, amount: 130),
                       FeatureSpec(kind: .bend, at: 0.75, amount: 130)],
            parStrikes: 54, heatsAllowed: 6,
            summary: "A heavy bar bent into a true circle with the ends scarfed to meet.",
            lore: "A knocker ring rings because it is loose in its boss. Weld it shut too tight and the door goes silent, which rather defeats the point.",
            spot: .doorFrame, needsHardening: false, idealTemper: nil),

        ForgeProject(
            id: "scrollbracket", name: "Scroll Bracket", chapter: .ornament, order: 3,
            stock: .patternWeld, barLength: 220, barThickness: 10, barWidth: 14,
            keys: [ProfileKey(pos: 0.00, thickness: 3.0, width: 18),
                   ProfileKey(pos: 0.22, thickness: 6, width: 12),
                   ProfileKey(pos: 0.55, thickness: 6, width: 12),
                   ProfileKey(pos: 0.82, thickness: 4, width: 9),
                   ProfileKey(pos: 1.00, thickness: 1.8, width: 5)],
            features: [FeatureSpec(kind: .hole, at: 0.05, amount: 0),
                       FeatureSpec(kind: .bend, at: 0.60, amount: 96),
                       FeatureSpec(kind: .bend, at: 0.92, amount: 280)],
            parStrikes: 62, heatsAllowed: 7,
            summary: "A wall plate, a right-angle arm and a long tapered scroll rolled at the end.",
            lore: "A scroll is judged by whether the curve tightens smoothly. Any flat spot in it, and the eye finds the mistake from across a room.",
            spot: .wallRack, needsHardening: false, idealTemper: nil),

        ForgeProject(
            id: "lanternbracket", name: "Lantern Bracket", chapter: .ornament, order: 4,
            stock: .patternWeld, barLength: 230, barThickness: 11, barWidth: 15,
            keys: [ProfileKey(pos: 0.00, thickness: 3.2, width: 22),
                   ProfileKey(pos: 0.20, thickness: 7, width: 13),
                   ProfileKey(pos: 0.60, thickness: 6.5, width: 12),
                   ProfileKey(pos: 0.88, thickness: 4.5, width: 8),
                   ProfileKey(pos: 1.00, thickness: 2.2, width: 4)],
            features: [FeatureSpec(kind: .hole, at: 0.06, amount: 0),
                       FeatureSpec(kind: .twist, at: 0.40, amount: 1),
                       FeatureSpec(kind: .bend, at: 0.70, amount: 100),
                       FeatureSpec(kind: .bend, at: 0.94, amount: 240)],
            parStrikes: 66, heatsAllowed: 7,
            summary: "The full ornamental vocabulary in one bar: plate, twist, arm and hanging curl.",
            lore: "Hang a lantern from this and the whole shop changes at dusk. It is also the first piece where you will be judged on symmetry rather than strength.",
            spot: .doorFrame, needsHardening: false, idealTemper: nil)
    ]

    private static let masterworksBook: [ForgeProject] = [
        // ── Masterworks ───────────────────────────────────────────────
        ForgeProject(
            id: "axehead", name: "Hand Axe Head", chapter: .masterworks, order: 0,
            stock: .springSteel, barLength: 150, barThickness: 22, barWidth: 20,
            keys: [ProfileKey(pos: 0.00, thickness: 14, width: 16),
                   ProfileKey(pos: 0.28, thickness: 18, width: 22),
                   ProfileKey(pos: 0.52, thickness: 15, width: 24),
                   ProfileKey(pos: 0.82, thickness: 6, width: 34),
                   ProfileKey(pos: 1.00, thickness: 1.4, width: 40)],
            features: [FeatureSpec(kind: .hole, at: 0.30, amount: 0),
                       FeatureSpec(kind: .taper, at: 0.94, amount: 0)],
            parStrikes: 60, heatsAllowed: 8,
            summary: "A drifted eye, a heavy poll and a bit fanned out wide and thin.",
            lore: "An axe is a wedge with a hole in it. Everything difficult about forging one comes from having to open that hole without wrecking the bit you already shaped.",
            spot: .wallRack, needsHardening: true, idealTemper: .purple),

        ForgeProject(
            id: "drawknife", name: "Draw Knife", chapter: .masterworks, order: 1,
            stock: .highCarbon, barLength: 240, barThickness: 13, barWidth: 16,
            keys: [ProfileKey(pos: 0.00, thickness: 6, width: 6),
                   ProfileKey(pos: 0.14, thickness: 8, width: 9),
                   ProfileKey(pos: 0.30, thickness: 5, width: 24),
                   ProfileKey(pos: 0.70, thickness: 4, width: 26),
                   ProfileKey(pos: 0.86, thickness: 8, width: 9),
                   ProfileKey(pos: 1.00, thickness: 6, width: 6)],
            features: [FeatureSpec(kind: .bend, at: 0.16, amount: 96),
                       FeatureSpec(kind: .bend, at: 0.84, amount: 96)],
            parStrikes: 60, heatsAllowed: 8,
            summary: "Two tangs bent forward, a long even blade between them, thin along the whole edge.",
            lore: "The hard part is not the blade. It is getting both tangs bent to the same angle so the tool pulls straight instead of wandering across the work.",
            spot: .toolRack, needsHardening: true, idealTemper: .bronze),

        ForgeProject(
            id: "vanearrow", name: "Weather Vane Arrow", chapter: .masterworks, order: 2,
            stock: .patternWeld, barLength: 260, barThickness: 10, barWidth: 11,
            keys: [ProfileKey(pos: 0.00, thickness: 2.4, width: 30),
                   ProfileKey(pos: 0.18, thickness: 5, width: 10),
                   ProfileKey(pos: 0.55, thickness: 5, width: 9),
                   ProfileKey(pos: 0.78, thickness: 4, width: 7),
                   ProfileKey(pos: 0.92, thickness: 3, width: 20),
                   ProfileKey(pos: 1.00, thickness: 1.5, width: 3)],
            features: [FeatureSpec(kind: .hole, at: 0.50, amount: 0),
                       FeatureSpec(kind: .twist, at: 0.35, amount: 1),
                       FeatureSpec(kind: .taper, at: 0.98, amount: 0)],
            parStrikes: 60, heatsAllowed: 9,
            summary: "A fletched tail, a long balanced shaft with a pivot hole, and a spear point.",
            lore: "A vane has to balance on its pivot or it will point at the ground forever. The hole goes exactly where the finished arrow balances on your finger, not where the drawing guesses.",
            spot: .ceilingHook, needsHardening: false, idealTemper: nil),

        ForgeProject(
            id: "letteropener", name: "Sky Iron Blade", chapter: .masterworks, order: 3,
            stock: .meteoric, barLength: 200, barThickness: 11, barWidth: 13,
            keys: [ProfileKey(pos: 0.00, thickness: 8, width: 8),
                   ProfileKey(pos: 0.22, thickness: 7, width: 9),
                   ProfileKey(pos: 0.34, thickness: 9, width: 16),
                   ProfileKey(pos: 0.46, thickness: 4.5, width: 22),
                   ProfileKey(pos: 0.82, thickness: 3.0, width: 19),
                   ProfileKey(pos: 1.00, thickness: 1.0, width: 4)],
            features: [FeatureSpec(kind: .twist, at: 0.12, amount: 1),
                       FeatureSpec(kind: .taper, at: 0.96, amount: 0)],
            parStrikes: 72, heatsAllowed: 9,
            summary: "Nickel iron from a fallen stone: twisted grip, raised bolster, long slender blade.",
            lore: "Meteoric iron carries a crystal pattern that took millions of years to grow while the core of a shattered planet cooled. Overheat it once and the pattern is gone forever.",
            spot: .shelf, needsHardening: true, idealTemper: .bronze)
    ]

    // Five smaller literals instead of one: a single 24-element array of
    // nested struct literals takes the Release optimiser many minutes.
    static let projects: [ForgeProject] =
        firstHeatsBook + toolsBook + hearthBook + ornamentBook + masterworksBook

    static func project(_ id: String) -> ForgeProject? { projects.first { $0.id == id } }

    static func projects(in chapter: Chapter) -> [ForgeProject] {
        projects.filter { $0.chapter == chapter }.sorted { $0.order < $1.order }
    }

    /// The rank a chapter opens at.
    static func requiredRank(for chapter: Chapter) -> Int {
        switch chapter {
        case .firstHeats: return 0
        case .tools: return 1
        case .hearth: return 3
        case .ornament: return 4
        case .masterworks: return 5
        }
    }

    // MARK: - Commission customers

    static let customers: [(name: String, ask: String)] = [
        ("Marek the Carter", "A cart came in with a broken fitting and the road will not wait."),
        ("The Miller's Wife", "The mill needs it before the grain arrives on Thursday."),
        ("Old Bess", "She will pay in bread, and her bread is worth more than the coin."),
        ("The Chandler", "Wax is cheap this month and she wants somewhere to put it."),
        ("Tam the Roofer", "He is not fussy about finish but he is very fussy about strength."),
        ("Sister Ellen", "For the chapel door, and she will notice every hammer mark."),
        ("The Ferryman", "Salt water eats everything he owns. Make it heavy."),
        ("Jorund the Drover", "Two hundred head of cattle and one broken gate."),
        ("The Schoolmaster", "He wants it neat more than he wants it soon."),
        ("Widow Ansley", "She brought the stock herself, wrapped in a cloth."),
        ("The Wheelwright", "He can make anything from wood and nothing from iron."),
        ("Cass the Fisher", "The boats go out at dawn whatever you have finished."),
        ("The Innkeeper", "Something for the yard that will survive a winter."),
        ("Bran the Forester", "He wears through tools faster than anyone in the valley.")
    ]

    // MARK: - Badges

    private static let badgesPart1: [ForgeBadge] = [
        ForgeBadge(id: "first_heat", name: "First Heat", detail: "Bring a bar up to forging colour.", art: "badge_first_heat"),
        ForgeBadge(id: "first_piece", name: "Off the Anvil", detail: "Finish your first commission.", art: "badge_first_piece"),
        ForgeBadge(id: "three_star", name: "Clean Work", detail: "Earn three stars on any piece.", art: "badge_three_star"),
        ForgeBadge(id: "pristine", name: "Not a Mark", detail: "Finish a piece at pristine quality.", art: "badge_pristine"),
        ForgeBadge(id: "chapter_first", name: "Past the Nails", detail: "Complete every First Heats commission.", art: "badge_chapter_first"),
        ForgeBadge(id: "chapter_tools", name: "Own Tools", detail: "Complete every Tools of the Trade commission.", art: "badge_chapter_tools"),
        ForgeBadge(id: "chapter_hearth", name: "Fireside Set", detail: "Complete every Hearth and Home commission.", art: "badge_chapter_hearth")
    ]

    private static let badgesPart2: [ForgeBadge] = [
        ForgeBadge(id: "chapter_ornament", name: "Worth Looking At", detail: "Complete every Ornament commission.", art: "badge_chapter_ornament"),
        ForgeBadge(id: "chapter_master", name: "Masterwork", detail: "Complete every Masterworks commission.", art: "badge_chapter_master"),
        ForgeBadge(id: "hardened", name: "Hard and Sharp", detail: "Harden and temper a piece to the colour it asked for.", art: "badge_hardened"),
        ForgeBadge(id: "no_crack", name: "Never Cold", detail: "Finish a commission without a single cold blow.", art: "badge_no_crack"),
        ForgeBadge(id: "under_par", name: "Economy of Blows", detail: "Finish a commission under its par strikes.", art: "badge_under_par"),
        ForgeBadge(id: "one_heat", name: "One Heat Wonder", detail: "Finish a commission in a single heat.", art: "badge_one_heat"),
        ForgeBadge(id: "twenty", name: "Twenty Pieces", detail: "Finish twenty pieces of any quality.", art: "badge_twenty")
    ]

    private static let badgesPart3: [ForgeBadge] = [
        ForgeBadge(id: "streak_3", name: "Three Days at the Fire", detail: "Forge on three days in a row.", art: "badge_streak_3"),
        ForgeBadge(id: "streak_7", name: "A Week of Smoke", detail: "Forge on seven days in a row.", art: "badge_streak_7"),
        ForgeBadge(id: "commissions_10", name: "Good for the Trade", detail: "Deliver ten daily commissions.", art: "badge_commissions"),
        ForgeBadge(id: "all_metals", name: "Every Stock", detail: "Forge a piece from all six metals.", art: "badge_all_metals"),
        ForgeBadge(id: "almanac", name: "Read the Book", detail: "Open every guide in the almanac.", art: "badge_almanac"),
        ForgeBadge(id: "quiz_perfect", name: "Knows the Trade", detail: "Answer all ten quiz questions correctly.", art: "badge_quiz")
    ]

    // Split into chunks: one huge array literal makes the Release
    // optimiser crawl through SIL for many minutes.
    static let badges: [ForgeBadge] =
        badgesPart1 + badgesPart2 + badgesPart3


    // MARK: - Almanac

    private static let guidesPart1: [ForgeGuide] = [
        ForgeGuide(id: "heat", title: "Reading the Heat",
                   standfirst: "The bar tells you its temperature. You only have to learn the language.",
                   art: "guide_heat",
                   paragraphs: [
                    "Steel glows because it is hot, and the colour of that glow maps almost exactly onto temperature. Below about 480 °C it looks like cold grey iron in daylight and gives nothing away. Somewhere around 520 °C the first faint red appears, and from there the colour climbs steadily: dull red, cherry, orange, light orange, yellow, and finally a white that throws sparks.",
                    "Most forging happens between a bright cherry and a light yellow. Below that the metal stops flowing and starts fracturing under the hammer; above it, carbon burns out of the surface and the bar begins to crumble at the edges.",
                    "This is why smiths work in dim shops. In bright sunlight a cherry red and a black heat look the same, and by the time you can see the colour clearly you have already cracked the bar. Turn the lights down and the whole scale opens up.",
                    "The practical rule is simple and does not change with the centuries: put it back in the fire earlier than you think you need to. A wasted heat costs you a minute. A cold-worked crack costs you the piece."
                   ]),
        ForgeGuide(id: "carbon", title: "Carbon Makes the Steel",
                   standfirst: "The difference between a nail and a chisel is a fraction of one per cent.",
                   art: "guide_carbon",
                   paragraphs: [
                    "Iron on its own is soft and will not harden. Add carbon and everything changes. Under about 0.25 per cent carbon you have mild steel: bendable, weldable, cheap, and effectively impossible to harden by quenching. Above roughly 0.4 per cent you can quench it hard.",
                    "Tool steels sit between 0.6 and 1.2 per cent. That carbon lets the steel lock into a hard structure when it is cooled quickly, which is what makes an edge possible — and what makes the steel brittle enough to need tempering afterwards.",
                    "Wrought iron is the odd one out. It is nearly carbon-free but shot through with fibres of glassy slag left over from the smelting process. Those fibres make it tough, rust-resistant and a joy to forge weld, and they are why old ironwork survives outdoors for centuries.",
                    "You cannot see carbon content. You infer it: from the spark pattern on a grinding wheel, from how the bar behaves under the hammer, and above all from knowing where the stock came from."
                   ]),
        ForgeGuide(id: "drawing", title: "Drawing Out and Upsetting",
                   standfirst: "Metal is not created or destroyed at the anvil. It is only moved.",
                   art: "guide_drawing",
                   paragraphs: [
                    "Drawing out means making a bar longer and thinner. Upsetting means the opposite: making it shorter and fatter. Between them they account for most of what happens in a working day.",
                    "A flat hammer face spreads metal in every direction at once, so a bar struck with it gets both longer and wider. A cross peen — a wedge-shaped face set across the handle — drives the metal mostly one way. Lay the peen across the bar and it lengthens; lay it along the bar and it widens.",
                    "Upsetting is done by striking the end of the bar along its length, usually with the far end resting on the anvil or the floor. Only the hot part upsets, so heating a short section and quenching the rest is how you control where the swelling goes.",
                    "The volume never changes. Any time a section gets thinner, that metal has gone somewhere — usually into length. Watching where it went is the whole skill."
                   ]),
        ForgeGuide(id: "anvil", title: "The Anvil and Its Parts",
                   standfirst: "Every curve on an anvil is there for a reason somebody discovered the hard way.",
                   art: "guide_anvil",
                   paragraphs: [
                    "The flat top is the face, and it is hardened steel. Work is done here and nothing else touches it — cutting on the face is how a good anvil is ruined.",
                    "The tapering horn at one end is for bending curves and drawing round sections. Near the horn there is often a softer step called the table, meant for cutting, exactly so nobody cuts on the face.",
                    "Two holes go through the far end. The square one is the hardy hole, which takes shanked bottom tools — cut-offs, bending forks, swages. The small round one is the pritchel hole, and it is there so a punch can be driven right through the work without hitting solid steel underneath.",
                    "A good anvil rings. That ring is the sound of an unbroken, well-hardened face, and it is also why anvils are traditionally set on a wooden stump rather than concrete: the wood takes the noise out without taking the rebound with it."
                   ])
    ]

    private static let guidesPart2: [ForgeGuide] = [
        ForgeGuide(id: "hammers", title: "Hammers, and Knowing When to Change",
                   standfirst: "A heavy hammer is not a better hammer.",
                   art: "guide_hammers",
                   paragraphs: [
                    "Most work is done with a hammer between 700 g and 1.2 kg. Beyond that the hammer starts working the smith instead of the steel, and accuracy collapses long before strength does.",
                    "The face is very slightly domed and the edges are always radiused. A sharp-edged hammer leaves crescent-shaped marks in the surface that will still be there after an hour of dressing, and worse, they concentrate stress and become cracks.",
                    "The blow itself comes from letting the hammer fall, not from pushing it. Grip near the end of the handle, let the wrist unlock at the bottom of the swing, and the hammer's own mass does the work. A day of correct hammering is tiring; a day of incorrect hammering is an injury.",
                    "Change hammers as the section changes. Heavy for the first rough moving, lighter as you approach the finished dimension, lightest of all for planishing the surface smooth."
                   ]),
        ForgeGuide(id: "fuller", title: "Fullering a Shoulder",
                   standfirst: "How to change section in one place without disturbing the next.",
                   art: "guide_fuller",
                   paragraphs: [
                    "A fuller is a blunt rounded tool used to sink a groove across a bar. It concentrates the blow into a narrow line, so the metal under it moves and the metal on either side largely does not.",
                    "This is the standard way to make a shoulder: fuller a groove where the change of section should be, then draw out everything beyond the groove. The result is a crisp step instead of a vague slope.",
                    "Fullers come in pairs — a top fuller you strike and a bottom fuller in the hardy hole — but a single top fuller against the flat anvil face does most of the work in a small shop.",
                    "The one thing a fuller will not forgive is a cold bar. Because it concentrates force into a small area, the stress under it is enormous, and a bar that would merely resist a flat hammer will split under a fuller."
                   ]),
        ForgeGuide(id: "punching", title: "Punching and Drifting",
                   standfirst: "A hole in forged work is never drilled. It is opened.",
                   art: "guide_punching",
                   paragraphs: [
                    "Drilling cuts through the grain of the metal. Punching pushes the grain aside, so the fibres flow round the hole instead of ending at it. That is why a punched hammer eye survives a lifetime of shock and a drilled one does not.",
                    "The punch is driven about two thirds of the way through from one side, then the work is flipped and the punch driven back from the other. The small slug that falls out should be a neat disc.",
                    "Punching swells the metal around the hole, so the bar gets wider and slightly shorter there. Experienced smiths allow for this before they punch, not after.",
                    "The drift comes next. It is a tapered tool driven through the punched hole to bring it to final size and shape. Both punch and drift are cooled constantly, because a hot tool driven into hot metal simply upsets and sticks."
                   ]),
        ForgeGuide(id: "quench", title: "Air, Oil, Water, Brine",
                   standfirst: "Hardening is a race between the steel and the clock.",
                   art: "guide_quench",
                   paragraphs: [
                    "Hardening works by heating carbon steel above its critical temperature — roughly 760 °C, the point where a magnet stops sticking to it — and then cooling it fast enough to trap the structure that forms up there.",
                    "How fast is fast enough depends entirely on the alloy. Simple high-carbon steel needs water or brine. Oil-hardening tool steels want oil, and quenching them in water will crack them outright. A few air-hardening steels need nothing but still air.",
                    "The faster the quench, the greater the risk. As the outside contracts around a still-hot centre, the stresses can exceed what the steel will take, and it splits. Thin sections, sharp internal corners and abrupt changes of thickness are where cracks start.",
                    "Move the work in the quench, and move it edge-first. Steam forms an insulating jacket around a stationary piece and gives you a soft spot exactly where you did not want one."
                   ])
    ]

    private static let guidesPart3: [ForgeGuide] = [
        ForgeGuide(id: "temper", title: "Running the Colours",
                   standfirst: "Fresh from the quench, the steel is too hard to use.",
                   art: "guide_temper",
                   paragraphs: [
                    "A just-quenched piece is at maximum hardness and maximum brittleness. Dropped on a stone floor, it can shatter. Tempering trades a little hardness back for a great deal of toughness.",
                    "Polish the surface bright and reheat gently, and a film of oxide grows and passes through a predictable sequence of colours: pale straw around 205 °C, bronze near 245, purple around 275, dark blue near 300. Past about 340 the colour goes grey and the hardening is essentially gone.",
                    "Each colour corresponds to a use. Straw for scribes and punches that must be hard. Bronze for knives and shears. Purple for axes and anything that takes an impact. Blue for springs.",
                    "Timing is everything, because the colours run and do not stop. Quench again the instant the right shade reaches the edge, or watch it walk straight past you into grey."
                   ]),
        ForgeGuide(id: "scale", title: "Fire Scale, Flux and Forge Welding",
                   standfirst: "To join two bars with fire alone, the surfaces must be perfectly clean.",
                   art: "guide_scale",
                   paragraphs: [
                    "Every heat grows a layer of black iron oxide on the surface, called fire scale. It flakes off under the hammer, it is abrasive enough to wear tools, and it will absolutely prevent a forge weld.",
                    "Forge welding means bringing two pieces to a near-molten yellow-white heat and joining them by hammer pressure alone, with no filler metal at all. It is the oldest joining process there is and still one of the most demanding.",
                    "Flux — traditionally borax — is sprinkled on at a red heat. It melts into a glass that floats the scale out of the joint and seals the surfaces from the air until the weld takes.",
                    "The welding heat is only a little below the burning heat, which is what makes it hard. Take the bar out slightly too late and instead of a weld you have a handful of sparks and a ruined billet."
                   ]),
        ForgeGuide(id: "bending", title: "Bending Hot and Bending Cold",
                   standfirst: "Where the bend starts matters more than how far it goes.",
                   art: "guide_bending",
                   paragraphs: [
                    "Hot metal bends where it is hottest. That gives you control: heat a narrow band and the bend happens exactly there, leaving everything on either side straight.",
                    "Cold bending is possible in mild steel and dangerous in anything else. The outer face of a cold bend is in tension, and in a hardenable or fibrous stock that tension opens cracks that may not be visible until the piece fails in use.",
                    "Scrolls are bent progressively, a little at a time, starting from the tip and working back. Trying to make a scroll in one movement gives a flat spot at the start and a kink at the end.",
                    "Right angles are made over the far edge of the anvil, with the bar held down hard and struck close to the edge. Struck too far out, the bend rounds off into a curve instead of a corner."
                   ]),
        ForgeGuide(id: "history", title: "Four Thousand Years at the Anvil",
                   standfirst: "The tools changed slowly. The problems never changed at all.",
                   art: "guide_history",
                   paragraphs: [
                    "The first iron worked by human hands came out of the sky. Meteoric iron beads were being made in Egypt more than five thousand years ago, long before anyone could smelt ore, and they were rarer and more valuable than gold.",
                    "Smelted iron arrived around 1200 BC and spread because ore was everywhere while the tin needed for bronze was not. Early iron was worse than good bronze in almost every way, but you could make it anywhere, and that decided it.",
                    "For most of history the village smith made everything: nails, hinges, tools, ploughshares, cooking gear, and the tools of every other trade in the village. The trade only fragmented when factories began mass-producing the simple items, leaving smiths the work that machines could not do.",
                    "What survives is the part that never automated. A bar of steel at a yellow heat behaves the same way for a modern smith as it did for a Roman one, and the sequence — heat, move, judge, heat again — has outlasted every empire that used it."
                   ])
    ]

    // Split into chunks: one huge array literal makes the Release
    // optimiser crawl through SIL for many minutes.
    static let guides: [ForgeGuide] =
        guidesPart1 + guidesPart2 + guidesPart3


    // MARK: - Glossary

    private static let glossaryPart1: [GlossaryEntry] = [
        GlossaryEntry(term: "Anneal", meaning: "Heating steel and cooling it as slowly as possible to leave it soft and easy to work or machine."),
        GlossaryEntry(term: "Billet", meaning: "A short, thick block of stock ready to be forged, often several pieces stacked for pattern welding."),
        GlossaryEntry(term: "Black Heat", meaning: "Hot enough to burn you badly, not hot enough to glow. The most dangerous temperature in the shop."),
        GlossaryEntry(term: "Bolster", meaning: "The thickened shoulder between a blade and its handle, forged rather than added."),
        GlossaryEntry(term: "Critical Temperature", meaning: "The point, near 760 °C, where steel changes structure and a magnet no longer sticks to it."),
        GlossaryEntry(term: "Draw Out", meaning: "To make a bar longer and thinner by hammering, moving metal along its length."),
        GlossaryEntry(term: "Drift", meaning: "A tapered tool driven through a punched hole to bring it to its final size and shape."),
        GlossaryEntry(term: "Fire Scale", meaning: "The flaking black oxide that grows on hot steel and must be cleared before any weld."),
        GlossaryEntry(term: "Flux", meaning: "Borax or similar, melted onto a joint to float out scale and keep air away during a forge weld."),
        GlossaryEntry(term: "Forge Weld", meaning: "Joining two pieces at a near-molten heat by hammer pressure alone, with no filler metal.")
    ]

    private static let glossaryPart2: [GlossaryEntry] = [
        GlossaryEntry(term: "Fuller", meaning: "A blunt rounded tool that sinks a groove and isolates a shoulder without moving neighbouring metal."),
        GlossaryEntry(term: "Hardy Hole", meaning: "The square hole in an anvil that holds shanked bottom tools."),
        GlossaryEntry(term: "Horn", meaning: "The tapered cone at one end of an anvil, used for bending curves and rings."),
        GlossaryEntry(term: "Mild Steel", meaning: "Steel under about 0.25 per cent carbon: cheap, forgiving, and effectively unhardenable."),
        GlossaryEntry(term: "Peen", meaning: "The end of a hammer head opposite the flat face, shaped to drive metal in one direction."),
        GlossaryEntry(term: "Planish", meaning: "To smooth a forged surface with light, overlapping blows from a polished hammer face."),
        GlossaryEntry(term: "Poll", meaning: "The heavy back end of an axe head, opposite the cutting edge."),
        GlossaryEntry(term: "Pritchel Hole", meaning: "The small round hole in an anvil, there so a punch can pass through work without hitting steel."),
        GlossaryEntry(term: "Quench", meaning: "Cooling hot steel rapidly in air, oil, water or brine in order to harden it."),
        GlossaryEntry(term: "Scarf", meaning: "The tapered, slightly domed end prepared on each piece before a forge weld.")
    ]

    private static let glossaryPart3: [GlossaryEntry] = [
        GlossaryEntry(term: "Shoulder", meaning: "A deliberate step where a bar changes section, usually made with a fuller."),
        GlossaryEntry(term: "Slack Tub", meaning: "The tub of water beside the anvil, used for cooling tools and hands, rarely for hardening."),
        GlossaryEntry(term: "Spring Steel", meaning: "A tough medium-carbon alloy that returns to shape under load and needs a gentle quench."),
        GlossaryEntry(term: "Swage", meaning: "A shaped block or tool used to force a bar into a set section, commonly round or hexagonal."),
        GlossaryEntry(term: "Tang", meaning: "The narrow part of a tool or blade that runs into the handle."),
        GlossaryEntry(term: "Temper", meaning: "Gently reheating hardened steel to trade some hardness back for toughness."),
        GlossaryEntry(term: "Upset", meaning: "To make a bar shorter and thicker by striking it along its length."),
        GlossaryEntry(term: "Wrought Iron", meaning: "Nearly carbon-free iron threaded with slag fibres: tough, weldable and highly rust-resistant.")
    ]

    // Split into chunks: one huge array literal makes the Release
    // optimiser crawl through SIL for many minutes.
    static let glossary: [GlossaryEntry] =
        glossaryPart1 + glossaryPart2 + glossaryPart3


    // MARK: - Quiz

    private static let quizPart1: [QuizQuestion] = [
        QuizQuestion(prompt: "Roughly what temperature is a bright cherry red?",
                     options: ["350 °C", "500 °C", "800 °C", "1400 °C"], answer: 2,
                     because: "Cherry red sits near 800 °C, comfortably inside the forging range for most steels."),
        QuizQuestion(prompt: "What happens if you hammer steel below its forging range?",
                     options: ["It moves faster", "It cracks and work-hardens", "It gets softer", "Nothing at all"], answer: 1,
                     because: "Cold-working forces the grain apart instead of letting it flow, and cracks follow."),
        QuizQuestion(prompt: "Which stock cannot be meaningfully hardened by quenching?",
                     options: ["High carbon steel", "Spring steel", "Mild steel", "Tool steel"], answer: 2,
                     because: "Under about 0.25 per cent carbon there is not enough carbon to lock a hard structure in."),
        QuizQuestion(prompt: "What is the critical temperature of carbon steel most easily tested with?",
                     options: ["A thermometer", "A magnet", "A drop of water", "Your hand"], answer: 1,
                     because: "Steel stops being magnetic right around the critical point, near 760 °C."),
        QuizQuestion(prompt: "What is the square hole in an anvil called?",
                     options: ["Pritchel hole", "Hardy hole", "Drift hole", "Swage hole"], answer: 1,
                     because: "The hardy hole takes shanked bottom tools; the small round one is the pritchel."),
        QuizQuestion(prompt: "Which quenchant is the most severe?",
                     options: ["Still air", "Oil", "Water", "Brine"], answer: 3,
                     because: "Brine pulls heat out fastest of all, which also makes it the most likely to crack a piece."),
        QuizQuestion(prompt: "Pale straw temper colour appears around:",
                     options: ["120 °C", "205 °C", "300 °C", "450 °C"], answer: 1,
                     because: "Straw is the first useful colour, near 205 °C, and suits punches and scribes."),
        QuizQuestion(prompt: "Which temper colour suits an axe?",
                     options: ["Pale straw", "Purple", "Grey", "None — leave it hard"], answer: 1,
                     because: "An axe takes shocks, so it wants toughness over maximum hardness: purple, near 275 °C.")
    ]

    private static let quizPart2: [QuizQuestion] = [
        QuizQuestion(prompt: "What does a cross peen do that a flat face does not?",
                     options: ["Cuts the bar", "Drives metal mostly in one direction", "Cools the bar", "Hardens the surface"], answer: 1,
                     because: "The wedge shape concentrates the blow along one axis, which is how bars are drawn out fast."),
        QuizQuestion(prompt: "Why is a hammer eye punched rather than drilled?",
                     options: ["It is faster", "It looks better", "The grain flows round the hole", "Drills did not exist"], answer: 2,
                     because: "Punching pushes the fibres aside; drilling cuts them, and cut grain is where cracks start."),
        QuizQuestion(prompt: "Fire scale is:",
                     options: ["A measuring tool", "Flaking iron oxide on hot steel", "A kind of flux", "A safety rating"], answer: 1,
                     because: "It grows on every heat, it is abrasive, and it must be cleared before any forge weld."),
        QuizQuestion(prompt: "What is flux used for?",
                     options: ["Cooling the work", "Colouring the steel", "Keeping air and scale out of a weld", "Hardening the edge"], answer: 2,
                     because: "Melted borax seals the joint from oxygen and floats the scale out ahead of the weld."),
        QuizQuestion(prompt: "Wrought iron is distinguished by:",
                     options: ["High carbon", "Slag fibres running through it", "Added nickel", "Being cast"], answer: 1,
                     because: "Those glassy fibres make it tough, weldable and famously resistant to rust."),
        QuizQuestion(prompt: "Upsetting a bar makes it:",
                     options: ["Longer and thinner", "Shorter and thicker", "Harder", "Straighter"], answer: 1,
                     because: "Striking along the length pushes metal back into the section instead of out along it."),
        QuizQuestion(prompt: "Where should a right-angle bend be struck?",
                     options: ["In the middle of the face", "Over the far edge of the anvil", "On the horn", "In the hardy hole"], answer: 1,
                     because: "The sharp edge of the anvil is what gives a corner rather than a soft curve."),
        QuizQuestion(prompt: "Which hammer weight suits most general forging?",
                     options: ["300 g", "900 g", "3 kg", "6 kg"], answer: 1,
                     because: "Somewhere near a kilogram gives useful force without wrecking your accuracy or your elbow.")
    ]

    private static let quizPart3: [QuizQuestion] = [
        QuizQuestion(prompt: "A just-quenched high carbon piece is:",
                     options: ["Soft and tough", "Hard and brittle", "Unchanged", "Annealed"], answer: 1,
                     because: "Maximum hardness comes with maximum brittleness, which is exactly why tempering exists."),
        QuizQuestion(prompt: "Meteoric iron is notable for containing:",
                     options: ["Copper", "Nickel", "Lead", "Tin"], answer: 1,
                     because: "Its nickel content and slow cosmic cooling give it the crystal pattern you cannot fake."),
        QuizQuestion(prompt: "Why do smiths often work in dim light?",
                     options: ["To save power", "Tradition", "So heat colours are readable", "To keep the shop cool"], answer: 2,
                     because: "In bright light a dull red and a black heat look identical, and that mistake breaks bars."),
        QuizQuestion(prompt: "A fuller is used to:",
                     options: ["Cut the bar off", "Sink a groove and isolate a shoulder", "Polish the surface", "Punch a hole"], answer: 1,
                     because: "It concentrates the blow into a narrow line so only the metal under it moves."),
        QuizQuestion(prompt: "What is a scarf?",
                     options: ["A safety garment", "A tapered end prepared for a weld", "A type of tongs", "A finishing wax"], answer: 1,
                     because: "Scarfing gives a slightly domed, tapered face so the joint closes from the middle outwards."),
        QuizQuestion(prompt: "Forge welding happens at what heat?",
                     options: ["Dull red", "Cherry red", "Near-molten yellow-white", "Black heat"], answer: 2,
                     because: "It is only a little below the burning heat, which is what makes it so unforgiving."),
        QuizQuestion(prompt: "Why move the piece around in the quench?",
                     options: ["To cool it evenly and break the steam jacket", "To harden it faster", "To stop it rusting", "Superstition"], answer: 0,
                     because: "A stationary piece grows an insulating steam blanket and comes out with soft spots."),
        QuizQuestion(prompt: "Annealing steel means:",
                     options: ["Cooling it as slowly as possible", "Quenching in brine", "Heating past burning", "Twisting it hot"], answer: 0,
                     because: "Slow cooling leaves the softest, most workable structure.")
    ]

    private static let quizPart4: [QuizQuestion] = [
        QuizQuestion(prompt: "The tapered cone on an anvil is the:",
                     options: ["Table", "Horn", "Poll", "Tang"], answer: 1,
                     because: "The horn is for bending curves, rings and drawing round sections."),
        QuizQuestion(prompt: "Which is the correct order of operations?",
                     options: ["Temper, quench, forge", "Forge, quench, temper", "Quench, forge, temper", "Temper, forge, quench"], answer: 1,
                     because: "Shape it first, harden it second, then take the brittleness back out of it."),
        QuizQuestion(prompt: "Burning a bar in the fire causes:",
                     options: ["Nothing serious", "Loss of metal and a ruined surface", "Better hardening", "Faster forging"], answer: 1,
                     because: "Past the burning point the steel sparks, sheds material and crumbles under the hammer."),
        QuizQuestion(prompt: "Why is a hammer face given radiused edges?",
                     options: ["It looks tidier", "Sharp edges leave marks that become cracks", "It is lighter", "To fit the hardy hole"], answer: 1,
                     because: "Crescent marks from a sharp edge concentrate stress and are hard work to dress out."),
        QuizQuestion(prompt: "Iron replaced bronze mainly because:",
                     options: ["It was harder", "Ore was available almost everywhere", "It was prettier", "It never rusted"], answer: 1,
                     because: "Early iron was arguably worse than good bronze, but you could make it without imported tin."),
        QuizQuestion(prompt: "A slack tub beside the anvil is mainly for:",
                     options: ["Hardening every piece", "Cooling tools and hands", "Storing flux", "Mixing quench oil"], answer: 1,
                     because: "Serious hardening is planned; the slack tub is mostly for keeping tools and fingers usable.")
    ]

    // Split into chunks: one huge array literal makes the Release
    // optimiser crawl through SIL for many minutes.
    static let quiz: [QuizQuestion] =
        quizPart1 + quizPart2 + quizPart3 + quizPart4

}
