import SwiftUI
import SwiftData

struct RealmMapView: View {
    @Query(sort: \Realm.order) private var realms: [Realm]

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                Text("Choose a World")
                    .font(.gameTitle)
                    .foregroundStyle(.white)
                    .padding(.top, Spacing.xl)

                ForEach(realms) { realm in
                    RealmCard(realm: realm)
                }
            }
            .padding(Spacing.lg)
        }
        .background(Color.realmDark.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct RealmCard: View {
    let realm: Realm

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                worldIcon

                VStack(alignment: .leading, spacing: 4) {
                    Text(realm.displayName)
                        .font(.levelHeader)
                        .foregroundStyle(.white)
                    Text(realm.subtitle)
                        .font(.bodyGame)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                if !realm.isUnlocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            if !realm.isUnlocked {
                Text("Complete the previous world to unlock.")
                    .font(.hintCaption)
                    .foregroundStyle(.white.opacity(0.45))
            }

            let sortedLevels = realm.levels.sorted { $0.number < $1.number }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 3),
                spacing: Spacing.sm
            ) {
                ForEach(sortedLevels) { level in
                    LevelTile(level: level, realm: realm)
                }
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardBackground)
        )
        .opacity(realm.isUnlocked ? 1.0 : 0.55)
    }

    private var cardBackground: Color {
        switch realm.id {
        case "light-realm": return Color(red: 0.10, green: 0.10, blue: 0.18)
        case "volt-city": return Color(red: 0.14, green: 0.16, blue: 0.28)
        default: return Color.realmMid
        }
    }

    @ViewBuilder
    private var worldIcon: some View {
        if let asset = realm.iconAssetName {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 8, y: 3)
        } else {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 64, height: 64)
        }
    }
}

private struct LevelTile: View {
    let level: Level
    let realm: Realm
    @Environment(AppRouter.self) private var router
    @Environment(AudioManager.self) private var audio
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Button {
            guard isUnlocked else {
                audio.play(.lockedAttempt)
                return
            }
            audio.play(.tap)
            router.push(.module(level.id))
        } label: {
            VStack(spacing: 4) {
                Text(level.isBoss ? "★" : "\(level.number)")
                    .font(.levelHeader)
                    .foregroundStyle(.white)
                Text(level.title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 26)
                if level.starsEarned > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<level.starsEarned, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Color.sparkYellow)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 86)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isUnlocked ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
            )
            .overlay(alignment: .topTrailing) {
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }

    private var isUnlocked: Bool {
        let store = ProgressStore(context: modelContext)
        return store.isLevelUnlocked(level)
    }
}

#Preview {
    NavigationStack {
        RealmMapView()
    }
    .environment(AppRouter())
    .environment(AudioManager())
    .modelContainer(.previewPhysica())
}
