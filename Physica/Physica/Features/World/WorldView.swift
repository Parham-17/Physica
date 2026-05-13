import SwiftUI
import SwiftData

/// Dedicated page for a single world — shows only that world's modules.
/// Pushed from `HomeView` via `NavRoute.world(<worldID>)`.
struct WorldView: View {
    let worldID: String

    @Query(sort: \Realm.order) private var realms: [Realm]
    @Environment(AppRouter.self) private var router
    @Environment(AudioManager.self) private var audio
    @Environment(NarrativeFlags.self) private var flags
    @Environment(\.modelContext) private var modelContext

    @State private var moduleToRetry: Level?

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
        .alert(
            "Replay this module?",
            isPresented: Binding(
                get: { moduleToRetry != nil },
                set: { if !$0 { moduleToRetry = nil } }
            ),
            presenting: moduleToRetry
        ) { module in
            Button("Cancel", role: .cancel) { moduleToRetry = nil }
            Button("Replay") { performRetry(module) }
        } message: { _ in
            Text("You'll start from the beginning. Your best stars are kept, and you won't earn XP again.")
        }
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
        let store = ProgressStore(context: modelContext)
        let nextID: String? = modules.first {
            store.isLevelUnlocked($0) && !$0.isCompleted
        }?.id

        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 3),
            spacing: Spacing.sm
        ) {
            ForEach(modules) { module in
                ModuleTile(
                    module: module,
                    isUnlocked: store.isLevelUnlocked(module),
                    isNext: module.id == nextID
                )
                .onTapGesture { handleTap(on: module) }
            }
        }
    }

    // MARK: - Tap handling

    private func handleTap(on module: Level) {
        let store = ProgressStore(context: modelContext)
        guard store.isLevelUnlocked(module) else {
            audio.play(.lockedAttempt)
            return
        }
        audio.play(.tap)

        if module.isCompleted {
            // Ask before re-running a finished module.
            moduleToRetry = module
        } else {
            router.push(.module(module.id))
        }
    }

    private func performRetry(_ module: Level) {
        // Clear this module's narrative beats so dialogue fires fresh on retry.
        flags.clearState(forModuleID: module.id)
        moduleToRetry = nil
        router.push(.module(module.id))
    }
}

// MARK: - Module tile

private struct ModuleTile: View {
    let module: Level
    let isUnlocked: Bool
    let isNext: Bool

    @State private var ringPulse: CGFloat = 1.0

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
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: isNext ? 2.5 : 1)
                .shadow(color: isNext ? Color.beaconWarm.opacity(0.7) : .clear, radius: 12)
                .scaleEffect(isNext ? ringPulse : 1.0)
        )
        .overlay(alignment: .topTrailing) {
            if !isUnlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(6)
            } else if module.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.beaconYellow)
                    .padding(4)
            }
        }
        .opacity(isUnlocked ? 1.0 : 0.55)
        .contentShape(Rectangle())
        .onAppear {
            guard isNext else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                ringPulse = 1.04
            }
        }
    }

    private var borderColor: Color {
        if isNext { return Color.beaconYellow }
        return Color.white.opacity(0.08)
    }
}

#Preview {
    NavigationStack {
        WorldView(worldID: "light-realm")
    }
    .environment(AppRouter())
    .environment(AudioManager())
    .environment(NarrativeFlags())
    .modelContainer(.previewPhysica())
}
