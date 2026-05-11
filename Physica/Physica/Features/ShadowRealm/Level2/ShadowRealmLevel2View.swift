import SwiftUI
import SwiftData

struct ShadowRealmLevel2View: View {
    @State private var state = ShadowRealmLevel2State()
    @Environment(AppRouter.self) private var router
    @Environment(AudioManager.self) private var audio
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                Color.shadowDeep.ignoresSafeArea()

                RadialGradient(
                    colors: [Color.shadowMid.opacity(0.3), Color.shadowDeep],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.8
                )
                .ignoresSafeArea()

                // Beam
                BeamPathView(segments: state.beamSegments, size: size)

                // Receiver
                ReceiverTargetView(
                    position: state.receiverPosition,
                    isLit: state.receiverLit,
                    size: size
                )

                // Crystals
                ForEach(state.crystals) { crystal in
                    CrystalGemView(
                        position: crystal.position,
                        isLit: crystal.isLit,
                        size: size
                    )
                }

                // Mirrors
                ForEach(state.mirrors) { mirror in
                    MirrorLineView(
                        mirror: mirror,
                        size: size,
                        isSelected: state.selectedMirrorID == mirror.id,
                        isHit: state.hitMirrorIDs.contains(mirror.id)
                    )
                }

                // Mirror drag areas (only during gameplay)
                if state.phase == .playing {
                    ForEach(state.mirrors) { mirror in
                        mirrorDragOverlay(mirror: mirror, size: size)
                    }
                }

                // Spark robot
                sparkLayer(size: size)

                // Intro overlay
                if state.phase == .intro {
                    introOverlay
                }

                // Hint text
                if state.phase == .playing, state.hintEngine.currentLevel != .none {
                    hintText
                }
            }
            .coordinateSpace(name: "gameArea")
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .onAppear {
            audio.startAmbient(.shadowCave)
            state.traceBeam()
        }
        .onDisappear {
            audio.stopAmbient()
            state.hintEngine.stop()
        }
        .onChange(of: state.phase) { _, newPhase in
            if newPhase == .complete { audio.play(.levelComplete) }
        }
        .fullScreenCover(isPresented: completionBinding) {
            LevelCompleteView(
                stars: state.starsEarned,
                conceptLearned: "Mirrors reflect light — angles matter.",
                onContinue: { state.startTest() }
            )
        }
        .fullScreenCover(isPresented: testBinding) {
            PostLevelTestView(
                question: postLevelQuestion,
                onCorrect: { recordAndExit() },
                onWrong: { state.reset() }
            )
        }
        .navigationBarBackButtonHidden(false)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Spark

    @ViewBuilder
    private func sparkLayer(size: CGSize) -> some View {
        SparkView(mode: .yellow, expression: .focused, size: 60)
            .shadow(color: .torchYellow.opacity(0.4), radius: 12)
            .position(
                x: state.sparkPosition.x * size.width,
                y: state.sparkPosition.y * size.height
            )
    }

    // MARK: - Mirror drag

    @ViewBuilder
    private func mirrorDragOverlay(mirror: ShadowRealmLevel2State.Mirror, size: CGSize) -> some View {
        let center = CGPoint(
            x: mirror.position.x * size.width,
            y: mirror.position.y * size.height
        )

        Circle()
            .fill(Color.white.opacity(0.001))
            .frame(width: 90, height: 90)
            .contentShape(Circle())
            .position(center)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("gameArea"))
                    .onChanged { value in
                        state.selectedMirrorID = mirror.id
                        let dx = value.location.x - center.x
                        let dy = value.location.y - center.y
                        let angle = atan2(dy, dx) * 180 / .pi
                        state.rotateMirror(id: mirror.id, to: angle)
                    }
                    .onEnded { _ in
                        state.selectedMirrorID = nil
                    }
            )
    }

    // MARK: - Overlays

    private var introOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                Text("Rotate the mirrors")
                    .font(.levelHeader)
                    .foregroundStyle(.white)

                Text("Guide the light beam to the receiver")
                    .font(.bodyGame)
                    .foregroundStyle(.white.opacity(0.65))

                Text("Tap to start")
                    .font(.hintCaption)
                    .foregroundStyle(Color.torchYellow)
                    .padding(.top, Spacing.sm)
            }
        }
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.4)) {
                state.startPlaying()
            }
        }
    }

    @ViewBuilder
    private var hintText: some View {
        let text: String = switch state.hintEngine.currentLevel {
        case .none: ""
        case .nudge: "Drag a mirror to rotate it"
        case .hint: "Try angling the mirrors at 45°"
        case .strong: "Chain all three mirrors to reach the target"
        }

        if !text.isEmpty {
            Text(text)
                .font(.hintCaption)
                .foregroundStyle(.white.opacity(0.55))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, Spacing.xxl)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.4), value: state.hintEngine.currentLevel)
        }
    }

    // MARK: - Bindings

    private var completionBinding: Binding<Bool> {
        Binding(get: { state.phase == .complete }, set: { _ in })
    }

    private var testBinding: Binding<Bool> {
        Binding(get: { state.phase == .test }, set: { _ in })
    }

    // MARK: - Completion

    private var postLevelQuestion: PostLevelTestQuestion {
        PostLevelTestQuestion(
            prompt: "A beam of light hits a flat mirror.\nWhat happens to the light?",
            options: ["It passes through the mirror", "It bounces off at an angle", "It stops completely"],
            correctIndex: 1,
            illustrationSymbol: "light.beacon.max.fill"
        )
    }

    private func recordAndExit() {
        let store = ProgressStore(context: modelContext)
        store.recordLevelCompletion(levelID: "shadow-realm.2", stars: state.starsEarned, xp: 50)
        state.finish()
        router.popToRoot()
    }
}

