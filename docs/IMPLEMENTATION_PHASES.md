# Physica — Implementation Phases

> Prioritized by dependency order. Each phase produces a buildable, runnable app.
> 7-person team, 8-week timeline. Aligned with [`../ARCHITECTURE.md`](../ARCHITECTURE.md).

---

## Priority Tiers

| Tier | Meaning |
|------|---------|
| **P0 — Core** | App is unusable without this. Blocks everything else. |
| **P1 — Essential** | The teaching loop doesn't work without this. |
| **P2 — Important** | Significantly improves experience, but app works without it. |
| **P3 — Polish** | Delight and visual quality. Concentrated in Week 8. |

---

## Critical Path

**Designers must stay 1 week ahead of devs on level specs.** Without specs, devs run out of work. Designers begin a level's spec the week before its dev week.

```
W1: Designers spec L1 (already done) + start L2 spec
W2: Designers spec L3, devs implement L1 + L2
W3: Designers spec L4-5, devs implement L3-5
W4: Designers spec Boss, devs implement Boss
... (and same pattern for Volt City)
```

If design slips a week, dev work stalls — flag this immediately.

---

## P0 — Core

### Phase 1: Foundation ✅ shipped (W1)

**What:** The invisible backbone. Architecture, models, navigation, design system, reusable engine.

**Files shipped:**
```
App/
├── PhysicaApp.swift
├── RootView.swift
└── AppRouter.swift
Core/
├── DesignSystem/{Theme,Typography,Spacing}.swift
├── Audio/AudioManager.swift            (stubs until W8)
├── Persistence/ModelContainer+Physica.swift
├── Persistence/ProgressStore.swift
├── Hints/HintEngine.swift
└── Components/
    ├── SparkView.swift
    ├── LightConeView.swift
    ├── LevelCompleteView.swift
    └── PostLevelTestView.swift
Models/
├── Realm.swift
├── Level.swift
├── Progress.swift
└── SeedData.swift
Features/
├── Hub/{HubView,HubState}.swift
├── RealmMap/{RealmMapView,RealmMapState}.swift
├── ShadowRealm/ShadowRealmPlaceholderView.swift
├── VoltCity/VoltCityPlaceholderView.swift
└── Profile/ProfilePlaceholderView.swift
Resources/Sounds/                        (awaits W8)
```

**Acceptance:** App launches → Hub renders → tap "Begin the journey" → Realm Map shows both realms (Volt City locked) → tap Shadow Realm L1 → placeholder/level renders.

---

### Phase 2: Shadow Realm L1 — "First Light" ✅ shipped (W2)

**What:** Most important level in the app. Tap → discover light → drag → discover crystal/bat/exit → win.

**Files shipped:**
```
Features/ShadowRealm/Level1/
├── ShadowRealmLevel1State.swift        @Observable phase machine
├── ShadowRealmLevel1View.swift         orchestrates light reveal + drag + win
└── CaveEnvironmentView.swift           placeholder cave + crystal + bat + exit
```

Spec: [`SHADOW_REALM_01.md`](SHADOW_REALM_01.md).

**Acceptance:** Player taps Spark → light reveals cave → drags Spark → discovers items → 1–3 stars → "you've learned: light reveals what it touches" → post-level test → returns to map with stars saved.

---

## P1 — Essential

### Phase 3: Shadow Realm L2 — "Things That Block" 🟡 next (W2)

**Concept:** Objects block light → make a shadow.

**Mechanic (proposal — needs designer spec):**
- Cave with a single object (boulder) and a back wall
- Drag Spark around the boulder
- Light cone falls on the boulder, casts a dark shadow on the wall behind it
- Goal: position Spark so the shadow covers a target outline on the wall

**Spec status:** Not yet written. Designer to produce `docs/SHADOW_REALM_02.md` before W2 dev starts.

**Implementation outline:**
```
Features/ShadowRealm/Level2/
├── ShadowRealmLevel2State.swift
├── ShadowRealmLevel2View.swift
├── BoulderView.swift                   single-feature subview
└── ShadowProjectionView.swift          calculates shadow polygon from light + boulder
```

Reuses: `SparkView`, `LightConeView`, `HintEngine`, `LevelCompleteView`, `PostLevelTestView`.

**Acceptance:** Player drags Spark; shadow projects onto wall; matching the target shadow outline completes the level.

---

### Phase 4: Shadow Realm L3-5 (W3)

