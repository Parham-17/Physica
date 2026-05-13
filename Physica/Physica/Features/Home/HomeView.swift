import SwiftUI
import SwiftData

/// Main page. Profile + level/XP at the top, then a scrollable list of all 5
/// worlds. Tapping a world pushes its dedicated `WorldView`.
struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AudioManager.self) private var audio
    @Query private var progressList: [Progress]
    @Query(sort: \Realm.order) private var realms: [Realm]

    @State private var badgeVisible = false
    @State private var cardsVisible = false

    private var totalXP: Int { progressList.first?.totalXP ?? 0 }
    private var streakDays: Int { progressList.first?.currentStreakDays ?? 0 }
    private var playerLevel: PlayerLevel { PlayerLevel(totalXP: totalXP) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.20, blue: 0.34),
                    Color(red: 0.05, green: 0.08, blue: 0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                topBar
                    .padding(.top, Spacing.sm)

                LevelBadge(playerLevel: playerLevel)
                    .opacity(badgeVisible ? 1 : 0)
                    .offset(y: badgeVisible ? 0 : -12)

                worldList
            }
            .padding(.horizontal, Spacing.lg)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.05)) {
                badgeVisible = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.18)) {
                cardsVisible = true
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button {
                router.push(.profile)
            } label: {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profile")

            Spacer()

            StreakIndicator(days: streakDays)
        }
    }

    // MARK: - World list

    private var worldList: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                ForEach(realms) { realm in
                    WorldCard(realm: realm)
                        .opacity(cardsVisible ? 1 : 0)
                        .offset(y: cardsVisible ? 0 : 18)
                        .onTapGesture {
                            handleTap(on: realm)
                        }
                }
            }
            .padding(.vertical, Spacing.md)
        }
    }

    private func handleTap(on realm: Realm) {
        guard realm.isUnlocked else {
            audio.play(.lockedAttempt)
            return
        }
        audio.play(.tap)
        router.push(.world(realm.id))
    }
}

// MARK: - World card

private struct WorldCard: View {
    let realm: Realm

    var body: some View {
        HStack(spacing: Spacing.md) {
            planetIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(realm.displayName)
                    .font(.levelHeader)
                    .foregroundStyle(.white)
                Text(realm.subtitle)
                    .font(.bodyGame)
                    .foregroundStyle(.white.opacity(0.6))

                if !realm.isUnlocked {
                    Label("Locked", systemImage: "lock.fill")
                        .font(.hintCaption)
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            if realm.isUnlocked {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.realmMid.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .opacity(realm.isUnlocked ? 1.0 : 0.5)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var planetIcon: some View {
        if let asset = realm.iconAssetName {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                .shadow(color: .black.opacity(0.55), radius: 12, y: 4)
        } else {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 88, height: 88)
        }
    }
}

#Preview {
    HomeView()
        .environment(AppRouter())
        .environment(AudioManager())
        .modelContainer(.previewPhysica())
}
