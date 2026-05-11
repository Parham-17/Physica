import SwiftUI

struct OnboardingSparkPage: View {
    var onComplete: () -> Void

    @State private var bodyRevealed = false
    @State private var sparkScale: CGFloat = 0.85
    @State private var line1Visible = false
    @State private var waveAngle: Double = -6
    @State private var hover: CGFloat = 0
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

                SparkAnimated(imageName: "SparkFrontHello", size: 200)
                    .scaleEffect(sparkScale)
                    .rotationEffect(.degrees(waveAngle), anchor: UnitPoint(x: 0.5, y: 0.85))
                    .offset(y: hover)
                    .shadow(color: .voltBlue.opacity(0.4), radius: 30)

                if line1Visible {
                    Text("Hello there! I'm Spark.")
                        .font(.gameTitle)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                Text("Tap to continue")
                    .font(.hintCaption)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.bottom, Spacing.xl)
                    .opacity(line1Visible ? 1 : 0)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard line1Visible else { return }
            onComplete()
        }
        .task { await runSequence() }
    }

    private func runSequence() async {
        try? await Task.sleep(for: .milliseconds(reduceMotion ? 200 : 400))

        // Spark enters with a gentle scale-up
        withAnimation(.spring(response: 0.9, dampingFraction: 0.75)) {
            sparkScale = 1.0
            bodyRevealed = true
        }

        // Hover loop
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                hover = -8
            }
            // Slow waving motion (rocking)
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                waveAngle = 6
            }
        } else {
            waveAngle = 0
        }

        try? await Task.sleep(for: .milliseconds(800))

        withAnimation(.easeOut(duration: 0.5)) {
            line1Visible = true
        }
    }
}
