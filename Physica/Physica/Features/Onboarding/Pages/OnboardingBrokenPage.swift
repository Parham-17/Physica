import SwiftUI

struct OnboardingBrokenPage: View {
    var onComplete: () -> Void

    @State private var sparkPosition: CGFloat = 300
    @State private var sparkVisible = false
    @State private var line1Visible = false
    @State private var glitchActive = false
    @State private var hover: CGFloat = 0
    @State private var autoAdvanceTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.realmDark, Color(red: 0.08, green: 0.12, blue: 0.28)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                LinearGradient(
                    colors: [
                        Color(red: 0.03, green: 0.04, blue: 0.08),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()

            if glitchActive {
                GlitchOverlayView()
                    .transition(.opacity)
            }

            VStack(spacing: Spacing.xl) {
                Spacer()

                if line1Visible {
                    Text("The laws of physics\nare breaking.")
                        .font(.gameTitle)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if sparkVisible {
                    SparkAnimated(imageName: "SparkFrontWow", size: 120)
                        .offset(x: sparkPosition, y: hover)
                        .shadow(color: .electricBlue.opacity(0.3), radius: 20)
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

    private func runSequence() async {
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                hover = -6
            }
        }

        try? await Task.sleep(for: .milliseconds(reduceMotion ? 200 : 400))

        sparkVisible = true
        withAnimation(.spring(response: 0.8, dampingFraction: 0.65)) {
            sparkPosition = 0
        }

        try? await Task.sleep(for: .milliseconds(700))

        withAnimation(.easeOut(duration: 0.5)) {
            line1Visible = true
        }

        try? await Task.sleep(for: .milliseconds(400))

        withAnimation(.easeIn(duration: 0.3)) {
            glitchActive = true
        }

        autoAdvanceTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled {
                await MainActor.run { onComplete() }
            }
        }
    }
}
