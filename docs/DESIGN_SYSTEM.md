# Physica — Design System

> Source of truth for color, typography, and spacing. Every view must use these tokens. **Never hardcode hex codes, font sizes, or magic-number padding in feature code.**
> Tokens are defined in `Physica/Core/DesignSystem/{Theme,Typography,Spacing}.swift`.

Some token names below are mid-rename during the V2 migration — current code names + target names are both shown where they differ. Sync up the code in a follow-up commit; do not invent new names that don't appear here.

---

## Color Tokens

### Spark palette (universal — used everywhere Spark appears)

| Token | Hex | Usage |
|---|---|---|
| `Color.sparkBrass` (current: `voltCopper`) | `#C78346` | Spark's body base |
| `Color.sparkBrassLight` (current: `voltCopperBright`) | `#EBA65C` | Spark's body highlight |

### Light Realm accent palette (World 1)

| Token | Hex | Usage |
|---|---|---|
| `Color.beaconYellow` (current: `torchYellow`) | `#FFC75C` | Spark's eye glow, beam center, lit receivers |
| `Color.beaconWarm` (current: `torchWarm`) | `#FF8C33` | Beam falloff, warm halo around restored objects |
| `Color.realmDark` (current: `shadowDeep`) | `#0A0D1A` | Deepest backgrounds, "unrestored" surfaces |
| `Color.realmMid` (current: `shadowMid`) | `#1A1F33` | Mid-tone walls, locked surfaces |

### Volt City accent palette (World 2, stretch)

| Token | Hex | Usage |
|---|---|---|
| `Color.electricBlue` (current: `voltBlue`) | `#52ABF5` | Spark's eye in Volt City, primary CTA buttons |
| `Color.sparkYellow` (current: `voltYellow`) | `#FFD752` | Lit windows, celebration sparks |

### Worlds 3–5

Palette TBD when those worlds enter scope. Each future world will get a 2-token accent palette (one primary glow, one ambient mid-tone).

### Adding a new color

1. Open `Physica/Core/DesignSystem/Theme.swift`.
2. Add the new `static let` to the `Color` extension.
3. Name it by **intent**, not appearance: `beaconYellow`, `sparkBrassLight` — **not** `darkBlue1` or `lightBrown`.
4. If you need it in 2+ files, it belongs here.

---

## Typography Tokens

All fonts use `.rounded` design — friendly, kid-appropriate, distinctly non-utility.

| Token | Spec | Usage |
|---|---|---|
| `Font.gameTitle` | 34pt heavy rounded | Main game title ("Physica"), section headlines |
| `Font.levelHeader` | 22pt bold rounded | Module titles, dialogue headlines, primary buttons |
| `Font.bodyGame` | 17pt medium rounded | Body copy, dialogue text, descriptions, button labels |
| `Font.hintCaption` | 13pt medium rounded | Subtle captions, lock messages, fine print, Spark Connection bylines |

### Dialogue typewriter

The dialogue overlay (V2 — to be implemented) uses `Font.bodyGame` rendered with a **typewriter effect at 35 chars/second**. Tap advances; tap during typewriter completes the current line instantly. Owned by `Core/Dialogue/TypewriterRenderer.swift`.

### Adding a new font

Same rule as colors — name by intent. If you need a 28pt header, try `.font(.levelHeader.weight(.heavy))` before adding a new token.

---

## Spacing Tokens

| Token | Value | Usage |
|---|---|---|
| `Spacing.xs` | 4 | Hairline gaps, tight icon spacing |
| `Spacing.sm` | 8 | Inline element separation |
| `Spacing.md` | 16 | Default container padding |
| `Spacing.lg` | 24 | Section separation, card padding |
| `Spacing.xl` | 40 | Major vertical rhythm, screen-edge padding |
| `Spacing.xxl` | 64 | Hero spacing, vertical breaks |

Use them like `.padding(Spacing.md)`, `VStack(spacing: Spacing.lg)`. Never `.padding(16)`.

---

## Portrait Layout Bands

App is **portrait-only**. Three vertical bands divide every module scene:

| Band | Height | Reserved for |
|---|---|---|
| Top UI | 8% | Pause button, hint button, dialogue progress dots |
| Active play | 64% | Puzzle elements, Spark, light beams |
| Dialogue overlay | 28% | Spark portrait + typewriter text panel |

