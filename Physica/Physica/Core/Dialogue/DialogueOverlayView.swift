import SwiftUI

/// Bottom-28% dialogue overlay. Sits above gameplay, shows portrait + typewriter
/// text panel for the active beat. Tap anywhere advances the line (or completes
/// the typewriter if it's still typing).
///
/// Renders nothing when there's no active beat — `allowsHitTesting(false)` lets
/// taps pass through to the gameplay layer.
struct DialogueOverlayView: View {
    @Environment(DialogueController.self) private var controller

    var body: some View {
        if controller.activeBeat != nil {
            activeOverlay
        } else {
            Color.clear
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var activeOverlay: some View {
        if let beat = controller.activeBeat, let line = controller.currentLine {
            HStack(alignment: .bottom, spacing: Spacing.md) {
                portrait(for: beat)
                textPanel(line: line, beat: beat)
            }
            .padding(Spacing.md)
            .padding(.bottom, Spacing.lg)
            .background(panelBackground)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .contentShape(Rectangle())
            .onTapGesture { controller.advance() }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: beat.id)
        }
    }

    private func portrait(for beat: DialogueBeat) -> some View {
        SparkView(
            mode: .yellow,
            expression: sparkExpression(from: beat.expression),
            size: 96
        )
        .opacity(beat.speaker == .spark ? 1.0 : 0.2)
        .overlay {
            if beat.speaker == .umbra {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private func textPanel(line: String, beat: DialogueBeat) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            TypewriterText(
                text: line,
                completeImmediately: controller.isTypewriterComplete,
                onComplete: { controller.isTypewriterComplete = true }
            )
            HStack {
                Spacer()
                Image(systemName: controller.isLastLine ? "checkmark" : "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.realmMid.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var panelBackground: some View {
        LinearGradient(
            colors: [
                Color.realmDark.opacity(0),
                Color.realmDark.opacity(0.55),
                Color.realmDark.opacity(0.85)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false)
    }

    /// Best-effort mapping of V2 expression strings to current `SparkView.Expression`.
    /// Will be replaced when `Core/Character/SparkCharacter` adds the full V2 expression set.
    private func sparkExpression(from string: String) -> SparkView.Expression {
        switch string {
        case "idle": return .idle
        case "curious": return .curious
        case "alarmed", "steady": return .focused
        case "hopeful", "resolved": return .happy
        default: return .curious
        }
    }
}
