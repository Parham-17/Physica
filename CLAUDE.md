# CLAUDE.md — Spark Project

> **Read this file first.** It contains the full creative, technical, and pedagogical foundation for this project. Always consult before writing code or making product decisions.

---

## 📋 Project Summary

**Spark** is a gamified iOS app that teaches **middle-school physics** through play. Built by **Team Secret API** (7 members) at the **Apple Developer Academy, Naples**, as Challenge 7 (8-week timeline).

**Curriculum source:** Indian English-medium school Class 6 Physics textbook.

**Target users:** Middle-school students (ages 10–13).

**Comparison reference:** *"Brilliant.org × Duolingo, but for physics, and more game than lesson."*

---

## 🎯 Core Pedagogical Principle

```
Play & Learn → Test → Earn → Unlock
```

**The game IS the lesson.** Concepts emerge through interaction, never through tutorial text. Students play first; the concept is named only at the end (if at all).

### Level Design Escalation (per chapter)

| Stage | Purpose | Student Experience |
|-------|---------|-------------------|
| 1. Discover | Mechanical familiarity | "What does this do?" |
| 2. Notice | Cause/effect emerges | "Oh, X causes Y" |
| 3. Apply | Use the rule | "I need Y — I know how" |
| 4. Combine | Mix concepts | "X + Z together" |
| 5. Boss | Transfer to new context | "Solve a new puzzle" |

### Hard Rules
- **No tutorial walls of text.** Ever.
- **No physics terminology in early levels.** Concepts named only after they're felt.
- **Hints are progressive and silent** — appear only after detected struggle.
- **Level 1 of any world cannot be failed.** Trust-building first.

---

## 🌍 Story Structure: "The Broken World"

Spark is a small robot from **Volt City**, the heart of a vast world held together by the laws of physics. But the laws are breaking. Light bends wrong in the **Shadow Realm**. Electricity sputters in Volt City itself. One by one, the realms are falling out of balance — and only by understanding how each one works can Spark help restore them. Each journey out brings Spark home a little wiser, and home a little brighter.

### Why this structure
- **Infinitely expandable** — every physics topic = a new realm
- **Volt City as hub** = permanent home screen with personality
- **No fixed ending** — game grows via post-launch content drops
- **Each realm self-contained** — releasable as updates

### World Order
1. **Volt City prologue** (brief intro, ~1-2 screens, no gameplay)
2. **World 1: Shadow Realm** (Light & Shadows)
3. **World 2: Volt City** (Electricity & Circuits — emotional "fix home" arc)
4. *Future: Magnetic Peaks, Echo Valley, Drift Plains, etc.*

---

## 🤖 Main Character: Spark

A small, curious robot from Volt City.

### Visual DNA (LOCKED — do not redesign)
| Element | Spec |
|---------|------|
| Shape | Sphere/rounded cube body, ~60% body 40% eye |
| Eye | One large central lens — primary expressive element |
| Color (Volt City) | Bright copper/brass body, electric blue eye |
| Color (Shadow Realm) | Same body, eye glows warm yellow (acts as torch) |
| Movement | Hovers/floats slightly — no legs, no walk cycle |
| Personality | Eye blinks, dilates when curious, squints when concentrating |
| Sounds | Soft mechanical hums, curious "?" beep, happy "!" beep |

### Eye-Color Mechanic
- **Yellow eye** = light mode (Shadow Realm)
- **Blue eye** = electricity mode (Volt City)

This visually signals which physics domain Spark is using.

---

## 🌑 World 1: Shadow Realm

**Setting:** A dark fantasy world where light is rare and precious.
**Vibe:** *Inside* / *Limbo* atmosphere, kid-friendly.
**Palette:** Deep blues, warm oranges (torchlight).

### Levels (planned)
| # | Concept | Mechanic |
|---|---------|----------|
| 1 | Light reveals what it touches | Tap to turn on torch in dark cave; drag to explore |
| 2 | Objects block light → shadows | Drag torch around an object |
| 3 | Distance changes shadow size | Move torch closer/farther from wall |
| 4 | Match shadow to target | Apply size + angle |
| 5 | Materials affect shadows (transparent/opaque) | Place objects between torch and wall |
| Boss | Escape the dark cave | Combine all skills |

