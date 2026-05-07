import SwiftUI

struct VoltCityPlaceholderView: View {
    let levelNumber: Int

    var body: some View {
        VStack(spacing: Spacing.lg) {
            SparkView(mode: .blue, expression: .focused, size: 110)

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
            ? "Volt City — Boss"
            : "Volt City — Level \(levelNumber)"
    }

    private var plannedWeek: Int {
        switch levelNumber {
        case 1, 2: return 5
        case 3, 4, 5: return 6
        case 99: return 7
        default: return 5
        }
    }
}

#Preview {
    VoltCityPlaceholderView(levelNumber: 1)
}
