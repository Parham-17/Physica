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
    @State private var showFeedback: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Spacer()

            if let symbol = question.illustrationSymbol {
                Image(systemName: symbol)
                    .font(.system(size: 64))
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Text(question.prompt)
                .font(.levelHeader)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)

            VStack(spacing: Spacing.sm) {
                ForEach(question.options.indices, id: \.self) { i in
                    optionButton(index: i)
                }
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.shadowDeep.ignoresSafeArea())
    }

    @ViewBuilder
    private func optionButton(index: Int) -> some View {
        Button {
            select(index)
        } label: {
            HStack {
                Text(question.options[index])
                    .font(.bodyGame)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                Spacer()
                if showFeedback && selectedIndex == index {
                    Image(systemName: index == question.correctIndex ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(index == question.correctIndex ? Color.green : Color.red)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(selectedIndex == index ? 0.18 : 0.08))
            )
        }
        .buttonStyle(.plain)
        .disabled(showFeedback)
    }

    private func select(_ index: Int) {
        selectedIndex = index
        withAnimation { showFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if index == question.correctIndex {
                onCorrect()
            } else {
                onWrong()
            }
        }
    }
}

#Preview {
    PostLevelTestView(
        question: PostLevelTestQuestion(
            prompt: "Spark's eye is off. The cave is dark. Spark walks forward.\nWhat does Spark see?",
            options: ["The whole cave", "Nothing", "Only the floor"],
            correctIndex: 1,
            illustrationSymbol: "moon.stars.fill"
        ),
        onCorrect: {},
        onWrong: {}
    )
}
