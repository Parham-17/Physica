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
        case yellow   // Shadow Realm — warm torch halo
        case blue     // Volt City / Hub — electric blue halo

        var glowColor: Color {
            switch self {
            case .yellow: return .beaconWarm
            case .blue: return .electricBlue
            }
        }
    }

    /// Drives subtle character behavior — scale, halo intensity, wobble — to convey state.
    enum Expression {
        case idle      // default — gentle hover + halo pulse
        case curious   // slightly larger + faster halo (used pre-tap on L1)
        case focused   // slightly smaller + dimmer halo (concentrating)
        case happy     // larger + brighter halo (discovery, win)
        case dim       // pre-light state — desaturated, no halo (Shadow Realm dark phase)
    }

    var mode: Mode = .blue
    var expression: Expression = .idle
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
                .opacity(expression == .dim ? 0 : 1)

            // Spark = body + spinning propeller composite
            characterComposite
                .frame(width: size, height: size)
                .brightness(expression == .dim ? -0.35 : 0)
                .saturation(expression == .dim ? 0.25 : 1.0)
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
    }

    @ViewBuilder
    private var characterComposite: some View {
        if reduceMotion || expression == .dim {
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
        case .idle:    return 360
        case .curious: return 450
        case .focused: return 300
        case .happy:   return 600
        case .dim:     return 0
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
        switch expression {
        case .dim:     return 0.0
        case .focused: return 0.20
        case .idle:    return 0.30
        case .curious: return 0.42
        case .happy:   return 0.55
        }
    }

    private var expressionScale: CGFloat {
        switch expression {
        case .dim:     return 1.0
        case .idle:    return 1.0
        case .curious: return 1.05
        case .focused: return 0.96
        case .happy:   return 1.08
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
        // Halo pulse — speed/amplitude varies by expression
        let (duration, target): (Double, CGFloat) = {
            switch expression {
            case .curious: return (0.85, 1.20)
            case .happy:   return (0.65, 1.18)
            case .focused: return (3.0,  1.04)
            case .dim:     return (3.0,  1.0)
            case .idle:    return (2.4,  1.08)
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
        HStack(spacing: 30) {
            ForEach([
                ("idle",    SparkView.Expression.idle),
                ("curious", SparkView.Expression.curious),
                ("focused", SparkView.Expression.focused),
                ("happy",   SparkView.Expression.happy),
                ("dim",     SparkView.Expression.dim)
            ], id: \.0) { label, expr in
                VStack(spacing: 8) {
                    SparkView(mode: .blue, expression: expr, size: 70)
                    Text(label).font(.caption).foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        HStack(spacing: 40) {
            VStack {
                SparkView(mode: .yellow, expression: .curious, size: 110)
                Text("yellow / curious").font(.caption).foregroundStyle(.white.opacity(0.6))
            }
            VStack {
                SparkView(mode: .blue, expression: .happy, size: 110)
                Text("blue / happy").font(.caption).foregroundStyle(.white.opacity(0.6))
            }
        }
    }
    .padding(40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.realmDark)
}
