# Shadow Realm — Level 1: "First Light"

> **The most important level in the entire app.** It has 30 seconds to hook the student, teach the controls without a tutorial, deliver one aha moment, and make them want Level 2.

> **Status (2026-05-08): ✅ Implemented.** Code lives at [`Physica/Physica/Features/ShadowRealm/Level1/`](Physica/Physica/Features/ShadowRealm/Level1/) — `ShadowRealmLevel1State.swift`, `ShadowRealmLevel1View.swift`, `CaveEnvironmentView.swift`. The SwiftUI scaffolding section below is the original design reference. The actual implementation extends it (see "Implementation notes" at the bottom).

---

## 🎯 Concept Being Taught

**Light travels from a source and reveals what it touches.**

That's it. No "luminous vs non-luminous." No definitions. Just the fundamental intuition.

---

## 🎬 Opening Scene

- **Almost entirely black screen.** Only Spark's faint silhouette in the center.
- A single subtle pulse animation on Spark's eye — the only thing drawing attention.
- **No text. No tutorial. No buttons.**

Within 3-5 seconds, every student will tap Spark's eye. It's the only interactive thing on screen, and curiosity does the rest.

---

## ✨ The First Tap → Aha Moment

When the student taps Spark's eye:

1. Eye **brightens to warm yellow**
2. A **cone of light** sweeps out from the eye
3. The cone **reveals the environment** — they were in a small cave the whole time
4. Soft "*click-hum*" sound effect
5. Cave details fade in: rocks, a path leading right, mysterious shapes in the distance

**The aha:** *"There was a whole world here I couldn't see. Light revealed it."*

---

## 🎮 Phase 2: Movement & Discovery (next 30 seconds)

Student notices Spark can move (drag-based control).

- Drag Spark around the cave
- Light cone moves with Spark
- Areas behind Spark fall back into darkness
- Three "things" hidden in the cave to discover:
  - **Glowing crystal** (collectible — first XP reward)
  - **Sleeping bat** (reacts cutely when light touches it — first delight moment)
  - **Cave exit** (the level goal)

**No instructions tell them to find these.** They explore because the cave is dark and they want to see.

---

## 🏁 Win Condition

Reaching the cave exit:
- Burst of light
- Star rating animates in (1-3 stars based on discoveries)
- Subtle text: *"You've learned: **Light reveals what it touches.**"*
- This is the **only time text shows up** — at the end, naming what they just felt.

---

## ❌ Failure States

**There aren't any.** Level 1 cannot be failed. No timer, no lives lost.

**Critical:** Level 1 = trust-building. They need to feel safe exploring before later levels introduce challenge.

---

## 💡 Stuck Detection (the only "tutorial")

Progressive, silent hints:
- **30s no taps** → eye does attention-grabbing pulse + soft beep
- **60s no movement after first tap** → tiny floating arrow hint near Spark
- **2 min no exit** → faint glowing trail toward exit

Never patronizing, never blocking gameplay.

---

## 🧪 Post-Level Test (single question)

> *Spark's eye is off. The cave is dark. Spark walks forward.*
> *What does Spark see?*
>
> 🅰️ The whole cave
> 🅱️ Nothing
> 🅲️ Only the floor

**Answer:** B. Tests *transfer* of "light reveals what it touches" to a new scenario.

If wrong → replay the relevant moment, not a text explanation.

---

## ⭐ Star Rating Logic

| Stars | Condition |
|-------|-----------|
| 1 ⭐ | Reach exit |
| 2 ⭐⭐ | Reach exit + discover crystal OR bat |
| 3 ⭐⭐⭐ | Reach exit + discover crystal AND bat |

---

## 🛠️ SwiftUI Scaffolding

