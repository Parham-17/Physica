import SwiftUI

struct StreakIndicator: View {
    let days: Int

    var body: some View {
        if days > 0 {
            HStack(spacing: 6) {
                Text("🔥")
                    .font(.system(size: 14))
                Text("\(days) day\(days == 1 ? "" : "s")")
                    .font(.hintCaption)
                    .foregroundStyle(.white.opacity(0.85))
                    .monospacedDigit()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Capsule().stroke(Color.voltYellow.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        StreakIndicator(days: 0)
        StreakIndicator(days: 1)
        StreakIndicator(days: 5)
        StreakIndicator(days: 42)
    }
    .padding(24)
    .background(Color.shadowDeep)
}
