---
# --- IDENTITY ---
id: calm_breath
title: Calm Breath
kind: composite
tags: [screen, breathing, meditation, timer, waves, water, orb, mint, ocean]

# --- TAXONOMY (§2) ---
paint_source: painter
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: calm_breath.dart
files:
  - calm_breath.dart: "entry, public API"
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

# Calm Breath

Guided wind-down (port of FeralUI's BreathScreen): a pearl orb leads
"Breathe in / Hold / Breathe out" (4-2-5 s) with a ripple each cycle, while
the session's water — two drifting sine shorelines over a deep body —
drains down the screen as the countdown runs out. Pause/resume, skip, a
mint/ocean droplet toggle, and an auto `onNext` shortly after "Well done".

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `calm_breath/` folder (1 dart file(s), see `files`)
- **Import:** `import 'calm_breath/calm_breath.dart';` — one line
- **Or:** `dart tools/export.dart calm_breath` → zip + paste-ready block

## API

### `CalmBreathScreen`

| Param | Type | Default | Meaning |
|---|---|---|---|
| `onNext` | `VoidCallback?` | — | Skip; also fired ~1.6 s after the countdown completes. |
| `totalSeconds` | `int` | `60` | Session length. |
| `startWithOcean` | `bool` | `false` | Start on the ocean theme instead of mint. |
| `title` | `String` | `'Wind down'` | Header caption. |
| `animate` | `bool` | `true` | False = a readable mid-session still, no ticker. |

`CalmBreathTheme.mint` / `.ocean` are public if you want the colors.

## Caveats

- The whole timing machine (phases, countdown, ripple, auto-advance) runs
  on one Ticker clock — pausing the viewer's TickerMode pauses everything,
  including the countdown.
- The droplet button always toggles between the two built-in themes.

## Changelog

- **1.0.0** (2026-08-22) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `CalmBreathScreen` vào project này.

**Context**
- Chức năng: bài thở 4-2-5 với orb dẫn nhịp + mực nước hạ theo countdown; pause/skip/toggle theme.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `calm_breath/` (1 file), import duy nhất `calm_breath.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `calm_breath/` vào <thư mục widget của project đích>.
2. Import entry file, nối `onNext` vào navigation sau bài thở.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