Never place interactive puzzle elements in the dialogue band — the overlay covers them.

---

## Component Patterns

### Buttons (CTA)

```swift
Button { ... } label: {
    Text("Begin the journey")
        .font(.levelHeader)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(Color.electricBlue, in: Capsule())
        .foregroundStyle(.white)
        .shadow(color: .electricBlue.opacity(0.4), radius: 14)
}
.buttonStyle(.plain)
```

- Capsule shape, accent color fill, white text
- Soft accent-color shadow (`opacity: 0.4`, `radius: 14`)
- Padded horizontally `Spacing.lg`, bottom `Spacing.xl`

### Cards (world / module surfaces)

```swift
.background(
    RoundedRectangle(cornerRadius: 24)
        .fill(cardBackground)
)
```

- `cornerRadius: 24` for world cards, `14` for module tiles
- Locked state: `.opacity(0.55)` + lock icon overlay

### Spark character

Two complementary types — pick by where Spark appears.

**`SparkView`** (SwiftUI) — for Home, World Map, dialogue overlay portrait, anywhere outside an SKScene.

```swift
SparkView(
    mode: .yellow,           // or .blue (per current world's accent)
    expression: .curious,    // V2 target set: .idle, .curious, .alarmed, .hopeful, .steady, .resolved
    size: 120
)
```

**`SparkCharacter`** (SpriteKit SKNode — V2 target, not yet built) — for in-scene gameplay. Owns `expression`, `coreGlow` (`.dim` / `.warm` / `.stable` / `.bright`), and `playReaction(_:)` for `.blink` / `.turn` / `.lightUp` / `.shrink`. Exposes `portrait() -> Image` to drive the dialogue overlay.

**Expression assets map to story arc** — see [`../PIPELINE.md`](../PIPELINE.md) §5.1 for which expression range fits which chapter.

### Dialogue overlay (V2 target)

- Sits in bottom 28% of screen.
- Spark portrait on left (or Umbra in M7), text panel on right.
- Typewriter at 35 chars/sec; tap to advance / complete current line.
- Never covers active puzzle elements (puzzle is constrained to middle 64%).

---

## Animation Conventions

### Timing curves

| Curve | When |
|---|---|
| `.easeInOut(duration: 1.6).repeatForever(autoreverses: true)` | Idle hover, ambient pulse |
| `.easeOut(duration: 0.7)` | Light reveal, single-shot transitions |
| `.spring(response: 0.4, dampingFraction: 0.5)` | Discovery feedback, beat opening |
| `.linear(duration: 1.0).repeatForever(autoreverses: false)` | Dashed-line trail movement |

### Reduced motion

Wrap any non-essential repeating animation:

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

private func startAnimations() {
    guard !reduceMotion else { return }
    withAnimation(...) { ... }
}
```

**Essential animations** (state transitions critical to gameplay) stay; **decorative animations** (ambient hover, halos) are gated.

---

## Sound Conventions

The full sound spec lives in [`../Physica/Physica/Core/Audio/AudioManager.swift`](../Physica/Physica/Core/Audio/AudioManager.swift). Pattern:

```swift
audio.play(.beaconActivate)         // single SFX
audio.startAmbient(.dawnCourt)      // looping background
audio.stopAmbient()                 // when leaving a module
```

When designing a module:
- **One ambient** loop for the chapter (start in `.onAppear`, stop in `.onDisappear`)
- **SFX** for: tap, beam-on, receiver chime, mirror sparkle, dialogue chime, transition swell — see `AudioManager.SFX` enum
- Volume: ambient `0.6`, SFX default `1.0`. Ambient never overpowers a dialogue beat or discovery chime.

---

## Asset Guidelines

When real art replaces placeholder shapes:

- **Resolution:** export at 3× minimum. iPhone 15 Pro is 3×.
- **Format:** PDFs (vector) preferred where possible — auto-scales. PNGs fine for hero scenes.
- **Asset catalog:** group by world/module: `Assets.xcassets/LightRealm/M1_SleepingBeacon/`, `Assets.xcassets/Spark/`, etc.
- **Rive files:** `Resources/Rive/spark.riv`. State machines named in PascalCase. (Rive integration is post-V1 polish — see [`BACKLOG.md`](BACKLOG.md).)
- **Dark-only for now:** all art is designed for the dark game theme. No light-mode variants in V1.

---

*Last updated: 2026-05-12 — V2 migration*
