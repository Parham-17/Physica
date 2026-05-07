import SwiftUI
import SwiftData

struct HubView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AudioManager.self) private var audio
    @Query private var progressList: [Progress]

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

            VoltCitySkyline()
                .frame(height: 200)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 40)

            VStack(spacing: Spacing.md) {
                Spacer()

                Text("Physica")
                    .font(.gameTitle)
                    .foregroundStyle(.white)
                    .padding(.top, Spacing.xl)

                SparkView(mode: .blue, expression: .curious, size: 120)
                    .padding(.vertical, Spacing.md)

                Text("Volt City")
                    .font(.levelHeader)
                    .foregroundStyle(.white.opacity(0.85))

                Text(welcomeSubtitle)
                    .font(.bodyGame)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)

                Spacer()

                Button {
                    audio.play(.tap)
                    router.push(.realmMap)
                } label: {
                    Text("Begin the journey")
                        .font(.levelHeader)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.voltBlue, in: Capsule())
                        .foregroundStyle(.white)
                        .shadow(color: .voltBlue.opacity(0.4), radius: 14)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var welcomeSubtitle: String {
        let xp = progressList.first?.totalXP ?? 0
        if xp == 0 {
            return "The world's physics laws are breaking.\nHelp Spark restore them."
        } else {
            return "Welcome back. \(xp) XP earned."
        }
    }
}

private struct VoltCitySkyline: View {
    var body: some View {
        GeometryReader { proxy in
            let columnCount = 11
            let totalSpacing: CGFloat = CGFloat(columnCount - 1) * 6
            let columnWidth = (proxy.size.width - totalSpacing - Spacing.lg * 2) / CGFloat(columnCount)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<columnCount, id: \.self) { i in
                    buildingColumn(index: i, width: columnWidth)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    @ViewBuilder
    private func buildingColumn(index i: Int, width: CGFloat) -> some View {
        let baseHeight: Int = 70 + (i % 3) * 32 + (i % 2) * 12
        let height: CGFloat = CGFloat(baseHeight)
        let isLit: Bool = (i % 3 == 1) || (i % 5 == 0)
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.shadowMid)
                .frame(width: width, height: height)
            VStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<2, id: \.self) { col in
                            Circle()
                                .fill(Color.voltYellow.opacity(isLit && (row + col) % 2 == 0 ? 0.85 : 0.12))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .padding(.top, 12)
        }
    }
}

#Preview {
    HubView()
        .environment(AppRouter())
        .environment(AudioManager())
        .modelContainer(.previewPhysica())
}
