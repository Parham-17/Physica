import SwiftUI

struct OnboardingSparkPage: View {
    var onComplete: () -> Void

    @State private var sparkVisible = false
    @State private var line1Visible = false
    @State private var line2Visible = false
    @State private var sparkExpression: SparkView.Expression = .curious
    @State private var autoAdvanceTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.08, blue: 0.14),
                    Color(red: 0.03, green: 0.04, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VoltCitySkylineView(allDark: true)
                .frame(height: 160)
                .opacity(0.4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 30)

            VStack(spacing: Spacing.lg) {
                Spacer()

                if sparkVisible {
                    SparkView(mode: .blue, expression: sparkExpression, size: 140)
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                }

                VStack(spacing: Spacing.sm) {
                    if line1Visible {
                        Text("I'm Spark.")
                            .font(.gameTitle)
                            .foregroundStyle(.white)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if line2Visible {
                        Text("Something's wrong.")
                            .font(.levelHeader)
                            .foregroundStyle(.white.opacity(0.7))
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }

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
        try? await Task.sleep(for: .milliseconds(reduceMotion ? 200 : 500))

        withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
            sparkVisible = true
        }

        try? await Task.sleep(for: .milliseconds(800))

        withAnimation(.easeOut(duration: 0.5)) {
            line1Visible = true
        }

        try? await Task.sleep(for: .milliseconds(800))

        withAnimation(.easeOut(duration: 0.5)) {
            line2Visible = true
            sparkExpression = .focused
        }

        autoAdvanceTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled {
                await MainActor.run { onComplete() }
            }
        }
    }
}
