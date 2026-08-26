---
# --- IDENTITY ---
id: skeleton_sweep
title: Skeleton Sweep
kind: effect
tags: [skeleton, shimmer, loading, placeholder, sweep, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: skeleton_sweep.dart
files:
  - skeleton_sweep.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Skeleton Sweep' (Surface & Motion)"
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

# Skeleton Sweep

Ba thanh skeleton bo tròn với gradient highlight quét ngang trong 1.4 giây.
Bề rộng theo parent và thanh cuối ngắn 60% để gợi hình một đoạn văn.

## Port notes

- Effect gốc: "Skeleton Sweep", section **Surface & Motion**, kinetics. Đã
  đọc card `.demo-skeleton-zone`, mục 21 trong `effects-c.css`, và xác nhận
  không có logic tương ứng trong `main.js`.
- Cơ chế gốc: **CSS keyframes** lặp vô hạn. Gradient ba stop
  `#232326 25% → #34343A 50% → #232326 75%`, rộng 200%, dịch
  `background-position` từ 200% đến -200% trong 1.4s `ease-in-out`.
- Kích thước giữ nguyên: line height 12, radius 6, gap 11, ba dòng và dòng
  cuối rộng 60%. Demo gốc rộng 220; component theo constraint của parent.
- Flutter dựng lại bằng một `CustomPainter`; phép căn background-position là
  `(containerWidth - gradientWidth) × position / 100`. `frozenAt` render
  frame tất định và không chạy ticker.
- Component này khác `shimmer_skeleton`: effect kia thuộc Feedback & State,
  dùng gradient/timing 1.5s linear khác nguồn.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `skeleton_sweep/` folder (1 dart file(s), see `files`)
- **Import:** `import 'skeleton_sweep/skeleton_sweep.dart';` — one line
- **Or:** `dart tools/export.dart skeleton_sweep` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `lineCount` | `int` | `3` | Số thanh |
| `lineHeight` | `double` | `12` | Chiều cao thanh; radius bằng một nửa |
| `gap` | `double` | `11` | Khoảng cách dọc |
| `lastLineFactor` | `double` | `0.6` | Tỷ lệ rộng của thanh cuối |
| `baseColor` | `Color` | `#232326` | Màu nền hai đầu gradient |
| `highlightColor` | `Color` | `#34343A` | Màu highlight giữa gradient |
| `period` | `double` | `1.4` | Giây mỗi lượt quét |
| `animate` | `bool` | `true` | Cho phép ticker chạy |
| `frozenAt` | `double?` | null | Render frame tại t giây, không ticker |

## Caveats

- Widget cần constraint chiều rộng hữu hạn; bọc `SizedBox(width: ...)` khi
  đặt trong parent không giới hạn theo trục ngang.
- Painter tạo gradient cho từng line mỗi frame. Với nhiều skeleton trong
  list, tắt animation ở item khuất hoặc dùng một instance lớn.
- Màu mặc định dành cho nền tối; truyền hai màu sáng hơn trên light theme.

## Changelog

- **1.0.0** (2026-08-26) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `SkeletonSweep` tại khối nội dung đang tải, bọc bằng chiều rộng khớp
layout thật. Đổi `baseColor`/`highlightColor` theo theme; dùng `frozenAt` cho
thumbnail/golden và `animate: false` khi item khuất.