```swift
import SwiftUI

// MARK: - Game State

@Observable
final class Level1State {
    var sparkPosition: CGPoint = CGPoint(x: 200, y: 400)
    var isLightOn: Bool = false
    var discoveries: Set<DiscoveryID> = []
    var hasReachedExit: Bool = false

    let crystalPosition  = CGPoint(x: 80, y: 200)
    let batPosition      = CGPoint(x: 320, y: 150)
    let exitPosition     = CGPoint(x: 350, y: 600)

    enum DiscoveryID: Hashable { case crystal, bat, exit }

    func tapSpark() {
        guard !isLightOn else { return }
        withAnimation(.easeOut(duration: 0.6)) {
            isLightOn = true
        }
    }

    func moveSpark(to newPosition: CGPoint) {
        sparkPosition = newPosition
        checkDiscoveries()
    }

    private func checkDiscoveries() {
        if isClose(to: crystalPosition) { discoveries.insert(.crystal) }
        if isClose(to: batPosition)     { discoveries.insert(.bat) }
        if isClose(to: exitPosition) {
            discoveries.insert(.exit)
            hasReachedExit = true
        }
    }

    private func isClose(to point: CGPoint, threshold: CGFloat = 50) -> Bool {
        hypot(sparkPosition.x - point.x, sparkPosition.y - point.y) < threshold
    }

    var starsEarned: Int {
        guard hasReachedExit else { return 0 }
        return min(3, 1 + (discoveries.contains(.crystal) ? 1 : 0)
                       + (discoveries.contains(.bat) ? 1 : 0))
    }
}

// MARK: - Level 1 View

struct ShadowRealmLevel1View: View {
    @State private var state = Level1State()
    @State private var showCompletion = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CaveEnvironmentView(state: state)
                .opacity(state.isLightOn ? 1 : 0)

            if state.isLightOn {
                LightConeView(position: state.sparkPosition)
                    .blendMode(.screen)
                    .allowsHitTesting(false)
            }

            SparkView(isLightOn: state.isLightOn)
                .position(state.sparkPosition)
                .gesture(dragGesture)
                .onTapGesture { state.tapSpark() }
        }
        .onChange(of: state.hasReachedExit) { _, reached in
            if reached { showCompletion = true }
        }
        .sheet(isPresented: $showCompletion) {
            LevelCompleteView(stars: state.starsEarned)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard state.isLightOn else { return }
                state.moveSpark(to: value.location)
            }
    }
}
```

### Components to build
- `SparkView` — animated robot sprite (eye pulse, color shift, idle bob)
- `LightConeView` — radial gradient mask following Spark's position
- `CaveEnvironmentView` — cave art, crystal, bat, exit
- `LevelCompleteView` — star animation, "You've learned…" reveal, next button

---

## 🛠 Implementation notes (what shipped vs. this spec)

The shipped implementation extends the scaffold above. Key differences:

**Position model: normalized, not pixel-based.** The scaffold used hardcoded `CGPoint(x: 200, y: 400)` etc. Shipped code uses 0..1 normalized coordinates (`crystalPosition = CGPoint(x: 0.18, y: 0.30)`) and multiplies by `GeometryReader`'s size at render. This adapts to all device sizes.

**Phase machine.** State now has an explicit `Phase` enum: `dark → exploring → complete → test → finished`. The scaffold's `isLightOn: Bool` and `hasReachedExit: Bool` are derived from this. Adds clean transitions between gameplay, completion, and the post-level test.

**Reusable components factored out at app-level (Week 1 foundation).**
- `SparkView`, `LightConeView`, `LevelCompleteView`, `PostLevelTestView` live in `Core/Components/` — used here and reusable by every other level.
- `HintEngine` (`Core/Hints/`) drives the 30s/60s/120s timeline; the level just instantiates one with the timeline from this spec.
- `AudioManager` (`Core/Audio/`) wires the sound cues (`.lightOn`, `.discoveryChime`, `.levelComplete`, ambient `.shadowCave`). Stubs no-op until W8 audio assets land.
- `ProgressStore` (`Core/Persistence/`) records the completion + stars when the post-level test is passed.

**Light reveal mechanic.** The scaffold called for `LightConeView` with `.blendMode(.screen)`. Shipped code uses two layers: a `RadialGradient` **mask** on the cave (so the cave only shows inside the cone radius), plus a separate `LightConeView` for the warm yellow glow. This gives the "darkness shrouds, light reveals" feel cleanly.

**Hint visuals.**
- 30s no-tap → attention pulse ring around Spark (in `dark` phase only)
- 60s → handled by hint engine level shifts (currently a no-op visual; small arrow can land in W8 polish)
- 120s no exit → dashed yellow trail from Spark to exit (`HintTrailView`)

**Wrong-answer flow.** The scaffold didn't specify; per the pedagogy ("replay the moment, not a text explanation"), wrong answer on the post-level test calls `state.reset()` — phase returns to `.dark`, discoveries clear, hint engine restarts.

**Placeholder art.** Cave art, crystal, bat, exit arch are all SwiftUI shapes (`Path`, `RadialGradient`, `Circle`, `Capsule`) — no asset-catalog images yet. Real art slots in at W8 with no API change.

**Accessibility.** `SparkView` and discovery items have `accessibilityLabel`. Reduced-motion respected on idle hover and pulse animations.
