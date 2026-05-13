import SwiftUI
import SwiftData

/// M1 Sleeping Beacon — greybox SwiftUI scene. Portrait layout: beacon column
/// at the top, 3 receiver crystals + Spark in the middle band, lantern slider
/// near the bottom (above the dialogue overlay).
///
/// The middle 64% of the screen is the play area; the lantern lives at y≈0.65
/// (still above the dialogue band that starts at y≈0.72).
struct M1Scene: View {
    @State private var coordinator = M1Coordinator()
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
                    receiverViews(in: proxy.size)
                    sparkView(in: proxy.size)
                    beamPath(in: proxy.size)
                    lanternView(in: proxy.size)
                }
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
    }

    // MARK: - Setup

    private func setUpScene() {
        coordinator.didLoad()
        do {
            try dialogue.loadScript(filename: "M1Dialogue")
            dialogue.fire(trigger: "onSceneLoaded")
        } catch {
            // In Phase 1, missing JSON is non-fatal — Spark just doesn't talk.
            assertionFailure("M1Dialogue.json failed to load: \(error)")
        }
    }

    /// Game-state-driven beat firing. Each new state change OR each beat dismissal
    /// re-checks every trigger — beats that couldn't fire earlier (because another
    /// beat was active) get a second chance once the overlay is free.
    private func tryFireQueuedBeats() {
        if coordinator.sparkAwakened, !flags.hasBeatFired("m1_discovery") {
            dialogue.fire(trigger: "onSparkActivated")
        }
        if coordinator.beaconRestored, !flags.hasBeatFired("m1_insight") {
            dialogue.fire(trigger: "onBeaconRestored")
        }
    }

    private func handleBeatTransition(from oldBeat: DialogueBeat?, to newBeat: DialogueBeat?) {
        // Any beat just dismissed — see if any others want to fire.
        if oldBeat != nil, newBeat == nil {
            tryFireQueuedBeats()
        }

        // Opening dismissed → unlock the lantern.
        if oldBeat?.id == "m1_opening", newBeat == nil {
            coordinator.dialogueDidDismissOpening()
        }

        // Insight dismissed → fire the Connection beat (the streetlight bridge).
        if oldBeat?.id == "m1_insight", newBeat == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                dialogue.fire(trigger: "onContinueAfterInsight")
            }
        }

        // Connection dismissed → show the quiz.
        if oldBeat?.id == "m1_connection", newBeat == nil {
            coordinator.startQuiz()
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
        .frame(
            width: size.width * r.width,
            height: size.height * r.height
        )
        .position(
            x: size.width * r.midX,
            y: size.height * r.midY
        )
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
        }
    }

    private func sparkView(in size: CGSize) -> some View {
        SparkView(
            mode: .yellow,
            expression: sparkExpression,
            glow: sparkGlow,
            size: 96
        )
        .position(
            x: size.width * coordinator.sparkPosition.x,
            y: size.height * coordinator.sparkPosition.y
        )
        .animation(.easeOut(duration: 0.45), value: coordinator.sparkAwakened)
        .animation(.easeOut(duration: 0.25), value: coordinator.sparkCurrentlyLit)
    }

    private var sparkExpression: SparkExpression {
        if !coordinator.sparkAwakened { return .curious }
        return coordinator.sparkCurrentlyLit ? .hopeful : .steady
    }

    private var sparkGlow: GlowState {
        if !coordinator.sparkAwakened { return .dim }
        return coordinator.sparkCurrentlyLit ? .bright : .warm
    }

    private func beamPath(in size: CGSize) -> some View {
        Canvas { context, _ in
            guard let segment = coordinator.currentBeam.segments.first else { return }
            var path = Path()
            path.move(to: CGPoint(x: size.width * segment.start.x, y: size.height * segment.start.y))
            path.addLine(to: CGPoint(x: size.width * segment.end.x, y: size.height * segment.end.y))
            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [Color.beaconYellow.opacity(0.85), Color.beaconYellow.opacity(0.15)]),
                    startPoint: CGPoint(x: size.width * segment.start.x, y: size.height * segment.start.y),
                    endPoint: CGPoint(x: size.width * segment.end.x, y: size.height * segment.end.y)
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
                x: size.width * coordinator.lanternX,
                y: size.height * coordinator.lanternY
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard coordinator.phase == .awake || coordinator.phase == .solved else { return }
                        let normalizedX = value.location.x / size.width
                        coordinator.handleLanternDrag(to: normalizedX)
                    }
            )
            .accessibilityLabel("Lantern — drag to aim the beam")
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

/// Receiver crystal. Three visual states:
///   - **off**: cold dark circle, no glow (default, no beam, never hit)
///   - **currentlyLit**: bright yellow with halo (beam currently passing through)
///   - **discovered, not lit**: cold dark with a small persistent sparkle (beam
///     has visited at least once — the player has *seen* this thing)
private struct ReceiverView: View {
    let currentlyLit: Bool
    let discovered: Bool

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
                // Tiny persistent marker — "we know this is here" without
                // pretending the crystal is still lit.
                Circle()
                    .fill(Color.beaconYellow.opacity(0.85))
                    .frame(width: 6, height: 6)
                    .offset(x: 14, y: -14)
                    .shadow(color: .beaconWarm, radius: 3)
            }
        }
        .animation(.easeOut(duration: 0.18), value: currentlyLit)
        .animation(.easeOut(duration: 0.25), value: discovered)
    }
}

// MARK: - Gate

/// The Dawn Court gate. Starts closed; three small lights along the top track
/// how many receivers have been discovered. Once the puzzle solves (all 3
/// receivers discovered + Spark awakened), the two door halves slide apart
/// and a warm portal of light pours out.
private struct GateView: View {
    let discoveredCount: Int    // 0–3
    let isOpen: Bool

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            ZStack {
                // Outer frame
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.realmMid)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.12), lineWidth: 2)
                    )

                // Inner glow — only visible when the gate is open
                if isOpen {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.beaconYellow)
                        .padding(10)
                        .shadow(color: Color.beaconWarm.opacity(0.9), radius: 36)
                }

                // Two door halves — slide apart when opening
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

                // Indicator lights along the top — one per receiver
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

// MARK: - Lantern placeholder

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
