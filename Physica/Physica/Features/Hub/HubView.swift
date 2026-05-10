import SwiftUI
import SwiftData

struct HubView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AudioManager.self) private var audio
    @Query private var progressList: [Progress]
    @State private var buttonVisible = false

    private var isFirstLaunch: Bool {
        (progressList.first?.totalXP ?? 0) == 0
    }

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

            VoltCitySkylineView()
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
                .opacity(buttonVisible ? 1 : 0)
                .offset(y: buttonVisible ? 0 : 30)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            let delay: Double = isFirstLaunch ? 1.0 : 0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    buttonVisible = true
                }
            }
        }
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


#Preview {
    HubView()
        .environment(AppRouter())
        .environment(AudioManager())
        .modelContainer(.previewPhysica())
}
