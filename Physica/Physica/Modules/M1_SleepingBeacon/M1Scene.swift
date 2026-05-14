import SwiftUI
import SwiftData
import UIKit
import CoreHaptics

/// M1 Sleeping Beacon — greybox SwiftUI scene.
///
/// Layout: gate at the very top; three receiver crystals scattered in the upper
/// half (one of them obstructed by the central pillar); Spark a faint silhouette
/// at the lower-left; lantern fixed at the bottom-center. The player drags
/// anywhere in the play area to aim the beam in that direction, and must hold
/// the beam on each target long enough to "charge" it.
struct M1Scene: View {
    @State private var coordinator = M1Coordinator()
    @State private var hasDraggedYet = false
    @State private var chargingHaptics = ChargingHaptic()
    @Environment(DialogueController.self) private var dialogue
    @Environment(NarrativeFlags.self) private var flags
    @Environment(AppRouter.self) private var router
    @Environment(AudioManager.self) private var audio
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                ZStack {
                    Color.realmDark.ignoresSafeArea()

                    beaconColumn(in: proxy.size)
                    blockerViews(in: proxy.size)
                    receiverViews(in: proxy.size)
                    chargeRings(in: proxy.size)

                    if isPuzzlePhase {
                        beamPath(in: proxy.size)
                        sparkView(in: proxy.size)
                        lanternView(in: proxy.size)
                    } else {
                        sparkWalkingView(in: proxy.size)
                    }

                    if shouldShowAimHint {
                        aimHintView(in: proxy.size)
                    }
                }
                .contentShape(Rectangle())
                .gesture(aimDragGesture(in: proxy.size))
            }

            if coordinator.phase == .walking {
                JoystickPad { vector in
                    coordinator.joystickInput = vector
                }
                .frame(width: 130, height: 130)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 60)
            }

            if coordinator.phase == .quiz {
                M1QuizView(question: .m1) { attempts in
                    coordinator.answerQuizCorrect(attempts: attempts)
                }
                .transition(.opacity)
            }

            if coordinator.phase == .celebrating {
                M1CelebrationView(
                    stars: coordinator.starsEarned,
                    xpEarned: 50,
                    onContinue: { finishModule() }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.phase)
        .navigationBarBackButtonHidden(true)
        .toolbar { backButtonToolbar }
        .onAppear { setUpScene() }
        .onChange(of: coordinator.sparkAwakened) { _, _ in tryFireQueuedBeats() }
        .onChange(of: coordinator.beaconRestored) { _, _ in tryFireQueuedBeats() }
        .onChange(of: dialogue.activeBeat) { oldBeat, newBeat in
            handleBeatTransition(from: oldBeat, to: newBeat)
        }
        .task(id: coordinator.phase) {
            await runPhaseLoopIfNeeded()
        }
    }

    /// True for the puzzle phases — lantern/beam/front-Spark visible.
    private var isPuzzlePhase: Bool {
        switch coordinator.phase {
        case .opening, .awake, .solved: return true
        default: return false
        }
    }

    // MARK: - Per-frame loops

    /// SwiftUI `.task(id: phase)` cancels the previous task and starts a new
    /// one each time `phase` changes. Each phase's loop returns immediately
    /// when invoked for a phase it doesn't handle.
    private func runPhaseLoopIfNeeded() async {
        switch coordinator.phase {
        case .awake:   await runPuzzleLoop()
        case .walking: await runWalkLoop()
        default:       break
        }
    }

    private func runPuzzleLoop() async {
        let dt: CGFloat = 1.0 / 60.0

        while !Task.isCancelled, coordinator.phase == .awake {
            coordinator.tickPuzzle(dt: dt)
            updateChargingHaptic()
            try? await Task.sleep(nanoseconds: 16_000_000)
        }

        // Phase changed — make sure the continuous haptic doesn't keep playing.
        chargingHaptics.stop()
    }

    /// Drives the continuous charging haptic each frame: starts the pattern
    /// when a crystal begins charging, smoothly ramps intensity with progress,
    /// stops the moment no crystal is being charged.
    private func updateChargingHaptic() {
        let progress = activelyChargingProgress()
        if progress > 0.01 {
            let intensity = Float(0.30 + Double(progress) * 0.70)   // 0.30 → 1.0
            let sharpness = Float(0.35 + Double(progress) * 0.45)   // 0.35 → 0.80 (more crisp near full)
            if chargingHaptics.isRunning {
                chargingHaptics.update(intensity: intensity, sharpness: sharpness)
            } else {
                chargingHaptics.start(intensity: intensity, sharpness: sharpness)
            }
        } else if chargingHaptics.isRunning {
            chargingHaptics.stop()
        }
    }

    /// Highest charge progress among receivers currently being charged (lit
    /// by the beam but not yet discovered). Returns 0 if nothing is charging.
    private func activelyChargingProgress() -> CGFloat {
        coordinator.receivers.compactMap { receiver -> CGFloat? in
            guard coordinator.currentlyLitReceiverIDs.contains(receiver.id),
                  !coordinator.discoveredReceiverIDs.contains(receiver.id)
            else { return nil }
            return coordinator.chargeProgress(for: receiver.id)
        }
        .max() ?? 0
    }

    private func runWalkLoop() async {
        let dt: CGFloat = 1.0 / 60.0
        while !Task.isCancelled, coordinator.phase == .walking {
            coordinator.tickWalk(dt: dt)
            try? await Task.sleep(nanoseconds: 16_000_000)
        }
    }

    // MARK: - Aim gesture

    private func aimDragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard coordinator.phase == .awake else { return }
                if !hasDraggedYet { hasDraggedYet = true }
                coordinator.handleAim(to: CGPoint(
                    x: value.location.x / size.width,
                    y: value.location.y / size.height
                ))
            }
            .onEnded { _ in
                guard coordinator.phase == .awake else { return }
                coordinator.endAim()
            }
    }

    /// Aim hint shows only at the very start — once during the first `.awake`
    /// phase, before the player has dragged anywhere. Dismisses the moment they
    /// touch the screen and stays gone.
    private var shouldShowAimHint: Bool {
        coordinator.phase == .awake && !hasDraggedYet
    }

    /// Animated drag hint above the lantern: pulsing ring + label + a small
    /// hand icon arcing left-right so the player knows to drag-and-hold, not tap.
    private func aimHintView(in size: CGSize) -> some View {
        AimHintView()
            .position(
                x: size.width * coordinator.lanternPosition.x,
                y: size.height * coordinator.lanternPosition.y - 80
            )
            .transition(.opacity)
            .allowsHitTesting(false)
    }

    // MARK: - Setup

    private func setUpScene() {
        coordinator.didLoad()
        do {
            try dialogue.loadScript(filename: "M1Dialogue")
            dialogue.fire(trigger: "onSceneLoaded")
        } catch {
            assertionFailure("M1Dialogue.json failed to load: \(error)")
        }
    }

    private func tryFireQueuedBeats() {
        if coordinator.sparkAwakened, !flags.hasBeatFired("m1_discovery") {
            dialogue.fire(trigger: "onSparkActivated")
        }
        if coordinator.beaconRestored, !flags.hasBeatFired("m1_insight") {
            dialogue.fire(trigger: "onBeaconRestored")
        }
    }

    private func handleBeatTransition(from oldBeat: DialogueBeat?, to newBeat: DialogueBeat?) {
        if oldBeat != nil, newBeat == nil {
            tryFireQueuedBeats()
        }
        if oldBeat?.id == "m1_opening", newBeat == nil {
            coordinator.dialogueDidDismissOpening()
        }
        if oldBeat?.id == "m1_insight", newBeat == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                dialogue.fire(trigger: "onContinueAfterInsight")
            }
        }
        if oldBeat?.id == "m1_connection", newBeat == nil {
            coordinator.startWalking()
        }
    }

    private func finishModule() {
        dialogue.unloadScript()
        let store = ProgressStore(context: modelContext)
        store.recordLevelCompletion(
            levelID: "light-realm.m1",
            stars: coordinator.starsEarned,
            xp: 50
        )
        coordinator.markComplete()
        router.popToRoot()
    }

    // MARK: - Subviews

    private func beaconColumn(in size: CGSize) -> some View {
        let r = coordinator.beaconColumnRect
        return GateView(
            discoveredCount: coordinator.discoveredReceiverIDs.count,
            isOpen: coordinator.beaconRestored
        )
        .frame(width: size.width * r.width, height: size.height * r.height)
        .position(x: size.width * r.midX, y: size.height * r.midY)
        .allowsHitTesting(false)
    }

    private func blockerViews(in size: CGSize) -> some View {
        ZStack {
            if isPuzzlePhase {
                ForEach(coordinator.blockers) { blocker in
                    let rect = blocker.bounds
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: [Color(white: 0.22), Color(white: 0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(white: 0.35), lineWidth: 1.2)
                        )
                        .frame(width: size.width * rect.width, height: size.height * rect.height)
                        .position(x: size.width * rect.midX, y: size.height * rect.midY)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func receiverViews(in size: CGSize) -> some View {
        ForEach(coordinator.receivers) { receiver in
            ReceiverView(
                currentlyLit: coordinator.currentlyLitReceiverIDs.contains(receiver.id),
                discovered: coordinator.discoveredReceiverIDs.contains(receiver.id)
            )
            .position(
                x: size.width * receiver.position.x,
                y: size.height * receiver.position.y
            )
            .allowsHitTesting(false)
        }
    }

    /// Circular charge rings on receivers while they're being charged. Spark
    /// has no charge ring — he awakens instantly on first beam contact.
    private func chargeRings(in size: CGSize) -> some View {
        ZStack {
            ForEach(coordinator.receivers) { receiver in
                let progress = coordinator.chargeProgress(for: receiver.id)
                if progress > 0, !coordinator.discoveredReceiverIDs.contains(receiver.id) {
                    ChargeRing(progress: progress, radius: 30)
                        .position(
                            x: size.width * receiver.position.x,
                            y: size.height * receiver.position.y
                        )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func sparkView(in size: CGSize) -> some View {
        SparkView(
            mode: .yellow,
            expression: sparkExpression,
            glow: sparkGlow,
            size: 96,
            haloScale: 1.05      // very tight — just kisses the silhouette
        )
        .opacity(sparkOpacity)
        .position(
            x: size.width * coordinator.sparkPosition.x,
            y: size.height * coordinator.sparkPosition.y
        )
        .animation(.easeOut(duration: 0.55), value: coordinator.sparkAwakened)
        .animation(.easeOut(duration: 0.25), value: coordinator.sparkCurrentlyLit)
        .allowsHitTesting(false)
    }

    /// Pre-awakening: a very faint silhouette. The player has to *find* him —
    /// they should sense something is there but not be able to read it as Spark
    /// until they bring the light close.
    private var sparkOpacity: Double {
        if coordinator.sparkAwakened { return 1.0 }
        return coordinator.sparkCurrentlyLit ? 1.0 : 0.18
    }

    private var sparkExpression: SparkExpression {
        if !coordinator.sparkAwakened { return .curious }
        return coordinator.sparkCurrentlyLit ? .hopeful : .steady
    }

    private var sparkGlow: GlowState {
        if !coordinator.sparkAwakened { return .dim }
        // Awakened — yellow halo *only* while the beam is currently on him.
        // Off otherwise (no lingering warmth).
        return coordinator.sparkCurrentlyLit ? .bright : .off
    }

    /// Spark from behind during the walking phase. His own internal LEDs are
    /// on — tight bluish halo behind him. He tilts in the joystick's direction;
    /// the propeller above his head spins at a constant rate with proper
    /// 3D tilt so it looks anchored to the antenna, not behind his head.
    private func sparkWalkingView(in size: CGSize) -> some View {
        let input = coordinator.joystickInput
        let tilt = Double(input.dx) * 14    // ±14° lean horizontally
        let pitch = Double(input.dy) * 8    // slight nose-down/up

        return ZStack {
            // Internal-LED blue halo — tight aura right around his body.
            Circle()
                .fill(Color.electricBlue.opacity(0.45))
                .frame(width: 122, height: 122)
                .blur(radius: 20)

            // Body + spinning propeller composite — same scaledToFit stack
            // pattern as the front view in SparkView so the assets align.
            ZStack {
                Image("SparkBack")
                    .resizable()
                    .scaledToFit()
                Image("SparkBackPropellerBlades")
                    .resizable()
                    .scaledToFit()
                    .modifier(BackPropellerSpin())
            }
            .frame(width: 110, height: 110)
            .rotationEffect(.degrees(tilt))
            .offset(y: pitch)
            .animation(.easeOut(duration: 0.15), value: tilt)
            .animation(.easeOut(duration: 0.15), value: pitch)
        }
        .position(
            x: size.width * coordinator.sparkWalkPosition.x,
            y: size.height * coordinator.sparkWalkPosition.y
        )
        .allowsHitTesting(false)
    }

    private func beamPath(in size: CGSize) -> some View {
        Canvas { context, _ in
            guard let segment = coordinator.currentBeam.segments.first else { return }
            let start = CGPoint(x: size.width * segment.start.x, y: size.height * segment.start.y)
            let end = CGPoint(x: size.width * segment.end.x, y: size.height * segment.end.y)
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [Color.beaconYellow.opacity(0.85), Color.beaconYellow.opacity(0.15)]),
                    startPoint: start,
                    endPoint: end
                ),
                lineWidth: 8
            )
        }
        .blur(radius: 1.5)
        .allowsHitTesting(false)
    }

    private func lanternView(in size: CGSize) -> some View {
        LanternView(isOn: coordinator.lanternIsOn)
            .position(
                x: size.width * coordinator.lanternPosition.x,
                y: size.height * coordinator.lanternPosition.y
            )
            .allowsHitTesting(false)
            .accessibilityLabel("Lantern — drag in the play area to aim the beam")
    }

    @ToolbarContentBuilder
    private var backButtonToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dialogue.unloadScript()
                router.popToRoot()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .accessibilityLabel("Leave module")
        }
    }
}

// MARK: - Receiver crystal

/// Receiver crystal. Four visual states:
///   - **undiscovered**: invisible (M1's lesson, embodied)
///   - **currentlyLit**: bright yellow with halo
///   - **discovered, not lit**: cold dark crystal + a small persistent sparkle
private struct ReceiverView: View {
    let currentlyLit: Bool
    let discovered: Bool

    private var isVisible: Bool { discovered || currentlyLit }

    var body: some View {
        ZStack {
            Circle()
                .fill(currentlyLit ? Color.beaconYellow : Color.realmMid)
                .frame(width: 44, height: 44)
                .shadow(color: currentlyLit ? Color.beaconWarm.opacity(0.75) : .clear, radius: 18)
                .overlay(
                    Circle()
                        .stroke(
                            currentlyLit ? Color.beaconYellow : Color.white.opacity(0.18),
                            lineWidth: 2
                        )
                )

            if currentlyLit {
                Image(systemName: "sparkle")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            } else if discovered {
                Circle()
                    .fill(Color.beaconYellow.opacity(0.85))
                    .frame(width: 6, height: 6)
                    .offset(x: 14, y: -14)
                    .shadow(color: .beaconWarm, radius: 3)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.7)
        .animation(.easeOut(duration: 0.4), value: discovered)
        .animation(.easeOut(duration: 0.18), value: currentlyLit)
    }
}

// MARK: - Charge ring

/// A circular progress ring drawn around a target while it's being charged.
/// `progress` is in 0…1 — when it hits 1, the parent view removes the ring.
private struct ChargeRing: View {
    let progress: CGFloat
    let radius: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 3)
                .frame(width: radius * 2, height: radius * 2)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(Color.beaconYellow, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: radius * 2, height: radius * 2)
                .shadow(color: Color.beaconWarm.opacity(0.6), radius: 5)
        }
        .animation(.linear(duration: 0.05), value: progress)
    }
}

