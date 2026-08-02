import SwiftUI

struct OnboardingView: View {
    let onDone: () -> Void

    @State private var page = 0

    private struct Card {
        let art: String
        let title: String
        let body: String
    }

    private let cards: [Card] = [
        Card(art: "onboard_fire",
             title: "The fire decides",
             body: "Steel only moves inside a narrow band of temperature. Work the bellows, watch the colour climb, and pull the bar out when it is right. Too cold and the hammer cracks it. Too hot and it burns away."),
        Card(art: "onboard_strike",
             title: "Every blow counts",
             body: "Tap the bar to strike it. Where you tap is where the metal moves, and the sweeping meter decides how hard the blow lands. The bar cools while you work, so you will be going back to the fire."),
        Card(art: "onboard_shape",
             title: "Answer the drawing",
             body: "Each commission comes with a blueprint. Draw the bar out, fuller the shoulders, punch the holes and bend where the drawing says. You are scored on how close the finished section comes."),
        Card(art: "onboard_shop",
             title: "The shop fills up",
             body: "Nothing you finish disappears. Hooks go on the wall, tools on the rack, a poker beside the hearth — and the shop follows the real hour of the day, right down to the lantern lighting at dusk.")
    ]

    var body: some View {
        ZStack {
            Forge.soot.edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                Spacer(minLength: 8)

                VStack(spacing: 18) {
                    ForgePlate(name: cards[page].art, height: Forge.wide ? 280 : 210)
                    VStack(spacing: 9) {
                        Text(cards[page].title)
                            .font(Forge.title(24))
                            .foregroundColor(Forge.chalk)
                            .multilineTextAlignment(.center)
                        Text(cards[page].body)
                            .font(Forge.body(14))
                            .foregroundColor(Forge.chalkDim)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: 470)
                .padding(.horizontal, 24)

                Spacer(minLength: 8)

                HStack(spacing: 7) {
                    ForEach(0..<cards.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Forge.ember : Forge.slate)
                            .frame(width: i == page ? 20 : 7, height: 7)
                    }
                }
                .padding(.bottom, 18)

                HStack(spacing: 10) {
                    if page > 0 {
                        ForgeButton(title: "Back", kind: .secondary) {
                            withAnimation { page -= 1 }
                        }
                    }
                    ForgeButton(title: page + 1 < cards.count ? "Next" : "Light the Fire",
                                kind: .primary) {
                        if page + 1 < cards.count {
                            withAnimation { page += 1 }
                        } else {
                            onDone()
                        }
                    }
                }
                .frame(maxWidth: 470)
                .padding(.horizontal, 24)
                .padding(.bottom, 26)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
