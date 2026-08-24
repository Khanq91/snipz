---
# --- IDENTITY ---
id: elastic_lasso
title: Elastic Lasso
kind: effect
tags: [lasso, selection, drag, dots, spring, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: elastic_lasso.dart
files:
  - elastic_lasso.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Elastic Lasso' (Interaction & Input)"
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

# Elastic Lasso

Bề mặt drag-to-select mini: kéo căng một khung lasso cam trong mờ từ điểm
bắt đầu; dot nằm trong khung spring to 1.45 và chuyển amber, chọn live theo
từng frame kéo, giữ nguyên sau khi nhả.

## Port notes

- Source thật: card `.demo-lasso` trong `src/content/body.html` (format nén,
  dòng 2801), CSS + JS đều minified (effects-a.css dòng 1475, main.js dòng
  1383).
- Cơ chế gốc: **JS pointer drag + CSS transition**. Drag là touch sẵn
  (`touch-action: none` trong bản gốc) — không cần map hover.
- Hành vi giữ đúng JS: chọn = tâm dot (offset+6) nằm trong rect hiện tại,
  RE-TOGGLE mỗi pointermove (dot ra ngoài rect là bỏ chọn ngay — kéo lại từ
  đầu tự "clear" selection cũ); nhả thì rect biến mất, selection giữ.
- Số liệu giữ nguyên: zone 210×112 radius 14, 5 dot 12px tại
  (22,24)/(78,65)/(132,29)/(174,73)/(45,83), selected scale 1.45 + amber
  0.3s `Cubic(0.34,1.56,0.64,1)`, rect border amber + amber 10% radius 5.
- Sai lệch nhỏ: điểm kéo clamp trong bounds zone (bản web cho rect tràn ra
  ngoài một chút khi pointer rời zone nhờ pointer capture).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `elastic_lasso/` folder (1 dart file(s), see `files`)
- **Import:** `import 'elastic_lasso/elastic_lasso.dart';` — one line
- **Or:** `dart tools/export.dart elastic_lasso` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `width` / `height` | `double` | `210 / 112` | Kích thước zone |
| `dotPositions` | `List<Offset>` | 5 vị trí gốc | Góc trên-trái các dot 12px |
| `initialSelection` | `Set<int>` | `{}` | Dot chọn sẵn (preview) |
| `borderColor` | `Color` | `#2A2A2E` | Viền zone |
| `dotColor` | `Color` | `#6E6C68` | Dot thường |
| `selectedColor` | `Color` | `#FF8A00` | Dot chọn + khung lasso |
| `onSelectionChanged` | `ValueChanged<Set<int>>?` | `null` | Mỗi lần set đổi (live khi kéo) |
| `animate` | `bool` | `true` | False = đổi trạng thái tức thì |

## Caveats

- Đặt trong scrollable dọc sẽ tranh gesture — `Listener` nhận mọi pointer
  down nên vùng này "nuốt" scroll; bọc bằng khoảng cách hoặc chấp nhận.
- `onSelectionChanged` bắn live trong lúc kéo (đúng hành vi gốc) — debounce
  phía consumer nếu cần.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `ElasticLasso` như multi-select surface thu nhỏ. Truyền
`dotPositions` theo data thật, đọc selection qua `onSelectionChanged`; giữ
nguyên scale 1.45 + spring 0.3s.
