---
# --- IDENTITY ---
id: jelly_blob
title: Jelly Blob
kind: composite
tags: [mascot, blob, jelly, character, moods, animated, speech-bubble, form, poke]

# --- TAXONOMY (§2) ---
paint_source: painter
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: folder
entry: jelly_blob.dart
files:
  - jelly_blob.dart: "entry, public API"
  - _engine.dart: "required by jelly_blob.dart"
  - _geom.dart: "required by jelly_blob.dart"
  - _painter.dart: "required by jelly_blob.dart"
  - _palette.dart: "required by jelly_blob.dart"
  - _speech.dart: "required by jelly_blob.dart"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: adapted
source: https://github.com/mortspace/feral-blob
author: "Khang"
license: "MIT (feral-blob, © mortspace)"

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-22
created_flutter: 3.44.0
created_dart: 3.12.0
created_deps: []
platforms_initial: [android]

# --- COMPONENT VERSION ---
version: 1.0.0

# --- DERIVED (computed from Test History by verify.dart, do not hand-edit) ---
latest_known_good: null
last_verified: null
status: null

preview: null
---

# Jelly Blob

A playful, pokeable jelly-blob mascot (port of React's feral-blob) — seven
moods that reshape face and body (`sad` melts the silhouette, `happy` hops
with squash-and-stretch), a slow physics-y idle slosh, seeded blinks and arm
fidgets, `gaze`/`nod`/`mouth` hooks so it reads along with a form, a poke
easter egg, and a re-skinnable 17-color palette. Ships with
`JellyBlobSpeech`, a speech cloud that hugs its text — a separate widget, so
it's on/off by simply (not) rendering it.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `jelly_blob/` folder (6 dart file(s), see `files`)
- **Import:** `import 'jelly_blob/jelly_blob.dart';` — one line
- **Or:** `dart tools/export.dart jelly_blob` → zip + paste-ready block

## API

### `JellyBlobMascot`

| Param | Type | Default | Meaning |
|---|---|---|---|
| `size` | `double` | `240` | Render width; height follows the 900:720 design box (`size * 0.8`). |
| `mood` | `JellyBlobMood` | `neutral` | `neutral · happy · sad · angry · hmm · sideEye · password`. Changes spring from wherever the blob currently is. |
| `palette` | `JellyBlobPalette` | `violet` | Whole skin. Presets: `violet` (upstream), `mint`/`coral`/`gold` (hand-mixed for this port). |
| `happyEyes` | `JellyHappyEyes` | `star` | Happy-mood eyes: sparkly stars or closed `^_^` arcs. |
| `gaze` | `Offset` | `Offset.zero` | Nudges where it looks, in viewBox units (x −16..18, y −10..10). |
| `gazeIntensity` | `double?` | derived | How far the body leans with the gaze (0..1). |
| `mouth` | `JellyTalkMouth?` | `null` | `open`/`wide` talking override — flip per keystroke. Null = the mood's mouth. |
| `nod` | `bool` | `false` | Subtle talking wobble. |
| `pokeable` | `bool` | `true` | Widget handles taps itself (boop squash). False = bring your own GestureDetector. |
| `onOverpoke` | `VoidCallback?` | — | Fired at 6 pokes within 2.5 s; the blob also shakes. Resets the tally. |
| `animate` | `bool` | `true` | Stop the internal ticker from outside. |
| `frozenAt` | `double?` | `null` | Deterministic still frame at t seconds (see `jellyMoodPoses`). No ticker. |
| `seed` | `int` | `0` | Varies blink rhythm / arm fidget / arm rest pose per instance, deterministically. |

### `JellyBlobSpeech`

| Param | Type | Default | Meaning |
|---|---|---|---|
| `mood` | `JellyBlobMood` | `neutral` | Which line to show + how the cloud bobs; pair with the blob's mood. |
| `messages` | `Map<JellyBlobMood, String>?` | built-ins | Override the default copy per mood. |
| `text` | `String?` | `null` | Hard text override (e.g. the overpoke protest). |
| `brightness` | `Brightness?` | theme | Dark glass cloud vs frosted-white chip. |
| `textStyle` | `TextStyle?` | built-in | Merged over the bubble text style. |
| `maxWidth` | `double` | `300` | Width clamp; the single line never wraps. |
| `animate` / `frozenAt` | | | Same contract as the mascot. |

`JellyBlobEngine` (pure `sample(t)`), the geometry tables and the painter are
exported too if you want to drive frames yourself.

## Caveats

- Upstream's SVG "goo" filter (blur + alpha threshold merging the tears /
  angry puffs into the body) needs FragmentProgram, which the vault forbids —
  the FX render crisp with the same layout instead. Everything else is a
  faithful port.
- ~10 blurred draws per frame (ground shadow, inner shading, glosses) via
  `MaskFilter.blur`. Fine on a modern phone at one instance; for a grid of
  live blobs, prefer `frozenAt` thumbnails (the demo does).
- Framer-motion's per-group springs are reproduced as closed-form springs;
  the happy hop "spring through keyframes" is baked as a keyframe curve with
  the overshoot in the keys — same feel, not sample-exact to upstream.
- Honors `MediaQuery.disableAnimations` (renders the mood's still pose,
  poke disabled) like upstream's `useReducedMotion`.
- The speech cloud is fixed at 56 px tall like upstream; scale it with a
  `Transform.scale` if you need another size.

## Changelog

- **1.0.0** (2026-08-22) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `JellyBlobMascot` (+ `JellyBlobSpeech` tuỳ chọn) vào project này.

**Context**
- Chức năng: mascot thạch jelly có 7 mood, đọc theo form qua `gaze`/`nod`/`mouth`, poke được; kèm bong bóng thoại `JellyBlobSpeech` (widget riêng — không render là tắt).
- Public API: xem bảng API trong README.
- Portability: folder — copy cả `jelly_blob/` (6 file), import duy nhất `jelly_blob.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `jelly_blob/` vào <thư mục widget của project đích>.
2. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
