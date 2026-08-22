---
# --- IDENTITY ---
id: calm_streak
title: Calm Streak
kind: composite
tags: [screen, streak, flame, confetti, celebration, week, counter]

# --- TAXONOMY (§2) ---
paint_source: painter
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: calm_streak.dart
files:
  - calm_streak.dart: "entry, public API"
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

# Calm Streak

Streak celebration (port of FeralUI's StreakScreen): the upstream layered
flame SVG — blurred core inside the shell, crisp outside, top light —
flickering and swaying on two loops, a deterministic confetti burst, the
day count thumping up, the week of check dots (today ringed + rippling),
stats and a warm CTA.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `calm_streak/` folder (1 dart file(s), see `files`)
- **Import:** `import 'calm_streak/calm_streak.dart';` — one line
- **Or:** `dart tools/export.dart calm_streak` → zip + paste-ready block

## API

### `CalmStreakScreen`

| Param | Type | Default | Meaning |
|---|---|---|---|
| `onNext` | `VoidCallback?` | — | "Keep it going". |
| `streakDays` | `int` | `7` | The big count (and the "n/7" stat). |
| `longestStreak` | `int` | `12` | The other stat. |
| `buttonLabel` | `String` | `'Keep it going'` | CTA text. |
| `animate` | `bool` | `true` | False = settled end state, no ticker (no confetti). |

## Caveats

- The week row always shows 7 checked days like the upstream demo —
  it is a celebration screen, not a general week widget.
- The upstream SVG mask/clip on the flame is redone with `Path.combine`;
  the CSS drop-shadows became one blurred glow underneath.

## Changelog

- **1.0.0** (2026-08-22) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `CalmStreakScreen` vào project này.

**Context**
- Chức năng: màn chúc mừng streak — lửa flicker, confetti, đếm ngày, tuần check, CTA.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `calm_streak/` (1 file), import duy nhất `calm_streak.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `calm_streak/` vào <thư mục widget của project đích>.
2. Import entry file, truyền `streakDays`/`longestStreak` từ data thật.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