// MARK: - Gate

private struct GateView: View {
    let discoveredCount: Int
    let isOpen: Bool

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.realmMid)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.12), lineWidth: 2)
                    )

                if isOpen {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.beaconYellow)
                        .padding(10)
                        .shadow(color: Color.beaconWarm.opacity(0.9), radius: 36)
                }

                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.realmDark)
                        .frame(width: w / 2 - 6)
                        .offset(x: isOpen ? -w * 0.55 : 0)
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.realmDark)
                        .frame(width: w / 2 - 6)
                        .offset(x: isOpen ? w * 0.55 : 0)
                }
                .padding(6)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i < discoveredCount ? Color.beaconYellow : Color.white.opacity(0.18))
                            .frame(width: 7, height: 7)
                            .shadow(
                                color: i < discoveredCount ? Color.beaconWarm : .clear,
                                radius: 5
                            )
                    }
                }
                .offset(y: -h / 2 + 8)
            }
        }
        .animation(.easeOut(duration: 0.9), value: isOpen)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: discoveredCount)
    }
}

// MARK: - Lantern

private struct LanternView: View {
    let isOn: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.beaconWarm.opacity(isOn ? 0.5 : 0.0))
                .frame(width: 72, height: 72)
                .blur(radius: 12)

            Circle()
                .fill(Color.sparkBrass)
                .overlay(Circle().stroke(Color.sparkBrassLight, lineWidth: 2))
                .frame(width: 38, height: 38)

            if isOn {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.beaconYellow)
            } else {
                Image(systemName: "moonphase.new.moon")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
        }
        .animation(.easeOut(duration: 0.25), value: isOn)
    }
}

