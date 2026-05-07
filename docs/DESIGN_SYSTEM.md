# Physica — Design System

> Source of truth for color, typography, and spacing. Every view must use these tokens. **Never hardcode hex codes, font sizes, or magic-number padding in feature code.**
> Tokens are defined in `Physica/Core/DesignSystem/{Theme,Typography,Spacing}.swift`.

---

## Color Tokens

### Volt City palette (warm, electric, hopeful)

| Token | Hex (approx) | Usage |
|-------|--------------|-------|
| `Color.voltCopper` | `#C78346` | Spark's body base, brass accents |
| `Color.voltCopperBright` | `#EBA65C` | Spark's body highlight |
| `Color.voltBlue` | `#52ABF5` | Spark's eye in Volt City mode, primary CTA buttons, electric accents |
| `Color.voltYellow` | `#FFD752` | Lit windows, stars, celebration |

### Shadow Realm palette (deep, mysterious, warm light)

| Token | Hex (approx) | Usage |
|-------|--------------|-------|
| `Color.shadowDeep` | `#0A0D1A` | Deepest cave background, "off" surfaces |
| `Color.shadowMid` | `#1A1F33` | Mid-tone cave walls, locked-state surfaces |
| `Color.torchYellow` | `#FFC75C` | Spark's eye in Shadow Realm mode, light cone center |
| `Color.torchWarm` | `#FF8C33` | Light cone falloff, warm halo |

### Realm theme accessor

`RealmTheme` enum gives a realm its background + accent color in one call:

```swift
RealmTheme.shadow.background  // Color.shadowDeep
RealmTheme.shadow.accent      // Color.torchYellow
RealmTheme.volt.background    // Color(red: 0.05, green: 0.08, blue: 0.16)
RealmTheme.volt.accent        // Color.voltBlue
```

### Adding a new color

1. Open `Physica/Core/DesignSystem/Theme.swift`.
2. Add the new `static let` to the `Color` extension.
3. Name it by **intent**, not appearance: `shadowMid`, `voltCopperBright`, **not** `darkBlue1` or `lightBrown`.
4. Use it. If you need it in 2+ files, it belongs here.

---

## Typography Tokens

| Token | Spec | Usage |
|-------|------|-------|
| `Font.gameTitle` | 34pt heavy rounded | Main game title ("Physica"), section headlines |
| `Font.levelHeader` | 22pt bold rounded | Level titles, dialog headlines, primary buttons |
| `Font.bodyGame` | 17pt medium rounded | Body copy, descriptions, button labels |
| `Font.hintCaption` | 13pt medium rounded | Subtle captions, lock messages, fine print |

**All fonts use `.rounded` design** — friendly, kid-appropriate, distinctly non-utility.

### Adding a new font

Same rule as colors — name by intent. If you need a 28pt header for a section, ask first whether `levelHeader` (22pt) sized up via `.font(.levelHeader.weight(.heavy))` works before adding `.sectionHeader`.

---

## Spacing Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `Spacing.xs` | 4 | Hairline gaps, tight icon spacing |
| `Spacing.sm` | 8 | Inline element separation |
| `Spacing.md` | 16 | Default container padding |
| `Spacing.lg` | 24 | Section separation, card padding |
| `Spacing.xl` | 40 | Major vertical rhythm, screen-edge padding |
| `Spacing.xxl` | 64 | Hero spacing, vertical breaks |

**Use them like:** `.padding(Spacing.md)`, `VStack(spacing: Spacing.lg)`. Never `.padding(16)`.

---

## Component Patterns

### Buttons (CTA)

```swift
Button { ... } label: {
    Text("Begin the journey")
        .font(.levelHeader)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(Color.voltBlue, in: Capsule())
        .foregroundStyle(.white)
        .shadow(color: .voltBlue.opacity(0.4), radius: 14)
}
.buttonStyle(.plain)
```

- Capsule shape, accent color fill, white text
- Soft accent-color shadow (`opacity: 0.4`, `radius: 14`)
- Padded horizontally `Spacing.lg`, bottom `Spacing.xl`

### Cards (realm/level surfaces)

```swift
.background(
    RoundedRectangle(cornerRadius: 24)
        .fill(cardBackground)
)
```

- `cornerRadius: 24` for realm cards, `14` for level tiles
- Background: shadow-realm cards use `Color(red: 0.10, green: 0.10, blue: 0.18)`; volt-city cards use `Color(red: 0.14, green: 0.16, blue: 0.28)`
- Locked state: `.opacity(0.55)` + lock icon overlay

### Spark character (`SparkView`)

Universal — used by every feature. Configure with:

```swift
SparkView(
    mode: .yellow,            // or .blue
    expression: .curious,     // .idle, .curious, .focused, .happy
    size: 120
)
```

- `mode: .yellow` → torch yellow eye + warm orange halo (Shadow Realm)
- `mode: .blue` → volt blue eye + blue halo (Volt City, Hub)
- Idle hover animation (-6pt Y offset, 1.6s ease-in-out, repeating)
- Eye scale animates to expression (curious = 1.18×, focused = 0.85×, happy = 1.05×)
- `@Environment(\.accessibilityReduceMotion)` respected — no animation if reduce-motion is on

### Level Complete

Use `LevelCompleteView` (in `Core/Components/`). Pass:
- `stars: Int` (0-3)
- `conceptLearned: String` (the **one sentence** to reveal)
- `onContinue: () -> Void`

Stars animate in sequentially with `.spring`, then concept reveals with fade + slide.

### Post-Level Test

Use `PostLevelTestView` with a `PostLevelTestQuestion` model. Single multiple-choice question. Wrong answer must trigger `state.reset()` — never explanatory text.

---

## Animation Conventions

### Timing curves

| Curve | When |
|-------|------|
| `.easeInOut(duration: 1.6).repeatForever(autoreverses: true)` | Idle hover, ambient pulse |
| `.easeOut(duration: 0.7)` | Light reveal, single-shot transitions |
| `.spring(response: 0.4, dampingFraction: 0.5)` | Star pop-in, discovery feedback |
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

## Sound Conventions (W8 implementation, but plan now)

The full sound spec lives in [`AudioManager.swift`](../Physica/Core/Audio/AudioManager.swift). Pattern:

```swift
audio.play(.lightOn)               // single SFX
audio.startAmbient(.shadowCave)    // looping background
audio.stopAmbient()                // when leaving realm
```

When designing a level:
- **One ambient** for the realm (start in `.onAppear`, stop in `.onDisappear`)
- **SFX** for: tap, discovery, wire-connect, level-complete, locked-attempt, etc. — see `AudioManager.SFX` enum
- Volume: ambient `0.6`, SFX default `1.0`. Ambient should never overpower a discovery chime.

---

## Asset Guidelines (W8)

When real art replaces placeholder shapes:

- **Resolution:** export at 3× minimum. iPhone 17 Pro is 3× density.
- **Format:** PDFs (vector) preferred where possible — auto-scales. PNGs fine for hero scenes.
- **Asset catalog:** group by feature: `Assets.xcassets/ShadowRealm/`, `Assets.xcassets/VoltCity/`, etc.
- **Rive files:** `Resources/Rive/spark.riv`. State machines named in PascalCase.
- **Dark-only for now:** all art is designed for the dark game theme. No light-mode variants in v1.

---

*Last updated: May 8, 2026*
