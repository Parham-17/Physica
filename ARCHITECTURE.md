# Physica Architecture

This document is the **source of truth** for architectural decisions. All contributors must follow these rules when adding new code. If you find yourself fighting these rules, raise it as a team discussion before working around them.

---

## Pattern: MV + Per-Level State + Shared Engine

Physica uses three cooperating patterns:

1. **MV + Services** for app-level concerns (hub, realm map, persistence, audio, hints).
2. **Per-Level `@Observable` State** for game state inside a level.
3. **Shared Engine Components** (Spark character, LightCone, LevelComplete, PostLevelTest, HintEngine) reused across every level.

There are **no ViewModels**. SwiftUI views read models directly via `@Query` and call services / state methods directly.

### Why not MVVM?

In UIKit, ViewModels were necessary because views couldn't observe data directly. SwiftUI's `@State`, `@Binding`, `@Query`, `@Bindable`, and `@Environment` already give the View a reactive observation channel. Adding a ViewModel layer creates redundant indirection and 1:1 pass-through boilerplate.

**Rule: do not create ViewModel classes.** Extract complex view logic into a Service or per-level State class — never a ViewModel.

---

## Layers

### App (`Physica/App/`)

Entry point and routing.

**Files:**
- `PhysicaApp.swift` — `@main`, composition root. Owns the singleton instances of `AppRouter` and `AudioManager`. Provides the `ModelContainer`.
- `RootView.swift` — `NavigationStack` + `navigationDestination` switch. Maps `NavRoute` cases to feature views.
- `AppRouter.swift` — `@Observable` route stack. Routes are pushed via `router.push(.shadowLevel(2))`.

**Rules:**
- All app-wide singletons are created in `PhysicaApp.swift`. Single composition root.
- Inject via `.environment(...)`. Never use singletons or `static let shared`.
- `NavRoute` is a flat enum — adding a new screen means adding a case + a destination in `RootView`. Don't deeply nest routes.

### Core (`Physica/Core/`)

Shared engine components used by every level / feature.

#### `Core/DesignSystem/`

`Theme.swift`, `Typography.swift`, `Spacing.swift` — color, font, and spacing tokens.

**Rules:**
- Every view must use these tokens. **Never** hardcode hex colors, font sizes, or spacing magic numbers in feature code.
- Adding a new color → add it to `Theme.swift` first, with a name describing intent (`shadowDeep`, not `darkBlue1`).
- See [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md) for the full token table.

#### `Core/Audio/`

`AudioManager.swift` — `@Observable` SFX + ambient player.

**Rules:**
- Add new SFX to `AudioManager.SFX` enum; add ambient tracks to `AudioManager.Ambient`.
- Stubs no-op when matching files don't exist. Audio assets land in W8 — calls are safe to wire now.

#### `Core/Persistence/`

`ModelContainer+Physica.swift` — shared SwiftData container with first-launch seeding.
`ProgressStore.swift` — `struct` wrapper around `ModelContext` for level-completion + cross-realm unlock.

**Rules:**
- All `@Model` types are registered in `ModelContainer+Physica.swift`'s `Schema`.
- `ProgressStore` is a struct (no state of its own) — instantiate per call: `ProgressStore(context: modelContext).recordLevelCompletion(...)`.
- `inMemory: true` for previews via `ModelContainer.previewPhysica()`.

#### `Core/Hints/`

`HintEngine.swift` — `@Observable`, timeline-based progressive hint system.

**Rules:**
- Each level instantiates one `HintEngine` with its own escalation timeline.
- Call `engine.start()` in `onAppear`, `engine.stop()` in `onDisappear`, `engine.registerActivity()` on every meaningful user action.
- Levels render hint visuals based on `engine.currentLevel` (`.none / .nudge / .hint / .strong`).

#### `Core/Components/`

Reusable game components.

**Rules:**
- A component qualifies for `Core/Components/` if it's used by **2+ features**. Single-feature views stay in the feature folder.
- Components accept data via parameters, **not** environment. Keep them generic.
- Each component file includes a `#Preview` block.

### Models (`Physica/Models/`)

`Realm.swift`, `Level.swift`, `Progress.swift`, `SeedData.swift`.

**Rules:**
- Annotate persistence types with `@Model`.
- Models hold data + simple computed properties. **No business logic, no side effects, no formatting.**
- Each `@Model` gets its own file.
- `SeedData.populateIfNeeded(_:)` is the only place that inserts the realm/level catalog. Edit it when adding a level.

### Features (`Physica/Features/`)

App screens grouped by feature, not by type.

**Rules:**
- One folder per top-level feature (Hub, RealmMap, ShadowRealm, VoltCity, Profile).
- Each level gets its own subfolder under its realm: `Features/ShadowRealm/Level1/`.
- A feature folder contains its `View`, `State` (`@Observable`), and any single-feature subviews.
- If a subview is used by 2+ features → promote to `Core/Components/`.

#### Per-level template

```
Features/<Realm>/Level<N>/
├── <Realm>Level<N>State.swift      ← @Observable game state (phase, positions, discoveries, timers)
├── <Realm>Level<N>View.swift       ← SwiftUI scene; orchestrates the level
└── <single-feature subviews>.swift ← e.g. CaveEnvironmentView, CircuitGridView
```

A level's State machine should:
- Have an explicit `Phase` enum (e.g., `dark → exploring → complete → test → finished`).
- Use **normalized 0..1 positions** for game elements, multiplied by `GeometryReader` size at render. Never hardcode pixel coordinates.
- Own a `HintEngine` instance.
- Expose a `reset()` method for the post-level-test wrong-answer replay flow.

