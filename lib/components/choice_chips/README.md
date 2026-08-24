---
# --- IDENTITY ---
id: choice_chips
title: Choice Chips
kind: effect
tags: [chips, filter, toggle, pop, spring, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: choice_chips.dart
files:
  - choice_chips.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Choice Chips' (Interaction & Input)"
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-24
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

# Choice Chips

Hàng filter chip multi-select: mỗi lần toggle chip pop scale 1.12 bằng spring
rồi settle, màu fill/viền/chữ crossfade 0.2s. Nhiều chip bật cùng lúc được.

## Port notes

- Source thật: card `.demo-chips`/`.demo-chip` trong `src/content/body.html`,
  mục `18. Choice chips` của effects-a.css, JS (`33. Choice chips` main.js):
  toggle `.on`, add `.pop` 300ms (remove + reflow để retrigger).
- Cơ chế gốc: **CSS transition + bezier giả spring**. Flutter:
  `AnimatedScale` 1↔1.12 0.3s `Cubic(0.34, 1.56, 0.64, 1)` giữ bằng
  `AnimationController` 300ms (không `Timer`); màu `AnimatedContainer` +
  `AnimatedDefaultTextStyle` 0.2s ease.
- Public class là **`PopChips`** (không phải `ChoiceChips`) để khỏi nhầm với
  `ChoiceChip` của Material; id giữ tên effect gốc.
- Số liệu giữ nguyên: padding 15×7, font 13/500, gap 8, radius pill, palette
  line/bone-dim/amber/graphite.
- Pop là transient nội bộ của từng chip (kích theo tap); trạng thái on/off
  controlled ở parent.
- Hover đổi viền đã bỏ; click → tap.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `choice_chips/` folder (1 dart file(s), see `files`)
- **Import:** `import 'choice_chips/choice_chips.dart';` — one line
- **Or:** `dart tools/export.dart choice_chips` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `options` | `List<String>` | `['Spring','Glide','Bounce','Decay']` | Nhãn chips |
| `selected` | `Set<String>` | `{}` | Các chip đang bật (controlled) |
| `onChanged` | `ValueChanged<Set<String>>?` | required | Nhận set MỚI đã toggle; null = disabled |
| `spacing` | `double` | `8` | Khoảng cách chips (cả hàng lẫn dòng) |
| `borderColor` / `labelColor` | `Color` | `#2A2A2E / #A8A6A0` | Chip off |
| `selectedColor` / `selectedLabelColor` | `Color` | `#FF8A00 / #0E0E10` | Chip on |
| `animate` | `bool` | `true` | False = không pop, đổi màu tức thì |

## Caveats

- Pop scale 1.12 vẽ tràn ra ngoài bounds chip một chút — tránh bọc từng chip
  trong widget clip sát.
- `options` trùng chuỗi sẽ toggle cùng nhau (set theo String) — dùng nhãn
  duy nhất.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `PopChips` như filter multi-select controlled. Parent giữ
`Set<String> selected`, thay bằng set mới trong `onChanged`; map options theo
domain thật, đổi màu qua constructor; giữ nguyên pop 1.12 + spring curve.
