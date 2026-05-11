import SwiftUI

struct XPProgressBar: View {
    var progress: Double
    var height: CGFloat = 12
    var animateOnAppear: Bool = true

    @State private var displayedProgress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.voltBlue, Color.voltCopperBright],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * CGFloat(clamped(displayedProgress)))
                    .shadow(color: .voltBlue.opacity(0.5), radius: 6)
            }
        }
        .frame(height: height)
        .onAppear {
            let target = clamped(progress)
            if animateOnAppear && !reduceMotion {
                displayedProgress = 0
                withAnimation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.1)) {
                    displayedProgress = target
                }
            } else {
                displayedProgress = target
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                displayedProgress = clamped(newValue)
            }
        }
    }

    private func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

#Preview {
    VStack(spacing: 24) {
        XPProgressBar(progress: 0.0)
        XPProgressBar(progress: 0.35)
        XPProgressBar(progress: 0.85)
        XPProgressBar(progress: 1.0)
    }
    .padding(40)
    .background(Color.shadowDeep)
}
