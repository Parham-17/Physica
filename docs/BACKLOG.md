# Physica — Backlog

> Ideas for future implementation. Not planned for v1.0.
> Add new ideas at the bottom of the relevant section. When something graduates to implementation, move it to [`IMPLEMENTATION_PHASES.md`](IMPLEMENTATION_PHASES.md) and delete it from here.

---

## New Realms (post-Academy)

The architecture is built to add realms without restructuring. Each new realm = one row in `SeedData` + one folder under `Features/`.

### Magnetic Peaks 🧲
Magnetism, attraction/repulsion, magnetic fields. Levels could explore: drag a magnet to attract iron filings; flip pole orientation to repel; map invisible field lines by moving a compass.

### Echo Valley 🔊
Sound, vibration, echoes, frequency. Levels: tap surfaces to hear different pitches; bounce sound off walls to reach a target; tune a string to match a frequency.

### Drift Plains 💨
Air, wind, pressure, simple aerodynamics. Levels: angle a sail to catch wind; design a paper plane shape; predict where smoke drifts under different fan setups.

### Tide Reef 🌊
Water, density, buoyancy. Levels: sort objects by sink/float prediction; shape a clay boat to support weight; release a ball into a current and predict where it lands.

### Bloom Garden 🌱
Plants, light, water, growth (cross-into biology — verify NCERT scope). Could be Class 7 territory; revisit if extending curriculum.

---

## Gameplay Features

### Daily Streaks System
Track consecutive days of play. Flame icon + count on Hub. Milestones at 3, 7, 14, 30 days with celebration. No punishment on break — reset to 0 with encouragement. Storage already exists in `Progress.currentStreakDays`.

### XP Levels for the Player (not just per-puzzle XP)
Aggregate XP into "explorer levels" with rank titles ("Curious", "Apprentice", "Discoverer", "Sage"). Visible on the Hub.

### Badge Collection
Achievements like "Shadow Master" (all shadow realm 3-stars), "Circuit Wizard" (all volt city 3-stars), "Speedy" (boss in under 2 min), "Patient" (used the strong hint). Storage: `Progress.earnedBadges` already there.

### Replay Levels for Better Stars
Currently star count is `max(stored, new)`. UI to surface "you got 2 stars — try for 3" on the realm map.

### Hint Coin Currency
Optional. Earn coins for completing levels; spend to unlock immediate strong hint. Not aligned with the "play first, hints emerge" pedagogy — flag for team discussion before adding.

### Story Cutscenes Between Realms
Short illustrated cutscenes when a new realm unlocks ("Spark hears about the Shadow Realm…"). Lottie or Rive animations. Major polish move.

### Multi-Question Post-Level Tests
Currently one question per level (per spec). For higher levels, a series of 2–3 short questions could deepen the assessment without becoming a "quiz."

### Wrong-Answer Replay Snippets
On a wrong post-level test answer, instead of fully resetting the level, replay the *specific moment* that demonstrates the concept (e.g., zoom in on Spark's eye turning on and the cave revealing). Higher polish than full reset.

---

## Visuals & Polish

### Illustrated Realm Map (replace card grid)
Hand-painted journey map (Candy Crush / Mario world map style) — single illustration with hotspots for each level, animated path between them, Spark icon walking the path. **This is the single biggest visual upgrade we can make.** Promote to W8 if budget allows; otherwise post-Academy.

### Rive Character for Spark
Replace `SparkView`'s SwiftUI shapes with a Rive file driven by a state machine. States: idle, curious, focused, happy, surprised, sleeping. Reacts to gameplay (eyes follow drag, blink on tap, dilate on discovery).

### Particle Systems
SwiftUI `Canvas` + `TimelineView` for star bursts on level complete, sparkle trails on discovery, electricity arcs in Volt City.

### Hub Scene Evolution
Volt City fills in as progress is made — more lit windows, more wandering NPCs, decorations on world events. Already data-driven from `ProgressStore`; just needs more visual layers.

### Dark Mode Variant
Currently the app is essentially dark-themed. A "warm sunrise" alternate palette could be a kid-friendly toggle.

---

## Platform / Technical

### iPad Polish
Universal binary already supports iPad. Levels currently scale; a polished iPad layout could split the realm map alongside a level preview, or use larger gesture areas.

### Apple Watch Companion
Streak status, "did you play today?" reminder, daily check-in. Lower priority — most middle-schoolers don't have a Watch.

### iCloud Sync
SwiftData CloudKit integration so progress syncs between iPhone and iPad. Easy to add (one ModelConfiguration change). Validate first that Academy submission allows it.

### Localization
English-only for v1 (curriculum is English-medium NCERT). For Italian / other markets, set up `Localizable.xcstrings` and translate. Architecture is ready (string catalog generation already enabled in build settings).

### Widgets
Lock-screen / Home-screen widget showing current streak + last realm visited. WidgetKit. Polish-tier feature.

### Live Activities
Dynamic Island support for in-progress levels ("Spark is exploring the cave"). Niche but delightful.

### Siri Shortcuts / App Intents
"Hey Siri, play Physica" / "What level is Spark on?". App Intents framework. Polish-tier.

---

## Pedagogy / Content

### Curriculum Expansion
Class 6 NCERT covers more than light + electricity. Other Class 6 topics that could become realms or levels: motion, magnets, water, air, separation of substances, garbage. Realm structure supports adding any of these.

### Class 7+ Curriculum
If v1 succeeds with Class 6, extending to Class 7+ adds: heat, acids/bases, weather/climate, soil, respiration, motion + time. Each could be a realm.

### Teacher Mode
Optional dashboard for teachers/parents to see student progress, suggest review of weak topics. Out of scope for student-facing v1.

### Multiplayer / Co-op
"Restore the realm together." Out of scope for v1 (no backend).

---

## Known Issues / Tech Debt

> Things noticed during W1–W2 that need follow-up.

- **Spark gesture-state quirk on synthetic launch:** when AppRouter's path is initialized to `[.shadowLevel(1)]` for testing, Spark renders in light-on state instead of dark. Doesn't reproduce on natural navigation, but worth investigating before someone tries to deep-link into a level. Likely cause: gesture composition between `.onTapGesture` and `.gesture(DragGesture(minimumDistance: 0))` on the same view.
- **`build/` folder appears in repo when running command-line `xcodebuild`** with `-derivedDataPath ./build`. Already gitignored, but worth removing the `-derivedDataPath` argument or always pointing it outside the repo.
- **No CI yet.** GitHub Actions workflow with `xcodebuild build` on every PR would catch compile errors before review. Add when remote is set up.

---

*Last updated: May 8, 2026*
