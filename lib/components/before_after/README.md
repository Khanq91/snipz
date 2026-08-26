---
# --- IDENTITY ---
id: before_after
title: Before / After
kind: composite
tags: [compare, slider, wipe, drag, reveal]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: before_after.dart
files:
  - before_after.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Before / After' (Surface & Motion)"
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-26
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

# Before / After

Slider so sánh hai lớp chồng nhau: kéo handle ngang để wipe lớp AFTER hiện
ra bên trái vạch chia. Bám ngón tay 1:1, không easing — đúng cảm giác gốc.

## Port notes

- Effect gốc: "Before / After", section **Surface & Motion**, kinetics. Đã
  đọc `.demo-compare*` trong `effects-c.css` và handler mục 41 trong
  `main.js`.
- Cơ chế gốc: **JS pointer drag** — `pointerdown` bật cờ dragging (+
  `setPointerCapture`), `pointermove` set `clip-path: inset(0 (100-p)% 0 0)`
  trực tiếp, clamp 0–100, khởi tạo 50%. Không transition, không rAF.
- Flutter: `GestureDetector.onPanDown/onPanUpdate` — down nhảy tới vị trí
  chạm ngay (như gốc), drag tiếp tục ngoài box nhờ gesture arena giữ pan.
- Số giữ nguyên: box 232×122 radius 9 viền `#2A2A2E`; layer chữ w800 19px
  tracking 0.05em; BEFORE gradient 135° `#141417→#1A1A1D` chữ `#A8A6A0`;
  AFTER gradient amber→amber-deep chữ `#0E0E10`; divider 2px `#EDE9E0`;
  handle 34px tròn `#EDE9E0` shadow `0 2 8 -1 rgba(0,0,0,0.5)`, chevron SVG
  stroke 2.2 round vẽ lại bằng `CustomPainter` 18px.
- Font Archivo 800 của label thay bằng font mặc định w800 (zero asset);
  layer thật truyền qua `before`/`after`.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `before_after/` folder (1 dart file(s), see `files`)
- **Import:** `import 'before_after/before_after.dart';` — one line
- **Or:** `dart tools/export.dart before_after` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `before` / `after` | `Widget?` | placeholder gốc | Hai lớp so sánh |
| `width` / `height` | `double` | `232 / 122` | Kích thước box |
| `initialFraction` | `double` | `0.5` | Vị trí chia ban đầu 0–1 |
| `onChanged` | `ValueChanged<double>?` | null | Báo fraction mỗi lần kéo |
| `borderRadius` | `double` | `9` | Bo góc box |
| `borderColor` | `Color` | `#2A2A2E` | Viền box |
| `dividerColor` / `dividerWidth` | — | `#EDE9E0` / `2` | Vạch chia |
| `handleSize` / `handleColor` / `handleIconColor` | — | `34` / `#EDE9E0` / `#0E0E10` | Handle + chevron |
| `semanticsLabel` | `String` | `Compare` | Nhãn slider cho a11y |

## Caveats

- Component tự giữ state fraction (uncontrolled, như gốc); cần điều khiển
  ngoài thì bọc và đổi `key` khi muốn reset về `initialFraction`.
- Pan ngang nuốt gesture — đặt trong `PageView`/scroll ngang sẽ tranh nhau;
  cân nhắc bọc `RawGestureDetector` phía app nếu cần.
- Semantics tăng/giảm bước 10% cho TalkBack.

## Changelog

- **1.0.0** (2026-08-26) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `BeforeAfterSlider` để so sánh ảnh/theme/kết quả xử lý. Truyền hai
lớp thật qua `before`/`after` (Image, screenshot, widget bất kỳ), nghe
`onChanged` nếu cần đồng bộ UI khác.
