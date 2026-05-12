# Physica Architecture

This document is the **source of truth for code-level rules**: patterns, file layout, dependency injection, SwiftData usage, decomposition, and anti-patterns. For project pipeline, module specs, and narrative architecture, see [`PIPELINE.md`](PIPELINE.md) — it is the higher-order source of truth and takes precedence in any conflict.

All contributors must follow these rules when adding new code. If you find yourself fighting them, raise it as a team discussion before working around them.

---

## Pattern: MV + Per-Module State + Shared Engine

Physica uses three cooperating patterns:

1. **MV + Services** for app-level concerns (home, world map, persistence, audio, hints, narrative flags).
2. **Per-Module `@Observable` State** for game state inside a module.
3. **Shared Engine Components** (`Core/Light/`, `Core/Character/`, `Core/Narrative/`, `Core/Dialogue/`, etc.) reused across every module.

There are **no ViewModels**. SwiftUI views read models directly via `@Query` and call services / state methods directly.

### Why not MVVM?

In UIKit, ViewModels were necessary because views couldn't observe data directly. SwiftUI's `@State`, `@Binding`, `@Query`, `@Bindable`, and `@Environment` already give the View a reactive observation channel. Adding a ViewModel layer creates redundant indirection.

**Rule: do not create ViewModel classes.** Extract complex view logic into a Service or per-module State class — never a ViewModel.

---

## SwiftUI ↔ SpriteKit split

Physica is a hybrid app. Decide which framework owns each surface by purpose:

| Surface | Framework | Why |
|---|---|---|
| Onboarding cinematic | SwiftUI | Screen flow, transitions, text effects |
| Home page (profile, XP, world map) | SwiftUI | Lists, buttons, scrolling, layout |
| World page (module list per world) | SwiftUI | Same |
| Dialogue overlay (portrait + typewriter) | SwiftUI | Text rendering, layout, animation primitives |
| Settings, Journal, Field Report | SwiftUI | Forms, tables, content |
| **Module gameplay** | **SwiftUI _or_ SpriteKit** — decided per-module | See below |
| Module → module transition scene | Usually SwiftUI; SpriteKit if it needs sprite animation | |

**Per-module decision rule:** start in SwiftUI. Switch to SpriteKit only when SwiftUI begins to struggle — typically when the module needs many simultaneous sprites, real-time geometry computation (shadow polygons), or particle effects.

When a module uses SpriteKit, present it via a `SpriteView` inside a SwiftUI container. SwiftUI still owns navigation, pause menu, and the dialogue overlay. SpriteKit owns the in-scene gameplay, animations, and particle FX. Communicate across the bridge via `@Observable` state and Combine publishers — never via globals.

---

## Portrait orientation is non-negotiable

Every layout, puzzle, transition, and overlay is portrait-first. Locked in `Info.plist`. Design for iPhone 15 Pro (393×852pt). Active play band is the middle 64% of the screen; dialogue overlay is the bottom 28%; top 8% is reserved for system UI and pause / hint buttons. See [`PIPELINE.md`](PIPELINE.md) §3 for the full constraint set.

---

## Layers

### App (`Physica/App/`)

Entry point and routing.

**Files:**
- `PhysicaApp.swift` — `@main`, composition root. Owns singletons (`AppRouter`, `AudioManager`, `NarrativeFlags`, `ChapterController`). Provides the `ModelContainer`. Locks portrait orientation.
- `RootView.swift` — top-level navigation switch.
- `AppRouter.swift` — `@Observable` route stack. Routes pushed via `router.push(.module("M1"))`.

**Rules:**
- All app-wide singletons are created in `PhysicaApp.swift`. Single composition root.
- Inject via `.environment(...)`. Never use singletons or `static let shared`.
- `NavRoute` is a flat enum — adding a new screen means adding a case + a destination in `RootView`. Don't deeply nest routes.

### Core (`Physica/Core/`)

