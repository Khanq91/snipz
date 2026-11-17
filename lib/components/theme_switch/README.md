---
# --- IDENTITY ---
id: theme_switch
title: Theme Switch
kind: composite
tags: [theme, toggle, animation, particles, rain, fireworks, droplet, canvas, physics]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: folder
entry: theme_switch.dart
files:
  - theme_switch.dart: "entry, public API + widget"
  - _engine.dart: "physics engine — droplet/rain/diwali math + data types"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/shadcn-labs/Pin-UI
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-11-17
created_flutter: 3.44.5
created_dart: 3.12.2
created_deps: []
platforms_initial: [android]

# --- COMPONENT VERSION ---
version: 1.0.0

# --- DERIVED (computed from Test History by verify.dart, do not hand-edit) ---
latest_known_good: null
last_verified: null
status: null
---

A theme-toggle button with **three animated transition effects** — all rendered on
a `CustomPaint` canvas, ticker-driven, fully self-contained.

## Effects

| Effect | Description |
|--------|-------------|
| **Droplet** | A drop of the next theme falls from above, squashes on impact, and a circle flood fills the scene from the splash point. |
| **Rain** | Raindrops fall at terminal velocity (depth-sorted, wind-slanted). Each near drop leaves a puddle that spreads and merges; a guaranteed-coverage algorithm (`coverageScale`) ensures full fill. |
| **Diwali** | Rockets launch from the toggle button, burst into peony/ring shells under air-drag + gravity (closed-form physics). Stars bloom into dots that tile the scene. |

The toggle button (moon/sun) and the segmented effect-picker take the new theme
progressively — the moment each control's centre is covered by the flood.

## Install

Flutter only — no pub packages.

```yaml
# pubspec.yaml: nothing to add
```

Copy the entire `theme_switch/` folder into your project and import:

```dart
import 'components/theme_switch/theme_switch.dart';
```

## API

| Param | Type | Default | Description |
|---|---|---|---|
| `theme` | `LiquidTheme` | `.light` | Current theme. A change from outside lands instantly with no effect. |
| `onThemeChange` | `void Function(LiquidTheme)?` | `null` | Called once the transition has fully covered the scene. |
| `defaultEffect` | `SwitchEffect` | `.droplet` | Starting effect. |
| `onEffectChange` | `void Function(SwitchEffect)?` | `null` | Called when the user picks another effect. |
| `sound` | `bool` | `true` | Reserved — currently a no-op (see Caveats). |
| `fill` | `bool` | `false` | Expand to fill the parent; otherwise 480 px tall with rounded corners. |
| `animate` | `bool` | `true` | Set `false` to freeze all animation (TickerMode-compatible). |
| `frozenAt` | `double?` | `null` | Render a deterministic still at this elapsed time (s). |

### Minimal usage

```dart
ThemeSwitchWidget(
  theme: _currentTheme,
  onThemeChange: (t) => setState(() => _currentTheme = t),
  defaultEffect: SwitchEffect.rain,
)
```

## Caveats

**Audio (Diwali):** The original uses Web Audio API to synthesise a whistle,
boom, and crackle. Synthesising PCM in Dart requires either a native plugin or
writing raw samples to a file — neither is feasible with `flutter only` deps.
The `sound` parameter is accepted but is a no-op. Diwali is visually complete;
only the audio is absent.

**Coverage guarantee:** The `coverageScale` algorithm (ported verbatim from
TypeScript) guarantees that puddles/dots cover every pixel before committing the
theme, no matter the scene size.

**Performance:** Diwali spawns up to ~1,400 stars. On low-end Android the frame
rate may drop during the merge phase. The `coverageScale` precomputation
(< 1 ms on modern devices) is done on the first toggle; subsequent toggles reuse
it if the scene size hasn't changed.

## Changelog

- **1.0.0** (2026-11-17) — created. All three effects implemented. Audio reserved.

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|
