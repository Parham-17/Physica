# Physica — Light Realm: Project Pipeline & Agent Handoff

**Version:** 2.0 (replaces V1)
**Team:** Secret API (7 people)
**World:** 1 of 5 — Light
**Source curriculum:** Physics 6, Chapter 5: Light (pp. 72–85)
**Design philosophy:** Interactable storytelling. Every module is a chapter in Spark's journey. The physics is the mechanic; the story is the reason.

---

## 0. Quick Start (read this first)

You are working on **Physica**, a story-driven physics learning app for 10–14 year olds. The first world is the **Light Realm**, a ruined observatory kingdom restored across 7 chapters. Each chapter teaches one light concept by putting the physics directly in the player's hands, and ends with **Spark** bridging the concept to a real-world example the kid actually sees in daily life.

**Before you write any code:**
1. Read sections 1–5 completely (intent, decisions, tech, structure, narrative).
2. Find your assigned module in section 7.
3. Confirm Core Systems dependencies (section 6) and Definition of Done (section 10).
4. Match the file structure exactly (section 4) so other teammates integrate without friction.

**Non-negotiables:**
- iOS 18+. SpriteKit for game scenes, SwiftUI for shell. `@Observable` for state. SwiftData for save.
- **Portrait orientation only.** All layouts, puzzles, and dialogue are portrait-first.
- Every module is a narrative chapter, not a standalone puzzle.
- Every module ends with a **Spark Connection** — a real-world bridge delivered by Spark in character.
- All modules reuse `Core/` types. Do not fork or duplicate them.
- Follow Apple HIG. No third-party UI libraries.

---

## 1. Project Intent

### The pivot
Physica is not a physics game with a story bolted on. It is a story-driven app where the chapters happen to teach physics. The player should not feel like they are studying optics. They should feel like they are walking a broken kingdom alongside a small robot who is learning the world for the first time — and noticing that the rules of light in this strange place are the same rules they see at home.

### The vision statement
> By using the mascot, Spark, we bridge the gap between abstract theory and high-stakes real-world examples — like the optics of an ambulance siren mirror. Each module is a necessary chapter in a larger story, maintaining balance between fun engagement and the technical constraints of an app's UI/UX.

### Core promise
Light can reveal, guide, block, reflect, and heal. Once you understand it inside the realm, you start noticing it outside the realm.

### Core teaching principle
Teach the concept through interaction first. Let the player do it before naming it. Then connect it to real life via Spark.

### What "medium narrative cadence" means
Each module has exactly **4 dialogue beats**:
1. **Opening beat** — Spark frames the chapter on arrival
2. **Discovery beat** — Spark reacts the first time the player does the core mechanic
3. **Insight beat** — Spark names the concept after the puzzle is solved
4. **Spark Connection beat** — Spark bridges to a real-world example

Plus a **15–30 second between-chapter transition** showing Spark moving to the next location with 1–2 reflective lines. No voice acting in V1; rich, expressive Spark portrait + typewriter text.

---

## 2. Locked Decisions

| Decision | Value | Rationale |
|---|---|---|
| Modules in V1 | 7 | Matches challenge scope, leaves polish budget |
| Game engine | SpriteKit | Built for 2D, particle FX, sprite animation |
| Shell framework | SwiftUI | Menus, journal, dialogue, settings |
| State | `@Observable` macro | iOS 17+ standard |
| Persistence | SwiftData | Save state, progression, journal, assessment log |
| Audio | AVFoundation | Music, SFX, ambience |
| Minimum iOS | 18.0 | Modern macros + SpriteKit APIs |
| **Orientation** | **Portrait only** | App constraint; narrative-led layout |
| Localization | English V1 | i18n keys in place; translation deferred |
| Narrative intensity | Medium | 4 dialogue beats per module + transitions |
| Umbra reveal | M7 only | Mystery preserved across M3–M6 |
| Voice acting | None in V1 | Out of scope for timeline |

### Out of scope (V1)
- Refraction (Glassfall — deferred to future world)
- Color theory / filters / additive mixing
- Diffuse reflection as its own module
- Adaptive mastery state machine (log evidence to SwiftData for V2)
- Voice acting, multiplayer, cloud sync
- iPad-specific UI (universal binary, but design portrait-first for iPhone)

---

## 3. Tech Stack

```
iOS 18+ ──────────────────────────────────────
│
├── SwiftUI (shell — first-class)
│   ├── Main menu, world map, journal
│   ├── DialogueOverlay (always-available, portrait-tuned)
│   ├── Settings, accessibility
│   └── Assessment / Spark Field Report
│
├── SpriteKit (game)
│   ├── One SKScene per module + one per transition
│   ├── Shared SKNode subclasses (Core/Light/, Core/Character/)
│   └── SKEmitterNode (.sks) for particle FX
│
├── @Observable (state)
│   ├── GameState (current module, save slot)
│   ├── ProgressionStore
│   ├── DialogueController
│   └── NarrativeFlags (which beats have fired, which Umbra glimpses seen)
│
├── SwiftData (persistence)
│   ├── PlayerProfile
│   ├── ModuleProgress
│   ├── AssessmentEvent (stealth log)
│   ├── JournalEntry
│   └── NarrativeProgress (story flags)
│
└── AVFoundation (audio)
    ├── Music: AVAudioPlayer w/ crossfade
    └── SFX: AVAudioPlayerNode pool
```

### Portrait constraints (enforce app-wide)
- Lock orientation in `Info.plist` (iPhone: Portrait only).
- Reference safe area on all SwiftUI views (notch + home indicator).
- SpriteKit scene size: design for **9:19.5** aspect (iPhone 15 Pro = 393×852pt). Use `.aspectFill` with letterbox tolerance.
- Dialogue overlay: bottom 28% of screen. Always above the safe area inset.
- Game UI (pause, hint button): top 8%. Below the dynamic island/notch.
- Active play area: middle 64%. Plan puzzles to read clearly within this band.

### SpriteKit ↔ SwiftUI bridge
- Each module presented via `SpriteView` inside a SwiftUI container.
- SwiftUI owns navigation, pause menu, dialogue overlay, transitions.
- SpriteKit owns gameplay, animations, in-scene FX.
- Communication via `@Observable` `GameState` + Combine publishers.

---

## 4. File Structure

