import SwiftUI

struct ShadowRealmPlaceholderView: View {
    let levelNumber: Int

    var body: some View {
        VStack(spacing: Spacing.lg) {
            SparkView(mode: .yellow, expression: .focused, size: 110)

            Text(headerTitle)
                .font(.gameTitle)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Coming in Week \(plannedWeek)")
                .font(.bodyGame)
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.shadowDeep.ignoresSafeArea())
    }

    private var headerTitle: String {
        levelNumber == 99
            ? "Shadow Realm — Boss"
            : "Shadow Realm — Level \(levelNumber)"
    }

    private var plannedWeek: Int {
        switch levelNumber {
        case 1, 2: return 2
        case 3, 4, 5: return 3
        case 99: return 4
        default: return 2
        }
    }
}

#Preview {
    ShadowRealmPlaceholderView(levelNumber: 1)
}
