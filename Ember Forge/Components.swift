import SwiftUI

// MARK: - Headings

struct ScreenTitle: View {
    let text: String
    var sub: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(Forge.title(Forge.wide ? 32 : 27))
                .foregroundColor(Forge.chalk)
            if let sub = sub {
                Text(sub)
                    .font(Forge.body(13))
                    .foregroundColor(Forge.chalkDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionHeading: View {
    let text: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text.uppercased())
                .font(Forge.label(12))
                .tracking(1.4)
                .foregroundColor(Forge.brass)
            Spacer(minLength: 8)
            if let t = trailing {
                Text(t)
                    .font(Forge.label(12))
                    .foregroundColor(Forge.chalkFaint)
            }
        }
    }
}

// MARK: - Buttons

struct ForgeButton: View {
    let title: String
    var kind: Kind = .primary
    var enabled: Bool = true
    let action: () -> Void

    enum Kind { case primary, secondary, quiet, danger }

    private var fillColors: [Color] {
        switch kind {
        case .primary: return [Forge.ember, Forge.emberDeep]
        case .secondary: return [Forge.stoneHigh, Forge.stone]
        case .quiet: return [Forge.stone.opacity(0.6), Forge.stone.opacity(0.6)]
        case .danger: return [Forge.warn.opacity(0.9), Forge.warn.opacity(0.6)]
        }
    }

    private var textColor: Color {
        switch kind {
        case .primary, .danger: return Forge.night
        case .secondary: return Forge.chalk
        case .quiet: return Forge.chalkDim
        }
    }

    var body: some View {
        Button(action: {
            guard enabled else { return }
            ForgeSound.shared.play(.tap, volume: 0.5)
            action()
        }) {
            Text(title)
                .font(Forge.label(15))
                .foregroundColor(enabled ? textColor : Forge.chalkFaint)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(LinearGradient(colors: enabled ? fillColors : [Forge.stone, Forge.stone],
                                             startPoint: .top, endPoint: .bottom))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(kind == .primary ? Forge.spark.opacity(0.45) : Forge.slate,
                                lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!enabled)
    }
}

struct PillButton: View {
    let title: String
    var selected: Bool = false
    var locked: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            guard !locked else { return }
            ForgeSound.shared.play(.tap, volume: 0.4)
            action()
        }) {
            HStack(spacing: 5) {
                if locked { LockMark(size: 11) }
                Text(title)
                    .font(Forge.label(13))
                    .foregroundColor(locked ? Forge.chalkFaint
                                            : (selected ? Forge.night : Forge.chalkDim))
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(selected ? Forge.brass : Forge.stone)
            )
            .overlay(
                Capsule().stroke(selected ? Forge.spark.opacity(0.5) : Forge.slate, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(locked)
    }
}

// MARK: - Stars, bars, tags

struct StarRow: View {
    let stars: Int
    var size: CGFloat = 13
    var total: Int = 3

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<total, id: \.self) { i in
                StarMark(size: size, filled: i < stars)
            }
        }
    }
}

struct ForgeBar: View {
    let value: Double            // 0…1
    var tint: Color = Forge.ember
    var height: CGFloat = 8
    var track: Color = Forge.night

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.75), tint],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}

struct QualityTag: View {
    let quality: PieceQuality

    var body: some View {
        Text(quality.name.uppercased())
            .font(Forge.label(10))
            .tracking(0.8)
            .foregroundColor(Forge.night)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(quality.tint))
    }
}

struct MetalTag: View {
    let metal: Metal

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(metal.barTint)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(Forge.slate, lineWidth: 1))
            Text(metal.name)
                .font(Forge.label(11))
                .foregroundColor(Forge.chalkDim)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(Forge.night.opacity(0.6)))
    }
}

// MARK: - Cards

struct StatTile: View {
    let value: String
    let caption: String
    var tint: Color = Forge.brass

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Forge.mono(19))
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(caption)
                .font(Forge.body(11))
                .foregroundColor(Forge.chalkFaint)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Forge.cornerSmall, style: .continuous)
                .fill(Forge.night.opacity(0.45))
        )
    }
}

/// A thin brass plaque, used to label finished work.
struct BrassPlaque: View {
    let text: String
    var sub: String? = nil

    var body: some View {
        VStack(spacing: 1) {
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .serif))
                .foregroundColor(Color(red: 0.20, green: 0.15, blue: 0.06))
            if let sub = sub {
                Text(sub)
                    .font(.system(size: 9, weight: .regular, design: .serif))
                    .foregroundColor(Color(red: 0.28, green: 0.22, blue: 0.10))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(LinearGradient(colors: [Forge.brass, Forge.brassDim],
                                     startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(Color(red: 0.35, green: 0.27, blue: 0.10), lineWidth: 0.8)
        )
    }
}

// MARK: - Sheets

struct SheetHeader: View {
    let title: String
    let onClose: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(Forge.heading(19))
                .foregroundColor(Forge.chalk)
            Spacer()
            Button(action: {
                ForgeSound.shared.play(.tap, volume: 0.4)
                onClose()
            }) {
                CrossMark(size: 16, color: Forge.chalkDim)
                    .padding(9)
                    .background(Circle().fill(Forge.stone))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }
}

/// Wraps sheet content with the app background and a header.
struct ForgeSheet<Content: View>: View {
    let title: String
    let onClose: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Forge.soot.edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                SheetHeader(title: title, onClose: onClose)
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        content()
                    }
                    .frame(maxWidth: Forge.column(UIScreen.main.bounds.width))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 34)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Toast

struct ForgeToast: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Forge.label(13))
            .foregroundColor(Forge.chalk)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(Forge.night.opacity(0.94))
            )
            .overlay(Capsule().stroke(Forge.brassDim, lineWidth: 1))
    }
}

// MARK: - Badge cell

struct BadgeCell: View {
    let badge: ForgeBadge
    let earned: Bool

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(earned ? Forge.night : Forge.night.opacity(0.5))
                    .frame(width: 66, height: 66)
                if earned {
                    ForgeArtImage(name: badge.art, corner: 33)
                        .frame(width: 62, height: 62)
                } else {
                    LockMark(size: 20, color: Forge.chalkFaint)
                }
            }
            .overlay(
                Circle().stroke(earned ? Forge.brass : Forge.slate, lineWidth: 1.5)
                    .frame(width: 66, height: 66)
            )
            Text(badge.name)
                .font(Forge.label(11))
                .foregroundColor(earned ? Forge.chalk : Forge.chalkFaint)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 28, alignment: .top)
        }
    }
}

// MARK: - Layout helper

/// A simple flow of equal-width columns that adapts to iPad without any
/// iOS 16-only grid APIs.
struct ColumnGrid<Item: Identifiable, Cell: View>: View {
    let items: [Item]
    let columns: Int
    let spacing: CGFloat
    @ViewBuilder let cell: (Item) -> Cell

    private var rows: [[Item]] {
        guard columns > 0 else { return [items] }
        var out: [[Item]] = []
        var i = 0
        while i < items.count {
            out.append(Array(items[i..<min(i + columns, items.count)]))
            i += columns
        }
        return out
    }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<rows.count, id: \.self) { r in
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(rows[r]) { item in
                        cell(item).frame(maxWidth: .infinity)
                    }
                    if rows[r].count < columns {
                        ForEach(0..<(columns - rows[r].count), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                        }
                    }
                }
            }
        }
    }
}
