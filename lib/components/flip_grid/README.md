---
# --- IDENTITY ---
id: flip_grid
title: Flip Grid
kind: composite
tags: [grid, flip, reorder, shuffle, filter, layout, transition, stagger, interactive, gsap]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: flip_grid.dart
files:
  - flip_grid.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/greensock/GSAP/blob/master/src/Flip.js
author: "Khang"
license: "GSAP Standard License (kỹ thuật FLIP dựng lại, không copy code)"

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-27
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

# Flip Grid

Lưới thẻ áp kỹ thuật FLIP (First–Last–Invert–Play) của GSAP Flip: đổi filter,
xáo bài, hay tap đưa một thẻ lên đầu — thẻ LƯỚT từ ô cũ sang ô mới thay vì
nhảy layout. Thẻ bị lọc mất fade-thu tại chỗ (onLeave), thẻ mới nở ra ở đích
(onEnter), delay lan từ nơi hành động ra xa (stagger `from: center`), xáo có
thể kèm một vòng xoay 360° (`spin`). Vị trí ô tính analytic nên capture/diff
chính xác không cần đo layout. Idle tự chạy kịch bản lọc/xáo cho gallery.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `flip_grid/` folder (1 dart file(s), see `files`)
- **Import:** `import 'flip_grid/flip_grid.dart';` — one line
- **Or:** `dart tools/export.dart flip_grid` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `itemCount` | `int` | `12` | Số thẻ; category của thẻ i là `i % 3` |
| `palette` | `List<Color>` | 6 màu | Màu thẻ (lặp vòng) |
| `moveDuration` | `double` | `0.55` | Giây một thẻ lướt sang ô mới |
| `staggerAmount` | `double` | `0.22` | Tổng delay rải theo khoảng cách từ nơi hành động |
| `spinOnShuffle` | `bool` | `true` | Xáo bài kèm xoay 360° |
| `autoDemo` | `bool` | `true` | Kịch bản lọc/xáo tự chạy tới khi user chạm |
| `seed` | `int` | `99` | Seed hoán vị xáo bài (deterministic) |
| `onItemTap` | `ValueChanged<int>?` | `null` | Tap thẻ (thẻ được đưa lên đầu) |
| `animate` | `bool` | `true` | Cho ticker chạy |
| `frozenAt` | `double?` | `null` | Render lưới tĩnh ban đầu, không ticker |

## Caveats

- Component tương tác rời rạc: `frozenAt` cho frame lưới nghỉ ban đầu (đủ
  cho thumbnail/state board), không replay kịch bản như comp thời-gian-liên-tục.
- Ô tính analytic theo bề rộng (cột `max(3, w/104)`) — items nhiều hơn chỗ
  chứa sẽ bị clip dưới đáy stage thay vì scroll (chủ đích giữ FLIP đơn giản).
- Mid-transition mà đổi filter tiếp thì capture lấy đúng vị trí đang bay —
  chuyển tiếp liên tục, không giật (hành vi Flip.killFlipsOf tương đương).

## Changelog

- **1.0.0** (2026-08-27) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `FlipGrid` vào project này.

**Context**
- Chức năng: lưới filter/shuffle/promote với FLIP transition — thẻ lướt giữa
  hai layout, vào/ra có onEnter/onLeave, stagger từ tâm hành động.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `flip_grid/` (1 file), import duy nhất `flip_grid.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `flip_grid/` vào <thư mục widget của project đích>.
2. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