| L | Title | Concept | Mechanic |
|---|-------|---------|----------|
| 3 | Closer & Bigger | Distance ↔ shadow size | Move Spark closer/farther from a wall; shadow scales |
| 4 | Match the Shadow | Apply size + angle | Position Spark so projected shadow matches a target |
| 5 | Through Or Not | Materials | Place transparent / translucent / opaque objects between light and wall |

Each level: own subfolder, own State + View + level-specific subviews. Detail specs to land week-of (W3).

---

### Phase 5: Shadow Realm Boss + Test System Polish (W4)

**Boss "Escape the Cave":** Multi-room puzzle combining all five mechanics. Full design spec required.

**Test system polish:**
- Multi-question post-level tests (currently single question per level)
- Question variation / shuffling
- Track per-test answer history in `Progress` for analytics

**On boss completion:** `ProgressStore.unlockNextRealmIfReady` flips Volt City's `isUnlocked` to true.

---

### Phase 6: Volt City L1 + L2 (W5)

| L | Title | Concept | Mechanic |
|---|-------|---------|----------|
| 1 | Close the Loop | Closed circuit = light | Drag wire from battery to bulb |
| 2 | Cut the Wire | Broken loop = no light | Cut the wire; bulb dies |

L1 of Volt City CANNOT be failed (per locked decision in [`CLAUDE.md`](CLAUDE.md)).

**Implementation:**
- Reusable `WireDragView` and `BulbView` belong in `Features/VoltCity/Components/` (single-realm) until used by 2+ levels — then promote to `Core/Components/`.
- Spark switches to **blue eye** mode here (per locked visual DNA).
- Ambient: `AudioManager.startAmbient(.voltCityHum)`.

---

### Phase 7: Volt City L3-5 (W6)

| L | Title | Concept | Mechanic |
|---|-------|---------|----------|
| 3 | Flip the Switch | Switches open/close | Add a switch to the loop, toggle on/off |
| 4 | What Lets It Through | Conductor vs insulator | Test materials in a wire gap. Deliberate echo of Shadow L5 (transparency). |
| 5 | Two Lights, One Battery | Series intuition | Power two bulbs from one battery; both lit, both dim |

---

### Phase 8: Volt City Boss + Meta-systems (W7)

**Boss "Repair the Robot":** Multi-stage circuit puzzle combining all five mechanics. Emotional payoff (fixing Spark's home).

**Meta-systems:**
- XP totals (already tracked in `Progress`; surface in Profile)
- Badge system (`Progress.earnedBadges` already there; define which badges and when)
- Daily streaks (track `Progress.currentStreakDays`)
- Profile screen (replace `ProfilePlaceholderView` with the real one)

**Hub state-conditional layers:** Volt City (the hub scene) reveals more lit windows / NPCs / decoration as levels complete. Drive from `ProgressStore`.

---

## P3 — Polish (W8)

### Phase 9: Art, Sound, Animation Polish

**Asset swap (no code rewrites):**
- Replace `SparkView`'s SwiftUI shapes with a real Spark sprite (Rive recommended — supports state machine for expressions)
- Cave hero art (replace placeholder gradients + stalactite paths)
- Volt City hero art (replace skyline placeholder)
- Realm Map redesign — illustrated journey map, not card grid (see [`BACKLOG.md`](BACKLOG.md) for the design direction)

**Sound:**
- All `AudioManager.SFX` enum cases need `.wav` files in `Resources/Sounds/`
- Both ambient tracks (`.shadowCave`, `.voltCityHum`) need `.mp3` files
- See [`AudioManager.swift`](../Physica/Core/Audio/AudioManager.swift) for the full file-name list

**Animation polish:**
- Level-complete star burst with particles
- Realm transition animation (Spark "travels" between worlds)
- Post-level test answer feedback (correct = soft pop; wrong = gentle shake before reset)

**Accessibility pass:**
- VoiceOver labels on every interactive element
- Reduced-motion already wired in `SparkView`; audit all animations
- Dynamic Type support (audit all `Font.system(size:)` calls)

**TestFlight:**
- Build archive
- Upload to App Store Connect
- Internal testers (the 7 of us + Academy mentors)
- Demo prep

---

## Outside Scope (see [`BACKLOG.md`](BACKLOG.md))

These don't ship in v1.0:
- Additional realms (Magnetic Peaks, Echo Valley, Drift Plains, etc.)
- Live leaderboards / multiplayer
- Cloud sync
- iPad-specific layouts (universal scaling is fine for v1)
- Localization (English-only for v1)

---

*Last updated: May 8, 2026*
