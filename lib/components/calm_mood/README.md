---
# --- IDENTITY ---
id: calm_mood
title: Calm Mood
kind: composite
tags: [screen, mood, check-in, slider, bloom, morph, spring, palette-shift]

# --- TAXONOMY (§2) ---
paint_source: painter
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: calm_mood.dart
files:
  - calm_mood.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: adapted
source: https://github.com/mortspace
author: "Khang"
license: "unspecified — FeralUI reference copy carried no LICENSE (© mortspace)"

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

# Calm Mood

"Choose how you're feeling" check-in (port of FeralUI's MoodScreen): a
layered glass bloom whose silhouette morphs with the mood — wobbling lobes
when uneasy, six petals when pleasant (upstream math verbatim) — while the
whole screen re-tints through seven palettes. The slider follows a real
spring; its thumb squashes against the direction of the lag and snaps to
sevenths on release.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `calm_mood/` folder (1 dart file(s), see `files`)
- **Import:** `import 'calm_mood/calm_mood.dart';` — one line
- **Or:** `dart tools/export.dart calm_mood` → zip + paste-ready block

## API

### `CalmMoodScreen`

| Param | Type | Default | Meaning |
|---|---|---|---|
| `onNext` | `VoidCallback?` | — | The glass chevron. |
| `onChanged` | `ValueChanged<double>?` | — | Snapped 0..1 value when a drag ends. |
| `initialValue` | `double` | `.5` | Starting position (0.5 = Neutral). |
| `title` | `String` | upstream copy | Heading. |
| `animate` | `bool` | `true` | False = settled still (slider still works). |

Also exported: `kCalmMoodStops`, `kCalmMoodLabels`, `calmMoodColorAt`,
`calmMoodBloomPath` — reuse the ramp/silhouette elsewhere.

## Caveats

- The bloom rebuilds its 144-point path each frame during the spring —
  cheap in practice, but it is the hottest part of the screen.
- Upstream's per-layer drop-shadows are approximated with the two blurred
  glow blobs; keyboard a11y of the web slider is not ported (mobile
  target).

## Changelog

- **1.0.0** (2026-08-22) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `CalmMoodScreen` vào project này.

**Context**
- Chức năng: check-in cảm xúc — bloom hình hoa morph theo slider spring, đổi palette cả màn.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `calm_mood/` (1 file), import duy nhất `calm_mood.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `calm_mood/` vào <thư mục widget của project đích>.
2. Import entry file, nối `onChanged` vào nơi lưu mood.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
