---
# --- IDENTITY ---
id: line_drawing
title: Line Drawing
kind: effect
tags: [lines, circles, stroke, drawing, ambient, animated, animejs]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: line_drawing.dart
files:
  - line_drawing.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/juliangarnier/anime (examples/svg-line-drawing)
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

# Line Drawing

Bộ vòng tròn đồng tâm (hoặc rèm kẻ dọc) với nét stroke "tự vẽ": mỗi đường
mang một đoạn màu lớn dần, trườn dọc path rồi tan, mỗi đường một vòng lặp
10s lệch pha 0–8s, màu chuyển xanh nõn → đỏ theo tiến trình (vòng lặp khép
tại đoạn zero-length nên cú snap màu vô hình). Port ví dụ `svg-line-drawing`
của anime.js v4, vẽ giải tích bằng drawArc/drawLine — không PathMetrics.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `line_drawing/` folder (1 dart file(s), see `files`)
- **Import:** `import 'line_drawing/line_drawing.dart';` — one line
- **Or:** `dart tools/export.dart line_drawing` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `variant` | `LineDrawingVariant` | `circles` | `circles` đồng tâm / `lines` kẻ dọc |
| `count` | `int?` | `null` | Số đường; null = 28 tròn / 44 dọc |
| `colorFrom` | `Color` | `0xFFA4FF4F` | Màu đầu vòng lặp |
| `colorTo` | `Color` | `0xFFFF4B4B` | Màu cuối vòng lặp |
| `backgroundColor` | `Color` | `0xFF161514` | Nền; `transparent` để overlay |
| `strokeWidth` | `double?` | `null` | Bề dày nét; null = 0.9% cạnh ngắn |
| `seed` | `int` | `9` | Seed các keyframe ngẫu nhiên |
| `animate` | `bool` | `true` | `false` dừng ticker |
| `frozenAt` | `double?` | `null` | Render đúng 1 frame tại t giây, không ticker |

## Caveats

- Mỗi frame ≤ `count` draw call — rất nhẹ.
- Có pre-roll 9s sẵn nên mở màn đã thấy nét đang chạy (không chờ stagger).

## Changelog

- **1.0.0** (2026-08-23) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `LineDrawing` vào project này.

**Context**
- Chức năng: nền ambient nét tự vẽ (vòng đồng tâm / rèm kẻ); đặt fullscreen hoặc sau hero text.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `line_drawing/` (1 file), import duy nhất `line_drawing.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `line_drawing/` vào <thư mục widget của project đích>.
2. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
