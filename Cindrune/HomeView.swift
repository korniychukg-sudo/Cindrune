import SwiftUI

// The rank ladder, opened from the workshop's status strip.

// MARK: - Rank sheet

struct RankSheet: View {
    @ObservedObject var store: ForgeStore
    let onClose: () -> Void

    var body: some View {
        ForgeSheet(title: "The Ladder", onClose: onClose) {
            Text("Every piece you finish pays experience, scaled by how well it came out and what it was made from.")
                .font(Forge.body(12))
                .foregroundColor(Forge.chalkDim)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(0..<Content.ranks.count, id: \.self) { i in
                let r = Content.ranks[i]
                let reached = store.rankIndex >= i
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(reached ? Forge.brass : Forge.stone)
                            .frame(width: 30, height: 30)
                        Text("\(i + 1)")
                            .font(Forge.mono(12))
                            .foregroundColor(reached ? Forge.night : Forge.chalkFaint)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(r.name)
                                .font(Forge.heading(14))
                                .foregroundColor(reached ? Forge.chalk : Forge.chalkFaint)
                            Spacer()
                            Text("\(r.xp) XP")
                                .font(Forge.mono(11))
                                .foregroundColor(Forge.chalkFaint)
                        }
                        Text(r.unlocks)
                            .font(Forge.body(11))
                            .foregroundColor(Forge.chalkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
