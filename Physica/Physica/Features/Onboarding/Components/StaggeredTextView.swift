import SwiftUI

struct StaggeredTextView: View {
    let words: [String]
    var font: Font = .levelHeader
    var color: Color = .white
    var delayBetween: Double = 0.35
    var trigger: Bool

    @State private var visibleCount: Int = 0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                Text(word)
                    .font(font)
                    .foregroundStyle(color)
                    .opacity(index < visibleCount ? 1 : 0)
                    .offset(y: index < visibleCount ? 0 : 12)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7),
                        value: visibleCount
                    )
            }
        }
        .onChange(of: trigger) { _, newValue in
            if newValue { revealWords() }
        }
    }

    private func revealWords() {
        for i in 0..<words.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + delayBetween * Double(i)) {
                withAnimation {
                    visibleCount = i + 1
                }
            }
        }
    }
}
