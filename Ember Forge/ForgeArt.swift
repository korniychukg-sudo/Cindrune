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

/// A framed illustration with the app's dark border treatment.
struct ForgePlate: View {
    let name: String
    var height: CGFloat = 150
    var corner: CGFloat = Forge.corner

    var body: some View {
        ForgeArtImage(name: name, corner: corner)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Forge.slate, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}
