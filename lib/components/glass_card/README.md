---
# --- IDENTITY ---
id: glass_card
title: Glass Card
kind: carrier
tags: [glass, blur, card, frosted]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: glass_card.dart
files:
  - glass_card.dart: "entry, public API"
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

# Glass Card

Frosted-glass card: blurs the content behind it, adds a translucent tint and a
hairline border. A carrier — put any child inside, place it over any busy
background. Over a flat color it reads as a plain rounded rectangle.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `glass_card/` folder (1 dart file, see `files`)
- **Import:** `import 'glass_card/glass_card.dart';` — one line
- **Or:** `dart tools/export.dart glass_card` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `child` | `Widget` | required | Content inside the card |
| `borderRadius` | `double` | `20` | Corner radius |
| `blurSigma` | `double` | `18` | Backdrop blur strength |
| `tint` | `Color?` | `null` (white) | Frost color; pass a themed color to match the host app |
| `tintOpacity` | `double` | `0.14` | Strength of the tint gradient |
| `borderOpacity` | `double` | `0.35` | Hairline border visibility |
| `padding` | `EdgeInsetsGeometry` | `EdgeInsets.all(20)` | Inner padding |

## Caveats

- Perf: `BackdropFilter` forces a `saveLayer` every frame — expensive on
  mid-range Android GPUs. A few cards are fine; a scrolling list of them is not.
- Needs visual noise behind it (image, gradient, colored shapes) to look like
  glass.
- The blur samples what is *behind* the card in the same paint order — siblings
  painted after the card are not blurred.

## Changelog

- **1.0.0** (2026-08-18) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|
| 2026-08-18 | 3.44.5 | 3.12.2 | — | android | pass | initial: analyze + tests clean |

## AI Integration Prompt

Tích hợp component `GlassCard` vào project này.

**Context**
- Chức năng: card kính mờ — blur backdrop + tint mờ + viền mảnh; nhận `child` bất kỳ.
- Public API: xem bảng API trong README (`child`, `borderRadius`, `blurSigma`, `tint`, `tintOpacity`, `borderOpacity`, `padding`).
- Portability: single_file — copy cả folder `glass_card/` (1 file), import duy nhất `glass_card.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `glass_card/` vào thư mục widget của project đích.
2. Import entry file, đặt `GlassCard` lên trên một background có chi tiết (ảnh/gradient).

**Việc cần adapt theo project đích**
- `tint`: đổi sang màu theme của project nếu nền sáng.
- Không đặt nhiều GlassCard cùng lúc trong list scroll (chi phí saveLayer).

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
