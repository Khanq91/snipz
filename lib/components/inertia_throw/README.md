---
# --- IDENTITY ---
id: inertia_throw
title: Inertia Throw
kind: effect
tags: [drag, throw, flick, momentum, inertia, snap, grid, physics, interactive, gsap]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: inertia_throw.dart
files:
  - inertia_throw.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/greensock/GSAP/blob/master/src/InertiaPlugin.js
author: "Khang"
license: "GSAP Standard License (mô hình momentum dựng lại, không copy code)"

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

# Inertia Throw

Bảng peg với các thẻ ném được: thả tay là thẻ bay tiếp theo đà, tự đáp vào
peg gần nhất **chỉ khi** điểm đáp tự nhiên nằm trong `snapRadius` (ném trượt
thì nằm ngoài lưới đúng nghĩa), chạm tường thì lún quá rồi nảy về mềm. Port
mô hình InertiaPlugin của GSAP: không có physics loop — mỗi cú ném giải
nghiệm đóng ngay lúc thả (`duration = |v|/resistance`, điểm đáp qua hằng số
power3 `0.18549`, soft-bounds = số hạng bậc hai), nên mọi frame scrub được.
Idle thì tự ném theo kịch bản deterministic (`autoDemo`) cho gallery sống.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `inertia_throw/` folder (1 dart file(s), see `files`)
- **Import:** `import 'inertia_throw/inertia_throw.dart';` — one line
- **Or:** `dart tools/export.dart inertia_throw` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `cardColors` | `List<Color>` | 3 màu | Mỗi màu một thẻ |
| `cardSize` | `double` | `64` | Cạnh thẻ |
| `cellExtent` | `double` | `88` | Bước lưới peg |
| `snapRadius` | `double` | `64` | Bán kính hít peg tính từ điểm đáp tự nhiên (0 = tắt snap, lớn = luôn snap) |
| `resistance` | `double` | `400` | px/s vận tốc tiêu mỗi giây bay (GSAP default web là 100; 400 hợp mobile) |
| `minDuration` / `maxDuration` | `double` | `0.3` / `2.5` | Kẹp thời gian bay |
| `showGrid` | `bool` | `true` | Vẽ chấm peg |
| `autoDemo` | `bool` | `true` | Tự ném theo kịch bản tới khi user chạm lần đầu |
| `onLanded` | `void Function(int card, int peg)?` | `null` | Thẻ đáp xong (`peg = -1` nếu ngoài lưới) |
| `animate` | `bool` | `true` | Cho ticker chạy |
| `frozenAt` | `double?` | `null` | Replay kịch bản autoDemo tới t giây, render một frame |

`InertiaFlight.solve(...)` / `InertiaAxis` export công khai — dùng lại cho
mọi gesture ném khác (flick-to-dismiss, throwable sheet...).

## Caveats

- Vận tốc lấy từ `DragEndDetails.velocity` (VelocityTracker chuẩn của
  Flutter — least-squares, tốt hơn tracker 2 mẫu của GSAP nên không port).
- `resistance` là "px/s vận tốc đổi lấy 1 giây bay", không phải hệ số vật lý
  — chỉnh cảm giác bằng nó và `maxDuration`.
- Snap chấm theo CẶP (x,y) như `linkedProps` của GSAP — không snap trục lẻ
  nên không có chuyện đáp lệch chéo nửa ô.
- Board cần kích thước hữu hạn (đặt trong Expanded/SizedBox).

## Changelog

- **1.0.0** (2026-08-27) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `InertiaThrow` vào project này.

**Context**
- Chức năng: thẻ ném theo đà kiểu GSAP Inertia — bay theo vận tốc thả, snap
  lưới trong bán kính, nảy mềm ở biên; kèm solver `InertiaFlight` tái dùng.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `inertia_throw/` (1 file), import duy nhất `inertia_throw.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `inertia_throw/` vào <thư mục widget của project đích>.
2. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
