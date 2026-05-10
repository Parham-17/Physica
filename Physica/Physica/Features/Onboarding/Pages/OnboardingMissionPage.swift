import SwiftUI

struct OnboardingMissionPage: View {
    var onComplete: () -> Void

    @State private var sparkFlownIn = false
    @State private var sparkOffset = CGSize(width: 0, height: 300)
    @State private var sparkRotation: Double = -15
    @State private var showFlyingPose = true
    @State private var wordsTriggered = false
    @State private var subtitleVisible = false
    @State private var trailProgress: CGFloat = 0
    @State private var hover: CGFloat = 0
    @State private var autoAdvanceTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.16),
                    Color(red: 0.10, green: 0.10, blue: 0.22)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            JourneyTrail(progress: trailProgress)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: Spacing.lg) {
                Spacer()

                ZStack {
                    if showFlyingPose {
                        Image("SparkFlyingUp")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180)
                            .transition(.opacity)
                    } else {
                        Image("SparkFrontHappy")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180)
                            .offset(y: hover)
                            .transition(.opacity)
                    }
                }
                .offset(sparkOffset)
                .rotationEffect(.degrees(sparkRotation))
                .shadow(color: .voltBlue.opacity(0.4), radius: 25)

                StaggeredTextView(
                    words: ["Explore.", "Discover.", "Fix the world."],
                    font: .gameTitle,
                    color: .white,
                    delayBetween: 0.4,
                    trigger: wordsTriggered
                )

                if subtitleVisible {
                    Text("Learn real physics by playing.")
                        .font(.bodyGame)
                        .foregroundStyle(.white.opacity(0.6))
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
        }
        .contentShape(Rectangle())
        .onTapGesture { onComplete() }
        .task { await runSequence() }
        .onDisappear { autoAdvanceTask?.cancel() }
    }

    private func runSequence() async {
        try? await Task.sleep(for: .milliseconds(reduceMotion ? 200 : 300))

        // Spark flies in from below with the flying pose
        withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
            sparkOffset = .zero
            sparkRotation = 0
        }

        try? await Task.sleep(for: .milliseconds(1000))

        // Switch to standing/happy pose
        withAnimation(.easeInOut(duration: 0.3)) {
            showFlyingPose = false
        }

        // Start hover
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                hover = -8
            }
        }

        // Draw trail
        withAnimation(.easeOut(duration: 1.2)) {
            trailProgress = 1.0
        }

        try? await Task.sleep(for: .milliseconds(500))
        wordsTriggered = true

        try? await Task.sleep(for: .milliseconds(1800))

        withAnimation(.easeOut(duration: 0.5)) {
            subtitleVisible = true
        }

        autoAdvanceTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled {
                await MainActor.run { onComplete() }
            }
        }
    }
}

private struct JourneyTrail: View {
    var progress: CGFloat

    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let startY = size.height * 0.55
            let endY = size.height * 0.15

            let path = Path { p in
                p.move(to: CGPoint(x: centerX, y: startY))
                p.addCurve(
                    to: CGPoint(x: centerX, y: endY),
                    control1: CGPoint(x: centerX - 40, y: startY - (startY - endY) * 0.3),
                    control2: CGPoint(x: centerX + 40, y: startY - (startY - endY) * 0.7)
                )
            }

            let trimmed = path.trimmedPath(from: 0, to: progress)
            context.stroke(
                trimmed,
                with: .color(.white.opacity(0.25)),
                style: StrokeStyle(lineWidth: 2, dash: [6, 4])
            )
        }
        .allowsHitTesting(false)
    }
}
