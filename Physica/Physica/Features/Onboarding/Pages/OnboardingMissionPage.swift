import SwiftUI

private enum SparkFlightPose {
    case side, up
}

struct OnboardingMissionPage: View {
    var onComplete: () -> Void

    @State private var sparkXOffset: CGFloat = 220
    @State private var sparkYOffset: CGFloat = 180
    @State private var pose: SparkFlightPose = .side
    @State private var hover: CGFloat = 0
    @State private var trailProgress: CGFloat = 0
    @State private var exploreVisible = false
    @State private var discoverVisible = false
    @State private var fixVisible = false
    @State private var worldVisible = false
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

            VStack(spacing: Spacing.md) {
                Spacer().frame(height: Spacing.xl)

                ZStack {
                    switch pose {
                    case .side:
                        Image("SparkFlyingSide")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180)
                            .transition(.opacity)
                    case .up:
                        Image("SparkFlyingUp")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160)
                            .transition(.opacity)
                    }
                }
                .offset(x: sparkXOffset, y: sparkYOffset + hover)
                .shadow(color: .voltBlue.opacity(0.4), radius: 25)

                Spacer()

                staircaseText
                    .padding(.horizontal, Spacing.lg)

                if subtitleVisible {
                    Text("Learn real physics by playing.")
                        .font(.bodyGame)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .padding(.top, Spacing.md)
                }

                Spacer().frame(height: Spacing.xl)
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
            HStack(spacing: 0) {
                Text("Explore.")
                    .font(.gameTitle)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .opacity(exploreVisible ? 1 : 0)
                    .offset(y: exploreVisible ? 0 : 12)
                Spacer(minLength: 0)
            }
            HStack(spacing: 0) {
                Color.clear.frame(width: 40, height: 1)
                Text("Discover.")
                    .font(.gameTitle)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .opacity(discoverVisible ? 1 : 0)
                    .offset(y: discoverVisible ? 0 : 12)
                Spacer(minLength: 0)
            }
            HStack(spacing: 0) {
                Color.clear.frame(width: 80, height: 1)
                Text("Fix the")
                    .font(.gameTitle)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .opacity(fixVisible ? 1 : 0)
                    .offset(y: fixVisible ? 0 : 12)
                Spacer(minLength: 0)
            }
            HStack(spacing: 0) {
                Color.clear.frame(width: 120, height: 1)
                Text("world.")
                    .font(.gameTitle)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .opacity(worldVisible ? 1 : 0)
                    .offset(y: worldVisible ? 0 : 12)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: exploreVisible)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: discoverVisible)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: fixVisible)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: worldVisible)
    }

    private func runSequence() async {
        try? await Task.sleep(for: .milliseconds(reduceMotion ? 200 : 400))

        // Spark zooms in diagonally from bottom-right using flying-side pose
        withAnimation(.easeOut(duration: 1.4)) {
            sparkXOffset = 0
            sparkYOffset = 80
        }

        // Start drawing the trail
        withAnimation(.easeInOut(duration: 2.8)) {
            trailProgress = 1.0
        }

        try? await Task.sleep(for: .milliseconds(1500))

        // Switch to upward-flying pose
        withAnimation(.easeInOut(duration: 0.35)) {
            pose = .up
        }

        try? await Task.sleep(for: .milliseconds(300))

        // Fly straight up to the top
        withAnimation(.easeInOut(duration: 1.5)) {
            sparkYOffset = -60
        }

        try? await Task.sleep(for: .milliseconds(1500))

        // Gentle hover at the top
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                hover = -10
            }
        }

        try? await Task.sleep(for: .milliseconds(600))

        // Reveal staircase words slowly so kids can read each one
        exploreVisible = true
        try? await Task.sleep(for: .milliseconds(900))
        discoverVisible = true
        try? await Task.sleep(for: .milliseconds(900))
        fixVisible = true
        try? await Task.sleep(for: .milliseconds(600))
        worldVisible = true

        try? await Task.sleep(for: .milliseconds(1200))

        withAnimation(.easeOut(duration: 0.6)) {
            subtitleVisible = true
        }

        // Auto-advance after giving kids plenty of time to read everything
        autoAdvanceTask = Task {
            try? await Task.sleep(for: .seconds(5))
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
            let startX = size.width * 0.72
            let startY = size.height * 0.65
            let midX = size.width * 0.5
            let midY = size.height * 0.45
            let endX = size.width * 0.5
            let endY = size.height * 0.18

            let path = Path { p in
                p.move(to: CGPoint(x: startX, y: startY))
                p.addQuadCurve(
                    to: CGPoint(x: midX, y: midY),
                    control: CGPoint(x: (startX + midX) / 2 + 30, y: (startY + midY) / 2)
                )
                p.addQuadCurve(
                    to: CGPoint(x: endX, y: endY),
                    control: CGPoint(x: midX - 30, y: (midY + endY) / 2)
                )
            }

            let trimmed = path.trimmedPath(from: 0, to: progress)
            context.stroke(
                trimmed,
                with: .color(.white.opacity(0.22)),
                style: StrokeStyle(lineWidth: 2, dash: [6, 5])
            )
        }
        .allowsHitTesting(false)
    }
}