// MARK: - Charging haptic (CoreHaptics continuous)

/// Drives a continuous CoreHaptics pattern whose intensity + sharpness can be
/// dynamically updated each frame. Used by M1 to give the player a smooth,
/// rising vibration while a crystal is being charged.
///
/// Why CoreHaptics instead of `UIImpactFeedbackGenerator`? Impact generators
/// fire discrete pulses and the OS throttles them to ~10/sec — at the speeds
/// needed for a "smooth rising buzz" they always feel scattered. A continuous
/// pattern is genuinely continuous in hardware, with dynamic parameters.
@Observable
final class ChargingHaptic {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    private(set) var isRunning = false

    func start(intensity: Float, sharpness: Float) {
        prepareEngine()
        guard let engine, !isRunning else { return }
        do {
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0,
                duration: 30  // long upper bound; we stop manually
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let newPlayer = try engine.makeAdvancedPlayer(with: pattern)
            try newPlayer.start(atTime: CHHapticTimeImmediate)
            player = newPlayer
            isRunning = true
        } catch {
            // Hardware unsupported, engine glitched — silently fall back to no haptic.
        }
    }

    /// Smoothly adjust the running pattern's intensity + sharpness (called
    /// every frame while the crystal charges). No-op if not running.
    func update(intensity: Float, sharpness: Float) {
        guard isRunning, let player else { return }
        let clampedIntensity = max(0, min(1, intensity))
        let clampedSharpness = max(0, min(1, sharpness))
        try? player.sendParameters(
            [
                CHHapticDynamicParameter(
                    parameterID: .hapticIntensityControl,
                    value: clampedIntensity,
                    relativeTime: 0
                ),
                CHHapticDynamicParameter(
                    parameterID: .hapticSharpnessControl,
                    value: clampedSharpness,
                    relativeTime: 0
                )
            ],
            atTime: CHHapticTimeImmediate
        )
    }

