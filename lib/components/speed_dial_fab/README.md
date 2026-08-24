---
# --- IDENTITY ---
id: speed_dial_fab
title: Speed-Dial FAB
kind: effect
tags: [fab, speed-dial, menu, stagger, spring, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: speed_dial_fab.dart
files:
  - speed_dial_fab.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Speed-Dial FAB' (Interaction & Input)"
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

# Speed-Dial FAB

FAB cam bung 3 mini action theo hình quạt bằng spring có stagger (delay
0.02/0.07/0.12s), icon + xoay 135° thành ×. Đóng lại thì đồng loạt, không
stagger — đúng bản gốc.

## Port notes

- Source thật: card `.demo-speeddial` trong `src/content/body.html`, mục
  `29. Speed-dial FAB` của effects-a.css. Không có JS — bản web chạy bằng
  checkbox `:checked` ẩn; Flutter thay bằng tap toggle state.
- Cơ chế gốc: **CSS transition + spring bezier + transition-delay stagger**.
  Flutter dùng implicit animation per item; stagger dựng bằng `Interval`
  prefix trên duration kéo dài (500+delay), CHỈ ở chiều mở —
  `transition-delay` gốc nằm trong block `:checked` nên chiều đóng chạy
  đồng loạt, không delay (giữ đúng chi tiết này).
- Số liệu giữ nguyên: fan (-54,-58)/(0,-80)/(54,-58), scale 0.4→1 0.5s
  `Cubic(0.34,1.56,0.64,1)`, opacity 0.3s ease, delay 20/70/120ms, icon +
  xoay 135° 0.45s spring, main 54px amber shadow amber-deep, item 40px
  card-2/line, zone 150×156.
- 3 icon gốc (share/edit/star) vẽ lại bằng `CustomPainter` từ hình học
  24-viewBox stroke 2 — zero asset; thay được qua `actions`.
- Không có hover lõi; checkbox toggle → tap.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `speed_dial_fab/` folder (1 dart file(s), see `files`)
- **Import:** `import 'speed_dial_fab/speed_dial_fab.dart';` — one line
- **Or:** `dart tools/export.dart speed_dial_fab` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `actions` | `List<SpeedDialAction>?` | share/edit/star | icon 18×18 + onPressed + label |
| `fanOffsets` | `List<Offset>` | 3 vị trí gốc | Điểm đáp của từng item so với FAB |
| `initiallyOpen` | `bool` | `false` | Trạng thái ban đầu |
| `mainSize` / `itemSize` | `double` | `54 / 40` | Kích thước nút |
| `mainColor` / `mainIconColor` | `Color` | `#FF8A00 / #0E0E10` | FAB |
| `itemColor` / `itemBorderColor` / `itemIconColor` | `Color` | card-2/line/bone | Item |
| `shadowColor` | `Color` | `#B36200` | Shadow FAB |
| `onOpenChanged` | `ValueChanged<bool>?` | `null` | Báo trạng thái sau toggle |
| `animate` | `bool` | `true` | False = đổi trạng thái tức thì |

## Caveats

- Footprint cố định 150×156 như stage gốc (fan cần chỗ); đặt trong Stack góc
  màn hình bằng Positioned.
- Số action > `fanOffsets.length` bị bỏ qua — fan 3 điểm là chữ ký của
  effect; muốn nhiều hơn thì truyền thêm offsets.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `SpeedDialFab` làm FAB chính của screen. Truyền `actions` với icon
18×18 (widget bất kỳ) và `onPressed` thật; giữ nguyên fan offsets, spring
curve và stagger 20/70/120ms.