Shared engine subsystems used by every module / feature.

| Folder | Purpose |
|---|---|
| `DesignSystem/` | Color, font, spacing tokens (`Theme`, `Typography`, `Spacing`) |
| `Audio/` | `AudioManager` — `@Observable` SFX + ambient player |
| `Persistence/` | `ModelContainer+Physica`, `ProgressStore` |
| `Hints/` | `HintEngine` — progressive idle-based hint timeline |
| `Components/` | Reusable UI components (used by 2+ features) |
| `Light/` | `LightEmitter`, `LightBeam`, `LightReceiver`, `BlockerObject`, `MirrorObject`, `MaterialPanel`, `ShadowZone`, `LightSimulation` |
| `Character/` | `SparkCharacter`, `SparkExpressions`, `UmbraCharacter` |
| `Narrative/` | `NarrativeFlags`, `ChapterController`, `TransitionScene`, `ConnectionBeat` |
| `Dialogue/` | `DialogueController`, `DialogueModel`, `DialogueLoader`, `TypewriterRenderer` |
| `Puzzle/` | `PuzzleGoal`, `PuzzleStateMachine`, `PuzzleCompletion` |
| `Progression/` | `GameState`, `ProgressionStore`, `ModuleRegistry` |
| `Assessment/` | `AssessmentEvent`, `AssessmentLogger`, `MasteryEvidence` |

**Rules:**
- A component qualifies for `Core/Components/` if it's used by **2+ features**. Single-feature views stay in the feature folder.
- Components accept data via parameters, **not** environment. Keep them generic.
- Every Core public type and method gets a `///` doc comment.
- **Do not modify `Core/Light/`, `Core/Character/`, or `Core/Narrative/` types without team sign-off.** Extend via subclass or composition.
- Each component file includes a `#Preview` block.

Full Core type contracts (signatures, ownership) are specified in [`PIPELINE.md`](PIPELINE.md) §6. Do not redefine them here.

### Models (`Physica/Models/`)

SwiftData `@Model` persistence types.

**V2 model set:**
- `PlayerProfile` — player identity, XP totals, streak
- `ModuleProgress` — per-module completion + stars + best time
- `JournalEntry` — captured artifacts (pinhole memories, mirror inscription, etc.)
- `NarrativeProgress` — which dialogue beats have fired, which Umbra glimpses seen
- `AssessmentEvent` — stealth log of meaningful player actions (feeds Spark Field Report)

