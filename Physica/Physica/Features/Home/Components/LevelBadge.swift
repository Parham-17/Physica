import SwiftUI

struct LevelBadge: View {
    let playerLevel: PlayerLevel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Level \(playerLevel.level)")
                    .font(.levelHeader)
                    .foregroundStyle(.white)
                Text("·")
                    .font(.levelHeader)
                    .foregroundStyle(.white.opacity(0.45))
                Text(playerLevel.title)
                    .font(.levelHeader)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer(minLength: 0)
            }

            HStack(spacing: Spacing.sm) {
                XPProgressBar(progress: playerLevel.progress)
                Text("\(playerLevel.xpInLevel)/\(playerLevel.xpForNextLevel)")
                    .font(.hintCaption)
                    .foregroundStyle(.white.opacity(0.6))
                    .monospacedDigit()
                    .frame(minWidth: 56, alignment: .trailing)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        LevelBadge(playerLevel: PlayerLevel(totalXP: 0))
        LevelBadge(playerLevel: PlayerLevel(totalXP: 50))
        LevelBadge(playerLevel: PlayerLevel(totalXP: 175))
        LevelBadge(playerLevel: PlayerLevel(totalXP: 525))
    }
    .padding(24)
    .background(Color.realmDark)
}
