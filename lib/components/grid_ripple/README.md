---
# --- IDENTITY ---
id: grid_ripple
title: Grid Ripple
kind: effect
tags: [grid, stagger, ripple, dots, ambient, animated, animejs]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: grid_ripple.dart
files:
  - grid_ripple.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/juliangarnier/anime (examples/advanced-grid-staggering)
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

# Grid Ripple

Lưới chấm với một ô vuông "con trỏ" tự nhảy giữa các ô ngẫu nhiên: mỗi cú
đáp bóp cả lưới về phía ô đó (200ms), bật ngược ra với chấm phóng to ×2
(500ms) rồi lắng xuống (600ms) — một gợn sóng lan từ điểm đáp, trong lúc con
trỏ đã lướt outCirc sang ô kế tiếp. Port ví dụ `advanced-grid-staggering`
của anime.js v4. Mọi frame là hàm đóng của t — không tích lũy trạng thái.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `grid_ripple/` folder (1 dart file(s), see `files`)
- **Import:** `import 'grid_ripple/grid_ripple.dart';` — one line
- **Or:** `dart tools/export.dart grid_ripple` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `rows` | `int` | `11` | Cạnh lưới (rows² chấm) |
| `dotColor` | `Color` | `0xFFEDEAE4` | Màu chấm |
| `cursorColor` | `Color` | `0xFFFF4B4B` | Màu viền ô con trỏ |
| `backgroundColor` | `Color` | `0xFF191817` | Nền; `transparent` để overlay |
| `seed` | `int` | `11` | Seed chuỗi ô nhảy — cùng seed cùng vũ đạo |
| `animate` | `bool` | `true` | `false` dừng ticker |
| `frozenAt` | `double?` | `null` | Render đúng 1 frame tại t giây, không ticker |

## Caveats

- rows² draw call mỗi frame — 11² mặc định rất nhẹ; 15+ vẫn ổn.
- Lưới luôn vuông, tự căn giữa và chiếm ~82% cạnh ngắn của box.

## Changelog

- **1.0.0** (2026-08-23) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `GridRipple` vào project này.

**Context**
- Chức năng: nền ambient lưới chấm gợn sóng tự chạy; đặt fullscreen, làm nền section hoặc màn chờ.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `grid_ripple/` (1 file), import duy nhất `grid_ripple.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `grid_ripple/` vào <thư mục widget của project đích>.
2. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
