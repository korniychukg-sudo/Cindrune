import SwiftUI

struct ForgeLaunch: Identifiable {
    let id = UUID()
    let project: ForgeProject?
    let metal: Metal
}

struct RootView: View {
    @StateObject private var store = ForgeStore()
    @State private var tab = 0
    @State private var launch: ForgeLaunch? = nil
    @State private var celebrating: ForgeBadge? = nil

    var body: some View {
        ZStack {
            Forge.soot.edgesIgnoringSafeArea(.all)

            if !store.save.onboarded {
                OnboardingView {
                    store.completeOnboarding()
                }
                .transition(.opacity)
            } else {
                mainShell
            }

            if let b = celebrating {
                BadgeCelebration(badge: b) {
                    withAnimation { celebrating = nil }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            ForgeSound.shared.enabled = store.save.soundOn
            ForgeSound.shared.hapticsEnabled = store.save.hapticsOn
        }
        .onReceive(store.$freshBadge.compactMap { $0 }) { b in
            withAnimation { celebrating = b }
            store.freshBadge = nil
        }
        .fullScreenCover(item: $launch) { item in
            AnvilView(store: store,
                      project: item.project,
                      metal: item.metal,
                      onExit: { launch = nil },
                      onRetry: {
                          let again = ForgeLaunch(project: item.project, metal: item.metal)
                          launch = nil
                          DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                              launch = again
                          }
                      })
        }
    }

    private var mainShell: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case 0:
                    WorkshopView(store: store,
                                 onStart: { p, m in start(p, m) },
                                 onTab: { tab = $0 })
                case 1:
                    ProjectsView(store: store, onStart: { p, m in start(p, m) })
                case 2:
                    AlmanacView(store: store)
                default:
                    JournalView(store: store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            tabBar
        }
    }

    private func start(_ project: ForgeProject?, _ metal: Metal) {
        launch = ForgeLaunch(project: project, metal: metal)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(index: 0, label: "Shop",
                      icon: AnyView(AnvilGlyph(size: 23, color: tint(0))))
            tabButton(index: 1, label: "Book",
                      icon: AnyView(ScrollGlyph(size: 23, color: tint(1))))
            tabButton(index: 2, label: "Almanac",
                      icon: AnyView(BookGlyph(size: 23, color: tint(2))))
            tabButton(index: 3, label: "Journal",
                      icon: AnyView(LedgerGlyph(size: 23, color: tint(3))))
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Forge.stone
                .overlay(Rectangle().fill(Forge.slate).frame(height: 1), alignment: .top)
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tint(_ index: Int) -> Color {
        tab == index ? Forge.spark : Forge.chalkFaint
    }

    private func tabButton(index: Int, label: String, icon: AnyView) -> some View {
        Button(action: {
            guard tab != index else { return }
            ForgeSound.shared.play(.tap, volume: 0.4)
            tab = index
        }) {
            VStack(spacing: 4) {
                icon.frame(height: 24)
                Text(label)
                    .font(Forge.label(10))
                    .foregroundColor(tint(index))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Badge celebration

struct BadgeCelebration: View {
    let badge: ForgeBadge
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.78)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                Text("Award earned")
                    .font(Forge.label(12))
                    .tracking(1.6)
                    .foregroundColor(Forge.brass)
                ZStack {
                    Circle()
                        .fill(Forge.night)
                        .frame(width: 132, height: 132)
                    ForgeArtImage(name: badge.art, corner: 64)
                        .frame(width: 124, height: 124)
                }
                .overlay(Circle().stroke(Forge.brass, lineWidth: 2).frame(width: 132, height: 132))
                Text(badge.name)
                    .font(Forge.title(24))
                    .foregroundColor(Forge.chalk)
                Text(badge.detail)
                    .font(Forge.body(13))
                    .foregroundColor(Forge.chalkDim)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                ForgeButton(title: "Back to Work", kind: .primary) { onDismiss() }
                    .frame(maxWidth: 240)
            }
            .padding(26)
            .frame(maxWidth: 380)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Forge.stone))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Forge.brassDim, lineWidth: 1))
            .padding(24)
        }
    }
}
