import SwiftUI

// Palette for Cindrune — a soot-dark smithy lit by coal and hot iron.
// Every colour is fixed, so the app never follows the device light/dark setting.
enum Forge {

    // Surfaces
    static let night = Color(red: 0.075, green: 0.063, blue: 0.059)      // deepest shadow
    static let soot = Color(red: 0.118, green: 0.098, blue: 0.090)       // main background
    static let stone = Color(red: 0.169, green: 0.145, blue: 0.133)      // raised card
    static let stoneHigh = Color(red: 0.216, green: 0.184, blue: 0.165)  // card highlight
    static let slate = Color(red: 0.259, green: 0.224, blue: 0.200)      // borders

    // Iron & steel
    static let iron = Color(red: 0.361, green: 0.337, blue: 0.318)
    static let steel = Color(red: 0.541, green: 0.529, blue: 0.510)
    static let polish = Color(red: 0.741, green: 0.741, blue: 0.729)

    // Fire
    static let emberDeep = Color(red: 0.541, green: 0.161, blue: 0.055)
    static let ember = Color(red: 0.831, green: 0.325, blue: 0.078)
    static let flame = Color(red: 0.949, green: 0.518, blue: 0.129)
    static let spark = Color(red: 0.996, green: 0.784, blue: 0.361)
    static let white = Color(red: 1.000, green: 0.949, blue: 0.816)

    // Accents
    static let brass = Color(red: 0.788, green: 0.635, blue: 0.310)
    static let brassDim = Color(red: 0.518, green: 0.412, blue: 0.196)
    static let quench = Color(red: 0.322, green: 0.494, blue: 0.541)     // slack-tub blue
    static let temper = Color(red: 0.502, green: 0.408, blue: 0.588)     // tempering purple
    static let moss = Color(red: 0.400, green: 0.478, blue: 0.322)

    // Text
    static let chalk = Color(red: 0.918, green: 0.886, blue: 0.831)
    static let chalkDim = Color(red: 0.694, green: 0.659, blue: 0.612)
    static let chalkFaint = Color(red: 0.494, green: 0.463, blue: 0.427)

    // Status
    static let warn = Color(red: 0.855, green: 0.404, blue: 0.278)
    static let good = Color(red: 0.541, green: 0.678, blue: 0.416)

    // MARK: - Type

    static func title(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .serif) }
    static func heading(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .serif) }
    static func body(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .default) }
    static func mono(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .monospaced) }
    static func label(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .rounded) }

    // MARK: - Layout

    /// True when the app is running on a wide (iPad-class) canvas.
    static var wide: Bool { UIScreen.main.bounds.width >= 700 }

    /// Content column width so text never stretches edge to edge on iPad.
    static func column(_ available: CGFloat) -> CGFloat { min(available, wide ? 900 : 620) }

    /// How many columns a list of cards should run in on this canvas.
    static var listColumns: Int { wide ? 2 : 1 }

    static let corner: CGFloat = 16
    static let cornerSmall: CGFloat = 10
}

// MARK: - Forging heat

/// The colour hot steel glows at a given temperature, used everywhere from the
/// anvil to the heat-colour chart in the almanac.
enum HeatColor {

    /// Working range of the app: 20 °C (cold) to 1450 °C (burning).
    static func color(for celsius: Double) -> Color {
        let t = max(20, min(1500, celsius))
        switch t {
        case ..<480:
            // Cold iron — grey, warming very slightly toward brown.
            let f = (t - 20) / 460
            return blend(Color(red: 0.290, green: 0.278, blue: 0.267),
                         Color(red: 0.404, green: 0.310, blue: 0.271), f)
        case ..<650:
            let f = (t - 480) / 170
            return blend(Color(red: 0.404, green: 0.310, blue: 0.271),
                         Color(red: 0.518, green: 0.129, blue: 0.078), f)   // faint red
        case ..<800:
            let f = (t - 650) / 150
            return blend(Color(red: 0.518, green: 0.129, blue: 0.078),
                         Color(red: 0.741, green: 0.204, blue: 0.078), f)   // cherry
        case ..<950:
            let f = (t - 800) / 150
            return blend(Color(red: 0.741, green: 0.204, blue: 0.078),
                         Color(red: 0.910, green: 0.400, blue: 0.098), f)   // orange
        case ..<1150:
            let f = (t - 950) / 200
            return blend(Color(red: 0.910, green: 0.400, blue: 0.098),
                         Color(red: 0.988, green: 0.663, blue: 0.208), f)   // light orange
        case ..<1320:
            let f = (t - 1150) / 170
            return blend(Color(red: 0.988, green: 0.663, blue: 0.208),
                         Color(red: 1.000, green: 0.898, blue: 0.596), f)   // yellow
        default:
            let f = min(1, (t - 1320) / 180)
            return blend(Color(red: 1.000, green: 0.898, blue: 0.596),
                         Color(red: 1.000, green: 1.000, blue: 0.949), f)   // white, sparking
        }
    }

    /// How brightly the piece lights the room around it (0…1).
    static func glow(for celsius: Double) -> Double {
        guard celsius > 500 else { return 0 }
        return min(1, (celsius - 500) / 800)
    }

    static func blend(_ a: Color, _ b: Color, _ f: Double) -> Color {
        let f = max(0, min(1, f))
        let ca = UIColor(a).cg, cb = UIColor(b).cg
        return Color(red: ca.0 + (cb.0 - ca.0) * f,
                     green: ca.1 + (cb.1 - ca.1) * f,
                     blue: ca.2 + (cb.2 - ca.2) * f)
    }
}

private extension UIColor {
    var cg: (Double, Double, Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }
}

// MARK: - Small helpers

extension View {
    /// Card surface used across the app.
    func forgeCard(padding: CGFloat = 14) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Forge.corner, style: .continuous)
                    .fill(Forge.stone)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Forge.corner, style: .continuous)
                    .stroke(Forge.slate, lineWidth: 1)
            )
    }

    /// Fullscreen background that never bleeds outside its container.
    func forgeBackground() -> some View {
        self.background(Forge.soot.edgesIgnoringSafeArea(.all))
    }
}
