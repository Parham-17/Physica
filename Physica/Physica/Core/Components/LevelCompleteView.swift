import SwiftUI

struct LevelCompleteView: View {
    let stars: Int
    let conceptLearned: String
    var onContinue: () -> Void

    @State private var animatedStars: Int = 0
    @State private var showConcept: Bool = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Text("Level Complete")
                .font(.gameTitle)
                .foregroundStyle(.white)

            HStack(spacing: Spacing.sm) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < animatedStars ? "star.fill" : "star")
                        .font(.system(size: 52))
                        .foregroundStyle(i < animatedStars ? Color.voltYellow : Color.white.opacity(0.25))
                        .scaleEffect(i < animatedStars ? 1.0 : 0.7)
                }
            }
            .accessibilityLabel("\(stars) out of 3 stars")

            if showConcept {
                VStack(spacing: Spacing.xs) {
                    Text("You've learned")
                        .font(.bodyGame)
                        .foregroundStyle(.white.opacity(0.55))
                    Text(conceptLearned)
                        .font(.levelHeader)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.levelHeader)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.voltBlue, in: Capsule())
                    .foregroundStyle(.white)
                    .shadow(color: .voltBlue.opacity(0.4), radius: 12)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.shadowDeep.ignoresSafeArea())
        .task { runReveal() }
    }

    private func runReveal() {
        for i in 0..<stars {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.4) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    animatedStars = i + 1
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(max(stars, 1)) * 0.4 + 0.3) {
            withAnimation(.easeIn(duration: 0.5)) {
                showConcept = true
            }
        }
    }
}

#Preview {
    LevelCompleteView(
        stars: 3,
        conceptLearned: "Light reveals what it touches.",
        onContinue: {}
    )
}
