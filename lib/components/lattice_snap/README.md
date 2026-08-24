---
# --- IDENTITY ---
id: lattice_snap
title: Lattice Snap
kind: effect
tags: [grid, drag, snap, magnetic, spring, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: lattice_snap.dart
files:
  - lattice_snap.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Lattice Snap' (Interaction & Input)"
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

# Lattice Snap

Lưới nam châm 3×2: kéo tile cam thì nó bám theo ngón tay với trail ngắn
(80ms) và ô dưới nó sáng lên; nhả thì tile spring vào ô đó (0.5s overshoot).
Lưới không bao giờ reflow.

## Port notes

- Source thật: card `.demo-lattice` trong `src/content/body.html`, mục
  `51. Lattice snap` của effects-a.css, main.js "Lattice snap" (follow clamp
  trong bounds, hot cell theo vị trí pointer, snap khi nhả).
- Cơ chế gốc: **JS pointer drag + CSS transition hai chế độ** (0.5s spring
  idle / 80ms cùng curve khi drag). Drag là touch sẵn (`touch-action: none`)
  — không cần map hover. Arrow keys của web bỏ (không phải driver Android).
- Số liệu giữ nguyên: 200×118 gap 8, tile = đúng 1 ô ((100%-16)/3 ×
  (100%-8)/2) radius 10, `Cubic(0.34,1.56,0.64,1)` 0.5s/80ms, scale 1.06
  0.3s spring khi drag, hot cell amber 55%/8%, shadow nâng khi drag + glow
  4px amber 18%, gradient tile #ffd08a→amber(46%)→#b36200 tại 30%/20%.
- Sai lệch nhỏ: gradient gốc elliptical 120%×80% — Flutter RadialGradient
  tròn (radius 1.2) cho kết quả gần tương đương; inset highlight 1px của
  tile bỏ (BoxShadow không có inset).
- Viền cell dashed vẽ bằng `PathMetric` (Border Flutter không hỗ trợ dashed).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `lattice_snap/` folder (1 dart file(s), see `files`)
- **Import:** `import 'lattice_snap/lattice_snap.dart';` — one line
- **Or:** `dart tools/export.dart lattice_snap` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `columns` / `rows` | `int` | `3 / 2` | Kích thước lưới |
| `width` / `height` / `gap` | `double` | `200 / 118 / 8` | Hình học |
| `initialColumn` / `initialRow` | `int` | `0 / 0` | Ô ban đầu của tile |
| `cellBorderColor` | `Color` | `#34322F` | Viền dashed cell |
| `cellColor` | `Color` | card-2@55% | Nền cell |
| `tileColor` | `Color` | `#FF8A00` | Tile + hot cell + glow |
| `onSnapped` | `(int c, int r)?` | `null` | Bắn khi tile đáp xuống ô |
| `animate` | `bool` | `true` | False = snap tức thì |

## Caveats

- Nằm trong scrollable sẽ tranh gesture (Listener nuốt pointer trên cả
  lưới); kéo bắt đầu chỉ khi chạm đúng tile.
- Tile scale 1.06 + shadow tràn ra ngoài bounds một chút — đừng clip sát.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `LatticeSnap` như bộ xếp vị trí (widget slot, layout chooser). Đọc
ô qua `onSnapped`; giữ nguyên cặp transition 0.5s/80ms cùng spring curve —
đó là cảm giác "nam châm" của effect.
