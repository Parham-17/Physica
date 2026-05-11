import SwiftUI
import SwiftData

struct ShadowRealmLevel1View: View {
    @State private var state = ShadowRealmLevel1State()
    @State private var movementTask: Task<Void, Never>? = nil
    @Environment(AppRouter.self) private var router
    @Environment(AudioManager.self) private var audio
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.shadowDeep.ignoresSafeArea()

                // Cave revealed only inside the directional light cone
                if state.isLightOn {
                    CaveEnvironmentView(
                        size: proxy.size,
                        crystalPosition: state.crystalPosition,
                        batPosition: state.batPosition,
                        exitPosition: state.exitPosition,
                        discoveries: state.discoveries,
                        batReacted: state.batReacted
                    )
                    .mask(
                        LightConeShape(
                            origin: actualPosition(state.sparkPositionNormalized, in: proxy.size),
                            radius: lightConeRadius(in: proxy.size),
                            headingDegrees: state.headingDegrees,
                            coneAngleDegrees: 120
                        )
                    )
                    .transition(.opacity)
                }

                // The visual cone glow
                if state.isLightOn {
                    DirectionalLightConeView(
                        origin: actualPosition(state.sparkPositionNormalized, in: proxy.size),
                        radius: lightConeRadius(in: proxy.size),
                        headingDegrees: state.headingDegrees,
                        color: .torchYellow
                    )
                }

                // Spark (back view, rotates to face heading)
                sparkLayer(in: proxy.size)

                // Idle hint (subtle ring around Spark before first tap)
                if !state.isLightOn && shouldShowAttentionPulse {
                    AttentionPulse()
                        .position(actualPosition(state.sparkPositionNormalized, in: proxy.size))
                }

                // Joystick in bottom-right corner
                if state.isLightOn && state.phase == .exploring {
                    VirtualJoystick(size: 130) { vec in
                        state.setJoystick(vec)
                    }
                    .padding(.trailing, Spacing.lg)
                    .padding(.bottom, Spacing.xl)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .transition(.opacity)
                }

                // First-tap hint
                if !state.isLightOn {
                    Text("Tap Spark to turn on the light")
                        .font(.hintCaption)
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, Spacing.xxl)
                        .transition(.opacity)
                }
            }
            .onAppear {
                state.hintEngine.start()
                audio.startAmbient(.shadowCave)
                startMovementLoop()
            }
            .onDisappear {
                state.hintEngine.stop()
                audio.stopAmbient()
                stopMovementLoop()
            }
            .onChange(of: state.phase) { _, newPhase in
                handlePhaseChange(newPhase)
            }
            .onChange(of: state.discoveries) { old, new in
                if new.subtracting(old).isEmpty == false {
                    audio.play(.discoveryChime)
                }
            }
            .fullScreenCover(isPresented: completionBinding) {
                LevelCompleteView(
                    stars: state.starsEarned,
                    conceptLearned: "Light reveals only what it touches.",
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

    // MARK: - Spark visual

    @ViewBuilder
    private func sparkLayer(in size: CGSize) -> some View {
        let pos = actualPosition(state.sparkPositionNormalized, in: size)
        Image("SparkBack")
            .resizable()
            .scaledToFit()
            .frame(width: 88, height: 88)
            .rotationEffect(.degrees(state.headingDegrees))
            .shadow(color: state.isLightOn ? .torchYellow.opacity(0.4) : .voltBlue.opacity(0.5), radius: 12)
            .position(pos)
            .onTapGesture { handleTap() }
            .animation(.easeInOut(duration: 0.25), value: state.headingDegrees)
    }

    // MARK: - Movement loop

    private func startMovementLoop() {
        stopMovementLoop()
        movementTask = Task { @MainActor in
            var last = Date()
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(16))
                let now = Date()
                let dt = now.timeIntervalSince(last)
                last = now
                state.tickMovement(deltaTime: dt)
            }
        }
    }

    private func stopMovementLoop() {
        movementTask?.cancel()
        movementTask = nil
    }

    // MARK: - Layout helpers

    private func actualPosition(_ normalized: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: normalized.x * size.width, y: normalized.y * size.height)
    }

    private func lightConeRadius(in size: CGSize) -> CGFloat {
        min(size.width, size.height) * 0.52
    }

    // MARK: - Phase / hint visuals

    private var shouldShowAttentionPulse: Bool {
        state.phase == .dark && (state.hintEngine.currentLevel == .nudge || state.hintEngine.currentLevel == .hint || state.hintEngine.currentLevel == .strong)
    }

    private var completionBinding: Binding<Bool> {
        Binding(get: { state.phase == .complete }, set: { _ in })
    }

    private var testBinding: Binding<Bool> {
        Binding(get: { state.phase == .test }, set: { _ in })
    }

    // MARK: - Interaction

    private func handleTap() {
        guard state.phase == .dark else { return }
        audio.play(.lightOn)
        withAnimation(.easeOut(duration: 0.6)) {
            state.tapSpark()
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
            prompt: "Spark walks through a dark cave with his flashlight off.\nWhat can Spark see?",
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

// MARK: - Attention pulse (subtle ring before first tap)

private struct AttentionPulse: View {
    @State private var scale: CGFloat = 1.0
    var body: some View {
        Circle()
            .stroke(Color.torchYellow.opacity(0.5), lineWidth: 2)
            .frame(width: 110, height: 110)
            .scaleEffect(scale)
            .opacity(2 - scale)
            .onAppear {
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                    scale = 1.6
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
