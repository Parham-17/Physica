import SwiftUI

struct OnboardingMissionPage: View {
    var onComplete: () -> Void

    @State private var sparkYOffset: CGFloat = 280
    @State private var sparkXOffset: CGFloat = 0
    @State private var showFlyingPose = true
    @State private var hover: CGFloat = 0
    @State private var trailProgress: CGFloat = 0
    @State private var exploreVisible = false
    @State private var discoverVisible = false
    @State private var fixWorldVisible = false
    @State private var subtitleVisible = false
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
                Spacer().frame(height: Spacing.xxl)

                ZStack {
                    if showFlyingPose {
                        Image("SparkFlyingUp")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 170)
                            .transition(.opacity)
                    } else {
                        SparkAnimated(imageName: "SparkFrontBlinking", size: 170)
                            .offset(y: hover)
                            .transition(.opacity)
                    }
                }
                .offset(x: sparkXOffset, y: sparkYOffset)
                .shadow(color: .voltBlue.opacity(0.4), radius: 25)

                Spacer()

                staircaseText
                    .padding(.horizontal, Spacing.lg)

                if subtitleVisible {
                    Text("Learn real physics by playing.")
                        .font(.bodyGame)
                        .foregroundStyle(.white.opacity(0.7))
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .padding(.top, Spacing.md)
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
        }
        .contentShape(Rectangle())
        .onTapGesture { onComplete() }
        .task { await runSequence() }
        .onDisappear { autoAdvanceTask?.cancel() }
    }

    private var staircaseText: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("Explore.")
                    .font(.gameTitle)
                    .foregroundStyle(.white)
                    .opacity(exploreVisible ? 1 : 0)
                    .offset(y: exploreVisible ? 0 : 12)
                Spacer()
            }
            HStack {
                Spacer().frame(width: 60)
                Text("Discover.")
                    .font(.gameTitle)
                    .foregroundStyle(.white)
                    .opacity(discoverVisible ? 1 : 0)
                    .offset(y: discoverVisible ? 0 : 12)
                Spacer()
            }
            HStack {
                Spacer().frame(width: 120)
                Text("Fix the world.")
                    .font(.gameTitle)
                    .foregroundStyle(.white)
                    .opacity(fixWorldVisible ? 1 : 0)
                    .offset(y: fixWorldVisible ? 0 : 12)
                Spacer()
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: exploreVisible)
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: discoverVisible)
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: fixWorldVisible)
    }

    private func runSequence() async {
        try? await Task.sleep(for: .milliseconds(reduceMotion ? 200 : 300))

        // Spark flies upward from below
        withAnimation(.easeOut(duration: 1.4)) {
            sparkYOffset = -40
        }

        // Draw the trail while flying
        withAnimation(.easeOut(duration: 1.4)) {
            trailProgress = 1.0
        }

        try? await Task.sleep(for: .milliseconds(1400))

        // Reached highest point — switch to blinking pose
        withAnimation(.easeInOut(duration: 0.35)) {
            showFlyingPose = false
        }

        // Gentle hover at top
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                hover = -8
            }
        }

        try? await Task.sleep(for: .milliseconds(500))

        // Stagger the staircase words
        exploreVisible = true
        try? await Task.sleep(for: .milliseconds(450))
        discoverVisible = true
        try? await Task.sleep(for: .milliseconds(450))
        fixWorldVisible = true

        try? await Task.sleep(for: .milliseconds(700))

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
            let startY = size.height * 0.75
            let endY = size.height * 0.20

            let path = Path { p in
                p.move(to: CGPoint(x: centerX, y: startY))
                p.addCurve(
                    to: CGPoint(x: centerX, y: endY),
                    control1: CGPoint(x: centerX - 30, y: startY - (startY - endY) * 0.3),
                    control2: CGPoint(x: centerX + 30, y: startY - (startY - endY) * 0.7)
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
