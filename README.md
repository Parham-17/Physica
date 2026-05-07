# Physica ⚡

> A gamified physics learning app for middle schoolers.
> *Brilliant × Duolingo, but for physics — and more game than lesson.*

**Team:** Secret API · **Apple Developer Academy, Naples** · **Challenge 7**

---

## Tech Stack

- **UI Framework:** SwiftUI
- **State:** `@Observable` + `@Environment`
- **Persistence:** SwiftData (local-only, zero backend cost)
- **Animation:** SwiftUI native + Canvas; Rive planned for character/celebration polish (W8)
- **Sound:** AVFoundation
- **Minimum Target:** iOS 26
- **Architecture:** MV + Services + per-level `@Observable` state

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for the full rule set.
See [`CONTRIBUTING.md`](CONTRIBUTING.md) before opening a PR.

---

## What is Physica?

An iOS app that teaches **Class 6 NCERT physics** through play. Students don't read lessons — they discover physics by interacting with **Spark**, a small robot from **Volt City** whose world's physics laws are breaking. Spark visits each broken realm to restore balance.

**Core loop:** `Play & Learn → Test → Earn → Unlock`

The game *is* the lesson. Concepts emerge through play, never through tutorial text. Locked decisions are in [`CLAUDE.md`](CLAUDE.md) (creative + product foundation).

### Worlds shipping in v1.0
1. 🌑 **Shadow Realm** — Light & Shadows
2. ⚡ **Volt City** — Electricity & Circuits

### Future expansion (post-Academy)
- 🧲 Magnetic Peaks · 🔊 Echo Valley · 💨 Drift Plains · *one realm per physics topic*

---

## Current Status

| Phase | Deliverable | Status |
|-------|-------------|--------|
| W1 | Foundation (architecture, models, hub, realm map, reusable engine) | ✅ shipped |
| W2 | Shadow Realm L1 "First Light" | ✅ shipped |
| W2 | Shadow Realm L2 "Things That Block" | 🟡 next |
| W3 | Shadow Realm L3–5 | ⬜ planned |
| W4 | Shadow Realm Boss + Test system polish | ⬜ planned |
| W5–7 | Volt City L1–Boss + meta-systems | ⬜ planned |
| W8 | Real art (Rive/Lottie), sound, polish, TestFlight | ⬜ planned |

Detailed phase plan: [`docs/IMPLEMENTATION_PHASES.md`](docs/IMPLEMENTATION_PHASES.md).
Out-of-scope ideas for later: [`docs/BACKLOG.md`](docs/BACKLOG.md).

---

## Getting Started

1. **Clone** the repo and `cd` into it.
2. **Pull `main`** before starting any work: `git pull origin main`
3. **Open** `Physica/Physica.xcodeproj` in Xcode 16+.
4. **Select** an iOS 26+ simulator (iPhone 17 Pro works).
5. **Build & run** with `⌘R`.

The Xcode project uses a **filesystem-synchronized group** — files added under `Physica/` automatically join the build target. **Never edit `.pbxproj` manually.**

> If a file you add starts producing a "Multiple commands produce" error, it's because Xcode treats unrecognized files as bundle resources. Move docs into `docs/` (outside the source tree) or add a unique extension.

---

## Project Structure

```
Physica/                        ← repo root
├── README.md                   ← this file
├── CLAUDE.md                   ← creative + product foundation (locked decisions)
├── ARCHITECTURE.md             ← architectural rules (read before contributing)
├── CONTRIBUTING.md             ← git workflow, push/pull, PR rules
├── .gitignore
├── docs/                       ← long-form docs and references
│   ├── IMPLEMENTATION_PHASES.md
│   ├── DESIGN_SYSTEM.md
│   ├── BACKLOG.md
│   └── SHADOW_REALM_01.md      ← reference level spec
└── Physica/                    ← Xcode project folder
    ├── Physica.xcodeproj       ← Xcode project (do not edit .pbxproj manually)
    └── Physica/                ← app source (filesystem-synchronized)
        ├── App/                    ← entry, root view, router
        ├── Core/
        │   ├── DesignSystem/       ← Theme, Typography, Spacing
        │   ├── Audio/              ← AudioManager (stubs until W8)
        │   ├── Persistence/        ← ModelContainer, ProgressStore
        │   ├── Hints/              ← HintEngine
        │   └── Components/         ← SparkView, LightConeView, LevelCompleteView, PostLevelTestView
        ├── Models/                 ← @Model: Realm, Level, Progress + SeedData
        ├── Features/
        │   ├── Hub/                ← Volt City home
        │   ├── RealmMap/           ← world / level selection
        │   ├── ShadowRealm/Level1/ ← shipped: First Light
        │   ├── ShadowRealm/        ← placeholders for L2–Boss
        │   ├── VoltCity/           ← placeholders for L1–Boss
        │   └── Profile/            ← placeholder for W7
        └── Resources/Sounds/       ← awaiting audio assets (W8)
```

---

## Commit Conventions

Follow `type: short description` — same scheme used by the Majestica/AfterInk project.

| Type | When to use |
|------|-------------|
| `init` | Project setup, initial config, scaffolding new world |
| `feat` | New feature, level mechanic, or component |
| `fix` | Bug fix |
| `refactor` | Code restructuring with no behavior change |
| `style` | UI/visual changes, formatting, no logic change |
| `docs` | Documentation only |
| `chore` | Dependencies, build settings, project file |
| `test` | Adding or updating tests |
| `art` | Asset additions or replacements (sprites, sounds, Rive files) |

**Rules:**
- Lowercase, imperative mood: `feat: add level 2 shadow blocker` (not `added` / `adds`)
- First line under 72 characters
- No period at the end
- Optional blank line + body for context (why, not what)

**Examples:**
```
init: scaffold Volt City Level 1 folder
feat: add light reveal mask in shadow realm L1
feat: implement post-level test reset on wrong answer
fix: correct gesture conflict on Spark drag
refactor: extract LightConeView from ShadowRealmLevel1View
style: align hub button shadow with design system
docs: add backlog entry for Magnetic Peaks
chore: bump iOS deployment target to 26.4
art: add Spark idle Rive file
```

For the full git workflow (branching, push/pull, PRs, conflict resolution) see [`CONTRIBUTING.md`](CONTRIBUTING.md).

---

## Team

7 members, 8-week timeline. Suggested roles:

| Role | Count | Responsibility |
|------|-------|----------------|
| Designer | 2 | Level design specs (always 1 week ahead of devs) |
| Dev — Shadow Realm | 2 | Implements shadow realm levels |
| Dev — Volt City | 1 | Implements volt city levels |
| Dev — Meta-systems | 1 | XP, badges, streaks, profile, navigation |
| Art + sound + polish | 1 | Spark sprites, scene art, Rive/Lottie animations, sound design |

**Critical path:** designers stay 1 week ahead of devs on level specs. Without specs, devs have nothing to build.

---

## Curriculum Source

Indian English-medium school **Class 6 Physics** textbook (NCERT Class 6 Science aligned).

---

*Last updated: May 8, 2026*