    func stop() {
        guard isRunning else { return }
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
        isRunning = false
    }

    /// Lazily creates + starts the CHHapticEngine. The engine is shared across
    /// all `start`s for the lifetime of this controller.
    private func prepareEngine() {
        guard engine == nil else { return }
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let e = try CHHapticEngine()
            // iOS can stop the engine on app interruptions (audio session changes,
            // backgrounding, etc.); restart it transparently.
            e.resetHandler = { [weak e] in
                try? e?.start()
            }
            e.stoppedHandler = { _ in /* engine stopped; will recreate next start */ }
            try e.start()
            engine = e
        } catch {
            // Silent: device unsupported or transient failure.
        }
    }
}

// MARK: - Aim hint

/// First-time-only hint that fades up above the lantern, showing the player
/// they should *drag* (not tap) to aim the beam. A small hand icon traces a
/// gentle arc; the surrounding ring pulses; the label sits underneath.
private struct AimHintView: View {
    @State private var sweep: CGFloat = -1   // -1...+1 horizontal sweep
    @State private var pulse: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.beaconYellow.opacity(0.55), lineWidth: 2)
                    .frame(width: 64, height: 64)
                    .scaleEffect(pulse)
                    .opacity(2 - Double(pulse))

                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .offset(x: sweep * 22, y: -sweep * 10)
                    .shadow(color: Color.beaconWarm.opacity(0.5), radius: 6)
            }

            Text("Drag and hold to aim the light")
                .font(.hintCaption)
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.realmMid.opacity(0.7))
                )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                sweep = 1
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: false)) {
                pulse = 1.6
            }
        }
    }
}

