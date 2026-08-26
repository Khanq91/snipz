---
# --- IDENTITY ---
id: float_bob
title: Float Bob
kind: effect
tags: [card, float, bob, hover, shadow, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: float_bob.dart
files:
  - float_bob.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Float Bob' (Surface & Motion)"
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

# Float Bob

Card nhỏ trôi lên 12px rồi hạ xuống trong bốn giây. Drop shadow đổi offset,
blur và opacity đồng bộ để card có cảm giác nổi trên một mặt phẳng cố định.

## Port notes

- Effect gốc: "Float Bob", section **Surface & Motion**, kinetics. Đã đọc
  `.demo-float-zone`/`.demo-float-card`, mục 26 trong `effects-c.css`, và xác
  nhận không có logic tương ứng trong `main.js`.
- Cơ chế gốc: **CSS keyframes** 4s `ease-in-out` lặp vô hạn. Card đi từ
  `translateY(0)` đến `-12px` rồi về 0.
- Shadow mốc nghỉ giữ `offsetY 10 / blur 20 / spread -8 / alpha 0.55`; mốc
  cao nhất giữ `offsetY 26 / blur 30 / spread -10 / alpha 0.45`.
- Kích thước/style demo giữ nguyên: 150×84, nền `#232326`, viền `#2A2A2E`,
  radius 14. Nội dung được mở qua `child` thay vì hardcode.
- Sample là hàm thuần của thời gian; `frozenAt` không tạo ticker và `animate`
  tắt chuyển động từ ngoài.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `float_bob/` folder (1 dart file(s), see `files`)
- **Import:** `import 'float_bob/float_bob.dart';` — one line
- **Or:** `dart tools/export.dart float_bob` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `width` / `height` | `double` | `150 / 84` | Kích thước card |
| `backgroundColor` / `borderColor` | `Color` | `#232326 / #2A2A2E` | Surface và viền |
| `borderRadius` | `double` | `14` | Bo góc card |
| `shadowColor` | `Color` | black | Màu gốc của shadow |
| `lift` | `double` | `12` | Độ cao bob tối đa |
| `restShadowOffset` / `peakShadowOffset` | `double` | `10 / 26` | Offset Y shadow |
| `restShadowBlur` / `peakShadowBlur` | `double` | `20 / 30` | Blur shadow |
| `restShadowSpread` / `peakShadowSpread` | `double` | `-8 / -10` | Spread shadow |
| `restShadowOpacity` / `peakShadowOpacity` | `double` | `0.55 / 0.45` | Opacity shadow |
| `period` | `double` | `4` | Giây mỗi chu kỳ |
| `animate` | `bool` | `true` | Cho phép ticker chạy |
| `frozenAt` | `double?` | null | Render frame tại t giây, không ticker |
| `child` | `Widget?` | label `float(4s)` | Nội dung giữa card |

## Caveats

- Translate và shadow vẽ ngoài layout box; dành đủ khoảng trống và tránh
  ancestor clip nếu muốn thấy toàn bộ chuyển động.
- Đây là surface có kích thước cố định theo source; truyền `width`/`height`
  khi nội dung thật cần nhiều chỗ hơn.
- Nhiều shadow động có chi phí GPU; tắt animation ở item ngoài viewport.

## Changelog

- **1.0.0** (2026-08-26) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `FloatBob` cho một card hoặc badge ambient. Truyền nội dung qua
`child`, chừa khoảng trống cho lift/shadow, dùng `frozenAt` cho thumbnail và
tắt `animate` khi widget khuất.
