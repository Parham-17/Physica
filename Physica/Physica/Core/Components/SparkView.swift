import SwiftUI

/// Spark — the robot character. Renders the team-designed SVG (`Spark.imageset`) with
/// SwiftUI animations layered on top: idle hover, halo pulse, subtle wobble, and
/// expression-driven scale + halo intensity.
///
/// Per-feature animation (eye blink, arm wave, mouth movement) requires either:
///   - separate sub-asset SVGs the designer can hand off, or
///   - a Rive file with a state machine.
/// Both are tracked in `docs/BACKLOG.md` as "Rive Character for Spark."
struct SparkView: View {
    /// `mode` controls the **halo color** around Spark, signalling which physics domain is active.
    /// The character's own colors (white body, cyan visor) stay constant — this is a backdrop tint.
    enum Mode {
        case yellow   // Light Realm — warm beacon halo
        case blue     // Volt City / Home — electric blue halo

        var glowColor: Color {
            switch self {
            case .yellow: return .beaconWarm
            case .blue: return .electricBlue
            }
        }
    }

    var mode: Mode = .blue
    var expression: SparkExpression = .idle
    var glow: GlowState = .stable
    var size: CGFloat = 80

    @State private var hover: CGFloat = 0
    @State private var halo: CGFloat = 1.0
    @State private var tilt: Double = 0
    @State private var bounce: CGFloat = 1.0   // for tap-feedback bounces
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let propellerAnchor = UnitPoint(x: 507.0 / 1024.0, y: 107.0 / 1024.0)

    var body: some View {
        ZStack {
            // Halo glow — softer behind the character
            Circle()
                .fill(mode.glowColor.opacity(haloOpacity))
                .frame(width: size * 1.65, height: size * 1.65)
                .blur(radius: size * 0.22)
                .scaleEffect(halo)
                .opacity(glow == .dim ? 0 : 1)

            // Spark = body + spinning propeller composite
            characterComposite
                .frame(width: size, height: size)
                .brightness(glow == .dim ? -0.35 : 0)
                .saturation(glow == .dim ? 0.25 : 1.0)
                .rotationEffect(.degrees(tilt))
                .scaleEffect(expressionScale * bounce)
                .animation(.spring(response: 0.35, dampingFraction: 0.55), value: expression)
        }
        .offset(y: hover)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Spark, the robot")
        .onAppear { startAnimations() }
        .onChange(of: expression) { _, _ in
            applyExpressionAnimations()
        }
        .onChange(of: glow) { _, _ in
            applyExpressionAnimations()
        }
    }

    @ViewBuilder
    private var characterComposite: some View {
        if reduceMotion || glow == .dim {
            Image(.spark)
                .resizable()
                .scaledToFit()
        } else {
            ZStack {
                Image(.sparkBody)
                    .resizable()
                    .scaledToFit()

                Image(.sparkPropeller)
                    .resizable()
                    .scaledToFit()
                    .modifier(PropellerSpin(
                        speed: propellerDegreesPerSecond,
                        anchor: Self.propellerAnchor
                    ))
            }
        }
    }

    private var propellerDegreesPerSecond: Double {
        switch expression {
        case .idle:     return 360
        case .curious:  return 450
        case .alarmed:  return 320
        case .hopeful:  return 540
        case .steady:   return 380
        case .resolved: return 480
        }
    }

    // MARK: - Tap bounce (callable from the parent)

    /// Plays a quick scale-bounce — useful when the level wants to acknowledge a tap.
    /// Call from a `.onTapGesture` along with whatever state change the tap triggers.
    func playTapBounce() {
        withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) {
            bounce = 0.88
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) {
                bounce = 1.0
            }
        }
    }

    // MARK: - Visual helpers

    private var haloOpacity: Double {
        switch glow {
        case .dim:    return 0.0
        case .warm:   return 0.30
        case .stable: return baseHaloByExpression
        case .bright: return min(baseHaloByExpression * 1.4, 0.65)
        }
    }

    private var baseHaloByExpression: Double {
        switch expression {
        case .idle:     return 0.30
        case .curious:  return 0.42
        case .alarmed:  return 0.22
        case .hopeful:  return 0.50
        case .steady:   return 0.34
        case .resolved: return 0.55
        }
    }

    private var expressionScale: CGFloat {
        switch expression {
        case .idle, .steady: return 1.0
        case .curious:       return 1.05
        case .alarmed:       return 0.96
        case .hopeful:       return 1.08
        case .resolved:      return 1.10
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else { return }
        // Idle hover (Y bob)
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            hover = -6
        }
        applyExpressionAnimations()
        // Subtle wobble — gives the character life
        withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
            tilt = 1.5
        }
    }

    private func applyExpressionAnimations() {
        guard !reduceMotion else { return }
        // Halo pulse — speed/amplitude varies by expression + glow
        let (duration, target): (Double, CGFloat) = {
            if glow == .dim { return (3.0, 1.0) }
            switch expression {
            case .curious:  return (0.85, 1.20)
            case .hopeful:  return (0.70, 1.18)
            case .resolved: return (0.60, 1.16)
            case .alarmed:  return (1.4,  1.06)
            case .steady:   return (2.0,  1.10)
            case .idle:     return (2.4,  1.08)
            }
        }()
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            halo = target
        }
    }
}

private struct PropellerSpin: ViewModifier {
    let speed: Double
    let anchor: UnitPoint

    func body(content: Content) -> some View {
        TimelineView(.animation) { context in
            let angle = context.date.timeIntervalSinceReferenceDate * speed
            content
                .rotationEffect(.degrees(angle), anchor: anchor)
                .rotation3DEffect(
                    .degrees(70),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: anchor,
                    perspective: 0.3
                )
        }
    }
}

#Preview("Spark — expressions") {
    VStack(spacing: 40) {
        HStack(spacing: 24) {
            ForEach(SparkExpression.allCases, id: \.self) { expr in
                VStack(spacing: 8) {
                    SparkView(mode: .blue, expression: expr, size: 70)
                    Text(expr.rawValue).font(.caption).foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        HStack(spacing: 30) {
            VStack {
                SparkView(mode: .yellow, expression: .curious, glow: .dim, size: 110)
                Text("dim / curious").font(.caption).foregroundStyle(.white.opacity(0.6))
            }
            VStack {
                SparkView(mode: .yellow, expression: .hopeful, glow: .warm, size: 110)
                Text("warm / hopeful").font(.caption).foregroundStyle(.white.opacity(0.6))
            }
            VStack {
                SparkView(mode: .yellow, expression: .resolved, glow: .bright, size: 110)
                Text("bright / resolved").font(.caption).foregroundStyle(.white.opacity(0.6))
            }
        }
    }
    .padding(40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.realmDark)
}
