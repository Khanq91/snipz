---
# --- IDENTITY ---
id: aurora_stack
title: Aurora Stack
kind: paint
tags: [aurora, animated, blobs, background, grain]

# --- TAXONOMY (§2) ---
paint_source: widget
carriers_verified: []
carriers_failed: []
scale_aware: true

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: folder
entry: aurora_stack.dart
files:
  - aurora_stack.dart: "entry, public API"
  - _blob_painter.dart: "required by aurora_stack.dart"
  - _noise_layer.dart: "required by aurora_stack.dart"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: original
source: null
author: "Khang"
license: null

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-18
created_flutter: 3.44.5
created_dart: 3.12.2
created_deps: []
platforms_initial: [android]

# --- COMPONENT VERSION ---
version: 1.0.0

# --- DERIVED (computed from Test History by verify.dart, do not hand-edit) ---
latest_known_good: 3.44.5
last_verified: 2026-08-18
status: verified

preview: null
---

# Aurora Stack

Animated aurora background: soft radial blobs drifting over a near-black
field, additively blended. The entry also exports `AuroraNoiseOverlay`, a
static grain layer that hides gradient banding — stack it on top.

`paint_source: widget` — this paint is a widget tree, not a Shader, so text
carriers are expensive (§2.2). Reaches shape carriers via clipping.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `aurora_stack/` folder (3 dart files, see `files`)
- **Import:** `import 'aurora_stack/aurora_stack.dart';` — one line
- **Or:** `dart tools/export.dart aurora_stack` → zip + paste-ready block

## API

`AuroraStack`

| Param | Type | Default | Meaning |
|---|---|---|---|
| `scale` | `double` | `1.0` | Detail density (§9.1). Drop to ~`0.3` on small carriers |
| `animate` | `bool` | `true` | `false` freezes the drift and stops the internal ticker |
| `colors` | `List<Color>?` | aurora palette | Blob colors |
| `background` | `Color?` | `0xFF07080F` | Field behind the blobs |

`AuroraNoiseOverlay` (exported from the entry)

| Param | Type | Default | Meaning |
|---|---|---|---|
| `opacity` | `double` | `0.05` | Grain visibility, keep 0.03–0.08 |
| `density` | `double` | `1.0` | Dots per area |
| `seed` | `int` | `7` | Fixed seed — stable pattern, no shimmer |

## Caveats

- Animated: one `AnimationController` per instance. `animate: false` stops the
  ticker — the app's viewport-pause (§9.2) relies on it.
- `BlendMode.plus` can clip to white when custom colors are too bright.
- Masking this onto text means saveLayer per frame — avoid on mobile (§9.2).

## Changelog

- **1.0.0** (2026-08-18) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|
| 2026-08-18 | 3.44.5 | 3.12.2 | — | android | pass | initial: analyze + tests clean |

## AI Integration Prompt

Tích hợp component `AuroraStack` vào project này.

**Context**
- Chức năng: background aurora động (blobs trôi + additive blend) kèm
  `AuroraNoiseOverlay` grain tĩnh, export cùng entry.
- Public API: xem 2 bảng API trong README.
- Portability: folder — copy cả `aurora_stack/` (3 file), import duy nhất
  `aurora_stack.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy cả folder `aurora_stack/` vào thư mục widget của project đích.
2. Import entry file, đặt `AuroraStack` làm lớp dưới cùng của Stack; thêm
   `AuroraNoiseOverlay` lên trên nếu thấy banding.

**Việc cần adapt theo project đích**
- `colors`/`background`: đổi sang token màu của project.
- `scale`: dùng ở vùng nhỏ (card/button) → giảm còn ~0.3.
- Màn hình có aurora ngoài viewport → set `animate: false` để tiết kiệm frame.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG gộp các file `_*.dart` lại, KHÔNG bỏ bớt file — cả 3 đều required.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
