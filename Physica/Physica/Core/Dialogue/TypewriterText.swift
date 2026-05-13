import SwiftUI
import UIKit

/// Types a string out one character at a time at `charsPerSecond`, firing a
/// subtle haptic at each word boundary so the dialogue feels alive in hand.
///
/// Behavior:
/// - On appear (or when `text` changes): starts at 0 revealed, ticks up.
/// - When `completeImmediately` toggles to true: jumps to fully revealed.
/// - When the full text is shown, calls `onComplete()` once.
///
/// Respects `accessibilityReduceMotion` by skipping the typewriter AND haptics.
struct TypewriterText: View {
    let text: String
    var charsPerSecond: Double = 35
    var completeImmediately: Bool = false
    var onComplete: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealedCount: Int = 0
    @State private var hasNotifiedComplete: Bool = false

    var body: some View {
        Text(visible)
            .font(.bodyGame)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear { restart() }
            .onChange(of: text) { _, _ in restart() }
            .onChange(of: completeImmediately) { _, complete in
                if complete { revealAll() }
            }
            .task(id: text) {
                await tick()
            }
    }

    private var visible: String {
        String(text.prefix(revealedCount))
    }

    private var wordStartIndices: Set<Int> {
        Self.wordStartIndices(in: text)
    }

    private func restart() {
        revealedCount = reduceMotion ? text.count : 0
        hasNotifiedComplete = false
        if reduceMotion { notifyComplete() }
    }

    private func revealAll() {
        revealedCount = text.count
        notifyComplete()
    }

    private func tick() async {
        guard !reduceMotion, charsPerSecond > 0 else { return }
        let interval = UInt64(1_000_000_000 / charsPerSecond)
        let starts = wordStartIndices
        while revealedCount < text.count {
            try? await Task.sleep(nanoseconds: interval)
            if completeImmediately {
                revealedCount = text.count
                break
            }
            if revealedCount < text.count {
                revealedCount += 1
                if starts.contains(revealedCount - 1) {
                    fireWordHaptic()
                }
            }
        }
        notifyComplete()
    }

    private func notifyComplete() {
        guard !hasNotifiedComplete else { return }
        hasNotifiedComplete = true
        onComplete()
    }

    private func fireWordHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred(intensity: 0.35)
    }

    /// Indices in `text` that begin a new word (letter/digit preceded by a non-word char or string start).
    private static func wordStartIndices(in text: String) -> Set<Int> {
        var indices: Set<Int> = []
        var inWord = false
        for (i, char) in text.enumerated() {
            let isWordChar = char.isLetter || char.isNumber
            if isWordChar && !inWord {
                indices.insert(i)
                inWord = true
            } else if !isWordChar {
                inWord = false
            }
        }
        return indices
    }
}

#Preview {
    VStack(spacing: 24) {
        TypewriterText(text: "Where am I? It is so dark.")
        TypewriterText(text: "When light touches something here, it remembers how to wake up.")
    }
    .padding()
    .background(Color.realmDark)
}
