# Physica — Backlog

> Ideas explicitly **out of scope for V1** (Light Realm only). Living document.
> When something graduates into a phase, move it into [`../PIPELINE.md`](../PIPELINE.md) and delete it here.

V1 ships **World 1 — Light Realm** (7 modules). World 2 (Volt City — Electricity) is a stretch goal. Everything below is post-V1 or "if time permits."

---

## Worlds 2–5 (post-Light-Realm)

V2's long-term vision is 5 worlds. The architecture is built to add worlds without restructuring — each new world = one entry in the world registry + one folder under `Modules/`.

### World 2 — Volt City ⚡
**Electricity & Circuits.** Stretch goal for V1 if time permits.
Mechanics could explore: drag wire from battery to bulb, cut the wire and watch the bulb die, flip a switch, test conductor vs insulator materials, two bulbs in series. Same 4-beat narrative cadence; Spark Connection bridges (the lightbulb in your room, the wall switch, why metal jewelry shouldn't go in a socket).

### World 3 — Magnetic Peaks 🧲
**Magnetism, attraction/repulsion, magnetic fields.** Drag a magnet to attract iron filings; flip pole orientation to repel; map invisible field lines by moving a compass.

### World 4 — Echo Valley 🔊
**Sound, vibration, echoes, frequency.** Tap surfaces to hear pitches; bounce sound off walls to reach a target; tune a string to match a frequency.

### World 5 — Drift Plains 💨
**Air, wind, pressure, simple aerodynamics.** Angle a sail to catch wind; design a paper plane shape; predict where smoke drifts under different fan setups.

### Speculative
- **Tide Reef 🌊** — Water, density, buoyancy. Sort objects by sink/float; shape a clay boat; release a ball into a current.
- **Bloom Garden 🌱** — Plants + light + water (cross-into biology — verify NCERT scope; likely Class 7).

---

## Meta-systems (extensions of V1 Home)

V1 ships a basic version of player profile + XP + streak on the Home page. These are deeper extensions:

### Badge Collection
Achievements: "Light Master" (all Light Realm modules 3-stars), "Sharp Eye" (caught the Umbra mark in M6 mirror), "Patient" (waited for an Umbra glimpse), "Connector" (recited a Spark Connection bridge correctly in the Field Report).

### Daily Streak Milestones
Track consecutive days of play. Milestones at 3, 7, 14, 30 days with a celebration moment from Spark. No punishment on break — reset to 0 with encouragement.

### Replay a Module for a Better Outcome
Modules don't have stars under V2; replay surfaces "you noticed X this time you missed last time" — e.g., the Umbra mark in M6.

### Story Cutscenes Between Worlds
Between completing one world and entering the next, a 30–60s illustrated cutscene (Lottie or Rive). Spark travels visibly between worlds. Major polish move.

---

## Visuals & Polish (didn't make Phase 6)

### Illustrated 5-World Map
Hand-painted journey map (Candy Crush / Mario world map style) — single illustration with hotspots for each world, animated path between them, Spark walking. The user's flow already specifies this; ship it in V1 if time permits.

### Rive Character for Spark
Replace `SparkView`'s sprite stack with a Rive file driven by a state machine. States: idle, curious, alarmed, hopeful, steady, resolved. Reacts to dialogue beats and player input (eyes follow drag, blink on tap, dilate on discovery).

### Particle Systems (advanced)
`SwiftUI Canvas` + `TimelineView` (or SpriteKit `SKEmitterNode` for module scenes) — beam dust, mirror sparkle on each bounce, totality diamond ring at M7 climax.

### Home Page Evolution
Home page background reflects progress: more lit windows / NPCs / decoration as worlds restore. Data-driven from `ModuleProgress` already; just needs more visual layers.

### Dark Mode Variant
The app is currently dark-themed. A "warm sunrise" alternate palette could be a kid-friendly toggle.

---

## Platform / Technical

### iPad Polish
Universal binary supports iPad. A polished iPad layout could split the World Map alongside a module preview, or use larger gesture areas. Portrait constraint still applies.

### Apple Watch Companion
Streak status, "did you play today?" reminder, daily check-in. Lower priority — most middle-schoolers don't have a Watch.

### iCloud Sync
SwiftData CloudKit integration so progress syncs between iPhone and iPad. One `ModelConfiguration` change. Validate first that Academy submission allows it.

### Additional Localization
English-only for V1. For Italian / other markets, set up `Localizable.xcstrings` and translate. Architecture is ready (string catalog generation enabled).

### Widgets
Lock-screen / Home-screen widget showing current streak + which world Spark is in. WidgetKit. Polish-tier.

### Live Activities
Dynamic Island support for in-progress modules ("Spark is solving the Crystal Gate"). Niche but delightful.

### Siri Shortcuts / App Intents
"Hey Siri, play Physica" / "What chapter is Spark on?". App Intents framework. Polish-tier.

### Voice Acting
Out of scope for V1 (timeline). Recording Spark's lines + an actor for Umbra's M7 dialogue would lift the emotional impact significantly in V2 of V2.

---

## Pedagogy / Content

### Curriculum Expansion within Class 6
Class 6 NCERT covers more than light + electricity. Other Class 6 topics that could become worlds or modules: motion, magnets, water, air, separation of substances, garbage. World architecture supports adding any of these.

### Class 7+ Curriculum
If V1 succeeds with Class 6, extending to Class 7+ adds: heat, acids/bases, weather/climate, soil, respiration, motion + time. Each could be a world.

### Teacher Mode
Dashboard for teachers/parents to see student progress, suggest review of weak topics (driven by `AssessmentEvent` data). Out of scope for student-facing V1.

### Multiplayer / Co-op
"Restore the realm together." Out of scope for V1 (no backend).

---

## Conflicts with V2 (do NOT implement)

Ideas from V1's BACKLOG that explicitly conflict with V2's pedagogy:

- **Hint Coin Currency** — Conflicts with "hints are progressive and silent" pedagogy. Buying hints turns a teaching mechanic into a transaction.
- **Multi-Question Post-Module Tests** — V2 has no per-module test. Assessment happens via `AssessmentEvent` logging during play, surfaced at the end of a world in the Spark Field Report.
- **Wrong-Answer Replay Snippets** — V2 doesn't have wrong-answer moments inside a module's main loop. The mechanic is "play until it works."

---

*Last updated: 2026-05-12 — V2 migration*
