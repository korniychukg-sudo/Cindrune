import SwiftUI

/// Shown while the launch check runs. Drawn in the app's own palette so the
/// first frame already belongs to the workshop: a coal bed breathing in the
/// dark, with sparks lifting off it.
struct CindruneLoadingScreen: View {
    var body: some View {
        ZStack {
            Forge.night.edgesIgnoringSafeArea(.all)

            TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: false)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    let w = size.width, h = size.height
                    let breath = 0.72 + 0.28 * abs(sin(t * 0.9))

                    let bed = CGRect(x: w * 0.5 - w * 0.22, y: h * 0.5 - w * 0.09,
                                     width: w * 0.44, height: w * 0.18)
                    ctx.fill(Path(ellipseIn: bed),
                             with: .color(Color(red: 0.055, green: 0.045, blue: 0.040)))
                    ctx.fill(Path(ellipseIn: bed.insetBy(dx: -bed.width * 0.7,
                                                         dy: -bed.height * 1.6)),
                             with: .radialGradient(Gradient(colors: [
                                Forge.white.opacity(0.85 * breath),
                                Forge.flame.opacity(0.45 * breath),
                                Forge.emberDeep.opacity(0.18 * breath),
                                Color.clear
                             ]), center: CGPoint(x: bed.midX, y: bed.midY),
                             startRadius: 0, endRadius: bed.width * 0.95))

                    // Lumps of coal sitting in the fire.
                    for i in 0..<16 {
                        let a = Double(i) * 0.83
                        let rr = 0.22 + Double((i * 31) % 60) / 100 * 0.30
                        let s = bed.width * 0.10
                        ctx.fill(Path(roundedRect: CGRect(
                            x: bed.midX + cos(a) * bed.width * rr - s / 2,
                            y: bed.midY + sin(a) * bed.height * rr - s * 0.34,
                            width: s, height: s * 0.68), cornerRadius: 2),
                                 with: .color(Color.black.opacity(0.6)))
                    }

                    // Sparks lifting into the dark.
                    for i in 0..<22 {
                        let seed = Double(i) * 12.9898
                        let speed = 0.14 + seed.truncatingRemainder(dividingBy: 0.10)
                        let life = (t * speed + Double(i) / 22).truncatingRemainder(dividingBy: 1)
                        let drift = sin(t * 0.9 + seed) * w * 0.03
                        let x = bed.midX + (seed.truncatingRemainder(dividingBy: 0.5) - 0.25)
                            * bed.width * 1.6 + drift
                        let y = bed.midY - life * h * 0.30
                        let fade = (1 - life) * breath
                        guard fade > 0.03 else { continue }
                        let r = 1.2 + (1 - life) * 2.0
                        ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                                 with: .color(Forge.spark.opacity(0.9 * fade)))
                    }
                }
            }

            VStack {
                Spacer()
                Text("Cindrune")
                    .font(Forge.title(30))
                    .foregroundColor(Forge.chalk)
                Text("Blowing up the fire")
                    .font(Forge.body(12))
                    .foregroundColor(Forge.chalkFaint)
                    .padding(.top, 4)
                Spacer()
                Spacer()
            }
        }
    }
}
