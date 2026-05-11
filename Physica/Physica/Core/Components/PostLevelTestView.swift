import SwiftUI

struct PostLevelTestQuestion {
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let illustrationSymbol: String?
}

struct PostLevelTestView: View {
    let question: PostLevelTestQuestion
    var onCorrect: () -> Void
    var onWrong: () -> Void

    @State private var selectedIndex: Int? = nil
    @State private var revealResult: Bool = false
    @State private var cardScale: CGFloat = 0.92
    @State private var cardOpacity: Double = 0
    @State private var wrongShake: CGFloat = 0

    var body: some View {
        ZStack {
            // Background — soft gradient, subtle particles for life
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.07, blue: 0.16),
                    Color(red: 0.10, green: 0.10, blue: 0.22)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Spacer()

                // Section label
                Text("CHECKPOINT")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.torchYellow.opacity(0.9))

                // Card
                VStack(spacing: Spacing.lg) {
                    illustration

                    Text(question.prompt)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Spacing.sm)

                    VStack(spacing: Spacing.sm) {
                        ForEach(question.options.indices, id: \.self) { i in
                            optionButton(index: i)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.xl)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                )
                .padding(.horizontal, Spacing.lg)
                .scaleEffect(cardScale)
                .opacity(cardOpacity)
                .offset(x: wrongShake)

                // Feedback caption
                if revealResult {
                    feedbackCaption
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                cardScale = 1
                cardOpacity = 1
            }
        }
    }

    // MARK: - Illustration

    @ViewBuilder
    private var illustration: some View {
        if let symbol = question.illustrationSymbol {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.torchYellow.opacity(0.35), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: symbol)
                    .font(.system(size: 54, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .torchYellow.opacity(0.5), radius: 14)
            }
            .padding(.top, Spacing.sm)
        }
    }

    // MARK: - Option buttons

    @ViewBuilder
    private func optionButton(index: Int) -> some View {
        let isSelected = selectedIndex == index
        let isCorrect = revealResult && index == question.correctIndex
        let isWrongPick = revealResult && isSelected && index != question.correctIndex

        Button {
            select(index)
        } label: {
            HStack(spacing: Spacing.sm) {
                Text(letterFor(index))
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 26, height: 26)
                    .background(
                        Circle().fill(Color.white.opacity(0.10))
                            .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                    )

                Text(question.options[index])
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.green)
                } else if isWrongPick {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.red)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(buttonBackground(isSelected: isSelected, isCorrect: isCorrect, isWrongPick: isWrongPick))
        }
        .buttonStyle(.plain)
        .disabled(revealResult)
        .scaleEffect(isSelected && !revealResult ? 0.98 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }

    private func buttonBackground(isSelected: Bool, isCorrect: Bool, isWrongPick: Bool) -> some View {
        let fill: Color
        let stroke: Color
        if isCorrect {
            fill = Color.green.opacity(0.20)
            stroke = Color.green.opacity(0.75)
        } else if isWrongPick {
            fill = Color.red.opacity(0.18)
            stroke = Color.red.opacity(0.70)
        } else if isSelected {
            fill = Color.white.opacity(0.15)
            stroke = Color.torchYellow.opacity(0.55)
        } else {
            fill = Color.white.opacity(0.07)
            stroke = Color.white.opacity(0.12)
        }
        return RoundedRectangle(cornerRadius: 16)
            .fill(fill)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(stroke, lineWidth: 1.5))
    }

    private func letterFor(_ index: Int) -> String {
        ["A", "B", "C", "D", "E"][index]
    }

    // MARK: - Feedback caption

    @ViewBuilder
    private var feedbackCaption: some View {
        let correct = selectedIndex == question.correctIndex
        HStack(spacing: Spacing.sm) {
            Image(systemName: correct ? "sparkles" : "arrow.counterclockwise")
                .foregroundStyle(correct ? Color.green : Color.torchYellow)
            Text(correct ? "Nice — light only reaches what it touches." : "Not quite — let's try again.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
        )
    }

    // MARK: - Selection

    private func select(_ index: Int) {
        guard !revealResult else { return }
        selectedIndex = index

        // Brief pause so the user sees their pick highlighted
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.3)) {
                revealResult = true
            }
            if index != question.correctIndex {
                triggerShake()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { onWrong() }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { onCorrect() }
            }
        }
    }

    private func triggerShake() {
        let pattern: [CGFloat] = [-10, 10, -7, 7, -3, 3, 0]
        for (i, dx) in pattern.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation(.easeInOut(duration: 0.05)) {
                    wrongShake = dx
                }
            }
        }
    }
}

#Preview {
    PostLevelTestView(
        question: PostLevelTestQuestion(
            prompt: "Spark walks through a dark cave with his flashlight off.\nWhat can Spark see?",
            options: ["The whole cave", "Nothing", "Only the floor"],
            correctIndex: 1,
            illustrationSymbol: "moon.stars.fill"
        ),
        onCorrect: {},
        onWrong: {}
    )
}
