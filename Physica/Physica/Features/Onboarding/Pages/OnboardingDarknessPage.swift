import SwiftUI

struct OnboardingDarknessPage: View {
    var onComplete: () -> Void

    @State private var sparkVisible = false
    @State private var sparkScale: CGFloat = 2.5
    @State private var glowRadius: CGFloat = 0
    @State private var lookOffset: CGFloat = 0
    @State private var showBlink = false
    @State private var autoAdvanceTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            RadialGradient(
                colors: [Color.voltBlue.opacity(0.25), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: glowRadius
            )
            .ignoresSafeArea()

            if sparkVisible {
                Image(showBlink ? "SparkFrontBlinking" : "SparkFrontWow")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220)
                    .scaleEffect(sparkScale)
                    .offset(x: lookOffset)
                    .mask(
                        RadialGradient(
                            colors: [.white, .white, .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: glowRadius
                        )
                    )
                    .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onComplete() }
        .task { await runSequence() }
        .onDisappear { autoAdvanceTask?.cancel() }
    }

    private func runSequence() async {
        let baseDelay: Duration = reduceMotion ? .milliseconds(300) : .milliseconds(1200)
        try? await Task.sleep(for: baseDelay)

        withAnimation(.easeIn(duration: 0.8)) {
            sparkVisible = true
            glowRadius = 60
        }

        try? await Task.sleep(for: .milliseconds(1000))

        withAnimation(.easeOut(duration: 1.0)) {
            glowRadius = 180
        }

        try? await Task.sleep(for: .milliseconds(600))

        // Look left
        withAnimation(.easeInOut(duration: 0.6)) {
            lookOffset = -15
        }
        try? await Task.sleep(for: .milliseconds(700))

        // Blink
        withAnimation(.easeInOut(duration: 0.15)) {
            showBlink = true
        }
        try? await Task.sleep(for: .milliseconds(200))
        withAnimation(.easeInOut(duration: 0.15)) {
            showBlink = false
        }

        try? await Task.sleep(for: .milliseconds(400))

        // Look right
        withAnimation(.easeInOut(duration: 0.6)) {
            lookOffset = 15
        }
        try? await Task.sleep(for: .milliseconds(800))

        // Center
        withAnimation(.easeInOut(duration: 0.4)) {
            lookOffset = 0
        }

        autoAdvanceTask = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled {
                await MainActor.run { onComplete() }
            }
        }
    }
}
