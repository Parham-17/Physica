import SwiftUI

struct OnboardingDarknessPage: View {
    var onComplete: () -> Void

    @State private var eyeVisible = false
    @State private var glowRadius: CGFloat = 0
    @State private var ellipsisCount = 0
    @State private var autoAdvanceTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            RadialGradient(
                colors: [Color.voltBlue.opacity(0.3), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: glowRadius
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                if eyeVisible {
                    Circle()
                        .fill(Color.voltBlue)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .fill(.white.opacity(0.75))
                                .frame(width: 10, height: 10)
                                .offset(x: -4, y: -4)
                        )
                        .shadow(color: .voltBlue, radius: 18)
                        .transition(.scale.combined(with: .opacity))
                }

                if ellipsisCount > 0 {
                    Text(String(repeating: ".", count: ellipsisCount))
                        .font(.gameTitle)
                        .foregroundStyle(.white.opacity(0.6))
                        .transition(.opacity)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onComplete() }
        .task { await runSequence() }
        .onDisappear { autoAdvanceTask?.cancel() }
    }

    private func runSequence() async {
        let delay: Duration = reduceMotion ? .milliseconds(300) : .milliseconds(1500)
        try? await Task.sleep(for: delay)

        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            eyeVisible = true
        }

        try? await Task.sleep(for: .milliseconds(600))

        withAnimation(.easeOut(duration: 1.5)) {
            glowRadius = 120
        }

        for i in 1...3 {
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.easeIn(duration: 0.2)) {
                ellipsisCount = i
            }
        }

        autoAdvanceTask = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled {
                await MainActor.run { onComplete() }
            }
        }
    }
}
