# Physica

> A story-driven physics learning app for 10–14 year olds.
> Spark walks the broken kingdoms of physics — and the player learns by walking with him.

**Team:** Secret API · **Apple Developer Academy, Naples** · **Challenge 7**

---

## What is Physica?

An iOS app where the **physics is the mechanic** and the **story is the reason**. Players don't read lessons — they restore broken worlds alongside **Spark**, a small robot from Volt City, by *doing* the physics. Each chapter ends with Spark bridging the concept to a real-world example the kid actually sees in daily life (a streetlight, a dusty sunbeam, an ambulance with reversed lettering).

This is the pivot from V1's "Brilliant × Duolingo" framing: Physica is **interactable storytelling**, not a puzzle app with story bolted on.

### The 5 worlds (long-term vision)

1. **Light Realm** — Light & Shadows *(World 1, V1 scope)*
2. **Volt City** — Electricity & Circuits *(World 2, stretch goal)*
3. Magnetic Peaks — Magnetism
4. Echo Valley — Sound
5. Drift Plains — Air & Pressure

V1 ships **Light Realm** (7 modules). World 2 is a stretch goal if time permits.

### The 7 chapters of the Light Realm

| # | Module | Concept |
|---|---|---|
| M1 | The Sleeping Beacon | Light reveals what it touches |
| M2 | The Line of Dawn | Light travels in straight lines |
| M3 | Shadow Garden | Source size shapes the shadow (umbra/penumbra) |
| M4 | Crystal Gate | Transparent / translucent / opaque |
| M5 | Pinhole Studio | The pinhole camera (eye analogue) |
| M6 | Mirrorworks Arcade | Law of reflection + lateral inversion (the AMBULANCE moment) |
| M7 | Eclipse Tower | Eclipses, balance, narrative resolution |

Full module specs, narrative architecture, and the phased pipeline live in [`PIPELINE.md`](PIPELINE.md) — **this is the source of truth for the project**. Read it before contributing.

---

## Tech Stack

- **Minimum iOS:** 18.0
- **Shell (menus, world map, dialogue, settings):** SwiftUI + `@Observable`
- **Game scenes (modules):** SpriteKit (or SwiftUI for simpler modules — decided per-module)
- **Persistence:** SwiftData (local-only, zero backend cost)
- **Audio:** AVFoundation
- **Orientation:** Portrait only

See [`PIPELINE.md`](PIPELINE.md) §3 for full tech details and [`ARCHITECTURE.md`](ARCHITECTURE.md) for code-level rules.

---

## Current Status

| Phase | Goal | Status |
|---|---|---|
| **0** | V1 → V2 migration (delete dead code, rewrite docs) | 🟡 in progress |
| **1** | Foundation — Core types + M1 in greybox | ⬜ planned |
| **2** | Vertical Slice — M1 + M2 + transition with real art | ⬜ planned |
| **3** | Core Content — M3 + M4 + Umbra silent presence | ⬜ planned |
| **4** | New Mechanics — M5 (pinhole) + M6 (mirrors) | ⬜ planned |
| **5** | Capstone — M7 + narrative resolution | ⬜ planned |
| **6** | Polish & Testing — kid playtest, TestFlight | ⬜ planned |

Phases are gated by milestones, not dates. Full criteria in [`PIPELINE.md`](PIPELINE.md) §8.

---

## App Flow

```
1. App launch → Intro cinematic (Spark introduces himself, the broken realms)
2. Tap "Begin" → Main Home Page (profile, XP, streak, 5-world map)
3. Tap a world → Spark "travels" to that world → World Page (lists modules)
4. Tap a module → Module gameplay
     ├── Opening dialogue beat
     ├── Discovery beat (first interaction)
     ├── Insight beat (puzzle solved)
     └── Spark Connection beat ← the real-world bridge
5. Transition scene → next module unlocks
```

---

## Getting Started

1. Clone the repo, `cd` into it.
2. Pull `main` before starting work: `git pull origin main`
3. Open `Physica/Physica.xcodeproj` in Xcode 16+.
4. Select an iOS 18+ simulator (iPhone 15 Pro recommended — design target).
5. Build & run with `⌘R`.

The Xcode project uses a **filesystem-synchronized group** — files added under `Physica/` automatically join the build target. **Never edit `.pbxproj` manually.**

---

## Project Structure

```
Physica/                        ← repo root
├── README.md                   ← this file
├── PIPELINE.md                 ← V2 source of truth (read first)
├── ARCHITECTURE.md             ← code-level rules
├── CONTRIBUTING.md             ← git workflow
├── .gitignore
├── docs/                       ← supporting docs
│   ├── DESIGN_SYSTEM.md
│   └── BACKLOG.md              ← out-of-scope ideas
└── Physica/                    ← Xcode project folder
    ├── Physica.xcodeproj
    └── Physica/                ← app source
        ├── App/                ← entry, root view, router
        ├── Core/               ← shared engine (Design, Audio, Persistence, Hints, Components)
        ├── Models/             ← SwiftData @Model types
        ├── Features/           ← Onboarding, Home, RealmMap, Profile
        └── Resources/          ← assets, sounds, dialogue JSON
```

The target end-state file structure (after V2 migration completes) is specified in [`PIPELINE.md`](PIPELINE.md) §4 — it adds `Core/Character/`, `Core/Narrative/`, `Modules/Mx_*/`, `Transitions/`, and `Shell/`.

---

## Commit Conventions

`<type>: <short description>` — lowercase, imperative.

| Type | When |
|---|---|
| `feat` | New feature, module, or component |
| `fix` | Bug fix |
| `refactor` | Code restructuring, no behavior change |
| `chore` | Build settings, dependencies, project file, cleanup |
| `docs` | Documentation only |
| `style` | UI / visual / formatting only |
| `test` | Tests |
| `art` | Asset additions or replacements |

Examples:
```
feat: implement M1 Sleeping Beacon opening beat
fix: dialogue overlay covers puzzle on iPhone 13 mini
docs: clarify Umbra glimpse cadence in PIPELINE.md
chore: remove V1 dead code ahead of V2 migration
```

Full git workflow in [`CONTRIBUTING.md`](CONTRIBUTING.md).

---

## Team

7 members, ~8-week timeline. Suggested roles (see [`PIPELINE.md`](PIPELINE.md) §8 for phase ownership):

| Role | Count | Responsibility |
|---|---|---|
| Designer | 2 | Module narrative + level design (1 phase ahead of devs) |
| Dev — Core systems | 1 | Light/Character/Narrative/Dialogue shared libraries |
| Dev — Modules | 3 | M1–M7 implementation, split across phases |
| Art + sound + polish | 1 | Spark sprites, environment art, audio integration |

---

## Curriculum Source

NCERT-aligned **Class 6 Physics**, specifically **Chapter 5: Light (pp. 72–85)**. Every module maps to a concept on those pages; assessment events log evidence of mastery for the end-of-world Spark Field Report.

---

*Last updated: 2026-05-12 — V2 migration in progress*