// MARK: - Beam visualization

private struct BeamPathView: View {
    let segments: [ShadowRealmLevel2State.BeamSegment]
    let size: CGSize

    @State private var glow: Double = 0.5

    var body: some View {
        ZStack {
            beamPath
                .stroke(Color.torchYellow.opacity(0.25), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .blur(radius: 6)

            beamPath
                .stroke(Color.torchYellow.opacity(glow), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .blur(radius: 2)

            beamPath
                .stroke(Color.white, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                glow = 0.35
            }
        }
    }

    private var beamPath: Path {
        Path { path in
            for seg in segments {
                path.move(to: denorm(seg.start))
                path.addLine(to: denorm(seg.end))
            }
        }
    }

    private func denorm(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x * size.width, y: p.y * size.height)
    }
}

// MARK: - Mirror line

private struct MirrorLineView: View {
    let mirror: ShadowRealmLevel2State.Mirror
    let size: CGSize
    let isSelected: Bool
    let isHit: Bool

    var body: some View {
        let (p1, p2) = screenEndpoints

        ZStack {
            if isHit {
                line
                    .stroke(Color.torchYellow.opacity(0.4), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .blur(radius: 4)
            }

            line
                .stroke(
                    isSelected ? Color.white : Color.white.opacity(0.75),
                    style: StrokeStyle(lineWidth: isSelected ? 4 : 3, lineCap: .round)
                )

            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 8, height: 8)
                .position(p1)

            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 8, height: 8)
                .position(p2)
        }
    }

    private var screenEndpoints: (CGPoint, CGPoint) {
        let (a, b) = mirror.endpoints()
        return (
            CGPoint(x: a.x * size.width, y: a.y * size.height),
            CGPoint(x: b.x * size.width, y: b.y * size.height)
        )
    }

    private var line: Path {
        let (p1, p2) = screenEndpoints
        return Path { path in
            path.move(to: p1)
            path.addLine(to: p2)
        }
    }
}

// MARK: - Receiver target

private struct ReceiverTargetView: View {
    let position: CGPoint
    let isLit: Bool
    let size: CGSize

    @State private var pulse: CGFloat = 1.0

    var body: some View {
        ZStack {
            if isLit {
                Circle()
                    .fill(Color.torchYellow.opacity(0.3))
                    .frame(width: 48, height: 48)
                    .blur(radius: 14)
            }

            Circle()
                .stroke(isLit ? Color.torchYellow : Color.white.opacity(0.25), lineWidth: 2)
                .frame(width: 32, height: 32)
                .scaleEffect(pulse)

            Circle()
                .stroke(isLit ? Color.torchYellow.opacity(0.6) : Color.white.opacity(0.15), lineWidth: 1)
                .frame(width: 20, height: 20)

            Circle()
                .fill(isLit ? Color.torchYellow : Color.white.opacity(0.15))
                .frame(width: 8, height: 8)
        }
        .position(x: position.x * size.width, y: position.y * size.height)
        .onChange(of: isLit) { _, lit in
            if lit {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulse = 1.15
                }
            } else {
                withAnimation(.default) { pulse = 1.0 }
            }
        }
    }
}

// MARK: - Crystal collectible

private struct CrystalGemView: View {
    let position: CGPoint
    let isLit: Bool
    let size: CGSize

    @State private var sparkle: CGFloat = 1.0

    var body: some View {
        ZStack {
            if isLit {
                Circle()
                    .fill(Color.torchYellow.opacity(0.3))
                    .frame(width: 28, height: 28)
                    .blur(radius: 10)
            }

            Image(systemName: "diamond.fill")
                .font(.system(size: 18))
                .foregroundStyle(isLit ? Color.torchYellow : Color.white.opacity(0.25))
                .scaleEffect(sparkle)
        }
        .position(x: position.x * size.width, y: position.y * size.height)
        .onChange(of: isLit) { _, lit in
            if lit {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    sparkle = 1.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        sparkle = 1.1
                    }
                }
            } else {
                withAnimation(.default) { sparkle = 1.0 }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ShadowRealmLevel2View()
    }
    .environment(AppRouter())
    .environment(AudioManager())
    .modelContainer(.previewPhysica())
}
