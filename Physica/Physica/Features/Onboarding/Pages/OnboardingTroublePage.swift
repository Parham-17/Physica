import SwiftUI

struct OnboardingTroublePage: View {
    var onComplete: () -> Void

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
                .opacity(0.35)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 30)

            VStack(spacing: Spacing.lg) {
                Spacer()

                SparkAnimated(imageName: "SparkFrontHappy", size: 200)
                    .offset(y: hover)
                    .shadow(color: .electricBlue.opacity(0.4), radius: 30)

                VStack(spacing: Spacing.sm) {
                    if line1Visible {
                        Text("Something's wrong with my world.")
                            .font(.levelHeader)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if line2Visible {
                        Text("I need your help.")
                            .font(.gameTitle)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, Spacing.lg)
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
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                hover = -8
            }
        }

        try? await Task.sleep(for: .milliseconds(reduceMotion ? 200 : 500))

        withAnimation(.easeOut(duration: 0.5)) {
            line1Visible = true
        }

        try? await Task.sleep(for: .milliseconds(900))

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