### Level 1 — "First Light" (designed in detail)
See **`docs/levels/shadow-realm-01.md`** for complete spec.

---

## ⚡ World 2: Volt City

**Setting:** A retro-futuristic city running on circuits.
**Vibe:** *Wall-E* meets *Human Resource Machine*.
**Palette:** Yellows, electric blues, copper.

### Levels (planned)
| # | Concept | Mechanic |
|---|---------|----------|
| 1 | Closed loop = light | Drag wire from battery to bulb |
| 2 | Broken circuit = no light | Cut a wire — bulb dies |
| 3 | Switches open/close circuits | Add a switch |
| 4 | Conductor vs insulator | Test materials in a gap |
| 5 | Series intuition | Power two bulbs from one battery |
| Boss | Repair a broken robot | Combine all skills |

### Volt City as Hub
Volt City is also the **app's home screen** — the player returns here between adventures. Visible state changes as progress is made (more bulbs lit, more NPCs, more decoration).

---

## 🎮 Gamification Systems

| System | Implementation |
|--------|---------------|
| XP | Earn per level/test completion |
| Stars (1–3) | Per-level mastery rating |
| Badges | "Shadow Master", "Circuit Wizard", etc. |
| Streaks | Daily play tracking |
| Realm Map | Worlds as unlockable map locations |
| Boss Challenge | End-of-world test to unlock next realm |

**No lives/energy system in Level 1.** Consider for later levels only.

---

## 🛠️ Technical Stack

| Layer | Choice |
|-------|--------|
| UI | SwiftUI |
| State | `@Observable` + `@Environment` |
| Persistence | SwiftData (local only — zero backend cost) |
| Animation | SwiftUI native + Canvas API |
| Sound | AVFoundation |
| Min iOS | iOS 26+ (matches Xcode project deployment target) |
| Target devices | iPhone primary; iPad nice-to-have |

### Architecture Principles
- **Apple-style level design methods** (clean MVVM-ish with `@Observable`)
- **Modular per-level architecture** — each level is self-contained
- **Shared design system** — colors, typography, audio defined centrally
- **No third-party dependencies** unless absolutely necessary
- **Production-ready, scalable, readable**

---

## 📁 Project Structure (proposed)

```
Spark/
├── App/
│   ├── SparkApp.swift
│   └── RootView.swift
├── Core/
│   ├── DesignSystem/        # Colors, typography, spacing
│   ├── Audio/               # AudioManager
│   ├── Persistence/         # SwiftData models
│   └── Extensions/
├── Features/
│   ├── Hub/                 # Volt City home/hub screen
│   ├── RealmMap/            # World selection map
│   ├── ShadowRealm/
│   │   ├── Level1/
│   │   ├── Level2/
│   │   └── ...
│   ├── VoltCity/
│   │   └── Levels/
│   ├── Profile/
│   └── Tests/               # Post-level checkpoint quizzes
├── Models/
│   ├── Realm.swift
│   ├── Level.swift
│   ├── Progress.swift
│   └── Spark.swift
├── Resources/
│   ├── Sounds/
│   └── Assets.xcassets
└── docs/
    ├── design/
    ├── levels/
    └── decisions/
```

---

## 👥 Team (Secret API — 7 members)

Suggested role breakdown for Challenge 7:
- **2 designers** → level design (the hardest job; every level must teach)
- **3 devs** → game mechanics (one per world + one shared)
- **1 dev** → meta-systems (XP, map, profile, SwiftData)
- **1 person** → art + sound + polish

---

## 📅 8-Week Timeline

| Week | Focus |
|------|-------|
| 1 | Architecture, SwiftData models, hub UI, navigation skeleton |
| 2 | Shadow Realm L1-2 (torch + basic shadow mechanic) |
| 3 | Shadow Realm L3-5 (distance, materials, matching) |
| 4 | Shadow Realm Boss + tests + polish |
| 5 | Volt City L1-2 (battery + bulb + wire mechanic) |
| 6 | Volt City L3-5 (switches, conductors, multi-bulb) |
| 7 | Volt City Boss + meta-system (XP, badges, streaks) |
| 8 | Final polish, sound, animations, TestFlight, demo prep |

---

## 📦 Implementation Progress

