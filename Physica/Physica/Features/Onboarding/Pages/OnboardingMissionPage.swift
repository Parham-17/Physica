import SwiftUI

private enum SparkFlightPose {
    case side, up
}

struct OnboardingMissionPage: View {
    var onComplete: () -> Void

    // Spark position as a fraction of screen size, animated through the flight
    @State private var sparkFraction: CGPoint = CGPoint(x: 0.85, y: 0.78)
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

    // Waypoints (fractions of screen size). Trail and Spark animation share these.
    private let startPoint = CGPoint(x: 0.95, y: 0.78)   // off-screen bottom-right
    private let midPoint   = CGPoint(x: 0.50, y: 0.55)   // mid-screen, where pose switches
    private let topPoint   = CGPoint(x: 0.50, y: 0.18)   // top hover position

    var body: some View {
        GeometryReader { proxy in
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

                JourneyTrail(
                    progress: trailProgress,
                    start: startPoint,
                    mid: midPoint,
                    end: topPoint
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Text layer pinned to the bottom half
                VStack {
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

                    Spacer().frame(height: Spacing.xxl)
                }
                .padding(.horizontal, Spacing.lg)

                // Spark, positioned absolutely on top
                sparkView
                    .position(
                        x: proxy.size.width * sparkFraction.x,
                        y: proxy.size.height * sparkFraction.y + hover
                    )
                    .shadow(color: .voltBlue.opacity(0.4), radius: 25)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onComplete() }
        .task { await runSequence() }
        .onDisappear { autoAdvanceTask?.cancel() }
    }

    @ViewBuilder
    private var sparkView: some View {
        switch pose {
        case .side:
            Image("SparkFlyingSide")
                .resizable()
                .scaledToFit()
                .frame(width: 190)
                .transition(.opacity)
        case .up:
            Image("SparkFlyingUp")
                .resizable()
                .scaledToFit()
                .frame(width: 170)
                .transition(.opacity)
        }
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
        // Initialize Spark at start point
        sparkFraction = startPoint

        try? await Task.sleep(for: .milliseconds(reduceMotion ? 200 : 400))

        // Phase 1: fly diagonally from bottom-right to mid-point (side pose)
        withAnimation(.easeOut(duration: 1.5)) {
            sparkFraction = midPoint
        }
        withAnimation(.easeInOut(duration: 2.8)) {
            trailProgress = 1.0
        }

        try? await Task.sleep(for: .milliseconds(1600))

        // Phase 2: switch to upward pose
        withAnimation(.easeInOut(duration: 0.35)) {
            pose = .up
        }

        try? await Task.sleep(for: .milliseconds(300))

        // Phase 3: fly straight up to the top
        withAnimation(.easeInOut(duration: 1.4)) {
            sparkFraction = topPoint
        }

        try? await Task.sleep(for: .milliseconds(1400))

        // Hover at top
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                hover = -10
            }
        }

        try? await Task.sleep(for: .milliseconds(600))

        // Reveal staircase words slowly
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
    var start: CGPoint
    var mid: CGPoint
    var end: CGPoint

    var body: some View {
        Canvas { context, size in
            let s = CGPoint(x: start.x * size.width, y: start.y * size.height)
            let m = CGPoint(x: mid.x * size.width,   y: mid.y * size.height)
            let e = CGPoint(x: end.x * size.width,   y: end.y * size.height)

            let path = Path { p in
                p.move(to: s)
                p.addQuadCurve(
                    to: m,
                    control: CGPoint(x: (s.x + m.x) / 2 + 40, y: (s.y + m.y) / 2 - 20)
                )
                p.addQuadCurve(
                    to: e,
                    control: CGPoint(x: m.x - 20, y: (m.y + e.y) / 2)
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
