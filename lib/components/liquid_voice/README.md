---
# --- IDENTITY ---
id: liquid_voice
title: Liquid Voice
kind: composite
tags: [voice, recording, glass, animation, pill]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: liquid_voice.dart
files:
  - liquid_voice.dart: "entry, public API"
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

A voice-input pill made of liquid glass — ported from the Pin-UI `LiquidVoice`
React/WebGL component. All animation is procedural Flutter (no WebGL, no assets).

## Install

Flutter only — no extra pub dependencies.

```yaml
# pubspec.yaml: nothing to add
```

Copy the entire `liquid_voice/` folder into your project and import:

```dart
import 'components/liquid_voice/liquid_voice.dart';
```

## API

| Param | Type | Default | Description |
|---|---|---|---|
| `theme` | `LiquidVoiceTheme` | `.light` | Day sky (light) or night sky (dark). Theme transition animates as an expanding circle from the pill center. |
| `fill` | `bool` | `false` | Fill container edge-to-edge; otherwise 16:10 aspect ratio box. |
| `onSend` | `void Function(Duration)?` | `null` | Called when user taps send, with the recording duration. |
| `onCancel` | `VoidCallback?` | `null` | Called when user cancels. |
| `animate` | `bool` | `true` | Set `false` to pause all animation (compatible with `TickerMode`). |

### States

1. **Idle** — 72×72 glass pill with mic button.
2. **Recording** — pill springs open to 300×84; cancel (left) + send (right) + 15 waveform bars appear.
3. **Processing** — bars gather to center, 3-dot spinner spins, action icon switches to stop.
4. **Done** — checkmark draws itself, pill returns to idle after ~0.9 s.

Cancel or stop can be triggered at any time during recording/processing.

## Caveats

- **No WebGL / real glass refraction** — the original uses a full two-pass WebGL 2 shader (SDF rounded-box + fresnel bevel). The Flutter port uses `BackdropFilter(blur)` + gradient overlay for the glass effect. This is visually similar but lacks true refractive dispersion and specular glare.
- **Sky rendered as a rasterised color grid** — the GLSL sky shaders are approximated by sampling a 10×8 Dart color grid each frame and drawing filled rects. This is cheap (no shader program) and smooth enough at runtime; a custom `FragmentProgram` would require `.frag` asset files (not portable — violates vault rule 4).
- **Waveform is simulated** — identical to the original; no real microphone access is used.
- **Spring physics** — implemented via Flutter's `SpringSimulation` from `package:flutter/physics.dart`; stiffness/damping values match the original (260/24 for pill, 420/30 for snappy, 260/26 for soft).
- **Night reveal** — expanding circle from pill center is approximated per-pixel in the sky grid painter. The original uses a smooth GLSL `smoothstep` over distance; the Flutter version does the same math in Dart.

## Changelog

- **1.0.0** (2026-11-17) — created; ported from Pin-UI LiquidVoice (React/WebGL → Flutter/Dart)

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|