```
Physica/
├── App/
│   ├── PhysicaApp.swift              ← @main, SwiftData container, orientation lock
│   ├── RootView.swift                ← navigation root
│   └── DependencyContainer.swift
│
├── Core/
│   ├── Light/
│   │   ├── LightEmitter.swift
│   │   ├── LightBeam.swift
│   │   ├── LightReceiver.swift
│   │   ├── BlockerObject.swift
│   │   ├── MirrorObject.swift
│   │   ├── MaterialPanel.swift
│   │   ├── ShadowZone.swift
│   │   ├── LightSimulation.swift
│   │   └── LightSimulation+Reflection.swift
│   │
│   ├── Character/                    ← NEW in V2
│   │   ├── SparkCharacter.swift      ← SKNode, animation states, portrait
│   │   ├── SparkExpressions.swift    ← enum + asset bindings
│   │   └── UmbraCharacter.swift      ← silent presence + final scene
│   │
│   ├── Narrative/                    ← NEW in V2
│   │   ├── NarrativeFlags.swift      ← @Observable
│   │   ├── ChapterController.swift   ← orchestrates module → transition → next
│   │   ├── TransitionScene.swift     ← 15–30s between-module scenes
│   │   └── ConnectionBeat.swift      ← the real-world bridge moment
│   │
│   ├── Puzzle/
│   │   ├── PuzzleGoal.swift
│   │   ├── PuzzleStateMachine.swift
│   │   └── PuzzleCompletion.swift
│   │
│   ├── Dialogue/
│   │   ├── DialogueController.swift  ← @Observable
│   │   ├── DialogueModel.swift       ← Beat type w/ speaker, expression, trigger
│   │   ├── DialogueLoader.swift      ← JSON
│   │   └── TypewriterRenderer.swift  ← SwiftUI text effect
│   │
│   ├── Progression/
│   │   ├── GameState.swift
│   │   ├── ProgressionStore.swift
│   │   └── ModuleRegistry.swift
│   │
│   ├── Assessment/
│   │   ├── AssessmentEvent.swift
│   │   ├── AssessmentLogger.swift
│   │   └── MasteryEvidence.swift
│   │
│   └── Audio/
│       ├── AudioManager.swift
│       ├── MusicPlayer.swift
│       └── SFXPool.swift
│
├── Modules/
│   ├── M1_SleepingBeacon/
│   │   ├── M1Scene.swift             ← SKScene
│   │   ├── M1Coordinator.swift       ← puzzle logic
│   │   ├── M1Assets.swift            ← asset name enum
│   │   └── M1Dialogue.json           ← 4 beats + transition lines
│   ├── M2_LineOfDawn/
│   ├── M3_ShadowGarden/
│   ├── M4_CrystalGate/
│   ├── M5_PinholeStudio/
│   ├── M6_Mirrorworks/
│   └── M7_EclipseTower/
│
├── Transitions/                      ← NEW in V2
│   ├── T1_ToCauseway.swift
│   ├── T2_ToGarden.swift
│   ├── T3_ToCrystals.swift
│   ├── T4_ToMemory.swift
│   ├── T5_ToWorkshop.swift
│   └── T6_ToTower.swift
│
├── Shell/
│   ├── MainMenu/
│   ├── WorldMap/
│   ├── Journal/
│   ├── Settings/
│   ├── DialogueOverlay/              ← bottom-anchored, portrait-tuned
│   └── Assessment/
│
├── Models/                           ← SwiftData
│   ├── PlayerProfile.swift
│   ├── ModuleProgress.swift
│   ├── JournalEntry.swift
│   └── NarrativeProgress.swift
│
└── Resources/
    ├── Assets.xcassets
    ├── Audio/
    ├── Dialogue/                     ← JSON per module + transitions
    ├── Particles/                    ← .sks files
    └── Localization/
```

---

## 5. Narrative Architecture

This section is required reading for everyone, not just writers and designers. The architecture controls how scenes are built, when the player can act, and what the dialogue system has to support.

### 5.1 Spark's arc across the realm

| Chapter | Spark's inner state | Knows about Umbra | Confidence level |
|---|---|---|---|
| M1 | Confused, just woke up | No knowledge | Low |
| M2 | Curious, starting to test the world | No | Low/medium |
| M3 | Sees Umbra for the first time, unsettled | Senses presence | Medium |
| M4 | Wants to understand materials, distracted by Umbra glimpses | Sees fleeting signs | Medium |
| M5 | Reflective, sees own past in pinhole memories | Glimpses Umbra in a reflection | Medium/high |
| M6 | Confident, decoding patterns | Sees a clue in the mirror script | High |
| M7 | Ready to meet Umbra, prepared to listen | Faces directly | Resolved |

This arc must show in Spark's **dialogue tone, facial expression, and movement speed** — not just in words. Each Spark expression asset (idle, curious, alarmed, hopeful, steady, resolved) maps to a chapter range.

### 5.2 Umbra's presence (mystery preserved)

Umbra never speaks before M7. But Umbra is *not* invisible. The player should feel watched.

| Chapter | Umbra's appearance |
|---|---|
| M1, M2 | Not present |
| M3 | Single silent silhouette at chapter end. Holds for 2s. Walks off-screen. |
| M4 | A shadow flickers across a wall during a puzzle interaction. No animation, no acknowledgment. |
| M5 | When a pinhole memory is captured, for one frame the inverted image contains an extra silhouette that wasn't in the source. The player may or may not notice. |
| M6 | The mirror inscription, when read in the handheld mirror, contains a faint character watermark in the corner — Umbra's mark. |
| M7 | First and only speech. Full presence. Resolution. |

Spark **never directly references Umbra by name** before M7. He may say "did you see that?" or "something is here" once, in M3 — and not again.

### 5.3 The four dialogue beats per module

Every module has the same dialogue rhythm:

| Beat | Trigger | Length | Purpose |
|---|---|---|---|
| **Opening** | Module load, after fade-in | 1–2 lines | Frame the chapter |
| **Discovery** | First successful interaction with core mechanic | 1–2 lines | React to the moment of physics |
| **Insight** | Puzzle completion / objective met | 1–2 lines | Name the concept |
| **Spark Connection** | Triggered by player tap "Continue" after Insight | 2–3 lines | Bridge to real life |

Beats are defined in `Modules/Mx/MxDialogue.json` and triggered by `DialogueController`. They must fire **exactly once per session** and persist in `NarrativeProgress`.

### 5.4 The Spark Connection beats (the real-world bridges)

This is the heart of the pivot. Each is workshopped here as a first draft. Writing lead refines.

