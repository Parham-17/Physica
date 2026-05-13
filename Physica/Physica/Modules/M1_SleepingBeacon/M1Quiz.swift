import SwiftUI
import UIKit

/// One multiple-choice question. Used by `M1QuizView`. Promote to `Core/Quiz/`
/// when M2+ also need quizzes.
struct QuizQuestion: Hashable {
    let prompt: String
    let options: [String]
    let correctIndex: Int
}

extension QuizQuestion {
    /// M1's transfer question — tests "things become visible only when light reaches them"
    /// (the Insight) by recasting it in a fresh scenario the player didn't just play.
    static let m1 = QuizQuestion(
        prompt: "Spark's lantern is off. The room is dark. What does Spark see?",
        options: [
            "The whole room",
            "Nothing",
            "Only what's near him"
        ],
        correctIndex: 1
    )
}

/// Post-module quiz overlay. Wrong answers shake the chosen option and let the
/// player retry — Level 1 cannot be failed (PIPELINE.md §11). On a correct
/// answer, calls `onCorrect(attempts:)` so the scene can award stars based on
/// how many attempts the player needed.
struct M1QuizView: View {
    let question: QuizQuestion
    let onCorrect: (_ attempts: Int) -> Void

    @State private var attempts: Int = 0
    @State private var wrongIndex: Int? = nil
    @State private var shake: CGFloat = 0

    var body: some View {
        ZStack {
            Color.realmDark.opacity(0.92).ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.sm) {
                    Text("Quick check")
                        .font(.hintCaption)
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(2)
                    Text(question.prompt)
                        .font(.levelHeader)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.md)
                }

                VStack(spacing: Spacing.sm) {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                        optionButton(text: option, index: index)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.xxl)
        }
        .transition(.opacity)
    }

    private func optionButton(text: String, index: Int) -> some View {
        Button {
            handleTap(index)
        } label: {
            HStack {
                Text(text)
                    .font(.bodyGame)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor(for: index))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor(for: index), lineWidth: 1.5)
                    )
            )
            .offset(x: wrongIndex == index ? shake : 0)
        }
        .buttonStyle(.plain)
    }

    private func backgroundColor(for index: Int) -> Color {
        if wrongIndex == index { return Color.red.opacity(0.18) }
        return Color.white.opacity(0.06)
    }

    private func borderColor(for index: Int) -> Color {
        if wrongIndex == index { return Color.red.opacity(0.55) }
        return Color.white.opacity(0.12)
    }

    private func handleTap(_ index: Int) {
        attempts += 1
        if index == question.correctIndex {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onCorrect(attempts)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            wrongIndex = index
            withAnimation(.easeInOut(duration: 0.07).repeatCount(4, autoreverses: true)) {
                shake = 8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                shake = 0
                wrongIndex = nil
            }
        }
    }
}

#Preview {
    M1QuizView(question: .m1) { _ in }
}
