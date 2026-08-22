---
# --- IDENTITY ---
id: calm_sleep
title: Calm Sleep
kind: composite
tags: [screen, sleep, night, moon, phase, stars, shooting-star, chart, constellation]

# --- TAXONOMY (§2) ---
paint_source: painter
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: calm_sleep.dart
files:
  - calm_sleep.dart: "entry, public API"
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

# Calm Sleep

"Last night" sleep summary (port of FeralUI's SleepScreen): a starfield
with one shooting star, the minutes counting up while the moon lights up
exactly as far as the goal was met (upstream phase-mask math verbatim),
then a frosted card draws the night as a constellation over night hills.
Moon face and hills are procedural, replacing the upstream webp photos.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `calm_sleep/` folder (1 dart file(s), see `files`)
- **Import:** `import 'calm_sleep/calm_sleep.dart';` — one line
- **Or:** `dart tools/export.dart calm_sleep` → zip + paste-ready block

## API

### `CalmSleepScreen`

| Param | Type | Default | Meaning |
|---|---|---|---|
| `onNext` | `VoidCallback?` | — | The skip chevron. |
| `sleptMinutes` | `int` | `384` | Drives the count-up, the % line and the moon phase. |
| `goalMinutes` | `int` | `480` | The goal (8 h). |
| `headline` | `String` | `'Nearly a full moon'` | Big line (pair it with the phase). |
| `bedtime` / `wakeTime` | `String` | `'11:12 pm'` / `'6:38 am'` | The card footer. |
| `animate` | `bool` | `true` | False = settled end state, no ticker. |

## Caveats

- The long staggered reveal (~4 s) is by design — it is the upstream
  timeline. `animate: false` skips straight to the end.
- Moon craters/hills are hand-placed procedural stand-ins, not the photos.
- The constellation chart is a fixed demo night (same as upstream).

## Changelog

- **1.0.0** (2026-08-22) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `CalmSleepScreen` vào project này.

**Context**
- Chức năng: tổng kết giấc ngủ — trăng sáng theo % goal, đếm phút, chart "chòm sao" của đêm.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `calm_sleep/` (1 file), import duy nhất `calm_sleep.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `calm_sleep/` vào <thư mục widget của project đích>.
2. Import entry file, truyền `sleptMinutes`/`goalMinutes` từ data thật.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
