import SwiftUI

struct OnboardingSparkPage: View {
    var onComplete: () -> Void

    @State private var sparkScale: CGFloat = 2.2
    @State private var sparkOffset: CGFloat = 0
    @State private var bodyRevealed = false
    @State private var line1Visible = false
    @State private var line2Visible = false
    @State private var hover: CGFloat = 0
    @State private var autoAdvanceTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.03, blue: 0.08),
                    Color(red: 0.06, green: 0.08, blue: 0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VoltCitySkylineView(allDark: true)
                .frame(height: 160)
                .opacity(bodyRevealed ? 0.35 : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 30)

            VStack(spacing: Spacing.lg) {
                Spacer()

                Image("SparkFrontHappy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .scaleEffect(sparkScale)
                    .offset(y: sparkOffset + hover)
                    .shadow(color: .voltBlue.opacity(0.4), radius: 30)

                VStack(spacing: Spacing.sm) {
                    if line1Visible {
                        Text("Hello there! I'm Spark.")
                            .font(.gameTitle)
                            .foregroundStyle(.white)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if line2Visible {
                        Text("Something's wrong with my world...")
                            .font(.levelHeader)
                            .foregroundStyle(.white.opacity(0.7))
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.top, Spacing.md)

                Spacer()
                Spacer()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onComplete() }
        .task { await runSequence() }
        .onDisappear { autoAdvanceTask?.cancel() }
    }

    private func runSequence() async {
        try? await Task.sleep(for: .milliseconds(reduceMotion ? 200 : 400))

        // Spark zooms out from close-up to reveal full body
        withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
            sparkScale = 1.0
            sparkOffset = 0
            bodyRevealed = true
        }

        // Start hover loop
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                hover = -8
            }
        }

        try? await Task.sleep(for: .milliseconds(1200))

        withAnimation(.easeOut(duration: 0.5)) {
            line1Visible = true
        }

        try? await Task.sleep(for: .milliseconds(1000))

        withAnimation(.easeOut(duration: 0.5)) {
            line2Visible = true
        }

        autoAdvanceTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled {
                await MainActor.run { onComplete() }
            }
        }
    }
}
