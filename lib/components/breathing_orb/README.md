---
# --- IDENTITY ---
id: breathing_orb
title: Breathing Orb
kind: effect
tags: [orb, breathe, glow, pulse, radial-gradient, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: breathing_orb.dart
files:
  - breathing_orb.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Breathing Orb' (Surface & Motion)"
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

# Breathing Orb

Quả cầu radial-gradient amber phồng và thả lỏng chậm, đồng thời quầng sáng
mở rộng theo nhịp. Nội dung giữa orb nhận qua `child` và có default giống demo.

## Port notes

- Effect gốc: "Breathing Orb", section **Surface & Motion**, kinetics. Đã
  đối chiếu `.demo-breathe` trong body, mục 25 của `effects-c.css`, và xác
  nhận không có hành vi JS.
- Cơ chế gốc: **CSS keyframes** 5s `ease-in-out` lặp vô hạn. Mốc 0/100%:
  scale 0.9, glow blur 20/spread 0/alpha 0.35; mốc 50%: scale 1.08, glow
  blur 48/spread 8/alpha 0.55.
- Giữ size 96 và radial gradient tâm 50%/45%, `#FF8A00 → #B36200`.
  Flutter radius được tính tới góc xa nhất để tương ứng CSS mặc định.
- `frozenAt` render sample tất định mà không tạo ticker; `animate` và
  `MediaQuery.disableAnimations` dừng loop từ ngoài.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `breathing_orb/` folder (1 dart file(s), see `files`)
- **Import:** `import 'breathing_orb/breathing_orb.dart';` — one line
- **Or:** `dart tools/export.dart breathing_orb` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `size` | `double` | `96` | Đường kính orb trước transform |
| `color` / `deepColor` | `Color` | `#FF8A00 / #B36200` | Hai đầu radial gradient |
| `glowColor` | `Color` | `#FF8A00` | Màu quầng sáng |
| `minScale` / `maxScale` | `double` | `0.9 / 1.08` | Biên độ thở |
| `minGlowBlur` / `maxGlowBlur` | `double` | `20 / 48` | Blur quầng ở hai mốc |
| `minGlowSpread` / `maxGlowSpread` | `double` | `0 / 8` | Spread quầng ở hai mốc |
| `minGlowOpacity` / `maxGlowOpacity` | `double` | `0.35 / 0.55` | Opacity quầng ở hai mốc |
| `period` | `double` | `5` | Giây mỗi nhịp đầy đủ |
| `animate` | `bool` | `true` | Cho phép ticker chạy |
| `frozenAt` | `double?` | null | Render frame tại t giây, không ticker |
| `child` | `Widget?` | label `breathe` | Nội dung giữa orb |

## Caveats

- Glow và scale vẽ ngoài box 96px; ancestor clip chặt có thể cắt quầng.
- Thông số `BoxShadow.blurRadius` của Flutter không trùng kernel CSS ở mức
  pixel, nhưng các giá trị và chuỗi trạng thái được giữ nguyên.
- Nhiều orb cùng lúc tạo nhiều blur layer; tắt animation cho item khuất.

## Changelog

- **1.0.0** (2026-08-26) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `BreathingOrb` làm trạng thái ambient/loading nhẹ. Chừa không gian
cho glow, truyền `child` nếu cần nội dung riêng, dùng `frozenAt` cho thumbnail
và tắt `animate` khi widget khuất.