| # | Module | Spark Connection |
|---|---|---|
| M1 | Sleeping Beacon | *"At night, when the streetlight on your block turns on, the whole street remembers it exists. Nothing changed except light."* |
| M2 | Line of Dawn | *"Look at a sunbeam coming through a window when the air is dusty. The line is straight. Always. That's all light knows how to do."* |
| M3 | Shadow Garden | *"On a sunny day your shadow is sharp — you can see your fingers. Under a cloudy sky, your shadow almost disappears. The sky becomes one big soft lamp."* |
| M4 | Crystal Gate | *"A frosted bathroom window lets the light in but not the view. A clear window lets both. A wall lets neither. Same three categories, every house."* |
| M5 | Pinhole Studio | *"Your eye works like this. A tiny opening, a curved screen, and the image inside your head is upside-down. Your brain just flips it back."* |
| M6 | Mirrorworks | *"Have you ever seen an ambulance? Look at the word on the front — it's written backwards. So when the driver ahead checks their mirror, they can read it. Same trick we just used."* |
| M7 | Eclipse Tower | *"When you cover a flashlight with your hand in a dark room, your shadow appears on the wall. An eclipse is the same thing. Just bigger. Just a moon, not a hand."* |

These lines are the **single most important text in the app**. They are what kids remember 6 months later. Treat them as final once approved.

### 5.5 Between-chapter transitions

Between every two modules, a `TransitionScene` plays:

- 15–30 seconds.
- Spark visibly moves to the next location (walk, glide, climb).
- World state visibly restored from previous chapter (a beacon glowing, a gate open, a garden lit).
- 1–2 lines of dialogue from Spark — reflective on what happened, foreshadowing what's next.
- Tap-to-skip allowed after 3 seconds.

Implemented as small `SKScene` subclasses in `Transitions/`, driven by `ChapterController`.

### 5.6 Dialogue overlay specification (portrait)

- Sits in bottom 28% of screen.
- Spark portrait on left (or Umbra in M7), text panel on right.
- Typewriter effect at 35 characters/second.
- Tap anywhere advances. Tap during typewriter completes the line.
- After last line of a beat, dialogue dismisses; gameplay resumes.
- Always above safe area; never covers active puzzle elements (puzzle area is constrained to top 64%).

---

## 6. Core Systems (shared library)

These types are shared across all 7 modules. Do not duplicate, fork, or shadow them. If a module needs different behavior, extend via subclass or composition — never edit the base type without team sign-off.

### 6.1 `LightEmitter`
```swift
@Observable
final class LightEmitter: SKNode {
    var direction: CGVector       // unit vector
    var intensity: CGFloat        // 0...1
    var color: SKColor            // V1: always white
    var isOn: Bool
    var sourceType: SourceType
    
    enum SourceType {
        case point
        case extended(radius: CGFloat)
    }
    
    func emit() -> LightBeam
}
```

### 6.2 `LightBeam`
```swift
final class LightBeam: SKNode {
    private(set) var segments: [BeamSegment]
    var color: SKColor
    var intensity: CGFloat
    
    struct BeamSegment {
        let start: CGPoint
        let end: CGPoint
        let intensity: CGFloat
    }
    
    func render()
    func appendSegment(_ segment: BeamSegment)
    func clear()
}
```
Render via `SKShapeNode` + glow `SKEmitterNode`. Do not use `SKLightNode`.

### 6.3 `LightReceiver`
```swift
final class LightReceiver: SKNode {
    var isActivated: Bool
    var requiredIntensity: CGFloat
    var requiredColor: SKColor?
    var requiredBeamProfile: BeamProfile?  // .sharp / .scattered / .blocked
    var onActivate: (() -> Void)?
    
    func receive(_ beam: LightBeam)
}
```

### 6.4 `BlockerObject`
```swift
class BlockerObject: SKSpriteNode {
    var isOpaque: Bool = true
    var castsShadow: Bool = false
    var blockerShape: BlockerShape  // .rect, .circle, .polygon([CGPoint])
}
```

### 6.5 `MirrorObject`
```swift
final class MirrorObject: SKSpriteNode {
    var rotationAngle: CGFloat
    var snapAngle: CGFloat = .pi / 12  // 15°
    var maxReflections: Int = 3
    var showsAngleIndicator: Bool = false  // protractor overlay (M6 L2+)
    
    func reflect(incoming: CGVector) -> CGVector
}
```

### 6.6 `MaterialPanel`
```swift
final class MaterialPanel: SKSpriteNode {
    var materialType: MaterialType
    
    enum MaterialType {
        case transparent      // pass clean
        case translucent      // soften, intensity *= 0.5, widen glow
        case opaque           // block, cast shadow
    }
    
    func transform(_ beam: LightBeam) -> LightBeam
}
```

### 6.7 `ShadowZone`
```swift
final class ShadowZone: SKNode {
    var polygon: [CGPoint]
    var darknessLevel: DarknessLevel
    
    enum DarknessLevel {
        case umbra
        case penumbra
    }
    
    func contains(_ point: CGPoint) -> Bool
}
```

### 6.8 `LightSimulation`
```swift
final class LightSimulation {
    weak var scene: SKScene?
    
    func cast(from emitter: LightEmitter, maxDistance: CGFloat = 4000) -> LightBeam
    func updateShadowZones()
    func tick(_ dt: TimeInterval)
}
```
Performance: one cast < 1ms on iPhone 12. Use `SKPhysicsWorld.enumerateBodies(alongRayStart:end:using:)`.

### 6.9 `SparkCharacter` (NEW)
```swift
final class SparkCharacter: SKNode {
    var expression: SparkExpression  // .idle, .curious, .alarmed, .hopeful, .steady, .resolved
    var coreGlow: GlowState          // .dim, .warm, .stable, .bright
    
    func playReaction(_ reaction: SparkReaction)  // .blink, .turn, .light_up, .shrink
    func portrait() -> Image  // SwiftUI portrait for dialogue overlay
}
```
Spark is a first-class character system, not a sprite. Used in every module and every transition. Portrait expressions drive the dialogue overlay; in-scene animation drives presence.

### 6.10 `PuzzleStateMachine`
States: `.idle`, `.active`, `.partialSuccess`, `.solved`, `.failed`. Transitions trigger dialogue beats and `NarrativeProgress` updates.

### 6.11 `DialogueController` (`@Observable`)
SwiftUI overlay reads from this. JSON schema:
```json
{
  "module": "M1",
  "beats": [
    {
      "id": "m1_opening",
      "type": "opening",
      "speaker": "spark",
      "expression": "curious",
      "lines": ["Where am I?", "It is so dark."],
      "trigger": "onSceneLoaded",
      "showOnce": true
    },
    {
      "id": "m1_discovery",
      "type": "discovery",
      "speaker": "spark",
      "expression": "hopeful",
      "lines": ["You aimed the light at me.", "I... I can see again."],
      "trigger": "onSparkActivated"
    },
    {
      "id": "m1_insight",
      "type": "insight",
      "speaker": "spark",
      "expression": "steady",
      "lines": ["When light touches something here, it remembers how to wake up."],
      "trigger": "onBeaconRestored"
    },
    {
      "id": "m1_connection",
      "type": "connection",
      "speaker": "spark",
      "expression": "steady",
      "lines": [
        "At night, when the streetlight on your block turns on,",
        "the whole street remembers it exists.",
        "Nothing changed except light."
      ],
      "trigger": "onContinueAfterInsight"
    }
  ]
}
```

