---
# --- IDENTITY ---
id: calm_climb
title: Calm Climb
kind: composite
tags: [screen, steps, progress, mountain, everest, parallax, route, snow, fog]

# --- TAXONOMY (§2) ---
paint_source: painter
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: calm_climb.dart
files:
  - calm_climb.dart: "entry, public API"
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

# Calm Climb

"This week you climbed Everest" step recap (port of FeralUI's ClimbScreen):
three parallax mountain layers rise in with drifting fog banks, the walked
route draws itself up the face (upstream path data), the road ahead dots
out, a pulsing "You're here" marker lands at `progress`, snow flurries
loop, and the step count rolls up. Mountains are procedural paintings
replacing the upstream webp photos.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `calm_climb/` folder (1 dart file(s), see `files`)
- **Import:** `import 'calm_climb/calm_climb.dart';` — one line
- **Or:** `dart tools/export.dart calm_climb` → zip + paste-ready block

## API

### `CalmClimbScreen`

| Param | Type | Default | Meaning |
|---|---|---|---|
| `onNext` | `VoidCallback?` | — | The skip chevron. |
| `progress` | `double` | `.5` | Marker position along the route, 0..1. |
| `steps` | `int` | `26500` | Count-up target. |
| `goalSteps` | `int` | `53000` | The "of N steps" figure. |
| `headline` | `String` | `'Halfway up Everest'` | Big line (pair with `progress`). |
| `caption` | `String` | upstream copy | Small line under the steps. |
| `animate` | `bool` | `true` | False = settled end state, no ticker. |

## Caveats

- The mountain layers are hand-drawn ridgelines, not the original photos —
  same composition (back/mid/front + fog + haze), different rock.
- The full reveal takes ~4 s (upstream timeline); `animate: false` skips
  to the end.

## Changelog

- **1.0.0** (2026-08-22) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `CalmClimbScreen` vào project này.

**Context**
- Chức năng: recap bước chân — route leo núi 3 lớp parallax, marker "You're here" tại `progress`, đếm bước.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `calm_climb/` (1 file), import duy nhất `calm_climb.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `calm_climb/` vào <thư mục widget của project đích>.
2. Import entry file, truyền `progress`/`steps`/`goalSteps` từ data thật.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
