---
# --- IDENTITY ---
id: tab_pill_glide
title: Tab Pill Glide
kind: effect
tags: [tabs, segmented, pill, glide, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: tab_pill_glide.dart
files:
  - tab_pill_glide.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Tab Pill Glide' (Interaction & Input)"
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

# Tab Pill Glide

Segmented tabs với pill màu accent glide theo cả `left` lẫn `width` sang tab
được chọn (mỗi tab một bề rộng riêng), label crossfade màu khi pill đến nơi.

## Port notes

- Source thật: card `.demo-tabs`/`.demo-tab-pill`/`.demo-tab-btn` trong
  `src/content/body.html`, mục `5. Tab pill glide` của
  `public/css/effects-a.css`; JS đo `offsetLeft`/`offsetWidth` của button
  active rồi set style cho pill.
- Cơ chế gốc: **CSS transition + JS đo layout**. Flutter thay phép đo DOM
  bằng `TextPainter` (cùng style + textScaler với label nên luôn khớp), pill
  là `AnimatedPositioned` left+width 0.4s `Cubic(0.65, 0, 0.35, 1)`; màu
  label `AnimatedDefaultTextStyle` 0.3s ease.
- Số liệu giữ nguyên: container padding 5, gap 4, button padding 16×7, font
  13/500, radius pill, palette card-2/line/amber/bone-dim/graphite.
- Readout `glide(0.4s, custom)` khớp đúng transition thật.
- Hover không thuộc lõi effect; click → tap.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `tab_pill_glide/` folder (1 dart file(s), see `files`)
- **Import:** `import 'tab_pill_glide/tab_pill_glide.dart';` — one line
- **Or:** `dart tools/export.dart tab_pill_glide` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `tabs` | `List<String>` | `['Plan','Build','Ship']` | Nhãn các tab |
| `index` | `int` | required | Tab đang chọn (controlled) |
| `onChanged` | `ValueChanged<int>?` | required | null = disabled |
| `backgroundColor` / `borderColor` | `Color` | `#232326 / #2A2A2E` | Khung |
| `pillColor` | `Color` | `#FF8A00` | Pill accent |
| `labelColor` / `activeLabelColor` | `Color` | `#A8A6A0 / #0E0E10` | Màu chữ |
| `animate` | `bool` | `true` | False = pill nhảy tức thì |

## Caveats

- Layout LTR (pill định vị bằng `left` như bản gốc); RTL cần đảo thứ tự tabs.
- Bề rộng đo bằng `TextPainter` với font mặc định hệ thống — nếu override
  fontFamily qua theme thì label và pill vẫn khớp nhau (đo cùng style).
- Tôn trọng `MediaQuery.disableAnimations`.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `TabPillGlide` như segmented control controlled. Parent sở hữu
`index`, cập nhật trong `onChanged`, đổi màu qua constructor; giữ nguyên
curve `Cubic(0.65, 0, 0.35, 1)` và timing 0.4s.