### 6.12 `AssessmentLogger`
```swift
@Model
final class AssessmentEvent {
    var timestamp: Date
    var moduleID: String
    var eventType: String
    var metadata: [String: String]
}
```
Writes on every meaningful player action. No UI. Feeds V2's adaptive system.

---

## 7. Module Specifications

All modules are portrait-first. Active play area = middle 64% of screen. Dialogue area = bottom 28%. UI area = top 8%.

---

### Module 1 — The Sleeping Beacon

**Purpose:** Tutorial. Introduce the realm, Spark, and the core idea that light reveals things.

**Player-facing concept:** Things wake up when light reaches them.
**Physics concept:** Light is energy. Luminous bodies emit; non-luminous bodies become visible when light reaches them.

**Story (Opening):** The player enters the **Dawn Court**, a dark plaza at the realm's edge. Spark lies inactive beside a broken beacon. A single shaft of light falls from a crack in the ceiling.

**Objective:** Wake Spark; restore the first beacon.

**Player actions (portrait layout):**
- Drag a movable lantern across the floor (horizontal slider band, middle of screen).
- The beam shoots upward by default; lantern position determines where it falls on Spark / receivers above it.
- Activate 3 receiver crystals positioned around the upper play area.

**Core types used:** `LightEmitter`, `LightBeam`, `LightReceiver`, `SparkCharacter`.

**Dialogue beats:**
- **Opening** — *"Where am I? It is so dark."*
- **Discovery** (Spark wakes) — *"You aimed the light at me. I... I can see again."*
- **Insight** — *"When light touches something here, it remembers how to wake up."*
- **Spark Connection** — the streetlight bridge (section 5.4).

**Transition out:** Spark stands, glows warmly. Beacon column extends up out of frame. Camera follows up. Spark says: *"There's a path forward. The light is showing us the way."*

**Required assets:**
- Dawn Court background (vertical parallax: floor, mid columns, ceiling crack)
- Lantern sprite (idle, drag, glow states)
- Spark: inactive, boot-up (3 frames), idle (4 frames), portrait set with all expressions
- Beam VFX (vertical glow + dust particles)
- 3 receiver crystal sprites (off, glow, on)
- Beacon: broken, restored, activation cinematic
- Dust particle .sks (gentle, ambient)

**Audio:** mysterious ambience loop (low strings + breath), beam hum, receiver chime, Spark boot-up SFX (mechanical click + warm rise), restoration sting.

**Definition of Done:**
- [ ] Player can wake Spark in <60 seconds without help
- [ ] All 3 receivers activatable in any order
- [ ] All 4 dialogue beats fire exactly once
- [ ] Save state persists "M1 completed" → unlocks M2 on world map
- [ ] Transition scene plays before M2 loads
- [ ] Runs at 60fps on iPhone 12; portrait orientation locked

---

### Module 2 — The Line of Dawn

**Purpose:** Teach that light travels in straight lines.

**Player-facing concept:** Light follows a straight path unless something blocks it.
**Physics concept:** Rectilinear propagation. Direct nod to book Experiment 2 (cardboard alignment).

**Story (Opening):** The restored beacon reveals a tall **Dawn Causeway** rising before them — a vertical structure of broken arches with eye-like receivers at three levels. Spark says the gate at the top will open if light can reach every eye.

**Objective:** Align the beam through the Dawn Gate.

**Player actions (portrait layout):**
- Bottom of screen: rotatable lantern pedestal (drag in circular arc to aim).
- Middle of screen: 2–3 vertical floors with broken pillars and stone blockers (draggable).
- Top of screen: 3 receiver eyes + Dawn Gate.
- Beam shoots upward; player must clear the path floor by floor.

**Levels (3):**
1. One floor, one blocker, one eye. Direct nod to "light goes straight."
2. Two floors, requires rotating the pedestal slightly.
3. Three floors — three holes through three "cardboard panels." Direct visual reference to Experiment 2. Player drags each panel until all holes align vertically.

**Core types used:** `LightEmitter`, `LightBeam`, `LightReceiver`, `BlockerObject`.

**Dialogue beats:**
- **Opening** — *"The gate is at the top. The light needs a clear line all the way up."*
- **Discovery** (first blocker placement) — *"It doesn't curve around the stone. It just... stops."*
- **Insight** (gate opens) — *"So light follows a path. A very stubborn, straight path."*
- **Spark Connection** — the dusty sunbeam bridge.

**Transition out:** Spark walks the causeway upward, looks back at the player. *"Wherever the light goes here, it goes straight. Let's see what happens when something tries to block more than just stone."*

**Required assets:**
- Vertical causeway background (parallax: 3 floors + sky)
- Rotating lantern pedestal sprite
- 3 movable stone blocker variants
- 3 receiver eye sprites
- 3 "cardboard panel" sprites for level 3
- Dawn Gate: closed, opening animation
- "Beam blocked" VFX (red glow at impact)

**Definition of Done:**
- [ ] Beam updates in real time as pedestal rotates or blockers move
- [ ] All 3 levels solvable
- [ ] Snap angles feel responsive (15° default; test on real kids before locking)
- [ ] Gate cinematic plays once; module marked complete
- [ ] All 4 dialogue beats fire correctly
- [ ] Transition plays

---

### Module 3 — Shadow Garden (Candle Wall + Bird Tower)

**Purpose:** Teach shadows. Introduce umbra/penumbra through the source-size shift. Umbra's first silent appearance.

**Player-facing concept:** Blocking light makes a shadow. The shape of the source changes the shape of the shadow.
**Physics concept:** Opaque objects block light and create shadows. Point sources produce sharp umbra; extended sources produce umbra + penumbra. Distant or high objects may not cast useful shadows.

**Story (Opening):** Spark enters a quiet luminous garden. A stone wall is covered in **faded shadow murals** — the realm's ancient art. A small table holds carved silhouettes (flower, bird, tree). A candle waits on a tray. The murals are puzzles waiting to be completed.

**Objective:** Restore 7 shadow murals across three levels.

**Levels (3):**

**Level 1 — Candle (point source):** Player holds a candle (drag it across the table). Three carved silhouettes sit on the table. Shadows of the silhouettes fall on the wall. Player matches 3 faded murals by positioning the candle at the right distance — closer = bigger shadow, farther = smaller. Shadow edges are sharp.

**Level 2 — Lantern (extended source):** The candle goes out. Spark hands the player a lantern (extended source). Now shadows have **soft edges** (umbra + penumbra). Three more murals — but these only match when reproduced with a soft-edged shadow.

