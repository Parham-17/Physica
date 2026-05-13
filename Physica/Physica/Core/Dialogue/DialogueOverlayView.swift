import SwiftUI

/// Dialogue overlay. Spark (or Umbra) enters from the bottom-right corner with
/// a static portrait; the text panel slides in to its left, in front of Spark.
/// Tap anywhere advances the line (or completes the typewriter if it's still typing).
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
            ZStack(alignment: .bottomTrailing) {
                Color.black.opacity(0.001)  // capture taps across full overlay
                    .contentShape(Rectangle())
                    .onTapGesture { controller.advance() }

                HStack(alignment: .bottom, spacing: -28) {
                    textPanel(line: line, beat: beat)
                    portrait(for: beat)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.lg)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.55, dampingFraction: 0.85), value: beat.id)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private func portrait(for beat: DialogueBeat) -> some View {
        let expression = SparkExpression(rawValue: beat.expression) ?? .idle
        return ZStack {
            Circle()
                .fill(Color.beaconWarm.opacity(beat.speaker == .spark ? 0.45 : 0))
                .frame(width: 140, height: 140)
                .blur(radius: 22)

            if beat.speaker == .spark {
                Image(portraitAssetName(for: expression))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .accessibilityHidden(true)
            } else {
                // Umbra placeholder — silent figure, hidden face.
                Circle()
                    .fill(Color.realmMid)
                    .frame(width: 110, height: 110)
                    .overlay(
                        Image(systemName: "questionmark")
                            .font(.system(size: 38, weight: .light))
                            .foregroundStyle(.white.opacity(0.7))
                    )
            }
        }
        .padding(.trailing, 8)
        .padding(.bottom, 4)
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
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(Spacing.md)
        .padding(.trailing, Spacing.lg + 14)   // leave room for the Spark portrait overlap
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.realmMid.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
        )
        .padding(.bottom, 24)
    }

    /// Static portrait imageset to use for a given expression. These shipped with
    /// the original Spark design and are distinct from the animated `SparkView`
    /// used in puzzle gameplay — so the dialogue Spark is visually different
    /// from the puzzle Spark.
    private func portraitAssetName(for expression: SparkExpression) -> String {
        switch expression {
        case .idle:     return "SparkFrontHello"
        case .curious:  return "SparkFrontHelloArm"
        case .alarmed:  return "SparkFrontWow"
        case .hopeful:  return "SparkFrontHappy"
        case .steady:   return "SparkFrontHello"
        case .resolved: return "SparkFrontHappy"
        }
    }
}
