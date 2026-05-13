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

    var body: some View {
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
        .navigationBarBackButtonHidden(true)
        .toolbar { backButtonToolbar }
        .onAppear { setUpScene() }
        .onChange(of: coordinator.sparkActivated) { _, _ in tryFireQueuedBeats() }
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
        if coordinator.sparkActivated, !flags.hasBeatFired("m1_discovery") {
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

        // Connection dismissed → module complete, pop back to world map.
        if oldBeat?.id == "m1_connection", newBeat == nil {
            coordinator.markComplete()
            dialogue.unloadScript()
            router.popToRoot()
        }
    }

    // MARK: - Subviews

    private func beaconColumn(in size: CGSize) -> some View {
        let r = coordinator.beaconColumnRect
        return RoundedRectangle(cornerRadius: 12)
            .fill(coordinator.beaconRestored ? Color.beaconYellow.opacity(0.85) : Color.realmMid)
            .frame(
                width: size.width * r.width,
                height: size.height * r.height
            )
            .shadow(
                color: coordinator.beaconRestored ? .beaconWarm.opacity(0.7) : .clear,
                radius: 30
            )
            .position(
                x: size.width * (r.midX),
                y: size.height * (r.midY)
            )
            .animation(.easeOut(duration: 0.8), value: coordinator.beaconRestored)
    }

    private func receiverViews(in size: CGSize) -> some View {
        ForEach(coordinator.receivers) { receiver in
            ReceiverView(activated: receiver.isActivated)
                .position(
                    x: size.width * receiver.position.x,
                    y: size.height * receiver.position.y
                )
        }
    }

    private func sparkView(in size: CGSize) -> some View {
        SparkView(
            mode: .yellow,
            expression: coordinator.sparkActivated ? .hopeful : .curious,
            glow: coordinator.sparkActivated ? .warm : .dim,
            size: 96
        )
        .position(
            x: size.width * coordinator.sparkPosition.x,
            y: size.height * coordinator.sparkPosition.y
        )
        .animation(.easeOut(duration: 0.6), value: coordinator.sparkActivated)
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

// MARK: - Receiver placeholder

private struct ReceiverView: View {
    let activated: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(activated ? Color.beaconYellow : Color.realmMid)
                .frame(width: 44, height: 44)
                .shadow(color: activated ? Color.beaconWarm.opacity(0.75) : .clear, radius: 18)
                .overlay(
                    Circle()
                        .stroke(activated ? Color.beaconYellow : Color.white.opacity(0.18), lineWidth: 2)
                )
            if activated {
                Image(systemName: "sparkle")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: activated)
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