**Level 3 — Bird Tower:** The final mural is at the top of a tall tower. Reach it by placing objects on platforms at three heights. Big object on low platform → big sharp shadow on the ground. Small object on high platform → shadow disappears entirely (the umbra never reaches the ground). Direct teaching of the book's "birds flying high don't cast shadows."

**The 7th and final shadow, once formed correctly, is Umbra's silhouette.** Hold for 2 seconds. Umbra (as a real character, not a shadow) appears at the edge of the screen. Silent. Walks off. Spark notices and goes quiet for a beat.

**Core types used:** `LightEmitter` (point and extended), `LightBeam`, `ShadowZone`, `BlockerObject`.
**New systems:** `ShadowPolygonComputer` (compute 2D shadow polygons from emitter + blocker).

**Dialogue beats:**
- **Opening** — *"Someone made these. They were trying to remember something."*
- **Discovery** (first mural matched) — *"The shape on the wall came from the shape on the table. The candle made it big."*
- **Insight** (level 2 complete) — *"The lantern is wider than the candle. So the edges go soft. Two kinds of shadow."*
- **Spark Connection** — the sunny day vs cloudy sky bridge.

**Special: Umbra glimpse beat (after the 7th mural):**
- Spark, low voice: *"Did you... did you see that?"*
- Pause. No answer. Music dims.
- *"Let's keep moving."*
This is the only time Spark acknowledges Umbra before M7.

**Transition out:** Spark walks quickly out of the garden, head turning back once. World ambient music is softer than before.

**Required assets:**
- Garden background (luminous plants, soft palette, stone wall on left)
- Candle sprite (lit + flicker)
- Lantern sprite (lit, glow extended)
- 6 silhouette table objects (flower, bird, tree, fish, cloud, sun)
- 7 faded mural placeholders + their "matched" lit states
- Bird Tower environment (3 platforms vertical)
- Shadow polygon shader (sharp edge mode + soft edge mode)
- Umbra silent silhouette appearance animation

**Definition of Done:**
- [ ] Shadow zones recompute every frame; no flicker
- [ ] Source type swap visibly changes shadow edge (hard vs soft)
- [ ] All 7 murals matchable; Bird Tower communicates "too high = no shadow"
- [ ] Umbra appearance triggers exactly once, at mural 7
- [ ] Spark's special glimpse beat fires only here
- [ ] Stealth log records source-type swaps + shadow size variance per attempt

---

### Module 4 — Crystal Gate

**Purpose:** Teach optical media: transparent / translucent / opaque.

**Player-facing concept:** Different materials change what light can do.
**Physics concept:** Transparent passes light cleanly. Translucent scatters it. Opaque blocks it.

**Story (Opening):** Spark approaches the **Crystal Gate** — a tall vertical door with three slots stacked along its center. Three sample materials sit on a tray below. Spark's scanner is damaged; he cannot classify materials until you teach him.

**Objective:** Place the correct material in each slot so each receiver gets the beam it needs.

**Player actions (portrait layout):**
- Bottom: emitter shoots beam upward.
- Middle: 3 vertically-stacked slots (drag materials in).
- Top: 3 receivers, each requiring a specific beam profile (sharp, scattered, blocked-for-color-receiver).
- Each receiver shows an icon hint: clean line / fog cloud / no-symbol.

**Levels:** one main puzzle with the full 3-slot system. Soft-fail: wrong material gives clear visual feedback, can be removed and retried.

**Umbra glimpse:** As player solves slot 2, a shadow briefly flickers across the wall behind the gate. Not Spark's. Not commented on.

**Core types used:** `MaterialPanel`, `LightReceiver` (with `requiredBeamProfile`), `LightSimulation`.

**Dialogue beats:**
- **Opening** — *"Three slots. Three samples. My scanner is broken — I need your eyes."*
- **Discovery** (first correct placement) — *"That one let the beam through clean. The line stayed sharp."*
- **Insight** (gate opens) — *"Three kinds of materials. Transparent, translucent, opaque. The light tells us which is which."*
- **Spark Connection** — the frosted bathroom window bridge.

**Transition out:** Gate opens upward. Spark's scanner lens activates (visual upgrade — persistent for the rest of the game). *"I can see them now. Materials. Properties. Everything has a story written in how light passes through it."*

**Required assets:**
- Crystal Gate environment (vertical cave entrance)
- 3 material samples (glass, fog-crystal, stone) — draggable
- Slot frame (3 slots stacked)
- 3 receiver variants matching profiles
- Beam VFX: sharp, scattered (wider glow + particles), blocked (red impact)
- Spark scanner upgrade animation (lens ring fades in, persistent)
- Gate-open cinematic
- Umbra flicker shadow asset

**Definition of Done:**
- [ ] All 9 slot/material combinations render correctly
- [ ] Receiver activation requires correct beam profile
- [ ] Scanner upgrade visible on Spark for rest of game
- [ ] Adaptive hint: if player swaps materials randomly >6 times, hint dialogue triggers
- [ ] Umbra flicker fires exactly once; not announced
- [ ] All 4 main dialogue beats fire correctly

---

### Module 5 — Pinhole Studio

**Purpose:** Teach the pinhole camera — the source book's flagship application.

**Player-facing concept:** A tiny hole turns the world upside down.
**Physics concept:** Pinhole camera: real, inverted, generally diminished image. Size depends on object distance (u), screen distance (v), and pinhole diameter. m = v/u.

**Story (Opening):** Spark enters the **Memory Chamber** — a warm, brass-lit room. Three pinhole rigs of decreasing size stand vertically. Spark says the realm's lost memories are stored as light patterns; the rigs can reconstruct them if calibrated correctly.

**Objective:** Capture 3 lost memories by matching target image profiles.

