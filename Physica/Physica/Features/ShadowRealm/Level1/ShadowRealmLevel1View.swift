import SwiftUI
import SwiftData

struct ShadowRealmLevel1View: View {
    @State private var state = ShadowRealmLevel1State()
    @Environment(AppRouter.self) private var router
    @Environment(AudioManager.self) private var audio
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.shadowDeep.ignoresSafeArea()

                if state.isLightOn {
                    CaveEnvironmentView(
                        size: proxy.size,
                        crystalPosition: state.crystalPosition,
                        batPosition: state.batPosition,
                        exitPosition: state.exitPosition,
                        discoveries: state.discoveries,
                        batReacted: state.batReacted
                    )
                    .opacity(state.isLightOn ? 1 : 0)
                    .mask(
                        LightMask(
                            sparkPosition: actualPosition(state.sparkPositionNormalized, in: proxy.size),
                            radius: lightRadius(in: proxy.size)
                        )
                    )
                    .transition(.opacity)
                }

                if state.isLightOn {
                    LightConeView(
                        position: actualPosition(state.sparkPositionNormalized, in: proxy.size),
                        radius: lightRadius(in: proxy.size) * 0.6,
                        color: .torchYellow
                    )
                }

                SparkLayer(
                    state: state,
                    proxySize: proxy.size,
                    showAttentionPulse: shouldShowAttentionPulse,
                    onTap: handleTap,
                    onDrag: handleDrag
                )

                HintTrailView(
                    show: state.hintEngine.currentLevel == .strong && !state.discoveries.contains(.exit),
                    from: actualPosition(state.sparkPositionNormalized, in: proxy.size),
                    to: actualPosition(state.exitPosition, in: proxy.size)
                )
            }
            .onAppear {
                state.hintEngine.start()
                audio.startAmbient(.shadowCave)
            }
            .onDisappear {
                state.hintEngine.stop()
                audio.stopAmbient()
            }
            .onChange(of: state.phase) { _, newPhase in
                handlePhaseChange(newPhase)
            }
            .fullScreenCover(isPresented: completionBinding) {
                LevelCompleteView(
                    stars: state.starsEarned,
                    conceptLearned: "Light reveals what it touches.",
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
        }
        .navigationBarBackButtonHidden(false)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Layout helpers

    private func actualPosition(_ normalized: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: normalized.x * size.width, y: normalized.y * size.height)
    }

    private func lightRadius(in size: CGSize) -> CGFloat {
        min(size.width, size.height) * 0.42
    }

    // MARK: - Phase / hint visuals

    private var shouldShowAttentionPulse: Bool {
        state.phase == .dark && (state.hintEngine.currentLevel == .nudge || state.hintEngine.currentLevel == .hint || state.hintEngine.currentLevel == .strong)
    }

    private var completionBinding: Binding<Bool> {
        Binding(
            get: { state.phase == .complete },
            set: { _ in }
        )
    }

    private var testBinding: Binding<Bool> {
        Binding(
            get: { state.phase == .test },
            set: { _ in }
        )
    }

    // MARK: - Interaction

    private func handleTap() {
        guard state.phase == .dark else { return }
        audio.play(.lightOn)
        withAnimation(.easeOut(duration: 0.7)) {
            state.tapSpark()
        }
    }

    private func handleDrag(value: DragGesture.Value, in size: CGSize) {
        guard state.isLightOn, state.phase == .exploring else { return }
        let normalized = CGPoint(
            x: value.location.x / size.width,
            y: value.location.y / size.height
        )
        let prevDiscoveries = state.discoveries
        state.moveSpark(toNormalized: normalized)
        let newDiscoveries = state.discoveries.subtracting(prevDiscoveries)
        if !newDiscoveries.isEmpty {
            audio.play(.discoveryChime)
        }
    }

    private func handlePhaseChange(_ phase: ShadowRealmLevel1State.Phase) {
        if phase == .complete {
            audio.play(.levelComplete)
        }
    }

    // MARK: - Completion

    private var postLevelQuestion: PostLevelTestQuestion {
        PostLevelTestQuestion(
            prompt: "Spark's eye is off. The cave is dark. Spark walks forward.\nWhat does Spark see?",
            options: ["The whole cave", "Nothing", "Only the floor"],
            correctIndex: 1,
            illustrationSymbol: "moon.stars.fill"
        )
    }

    private func recordAndExit() {
        let store = ProgressStore(context: modelContext)
        store.recordLevelCompletion(levelID: "shadow-realm.1", stars: state.starsEarned, xp: 50)
        state.finish()
        router.popToRoot()
    }
}

// MARK: - Light mask: discovers cave only inside the cone radius

private struct LightMask: View {
    let sparkPosition: CGPoint
    let radius: CGFloat

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [.white, .white.opacity(0.85), .white.opacity(0.0)],
                center: .center,
                startRadius: 8,
                endRadius: radius
            )
            .frame(width: radius * 2, height: radius * 2)
            .position(sparkPosition)
        }
    }
}

// MARK: - Spark + interactions layer

private struct SparkLayer: View {
    let state: ShadowRealmLevel1State
    let proxySize: CGSize
    let showAttentionPulse: Bool
    let onTap: () -> Void
    let onDrag: (DragGesture.Value, CGSize) -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            if showAttentionPulse {
                Circle()
                    .stroke(Color.torchYellow.opacity(0.5), lineWidth: 2)
                    .frame(width: 110, height: 110)
                    .scaleEffect(pulseScale)
                    .opacity(2 - pulseScale)
                    .position(
                        x: state.sparkPositionNormalized.x * proxySize.width,
                        y: state.sparkPositionNormalized.y * proxySize.height
                    )
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                            pulseScale = 1.6
                        }
                    }
                    .onDisappear { pulseScale = 1.0 }
            }

            SparkView(
                mode: state.isLightOn ? .yellow : .blue,
                expression: sparkExpression,
                size: 84
            )
            .position(
                x: state.sparkPositionNormalized.x * proxySize.width,
                y: state.sparkPositionNormalized.y * proxySize.height
            )
            .onTapGesture { onTap() }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        onDrag(value, proxySize)
                    }
            )
        }
    }

    private var sparkExpression: SparkView.Expression {
        switch state.phase {
        case .dark: return .curious
        case .exploring: return state.discoveries.isEmpty ? .focused : .happy
        case .complete, .test, .finished: return .happy
        }
    }
}

// MARK: - Strong-hint trail (60s+ no exit)

private struct HintTrailView: View {
    let show: Bool
    let from: CGPoint
    let to: CGPoint
    @State private var phase: CGFloat = 0

    var body: some View {
        if show {
            Path { path in
                path.move(to: from)
                path.addLine(to: to)
            }
            .stroke(
                Color.torchYellow.opacity(0.5),
                style: StrokeStyle(lineWidth: 3, dash: [6, 10], dashPhase: phase)
            )
            .blendMode(.screen)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    phase = 32
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ShadowRealmLevel1View()
    }
    .environment(AppRouter())
    .environment(AudioManager())
    .modelContainer(.previewPhysica())
}
