import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AudioManager.self) private var audio
    @Query private var progressList: [Progress]

    @State private var badgeVisible = false
    @State private var buttonVisible = false

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

            VoltCitySkylineView()
                .frame(height: 200)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 40)

            VStack(spacing: Spacing.md) {
                topBar
                    .padding(.top, Spacing.sm)

                LevelBadge(playerLevel: playerLevel)
                    .opacity(badgeVisible ? 1 : 0)
                    .offset(y: badgeVisible ? 0 : -12)

                Spacer()

                SparkView(mode: .blue, expression: .curious, size: 130)

                VStack(spacing: 4) {
                    Text("Physica")
                        .font(.gameTitle)
                        .foregroundStyle(.white)
                    Text("Spark's Workshop")
                        .font(.bodyGame)
                        .foregroundStyle(.white.opacity(0.55))
                }
                .padding(.top, Spacing.sm)

                Spacer()

                continueButton
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xl)
                    .opacity(buttonVisible ? 1 : 0)
                    .offset(y: buttonVisible ? 0 : 30)
            }
            .padding(.horizontal, Spacing.lg)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.05)) {
                badgeVisible = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.3)) {
                buttonVisible = true
            }
        }
    }

    private var topBar: some View {
        HStack {
            // Profile entry point (stub for future Profile screen)
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

            Spacer()

            StreakIndicator(days: streakDays)
        }
    }

    private var continueButton: some View {
        Button {
            audio.play(.tap)
            router.push(.realmMap)
        } label: {
            HStack(spacing: Spacing.sm) {
                Text(totalXP == 0 ? "Begin the journey" : "Continue the journey")
                    .font(.levelHeader)
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.electricBlue, in: Capsule())
            .foregroundStyle(.white)
            .shadow(color: .electricBlue.opacity(0.45), radius: 16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .environment(AppRouter())
        .environment(AudioManager())
        .modelContainer(.previewPhysica())
}
