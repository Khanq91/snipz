---
# --- IDENTITY ---
id: additive_creature
title: Additive Creature
kind: effect
tags: [particles, follow, touch, glow, creature, animated, animejs]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: additive_creature.dart
files:
  - additive_creature.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/juliangarnier/anime (examples/additive-creature)
author: "Khang"
license: null

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-23
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

# Additive Creature

"Sinh vật" 13×13 chấm đỏ phát sáng chồng lên nhau thành một khối glow, bám
theo ngón tay như sao chổi (chấm sáng ở lõi đi trước, quầng tối theo sau),
tự bơi lượn khi bỏ tay ra ~1.5s và cứ mỗi 3s lại phát một sóng pulse lan từ
tâm. Port demo trứ danh `additive-creature` của anime.js v4; `composition:
'blend'` của bản gốc được thay bằng chuỗi hai bộ lọc mũ (cascaded exponential
pursuit) đuổi theo con trỏ trễ theo từng chấm — cùng một cảm giác chuyển động.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `additive_creature/` folder (1 dart file(s), see `files`)
- **Import:** `import 'additive_creature/additive_creature.dart';` — one line
- **Or:** `dart tools/export.dart additive_creature` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `rows` | `int` | `13` | Cạnh lưới stagger; sinh vật = rows² chấm |
| `color` | `Color` | `0xFFE8442E` | Tint — hue/sat của nó tạo ramp lõi sáng → quầng tối |
| `backgroundColor` | `Color` | `0xFF190D08` | Nền vẽ sau; `transparent` để overlay |
| `dotRadius` | `double` | `5.0` | Bán kính chấm scale-1 (chạy ×2 lõi → ×5 quầng) |
| `interactive` | `bool` | `true` | `false` bỏ qua touch, chỉ tự bơi |
| `animate` | `bool` | `true` | `false` dừng ticker |
| `frozenAt` | `double?` | `null` | Render đúng 1 frame tại t giây, không ticker |

## Caveats

- rows² × 2 draw call mỗi frame (quầng gradient + lõi). 13² = 338 draw —
  mượt trên máy tầm trung; máy rất yếu giảm `rows` xuống 9-11.
- Pulse chỉ phát khi đang auto-wander (đúng bản gốc — kéo tay thì creature
  tập trung đuổi, không pulse).
- Hành vi "blend" là mô phỏng lại bằng bộ lọc mũ, không phải sao chép từng
  keyframe của anime.js — quỹ đạo giống về chất chuyển động, không giống
  từng pixel.

## Changelog

- **1.0.0** (2026-08-23) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `AdditiveCreature` vào project này.

**Context**
- Chức năng: mascot/ambient effect — bầy chấm glow bám theo ngón tay như
  sao chổi, tự bơi khi thả; đặt fullscreen hoặc làm nền một section.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `additive_creature/` (1 file), import duy nhất `additive_creature.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `additive_creature/` vào <thư mục widget của project đích>.
2. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
