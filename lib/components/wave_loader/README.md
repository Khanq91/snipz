---
# --- IDENTITY ---
id: wave_loader
title: Wave Loader
kind: effect
tags: [loader, dots, wave, bounce, stagger, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: wave_loader.dart
files:
  - wave_loader.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Wave Loader' (Surface & Motion)"
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

# Wave Loader

Bốn chấm tròn amber nảy thành một làn sóng lệch pha. Component nhỏ, tự đủ,
phù hợp cho trạng thái chờ ngắn và có thể đóng băng chính xác theo thời gian.

## Port notes

- Effect gốc: "Wave Loader", section **Surface & Motion**, kinetics. Đã đối
  chiếu card `.demo-dots` trong `src/content/body.html`, mục 20 của
  `public/css/effects-c.css`, và `public/js/main.js` (không có hành vi JS).
- Cơ chế gốc: **CSS keyframes** lặp 1.1s `ease-in-out`; mỗi chấm trễ thêm
  0.12s. Các mốc thật: 0/60/100% ở `translateY(0)`, opacity 0.4; 30% ở
  `translateY(-12px)`, opacity 1.
- Demo sống có **4 chấm**, dù dòng mô tả card ghi “Three dots”; port bám DOM
  và CSS thật. Size 11, gap 7 và màu `#FF8A00` cũng được giữ nguyên.
- Flutter sample frame như hàm thuần của `t`; `frozenAt` không tạo ticker,
  `animate` và `MediaQuery.disableAnimations` có thể tắt chuyển động.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `wave_loader/` folder (1 dart file(s), see `files`)
- **Import:** `import 'wave_loader/wave_loader.dart';` — one line
- **Or:** `dart tools/export.dart wave_loader` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `dotCount` | `int` | `4` | Số chấm |
| `dotSize` | `double` | `11` | Đường kính chấm |
| `gap` | `double` | `7` | Khoảng cách ngang |
| `bounceHeight` | `double` | `12` | Độ cao nảy |
| `color` | `Color` | `#FF8A00` | Màu chấm |
| `restOpacity` | `double` | `0.4` | Opacity ở đáy |
| `period` | `double` | `1.1` | Giây mỗi chu kỳ |
| `stagger` | `double` | `0.12` | Delay giữa hai chấm, tính bằng giây |
| `animate` | `bool` | `true` | Cho phép ticker chạy |
| `frozenAt` | `double?` | null | Render frame tại t giây, không ticker |

## Caveats

- Chấm dịch lên ngoài chiều cao layout 11px giống CSS `transform`; ancestor
  có clipping sát widget có thể cắt phần đỉnh của cú nảy.
- Đây là loader trang trí, không tự cung cấp semantics về tiến độ. Đặt label
  loading ở vùng cha nếu luồng cần accessibility.
- Với danh sách dài, dùng `frozenAt`, `animate: false`, hoặc `TickerMode` cho
  item ngoài viewport.

## Changelog

- **1.0.0** (2026-08-26) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `WaveLoader` vào trạng thái chờ ngắn. Giữ vùng cha đủ cao để không
clip biên độ 12px; dùng `frozenAt` cho thumbnail/golden và tắt `animate` khi
widget khuất.
