import SwiftUI

struct OnboardingBrokenPage: View {
    var onComplete: () -> Void

    @State private var line1Visible = false
    @State private var line2Visible = false
    @State private var glitchActive = false
    @State private var autoAdvanceTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.shadowDeep, Color(red: 0.08, green: 0.12, blue: 0.28)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                LinearGradient(
                    colors: [Color(red: 0.12, green: 0.14, blue: 0.26), Color(red: 0.20, green: 0.14, blue: 0.08)],
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
                    Text("The laws of physics are breaking.")
                        .font(.levelHeader)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                SparkView(mode: .blue, expression: .focused, size: 60)

                if line2Visible {
                    Text("Light. Electricity. All failing.")
                        .font(.bodyGame)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
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
        try? await Task.sleep(for: .milliseconds(reduceMotion ? 200 : 600))

        withAnimation(.easeOut(duration: 0.5)) {
            line1Visible = true
        }

        try? await Task.sleep(for: .milliseconds(500))

        withAnimation(.easeIn(duration: 0.3)) {
            glitchActive = true
        }

        try? await Task.sleep(for: .milliseconds(800))

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