**Player actions (portrait layout) — vertical pinhole rig (natural fit for portrait):**
- Bottom: source object (Spark's profile, a tree, the broken beacon)
- Middle: pinhole box with diameter slider
- Top: screen with target outline overlay
- Player drags source up/down (changes u), drags screen up/down (changes v), adjusts pinhole slider
- Live readout: brass dial showing magnification m = v/u

**Levels (3):**
1. **Portrait mode** — fill the frame. Discover: closer object = larger image.
2. **Sharpshooter** — get sharpest possible image. Discover: smaller pinhole = sharper but dimmer.
3. **Trade-off** — bright AND sharp. Discover the tension. Elegant solution rewarded.

**Umbra glimpse:** When the 3rd memory is captured, the inverted image on the screen contains an extra silhouette — Umbra — that wasn't in the source. One frame only. Most players will not consciously catch it.

**Core types used:** custom — this module is more self-contained.
**New systems:**
- `PinholeRig` (object + pinhole + screen + image renderer)
- `PinholeImageRenderer` (invert source sprite, scale by v/u, blur by pinhole diameter)
- Magnification dial UI (brass, animated)

**Dialogue beats:**
- **Opening** — *"The memories are here. I just have to focus them."*
- **Discovery** (first inverted image) — *"Wait. It's upside down. The world flipped."*
- **Insight** (3 memories captured) — *"Smaller hole, sharper image. But darker. The light has to choose."*
- **Spark Connection** — the eye bridge. *"Your eye works like this. A tiny opening, a curved screen, and the image inside your head is upside-down. Your brain just flips it back."*

**Transition out:** Spark holds a small captured memory in his hands. Looks at the player. *"I think I'm starting to remember who I was."*

**Required assets:**
- Memory Chamber background (warm brass, archival, vertical)
- 3 source-object sprites
- Pinhole rig parts (object plinth, pinhole box, screen, sliders)
- Brass magnification dial (animated)
- "Memory captured" flash + scrapbook animation
- Target image outline overlay
- Hidden Umbra frame for memory 3

**Definition of Done:**
- [ ] Image renders inverted, scaled by v/u, blurred proportional to pinhole diameter
- [ ] All 3 challenges solvable
- [ ] Magnification dial updates live; accurate to ±5%
- [ ] 3 memories appear in Journal
- [ ] Umbra hidden frame triggers exactly once on memory 3
- [ ] All 4 dialogue beats fire correctly
- [ ] Vertical layout works on all supported iPhone sizes

---

### Module 6 — Mirrorworks Arcade

**Purpose:** Teach reflection — including the **law of reflection** (angle of incidence = angle of reflection) and **lateral inversion** (the AMBULANCE moment).

**Player-facing concept:** Mirrors don't just bounce light. They follow a rule, and they flip what they show.
**Physics concept:** Smooth surfaces reflect light predictably. Angle of incidence = angle of reflection. Mirror images are laterally inverted (left/right flipped).

**Story (Opening):** Spark climbs to the **Mirror Spire** — a tall vertical workshop where old machines were powered by reflected light. Four chambers stack one above the other. Each chamber teaches one rule about mirrors.

**Objective:** Restore the spire and read its locked inscription.

**Player actions and levels (4, stacked vertically as chambers):**

**Chamber 1 — First Bounce:**
One mirror, one beam, one target. Player rotates mirror to redirect a beam. Simple.

**Chamber 2 — The Protractor Mirror (the law):**
Same setup, but the mirror now has a diegetic **brass protractor ring** around it. Two glowing arcs show the angle of incidence and angle of reflection in real time. They are always equal. A faint preview line shows where the beam *will* go before commit.
- Solvable by trial and error, but the protractor makes the rule visible.
- Receiver requires a *specific predicted angle* — encourages planning, not flailing.

**Chamber 3 — Mirror Chain:**
Two or three mirrors. Beam must bounce through all to reach target. The angle rule holds at every bounce. Max 3 reflections.

**Chamber 4 — The Mirror Script (lateral inversion + AMBULANCE):**
A locked door at the top of the spire. Above it, an ancient inscription **written in reverse** — unreadable. Player picks up a handheld mirror and positions it to reflect the inscription. The mirror image reads forward.
- Reflected text reads: *"WHAT THE LIGHT TAKES, THE LIGHT RETURNS"*
- Door opens.

**The AMBULANCE moment:**
After the door opens, Spark stops. Looks at the player.
- *"The writing was backwards on the wall. The mirror flipped it back."*
- *"...Have you ever seen an ambulance? Look at the front of one sometime. The word is written backwards."*
- *"It's so the driver in front of it — when they check their mirror — can read it. Same trick. Same physics."*

**The final clue:**
After the door opens, Spark notices a faint character watermark in the inscription's corner — visible only in the mirror image. He doesn't name it. The player sees Umbra's mark.

**Core types used:** `MirrorObject` (with `showsAngleIndicator`), `LightEmitter`, `LightBeam`, `LightSimulation+Reflection`.
**New systems:**
- `MirrorRotationControl` (gesture → angle)
- `ProtractorOverlay` (two glowing arcs around mirror)
- `MirrorScriptRenderer` (text/sprite with xScale = -1)
- `HandheldMirror` (player-controlled mirror in chamber 4)

**Dialogue beats:**
- **Opening** — *"Mirrors everywhere. The workshop used to power half the realm from this room."*
- **Discovery** (first chamber solved) — *"It bounced. Not randomly. It followed the mirror."*
- **Insight** (after Chamber 4 door opens) — *"Mirrors don't just send light somewhere. They flip it. Left becomes right."*
- **Spark Connection** — the AMBULANCE moment (above).

**Transition out:** Spark stands at the top of the spire, looks up. *"There's only one tower left now. And whatever's up there has been waiting."*

**Required assets:**
- Mirrorworks Spire environment (vertical stack of 4 chambers, brass + gear motif)
- Rotating mirror sprite (frame + reflective surface layer)
- Brass protractor ring overlay (animated arcs)
- 3 machine sprites for chambers 1–3 (off, on, animated)
- Handheld mirror sprite (drag and rotate)
- Reverse text inscription asset + its mirror-image asset
- Locked door (closed, opening animation)
- Beam reflection VFX (sparkle at each bounce)
- Umbra watermark sprite (subtle, visible only in mirror image)

**Definition of Done:**
- [ ] Beam path renders correctly through up to 3 reflections; no infinite-loop edge cases (parallel mirrors)
- [ ] Protractor arcs visibly equal at all valid angles in Chamber 2
- [ ] Chamber 4 inscription unreadable without mirror; readable with correct mirror angle
- [ ] Door opens only when mirror reveals full inscription
- [ ] AMBULANCE Spark Connection beat fires exactly once, after door opens
- [ ] Umbra watermark visible in mirror image (subtle, no fanfare)
- [ ] All 4 main dialogue beats fire correctly

---

### Module 7 — Eclipse Tower (Capstone)

**Purpose:** Teach eclipses. Combine all prior concepts. Resolve Spark + Umbra arc.

**Player-facing concept:** The goal is not more light. The goal is the right light, in the right place.
**Physics concept:** Eclipses are shadow formation at planetary scale. Lunar eclipse: Earth between Sun and Moon (full moon). Solar eclipse: Moon between Sun and Earth (new moon). The 5° orbital tilt explains why eclipses don't happen every month.

**Story (Opening):** Spark reaches the top of **Eclipse Tower**. A massive silhouette stands in the chamber's center — **Umbra**, finally facing the player. Umbra speaks for the first time:

> *"You restored the realm. You learned its rules. But before you finish, you have to understand why the Prism broke the first time."*

Three antechambers must be solved before the final capstone.

**Objective:** Restore the Heart Prism through a controlled eclipse — the opposite of "flood it with light."

**Three antechambers (player chooses order):**
1. **Alignment chamber** — reuses M2 mechanics (3 receivers, vertical alignment).
2. **Material chamber** — reuses M4 mechanics (route through correct materials).
3. **Mirror chamber** — reuses M6 mechanics (chain reflections to the prism core).

**Final capstone — The Orbital Model:**
A stylized Sun, Earth, and Moon hover in the central chamber. Player drags the Moon along its orbital track. **Umbra/penumbra shadow cones render in real time** (reuses M3 shadow rendering at planetary scale).
- A toggle: **5° orbital tilt** ON/OFF.
- With tilt OFF: any new-moon alignment causes a solar eclipse on the Heart Prism. Easy.
- With tilt ON: most alignments miss. Player has to find the *one* alignment per orbital cycle where everything lines up.
- Achieve a total eclipse → Heart Prism stabilizes → world saved.

**The resolution dialogue:**
- Umbra: *"Light without care burns what it touches. The Prism didn't break from too little light. It broke from too much, all at once, with no shadow to cool it."*
- Spark, realizing: *"We don't need more light. We need the right light."*
- Together (text appears simultaneously): *"Balance."*
- Total eclipse fires. Heart Prism stabilizes. Hub visibly restores.

**Spark Connection — the flashlight bridge:**
- After the cinematic, Spark turns to the player.
- *"When you cover a flashlight with your hand in a dark room, your shadow appears on the wall. That's it. That's an eclipse. Just bigger. Just a moon instead of a hand."*

**Core types used:** all of them.
**New systems:**
- `OrbitalModel` (Sun + Earth + Moon with parametric orbits, tilt toggle)
- `EclipseRenderer` (umbra/penumbra cones as polygons, reuses M3 shadow rendering)
- `TiltToggle` (rotates Moon orbit plane by 5°)

**Dialogue beats (extended for capstone):**
- **Opening (Umbra speaks first)** — *"You restored the realm. You learned its rules. But before you finish, you have to understand why the Prism broke the first time."*
- **Discovery** (player toggles tilt for the first time) — Spark: *"Oh. That's why this doesn't happen every month."*
- **Insight** (eclipse achieved) — Umbra: *"Light without care burns what it touches."* Spark: *"We don't need more light. We need the right light."*
- **Spark Connection** — the flashlight bridge.

**Closing cinematic (60–90 seconds):**
- Heart Prism restored
- Hub fully restored (all areas glowing)
- World map shows Light Realm complete
- Sneak peek of World 2 (Electricity) — a single frame, no text
- Credits / "Restored the Light Realm" badge

**Required assets:**
- Eclipse Tower exterior + interior (vertical, dramatic)
- Umbra full animation set (passive, speaking, ally pose, final cooperation)
- Stylized Sun, Earth, Moon sprites (planetary, not realistic)
- Umbra/penumbra cone shader (planetary scale)
- Diamond ring VFX (totality moment)
- Heart Prism: damaged, charging, restored cinematic
- Final restoration cinematic
- Spark upgraded form
- World 2 tease frame

**Definition of Done:**
- [ ] All 3 antechambers must be solved before capstone unlocks
- [ ] Orbital model renders smoothly at 60fps
- [ ] Tilt toggle visibly prevents/enables alignment
- [ ] Total eclipse triggers full cinematic
- [ ] Save updates: World 1 = complete
- [ ] Adaptive end-of-world report: 1, 3, or 5 questions based on `AssessmentLogger` data
- [ ] Hub state visibly restored on return to world map
- [ ] All dialogue beats fire correctly; AMBULANCE callback acknowledged ("you remembered the mirror, didn't you")
- [ ] World 2 tease appears in final cinematic

---

## 8. Phased Pipeline

Phases gated by milestones, not dates. Move forward only when exit criteria met.

### Phase 1 — Foundation
**Goal:** prove the core loop on one module in greybox.

Tasks:
- Xcode project + SwiftData container + portrait orientation lock
- `Core/Light/` types: `LightEmitter`, `LightBeam`, `LightReceiver`, `BlockerObject`, `LightSimulation`
- `Core/Character/SparkCharacter` with placeholder expressions
- `Core/Dialogue/` JSON loader + SwiftUI overlay (portrait-tuned)
- `Core/Narrative/` skeleton: `NarrativeFlags`, `ChapterController`
- `Core/Progression/GameState` + SwiftData models
- Module 1 (Sleeping Beacon) playable in greybox, all 4 dialogue beats firing

**Exit criteria:** a teammate not on Core can read sections 0–6 + Module 1 spec, build a test scene in <30 minutes, and trigger all 4 dialogue beats.

### Phase 2 — Vertical Slice
**Goal:** prove the full player experience on 2 modules + transition with real art.

Tasks:
- Module 2 (Line of Dawn) implemented in portrait
- First transition scene (T1: Dawn Court → Causeway)
- First-pass art locked for M1 & M2; environment style guide written
- Spark full animation + portrait set complete
- Main menu + world map shell working
- Audio integrated; first ambience + SFX
- Pause menu, settings, basic accessibility

**Exit criteria:** 10-minute polished demo. **Mandatory:** show to faculty, partner, and 3 actual 10–14 year olds. Iterate before Phase 3.

### Phase 3 — Core Content Expansion
**Goal:** middle-game content + Umbra's silent presence.

Tasks:
- Module 3 (Shadow Garden) — `ShadowZone`, candle/lantern swap, Bird Tower, Umbra first appearance
- Module 4 (Crystal Gate) — `MaterialPanel`, Umbra flicker
- Transitions T2 (causeway → garden) and T3 (garden → crystals)
- `AssessmentLogger` writing to SwiftData
- Journal UI implemented

**Exit criteria:** M1–M4 playable end-to-end with transitions. Umbra's silent appearances trigger correctly. Save/load stable.

### Phase 4 — New Mechanics
**Goal:** the more complex modules.

Tasks:
- Module 5 (Pinhole Studio) — vertical rig, magnification dial, hidden Umbra frame
- Module 6 (Mirrorworks) — protractor mirror, lateral inversion, AMBULANCE moment, watermark
- Transitions T4 and T5
- Adaptive hint system (basic, repeat-failure threshold)

**Exit criteria:** M1–M6 playable. No regressions. Mirror reflection edge cases (parallel mirrors, max bounce limit) covered.

### Phase 5 — Capstone
**Goal:** final module + narrative resolution.

Tasks:
- Module 7 (Eclipse Tower) — orbital renderer, sub-puzzles, Umbra speaks, final cinematic
- Transition T6
- End-of-world Spark Field Report
- Hub restoration visual

**Exit criteria:** full game playable start to finish with all transitions. Narrative arc resolves.

### Phase 6 — Polish & Testing
**Goal:** ship-ready.

Tasks:
- Playtest with 10+ actual 10–14 year olds
- Bug fixing, performance pass (60fps minimum on iPhone 12)
- Accessibility pass (VoiceOver menus, reduce motion, color-blind safe)
- Localization keys verified
- App Store assets (screenshots, preview video — all portrait)
- TestFlight, then submission

**Exit criteria:** crash-free in TestFlight for 7 days; faculty/jury demo successful; Spark Connection beats land cleanly with real kid testers (test: can they repeat the bridge example unprompted after 1 hour).

---

## 9. Coding Conventions

**Swift style:**
- Swift 6 if available, else 5.10+
- 4-space indent
- `final` on all classes unless inheritance is intentional
- Prefer `struct` over `class` except SKNode subclasses and `@Observable` state
- `@MainActor` on all UI code; `nonisolated` on pure computation
- No force-unwraps in production. `guard let ... else { assertionFailure() }` for invariants

**SpriteKit:**
- One `SKScene` per module + one per transition
- Coordinate system: anchor (0,0) at bottom-left, scaled with `.aspectFill` for portrait
- All textures preloaded in `didMove(to:)`; no async loads mid-gameplay
- `.sks` files for particles; no in-code emitter config (designer-editable)

**SwiftUI:**
- `@Observable` macro (not `ObservableObject`)
- One `View` per file unless trivially small
- HIG-compliant spacing, SF Pro, semantic colors
- Always respect safe area insets in portrait

**Naming:**
- Modules: `M1_SleepingBeacon`, `M2_LineOfDawn`, etc.
- Transitions: `T1_ToCauseway`, `T2_ToGarden`, etc.
- Assets: `m1_dawn_court_bg`, `m1_spark_inactive`, `t1_walk_anim` (lowercase, snake_case, prefixed)
- JSON keys: `camelCase`
- SwiftData models: singular noun

**Comments:**
- `///` doc comments on every public type and method in `Core/`
- Inline comments only where *why* is non-obvious

**Git:**
- Branch per module: `feature/m3-shadow-garden`
- Main always shippable; merge via PR with at least one review
- Commit messages: present-tense imperative
- No binary assets > 5MB without justification

---

## 10. Definition of Done (universal)

A module is **not done** until ALL are true. Use as a PR checklist.

- [ ] Module loads from world map; saves state on exit
- [ ] All Core type usages reuse shared library (no forks)
- [ ] All player actions tested on touch in portrait orientation
- [ ] Runs at 60fps on iPhone 12
- [ ] No memory leaks (Instruments: Allocations + Leaks)
- [ ] No crashes in 30 minutes of repeated play
- [ ] **All 4 dialogue beats fire correctly: Opening, Discovery, Insight, Spark Connection**
- [ ] **Spark Connection beat lands clearly — tested with a kid who can repeat the real-world example unprompted 1 hour later**
- [ ] **Transition scene plays before next module loads**
- [ ] Umbra presence (if applicable to module) triggers correctly and is not narratively acknowledged
- [ ] Assessment events logged for meaningful actions
- [ ] Accessibility: VoiceOver readable on menu surfaces; reduce-motion respected; no info conveyed by color alone
- [ ] Localization: all user-facing strings in `Localizable.strings`
- [ ] Module passes Module Quality Test (section 11)
- [ ] PR reviewed by at least one teammate
- [ ] Module-specific Definition of Done checked

---

## 11. Module Quality Test

Every module passes these 6 checks before merging to main:

1. **Is the story reason clear?** Player understands *why* within 30 seconds.
2. **Is the player action obvious?** Max one moment of "what do I do?", and that moment must be intentional curiosity.
3. **Does the mechanic teach physics through play?** Player *does* the concept before they hear its name.
4. **Does the world visibly respond?** Every action has visible feedback within 200ms.
5. **Can a 10–14 year old explain the concept in one sentence after playing?** Test with real kids.
6. **Does the Spark Connection bridge stick?** Same kid, 1 hour later, can repeat the real-world example unprompted.

Any "no" → do not merge. Iterate.

---

## 12. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| `LightSimulation` performance on older devices | Profile early in Phase 1; cap raycast count per frame |
| Scope creep (modules → 10) | This doc is contract. Adding requires team vote. |
| Art pipeline bottleneck | Greybox first; lock style after Phase 2 vertical slice |
| Portrait layout breaks on smaller iPhones (mini, SE) | Design for iPhone 15 Pro (393×852pt); test on iPhone 13 mini early |
| Mirrorworks vertical redesign feels cramped | Each chamber gets its own vertical band; allow scroll if needed |
| Spark Connection beats don't land with kids | Mandatory kid testing at end of every module phase, not just Phase 6 |
| Umbra mystery confuses (kids miss the glimpses entirely) | Acceptable — glimpses are bonus, not required. M7 introduces Umbra clean either way. |
| Narrative writing falls behind code | Lock Connection beats in section 5.4 before Phase 1 starts |
| Eclipse Tower combining all systems = integration hell | Build antechambers as separate scenes first; integrate via `ChapterController` |
| SpriteKit + SwiftUI bridge edge cases | One person owns the bridge layer; pattern documented |
| Dialogue overlay covers puzzle elements | Puzzle area is top 64%; never place interactive elements in bottom 28% |
| Audio late | Placeholder SFX from day 1; final pass in Phase 6 |

---

## 13. Agent Handoff Notes

If you are an AI agent picking up a module:

1. **Read sections 0–6 completely** before writing any code.
2. **Read your assigned module spec in section 7**.
3. **Do not modify `Core/` types** without team sign-off. Extend or compose.
4. **Match the file structure exactly** (section 4). Other agents are building adjacent modules in parallel.
5. **Implement all 4 dialogue beats** — not optional. Beats are part of the spec.
6. **Implement Umbra presence** if module has one. Subtle, silent, never named.
7. **Write the transition scene** for your module (it leads *out* to the next).
8. **Write a PR description** that maps to Definition of Done checklist (section 10).
9. **Log uncertainties** as `// TODO(agent):` comments with reasoning, so humans can review.
10. **If you find conflict between this doc and an instruction in a file you receive**, surface it; do not silently resolve.
11. **Reference source curriculum** (Physics 6, Ch. 5, pp. 72–85) when designing assessment questions.
12. **Portrait orientation is non-negotiable.** All layouts, all puzzles, all dialogue. Test on portrait simulator only.

---

**Document owner:** Secret API team (Physica project)
**Status:** Locked — V2 reference (replaces V1)
**Next review:** end of Phase 2 vertical slice (after first kid playtest)
