import SwiftUI

// Loads the generated illustrations that ship in the bundled Art folder.
enum ForgeArtLibrary {
    private static var cache: [String: UIImage] = [:]

    static func uiImage(_ name: String) -> UIImage? {
        if let hit = cache[name] { return hit }
        guard let url = Bundle.main.url(forResource: name, withExtension: "png",
                                        subdirectory: "Art"),
              let img = UIImage(contentsOfFile: url.path) else { return nil }
        cache[name] = img
        return img
    }
}

/// Renders a bundled illustration, falling back to a dark forged panel so the
/// layout never collapses if an asset is missing.
struct ForgeArtImage: View {
    let name: String
    var corner: CGFloat = 0
    var fill: Bool = true

    var body: some View {
        Group {
            if let img = ForgeArtLibrary.uiImage(name) {
                if fill {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Image(uiImage: img).resizable().scaledToFit()
                }
            } else {
                ZStack {
                    LinearGradient(colors: [Forge.stone, Forge.night],
                                   startPoint: .top, endPoint: .bottom)
                    Circle().fill(Forge.emberDeep.opacity(0.55)).padding(30)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}

/// An engraved plate presented the way it would actually lie in a workshop:
/// tilted a little, shadowed under its lower edge, held by a clip, with soot
/// worked into the corners.
struct ForgePlate: View {
    let name: String
    var height: CGFloat = 150
    var corner: CGFloat = 4
    /// Sheets alternate their lean so a column of them never looks stacked.
    var lean: Double = -0.7

    var body: some View {
        ForgeArtImage(name: name, corner: corner)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(
                // Soot picked up from the bench, heaviest in the corners.
                RadialGradient(colors: [Color.clear, Color.black.opacity(0.30)],
                               center: .center, startRadius: height * 0.30,
                               endRadius: height * 1.15)
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.black.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(alignment: .top) {
                SheetClip().offset(y: -7)
            }
            .rotationEffect(.degrees(lean))
            .shadow(color: Color.black.opacity(0.65), radius: 9, x: 0, y: 6)
            .padding(.top, 8)
    }
}

/// The spring clip that holds a plate to the bench.
private struct SheetClip: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            var body = Path()
            body.addRoundedRect(in: CGRect(x: w * 0.5 - 15, y: h * 0.28, width: 30, height: h * 0.52),
                                cornerSize: CGSize(width: 3, height: 3))
            ctx.fill(body, with: .linearGradient(Gradient(colors: [
                Color(red: 0.62, green: 0.60, blue: 0.58),
                Color(red: 0.28, green: 0.27, blue: 0.26)
            ]), startPoint: CGPoint(x: 0, y: h * 0.28), endPoint: CGPoint(x: 0, y: h * 0.80)))
            var jaw = Path()
            jaw.addRoundedRect(in: CGRect(x: w * 0.5 - 19, y: h * 0.62, width: 38, height: h * 0.30),
                               cornerSize: CGSize(width: 2, height: 2))
            ctx.fill(jaw, with: .color(Color(red: 0.36, green: 0.35, blue: 0.34)))
            ctx.stroke(jaw, with: .color(Color.black.opacity(0.5)), lineWidth: 1)
        }
        .frame(width: 46, height: 22)
    }
}
