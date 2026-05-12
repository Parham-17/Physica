import SwiftUI

/// Types a string out one character at a time at `charsPerSecond`.
///
/// Behavior:
/// - On appear (or when `text` changes): starts at 0 revealed, ticks up.
/// - When `completeImmediately` toggles to true: jumps to fully revealed.
/// - When the full text is shown, calls `onComplete()` once.
///
/// Respects `accessibilityReduceMotion` by skipping straight to fully revealed.
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
        while revealedCount < text.count {
            try? await Task.sleep(nanoseconds: interval)
            if completeImmediately {
                revealedCount = text.count
                break
            }
            if revealedCount < text.count {
                revealedCount += 1
            }
        }
        notifyComplete()
    }

    private func notifyComplete() {
        guard !hasNotifiedComplete else { return }
        hasNotifiedComplete = true
        onComplete()
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