> Updated as work lands. Reflects the actual codebase state, not aspirational plans.

### ✅ Week 1 — Foundation (shipped)

Complete architecture is in `Physica/Physica/`:

- **App layer** — `App/PhysicaApp.swift`, `App/RootView.swift` (NavigationStack), `App/AppRouter.swift` (`@Observable` route stack)
- **Design system** — `Core/DesignSystem/{Theme,Typography,Spacing}.swift`
- **SwiftData models** — `Models/{Realm,Level,Progress}.swift` with code-driven first-launch seeding via `Models/SeedData.swift`
- **Persistence** — `Core/Persistence/ModelContainer+Physica.swift` (shared container + preview helper), `Core/Persistence/ProgressStore.swift` (level-completion + cross-realm unlock)
- **Reusable components** — `Core/Components/{SparkView,LightConeView,LevelCompleteView,PostLevelTestView}.swift`
- **Hint engine** — `Core/Hints/HintEngine.swift` (timeline-based idle detection)
- **Audio** — `Core/Audio/AudioManager.swift` (no-op stubs; `Resources/Sounds/` awaits assets)
- **Hub** — `Features/Hub/HubView.swift` (Volt City home)
- **Realm Map** — `Features/RealmMap/RealmMapView.swift` (per-realm level grids with unlock gating)
- **Placeholders** — `Features/{ShadowRealm,VoltCity,Profile}/...PlaceholderView.swift` for unbuilt levels
- **CLAUDE.md** — `iOS 17+` updated to `iOS 26+` to match actual project setting

### ✅ Week 2 — Shadow Realm Level 1 "First Light" (shipped)

Implements the spec from `shadow-realm-01.md`. Files in `Features/ShadowRealm/Level1/`:

- `ShadowRealmLevel1State.swift` — `@Observable` phase machine: `dark → exploring → complete → test → finished`. Normalized 0..1 positions for crystal/bat/exit. Hint engine with the spec's 30s/60s/120s escalation.
- `CaveEnvironmentView.swift` — placeholder cave art (radial gradient, stalactites, floor rocks) + crystal (sparkles when discovered), sleeping bat (wing-flap rate changes), exit arch (glows when found).
- `ShadowRealmLevel1View.swift` — orchestrates the dark→light reveal via a `RadialGradient` mask on the cave layer; drag to move Spark; discovery checks fire audio cues; attention pulse + dashed-trail hint visuals.
- Win flow → `LevelCompleteView` → `PostLevelTestView` → `ProgressStore.recordLevelCompletion` → router pops to root.

Wired into `App/RootView.swift`: `shadowLevel(1)` route resolves to `ShadowRealmLevel1View`; other levels still hit `ShadowRealmPlaceholderView`.

### 🚧 Up next

- Shadow Realm L2 "Things That Block" — design spec needed first (template: `shadow-realm-01.md`)
- Shadow Realm L3-5 + Boss
- Volt City L1-Boss
- Meta-systems (XP, badges, streaks, Profile screen)
- W8 polish: real Spark sprite art, cave/Volt City art, sound assets, animation polish, TestFlight

---

## ✅ How to Use This File

When working with Claude Code:
- **Always read this file first** in any new session
- **Reference specific sections** when asking for help (e.g. "design Level 2 of Shadow Realm following the principles in CLAUDE.md")
- **Update this file** when major decisions change (mark with date)
- **Never deviate from locked elements** (Spark visual DNA, story structure, core loop) without team discussion

---

## 🔒 Locked Decisions (do not change without team consensus)

- ✅ Core loop: Play & Learn → Test → Earn → Unlock
- ✅ Two worlds for Challenge 7: Shadow Realm + Volt City
- ✅ Character: Spark (one character across all worlds)
- ✅ Story: The Broken World (hub-and-spoke, expandable)
- ✅ World order: Shadow Realm first, Volt City second
- ✅ Hub: Volt City doubles as home screen
- ✅ Stack: SwiftUI + SwiftData + `@Observable`, iOS 26+
- ✅ No tutorial text in early levels
- ✅ Level 1 of any world cannot be failed

---

*Last updated: May 8, 2026 — Week 1 foundation + Shadow Realm L1 "First Light" shipped. Implementation Progress section added.*