**Rules:**
- Annotate persistence types with `@Model`.
- Each `@Model` gets its own file.
- Models hold data + simple computed properties. **No business logic, no side effects, no formatting.**
- Register every `@Model` in `ModelContainer+Physica.swift`'s `Schema`.
- For schema migrations, use `VersionedSchema` (don't rely on lightweight migration silently).

### Features (`Physica/Features/`) and Shell (`Physica/Shell/`)

App screens grouped by feature, not by type.

- `Features/Onboarding/` — intro cinematic before main app
- `Features/Home/` — main page (profile, XP, streak, 5-world map)
- `Features/RealmMap/` — world page (lists a world's modules) — being renamed to `Shell/WorldMap/` during V2 migration
- `Features/Profile/` — profile screen
- `Shell/` (target structure) — `MainMenu/`, `WorldMap/`, `Journal/`, `Settings/`, `DialogueOverlay/`, `Assessment/`

### Modules (`Physica/Modules/`)

Each chapter of the Light Realm lives in its own folder:

```
Modules/M<N>_<Name>/
├── M<N>Scene.swift        ← SwiftUI View or SKScene
├── M<N>Coordinator.swift  ← puzzle logic, @Observable state
├── M<N>Assets.swift       ← asset name enum
└── M<N>Dialogue.json      ← 4 beats + transition lines
```

A module's State machine should:
- Have an explicit `Phase` enum (e.g., `idle → active → solved → connection → complete`).
- Use **normalized 0..1 positions** for game elements, multiplied by container size at render. Never hardcode pixel coordinates.
- Trigger the 4 dialogue beats at the correct moments (Opening, Discovery, Insight, Spark Connection) and persist firing in `NarrativeProgress`.
- Own a `HintEngine` instance.
- Log meaningful events to `AssessmentLogger`.

A module's View should:
- Wire `AudioManager` calls for narrative cues (`.beaconActivate`, `.dialogueOpen`, etc.).
- Show the `TransitionScene` after Spark Connection completes.
- Save `ModuleProgress` via `ProgressStore` on completion.

### Transitions (`Physica/Transitions/`)

15–30 second between-module scenes. Each transition is a small `SKScene` or SwiftUI view driven by `ChapterController`. See [`PIPELINE.md`](PIPELINE.md) §5.5.

---

## Dependency Injection

### Composition root

```
PhysicaApp (@main)
├── @State private var router = AppRouter()
├── @State private var audioManager = AudioManager()
├── @State private var narrativeFlags = NarrativeFlags()
├── @State private var chapterController = ChapterController()
└── modelContainer = ModelContainer.physica()

WindowGroup {
    RootView()
        .environment(router)
        .environment(audioManager)
        .environment(narrativeFlags)
        .environment(chapterController)
}
.modelContainer(modelContainer)
```

Views access dependencies via:

```swift
@Environment(AppRouter.self) private var router
@Environment(AudioManager.self) private var audio
@Environment(NarrativeFlags.self) private var flags
@Environment(\.modelContext) private var modelContext
@Query(sort: \ModuleProgress.order) private var modules: [ModuleProgress]
```

**Rules:**
- All shared singletons are created in `PhysicaApp.swift`. Single composition root.
- Use `.environment(value)` for `@Observable` classes (type-based).
- Never use legacy `@ObservedObject`, `@StateObject`, or `@EnvironmentObject`.
- Per-module `@Observable` State is created locally with `@State private var state = ...`. Not injected — state is per-module, not app-wide.

---

## Property Wrapper Decision Guide

| Scenario | Use | Example |
|---|---|---|
| Local UI value (toggle, sheet) | `@State` | `@State private var showSheet = false` |
| View creates and owns an `@Observable` | `@State` | `@State private var state = M1Coordinator()` |
| Two-way binding to parent value | `@Binding` | Child edits parent's text |
| Bind to `@Observable` properties from environment | `@Bindable var x = environment-x` (in body) | Inside `RootView` for `NavigationStack(path:)` |
| Read SwiftData collection | `@Query` | `@Query(sort: \.order) var modules: [ModuleProgress]` |
| Access shared service | `@Environment(Type.self)` | `@Environment(AudioManager.self) var audio` |
| Access system value | `@Environment(\.keyPath)` | `@Environment(\.modelContext) var ctx` |
| Read-only data from parent | Plain `let` | `let module: ModuleProgress` |

---

## SpriteKit Conventions

When a module uses SpriteKit:

- One `SKScene` per module + one per transition.
- Coordinate system: anchor (0,0) at bottom-left; design for portrait 9:19.5 aspect (iPhone 15 Pro = 393×852pt). Use `.aspectFill` with letterbox tolerance.
- All textures preloaded in `didMove(to:)`; no async loads mid-gameplay.
- Use `.sks` files for particles; no in-code emitter config (designer-editable).
- Do **not** use `SKLightNode` for the light realm. Render beams via `SKShapeNode` + glow `SKEmitterNode`.
- Performance budget: one light cast < 1ms on iPhone 12.

---

## SwiftData Conventions

- Register every `@Model` in `ModelContainer+Physica.swift`'s `Schema`.
- Read in views via `@Query`. Write in services or `ProgressStore` calls.
- Use `inMemory: true` for previews — `ModelContainer.previewPhysica()` does this.
- For schema migrations, use `VersionedSchema` (don't rely on lightweight migration silently).

---

## Decomposition Guidelines

| Layer | Soft cap | Notes |
|---|---|---|
| Views | ~150 lines | Beyond this, extract subviews. Single-use → sibling file. Reused → `Core/Components/`. |
| State (`@Observable`) | ~200 lines | If a module's state grows beyond, the module is doing two things — split mechanics. |
| Models | thin | Stored properties + simple computed. No formatting, no business rules. |
| Static data (e.g., `SeedData`) | unlimited | Data declarations can be long. |

**150 lines is a warning threshold.** Look for extraction opportunities before crossing it.

---

## Previews

Every view file ships with a `#Preview`. Patterns:

```swift
#Preview {
    HomeView()
        .environment(AppRouter())
        .environment(AudioManager())
        .environment(NarrativeFlags())
        .modelContainer(.previewPhysica())
}
```

**Rules:**
- Every view must have a working preview.
- Use `.modelContainer(.previewPhysica())` (in-memory + seeded) for SwiftData.
- Inject every required environment value the real composition root would.
- A broken preview is a bug — fix it before merging.

---

## Pedagogical Rules (from PIPELINE.md)

These constrain feature code. Violating them is a bug, not a style choice.

- **Teach the concept through interaction first.** The player does it before they hear it named. The Insight dialogue beat names the concept *after* the puzzle is solved.
- **No tutorial walls of text.** Spark frames the chapter in 1–2 lines. The puzzle teaches the mechanic.
- **Every module ends with a Spark Connection beat** — Spark bridging the concept to a real-world example. These are the single most important text in the app. See [`PIPELINE.md`](PIPELINE.md) §5.4 for the canonical wording.
- **Umbra is a silent presence before M7.** Glimpses only; never named.
- **Wrong answers replay the moment**, never show a text explanation.
- **Module 1 of any world cannot be failed.** No timer, no lives lost.

If a feature would violate these, it's wrong. Discuss with the team before shipping.

---

## Anti-Patterns (Do NOT Do)

| Anti-Pattern | Why | Do Instead |
|---|---|---|
| Create ViewModel classes | Redundant in SwiftUI | View reads models, calls services / state methods |
| Use singletons (`static let shared`) | Untestable, hidden deps | Inject via `.environment(...)` |
| Modify `Core/Light`, `Core/Character`, or `Core/Narrative` types without team sign-off | Other modules depend on them | Extend via subclass or composition |
| Hardcode colors / fonts / spacing in feature code | Defeats theming + art swap | Use `Theme`, `Typography`, `Spacing` tokens |
| Hardcode pixel positions in a module | Breaks across devices | Use 0..1 normalized + container size |
| Edit `.pbxproj` manually | Project uses filesystem-synchronized groups | Add files in the synced source tree |
| Add files at the project root level expecting them in the bundle | They're not in the synced group | Source files go inside `Physica/Physica/`. Docs go at the repo root or in `docs/`. |
| Skip a dialogue beat in a module | The 4 beats are part of the spec | Implement all 4 (Opening / Discovery / Insight / Connection) |
| Reference Umbra by name before M7 | Breaks the mystery | Spark may only say "did you see that?" once, in M3 |
| Show text explanation on a wrong assessment answer | Violates pedagogy | Replay the moment instead |
| Use `@ObservedObject` / `@StateObject` / `@EnvironmentObject` | Legacy pre-iOS 17 | Use `@State` + `@Observable` + `@Environment(Type.self)` |
| Add a third-party dependency without team discussion | Zero-deps default | Discuss before adding |
| Commit `xcuserdata/`, `build/`, `DerivedData/` | Local user state | Already in `.gitignore` — keep it that way |
| Landscape layout assumptions | App is portrait-only | All layouts and puzzles design for portrait |

---

*Last updated: 2026-05-12 — V2 migration*
