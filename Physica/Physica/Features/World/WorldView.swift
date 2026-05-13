import SwiftUI
import SwiftData

/// Dedicated page for a single world — shows only that world's modules.
/// Pushed from `HomeView` via `NavRoute.world(<worldID>)`.
struct WorldView: View {
    let worldID: String

    @Query(sort: \Realm.order) private var realms: [Realm]
    @Environment(AppRouter.self) private var router
    @Environment(AudioManager.self) private var audio
    @Environment(\.modelContext) private var modelContext

    private var realm: Realm? {
        realms.first(where: { $0.id == worldID })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if let realm {
                    worldHeader(realm)
                    moduleGrid(realm)
                } else {
                    Text("World not found")
                        .font(.bodyGame)
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.top, Spacing.xl)
                }
            }
            .padding(Spacing.lg)
        }
        .background(Color.realmDark.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private func worldHeader(_ realm: Realm) -> some View {
        VStack(spacing: Spacing.md) {
            planetIcon(for: realm)
            VStack(spacing: 4) {
                Text(realm.displayName)
                    .font(.gameTitle)
                    .foregroundStyle(.white)
                Text(realm.subtitle)
                    .font(.bodyGame)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.top, Spacing.lg)
    }

    @ViewBuilder
    private func planetIcon(for realm: Realm) -> some View {
        if let asset = realm.iconAssetName {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                .shadow(color: .black.opacity(0.6), radius: 22, y: 8)
        } else {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 160, height: 160)
        }
    }

    // MARK: - Module grid

    private func moduleGrid(_ realm: Realm) -> some View {
        let modules = realm.levels.sorted { $0.number < $1.number }
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 3),
            spacing: Spacing.sm
        ) {
            ForEach(modules) { module in
                ModuleTile(module: module, isUnlocked: isModuleUnlocked(module))
                    .onTapGesture { handleTap(on: module) }
            }
        }
    }

    private func handleTap(on module: Level) {
        guard isModuleUnlocked(module) else {
            audio.play(.lockedAttempt)
            return
        }
        audio.play(.tap)
        router.push(.module(module.id))
    }

    private func isModuleUnlocked(_ module: Level) -> Bool {
        ProgressStore(context: modelContext).isLevelUnlocked(module)
    }
}

// MARK: - Module tile

private struct ModuleTile: View {
    let module: Level
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("\(module.number)")
                .font(.levelHeader)
                .foregroundStyle(.white)
            Text(module.title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 28)
            if module.starsEarned > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<module.starsEarned, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(Color.beaconYellow)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isUnlocked ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .overlay(alignment: .topTrailing) {
            if !isUnlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(6)
            }
        }
        .opacity(isUnlocked ? 1.0 : 0.6)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        WorldView(worldID: "light-realm")
    }
    .environment(AppRouter())
    .environment(AudioManager())
    .modelContainer(.previewPhysica())
}
