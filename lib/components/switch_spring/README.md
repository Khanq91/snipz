---
# --- IDENTITY ---
id: switch_spring
title: Switch Spring
kind: effect
tags: [switch, toggle, spring, control, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: switch_spring.dart
files:
  - switch_spring.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Switch Spring' (Feedback & State)"
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-24
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

preview: null
---

# Switch Spring

Toggle controlled có knob trượt ngang rồi overshoot nhẹ, dựng lại từ kinetics
"Switch Spring". Track và knob crossfade màu độc lập với chuyển động.

## Port notes

- Source thật: card `.demo-switch` trong `src/content/body.html`, mục
  `16. Switch spring` của `public/css/effects-b.css`, JS chỉ toggle `.on`.
- Cơ chế gốc: **CSS transition + bezier giả spring**. Flutter dùng implicit
  animation: knob 0.4s `Cubic(0.34, 1.56, 0.64, 1)`, màu/viền 0.3s ease.
- Số liệu giữ nguyên: track 54×30, padding 4, knob 22, travel mặc định 24px,
  radius pill, palette card-2/line/amber-deep/amber/graphite/bone-dim.
- Readout `spring(340, 22)` chỉ là tham chiếu; demo thật chạy bằng cubic nên
  port theo cubic. Click web map trực tiếp sang tap Android; không có hover lõi.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- Copy folder `switch_spring/`, import `switch_spring.dart`.
- Hoặc chạy `dart tools/export.dart switch_spring`.

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `value` | `bool` | required | Trạng thái controlled |
| `onChanged` | `ValueChanged<bool>?` | required | null = disabled |
| `width` / `height` | `double` | `54 / 30` | Kích thước track |
| `padding` / `knobSize` | `double` | `4 / 22` | Hình học knob |
| `offTrackColor` / `onTrackColor` | `Color` | `#232326 / #B36200` | Màu track |
| `borderColor` / `onBorderColor` | `Color` | `#2A2A2E / #FF8A00` | Màu viền |
| `offKnobColor` / `onKnobColor` | `Color` | `#A8A6A0 / #0E0E10` | Màu knob |
| `animate` | `bool` | `true` | false = đổi trạng thái tức thì |

## Caveats

- Parent phải giữ `value` và rebuild trong `onChanged`.
- Hit target mặc định 54×30; nơi cần accessibility 48px theo chiều cao nên bọc
  thêm padding ngoài.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `SwitchSpring` như controlled toggle. Parent sở hữu `value`, cập nhật
trong `onChanged`; chỉ đổi style qua constructor và giữ nguyên spring curve.