// MARK: - Back propeller spin

/// Rotates the back-view propeller blades continuously at a fixed rate, with
/// the same 3D X-axis tilt + perspective as `SparkView`'s front-view propeller
/// so the blades read as a horizontal disc spinning *above* Spark's head, not
/// a flat spinner behind him.
///
/// The anchor is matched to the back-view blade SVG's actual content position
/// (Y ≈ 171/1024 ≈ 0.167 in canvas space). The front-view blades sit higher
/// (Y ≈ 107/1024 ≈ 0.104), so the two views need different anchors.
private struct BackPropellerSpin: ViewModifier {
    /// Constant. Doesn't change with joystick input.
    static let speed: Double = 420
    static let anchor = UnitPoint(x: 0.5, y: 0.171)

    func body(content: Content) -> some View {
        TimelineView(.animation) { context in
            let angle = context.date.timeIntervalSinceReferenceDate * Self.speed
            content
                .rotationEffect(.degrees(angle), anchor: Self.anchor)
                .rotation3DEffect(
                    .degrees(70),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: Self.anchor,
                    perspective: 0.3
                )
        }
    }
}

// MARK: - Joystick

private struct JoystickPad: View {
    let onChange: (CGVector) -> Void

    @State private var thumbOffset: CGSize = .zero

    private let baseRadius: CGFloat = 60
    private let thumbRadius: CGFloat = 26

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.realmMid.opacity(0.55))
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                .frame(width: baseRadius * 2, height: baseRadius * 2)

            Circle()
                .fill(Color.sparkBrass)
                .overlay(Circle().stroke(Color.sparkBrassLight, lineWidth: 2))
                .shadow(color: Color.beaconWarm.opacity(0.5), radius: 12)
                .frame(width: thumbRadius * 2, height: thumbRadius * 2)
                .offset(thumbOffset)
        }
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let raw = value.translation
                    let maxOffset = baseRadius - thumbRadius
                    let mag = hypot(raw.width, raw.height)
                    if mag > maxOffset, mag > 0 {
                        let scale = maxOffset / mag
                        thumbOffset = CGSize(
                            width: raw.width * scale,
                            height: raw.height * scale
                        )
                    } else {
                        thumbOffset = raw
                    }
                    onChange(CGVector(
                        dx: thumbOffset.width / maxOffset,
                        dy: thumbOffset.height / maxOffset
                    ))
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        thumbOffset = .zero
                    }
                    onChange(.zero)
                }
        )
        .accessibilityLabel("Movement joystick")
    }
}

#Preview {
    NavigationStack {
        M1Scene()
    }
    .environment(AppRouter())
    .environment(AudioManager())
    .environment(NarrativeFlags())
    .environment(DialogueController(flags: NarrativeFlags()))
    .modelContainer(.previewPhysica())
}