A level's View should:
- Wire `AudioManager` calls for `.lightOn`, `.discoveryChime`, `.levelComplete`, etc.
- Show `LevelCompleteView` on `.complete` phase, then `PostLevelTestView` on `.test` phase.
- On correct test answer, call `ProgressStore(context:).recordLevelCompletion(...)` and `router.popToRoot()`.
- On wrong answer, call `state.reset()` — never show a text explanation.

---

## Dependency Injection

### Composition root

```
PhysicaApp (@main)
├── @State private var router = AppRouter()
├── @State private var audioManager = AudioManager()
└── modelContainer = ModelContainer.physica()

WindowGroup {
    RootView()
        .environment(router)
        .environment(audioManager)
}
.modelContainer(modelContainer)
```

Views access dependencies via:

```swift
@Environment(AppRouter.self) private var router
@Environment(AudioManager.self) private var audio
@Environment(\.modelContext) private var modelContext
@Query(sort: \Realm.order) private var realms: [Realm]
```

**Rules:**
- All shared singletons are created in `PhysicaApp.swift`. Single composition root.
- Use `.environment(value)` for `@Observable` classes (type-based).
- Never use legacy `@ObservedObject`, `@StateObject`, or `@EnvironmentObject`.
- Per-level `@Observable` State is created locally with `@State private var state = ...`. It is NOT injected via environment (state is per-level, not app-wide).

---

## Property Wrapper Decision Guide

| Scenario | Use | Example |
|----------|-----|---------|
| Local UI value (toggle, sheet) | `@State` | `@State private var showSheet = false` |
| View creates and owns an `@Observable` | `@State` | `@State private var state = ShadowRealmLevel1State()` |
| Two-way binding to parent value | `@Binding` | Child edits parent's text |
| Bind to `@Observable` properties from environment | `@Bindable var x = environment-x` (in body) | Inside `RootView` for `NavigationStack(path:)` |
| Read SwiftData collection | `@Query` | `@Query(sort: \.order) var realms: [Realm]` |
| Access shared service | `@Environment(Type.self)` | `@Environment(AudioManager.self) var audio` |
| Access system value | `@Environment(\.keyPath)` | `@Environment(\.modelContext) var ctx` |
| Read-only model from parent | Plain `let` | `let level: Level` |

---

## SwiftData Conventions

- Register every `@Model` in `ModelContainer+Physica.swift`'s `Schema`.
- Read in views via `@Query`. Write in services or `ProgressStore` calls.
- Use `inMemory: true` for previews — `ModelContainer.previewPhysica()` does this.
- For schema migrations, use `VersionedSchema` (don't rely on lightweight migration silently).

---

## Decomposition Guidelines

| Layer | Soft cap | Notes |
|-------|----------|-------|
| Views | ~150 lines | Beyond this, extract subviews. Single-use → sibling file. Reused → `Core/Components/`. |
| State (`@Observable`) | ~200 lines | If a level's state grows beyond, that's a sign the level is doing two things — split mechanics. |
| Models | thin | Stored properties + simple computed. No formatting, no business rules. |
| Static data (e.g., `SeedData`) | unlimited | Data declarations can be long. |

**150 lines is a warning threshold.** Look for extraction opportunities before crossing it.

---

## Previews

Every view file ships with a `#Preview`. Patterns:

```swift
#Preview {
    HubView()
        .environment(AppRouter())
        .environment(AudioManager())
        .modelContainer(.previewPhysica())
}
```

```swift
#Preview {
    NavigationStack {
        ShadowRealmLevel1View()
    }
    .environment(AppRouter())
    .environment(AudioManager())
    .modelContainer(.previewPhysica())
}
```

**Rules:**
- Every view must have a working preview.
- Use `.modelContainer(.previewPhysica())` (in-memory + seeded) for SwiftData.
- Inject every required environment value the real composition root would.
- A broken preview is a bug — fix it before merging.

---

## Pedagogical Rules (from CLAUDE.md)

These are not architecture, but they constrain feature code:

- **No tutorial walls of text.** Concepts emerge through interaction, named only at the end (post-level reveal).
- **Level 1 of any world cannot be failed.** No timer, no lives lost on L1.
- **Hints are progressive and silent** — only after detected idle, never on first appearance.
- **Wrong answers replay the moment**, never show a text explanation.

If a feature would violate these, it's wrong. Discuss with the team before shipping.

---

## Anti-Patterns (Do NOT Do)

| Anti-Pattern | Why | Do Instead |
|-------------|-----|------------|
| Create ViewModel classes | Redundant in SwiftUI | View reads models, calls services / state methods |
| Use singletons (`static let shared`) | Untestable, hidden deps | Inject via `.environment(...)` |
| Hardcode colors / fonts / spacing in feature code | Defeats theming + W8 art swap | Use `Theme`, `Typography`, `Spacing` tokens |
| Hardcode pixel positions in level state | Breaks across devices | Use 0..1 normalized + `GeometryReader` |
| Edit `.pbxproj` manually | Project uses filesystem-synchronized groups | Just add files in the synced source tree |
| Add files alongside `.pbxproj` (project root level) and expect them in the bundle | They're not in the synced group | Source files go inside `Physica/Physica/`. Docs go in `docs/`. |
| Tutorial text in early levels | Violates pedagogy | Mechanics teach themselves |
| Show text explanation on wrong post-level test | Violates pedagogy | `state.reset()` to replay |
| Use `@ObservedObject` / `@StateObject` / `@EnvironmentObject` | Legacy pre-iOS 17 | Use `@State` + `@Observable` + `@Environment(Type.self)` |
| Add a third-party dependency without team discussion | CLAUDE.md says zero deps | Discuss before adding (Rive in W8 may be the one approved exception) |
| Commit `xcuserdata/`, `build/`, `DerivedData/` | Local user state | Already in `.gitignore` — keep it that way |

---

*Last updated: May 8, 2026*
