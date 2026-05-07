import SwiftUI

struct SparkView: View {
    enum Mode {
        case yellow, blue

        var eyeColor: Color {
            switch self {
            case .yellow: return .torchYellow
            case .blue: return .voltBlue
            }
        }

        var glowColor: Color {
            switch self {
            case .yellow: return .torchWarm
            case .blue: return .voltBlue
            }
        }
    }

    enum Expression {
        case idle, curious, focused, happy
    }

    var mode: Mode = .blue
    var expression: Expression = .idle
    var size: CGFloat = 80

    @State private var hover: CGFloat = 0
    @State private var pulse: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .fill(mode.glowColor.opacity(expression == .happy ? 0.55 : 0.32))
                .frame(width: size * 1.7, height: size * 1.7)
                .blur(radius: size * 0.22)
                .scaleEffect(pulse)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.voltCopperBright, Color.voltCopper.opacity(0.75)],
                        center: UnitPoint(x: 0.32, y: 0.28),
                        startRadius: 0,
                        endRadius: size
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle().stroke(.white.opacity(0.18), lineWidth: 1)
                )

            Circle()
                .fill(mode.eyeColor)
                .frame(width: size * 0.46, height: size * 0.46)
                .overlay(
                    Circle()
                        .fill(.white.opacity(0.75))
                        .frame(width: size * 0.13, height: size * 0.13)
                        .offset(x: -size * 0.07, y: -size * 0.07)
                )
                .shadow(color: mode.glowColor, radius: size * 0.18)
                .scaleEffect(eyeScale)
                .animation(.easeInOut(duration: 0.3), value: expression)
        }
        .offset(y: hover)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Spark, the robot")
        .onAppear { startAnimations() }
    }

    private var eyeScale: CGFloat {
        switch expression {
        case .idle: return 1.0
        case .curious: return 1.18
        case .focused: return 0.85
        case .happy: return 1.05
        }
    }

    private func startAnimations() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            hover = -6
        }
        if expression == .curious {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = 1.18
            }
        } else {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulse = 1.05
            }
        }
    }
}

#Preview("Spark — modes") {
    HStack(spacing: 40) {
        SparkView(mode: .yellow, expression: .curious)
        SparkView(mode: .blue, expression: .idle)
        SparkView(mode: .blue, expression: .happy, size: 120)
    }
    .padding(40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.shadowDeep)
}
