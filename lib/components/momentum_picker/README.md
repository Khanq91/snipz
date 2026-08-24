---
# --- IDENTITY ---
id: momentum_picker
title: Momentum Picker
kind: effect
tags: [picker, wheel, detent, momentum, spring, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: momentum_picker.dart
files:
  - momentum_picker.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Momentum Picker' (Interaction & Input)"
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

# Momentum Picker

Picker dọc "có trọng lượng": track lăn sau một highlight amber cố định, mỗi
lần đúng một detent với overshoot spring; hàng ngoài rìa mờ (0.28) và co
(0.88) gợi chiều sâu trụ tròn. Readout mono góc dưới phải.

## Port notes

- Source thật: card `.demo-momentum-picker` trong `src/content/body.html`,
  effects-a.css dòng 1841-1920, main.js "Momentum picker" (click + wheel
  lock 260ms + arrow keys, `--picker-i` translateY).
- Cơ chế gốc: **CSS transition + JS state**. Input map cho touch:
  **wheel → swipe dọc** (mỗi 38px kéo = một detent, tương đương wheel-lock
  "one detent at a time" của gốc), **click → tap hàng**; arrow keys bỏ
  (Android không bàn phím cứng làm driver chính).
- Số liệu giữ nguyên: khung 208×122 radius 18, hàng 38px, focus band top 37
  left/right 10 radius 11 (amber 8%/46%), track 0.58s
  `Cubic(0.34,1.56,0.64,1)`, inactive opacity 0.28 (0.35s ease) + scale
  0.88 (0.5s spring), label active amber 0.25s ease, fade 35px hai đầu,
  readout `LABEL · 0N` font 8 bone-faint.
- Controlled `index` (JS gốc tự giữ index — chuyển sang controlled theo
  chuẩn vault, hành vi không đổi).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `momentum_picker/` folder (1 dart file(s), see `files`)
- **Import:** `import 'momentum_picker/momentum_picker.dart';` — one line
- **Or:** `dart tools/export.dart momentum_picker` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `options` | `List<String>` | `['Airy','Balanced','Dense']` | Các hàng |
| `index` | `int` | required | Hàng đang chọn (controlled) |
| `onChanged` | `ValueChanged<int>?` | required | null = disabled |
| `width` / `height` | `double` | `208 / 122` | Khung |
| `backgroundColor` / `borderColor` | `Color` | `#232326 / #2A2A2E` | Khung |
| `textColor` | `Color` | `#EDE9E0` | Label thường |
| `accentColor` | `Color` | `#FF8A00` | Focus band + label active |
| `readoutColor` | `Color` | `#6E6C68` | Readout mono |
| `animate` | `bool` | `true` | False = nhảy detent tức thì |

## Caveats

- Nằm trong scrollable dọc sẽ tranh gesture với swipe — đặt ngoài vùng
  scroll hoặc chấp nhận ưu tiên gesture arena.
- Nhiều options hơn 3 vẫn chạy (track dài ra, fade che hai đầu) nhưng khung
  122px gốc chỉ hé lộ ±1 hàng quanh focus.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `MomentumPicker` cho lựa chọn 1-chiều ít mục (density, size…).
Parent giữ `index`, cập nhật trong `onChanged`; giữ nguyên detent 38px và
spring 0.58s.
