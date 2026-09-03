---
# --- IDENTITY ---
id: snap_rail
title: Snap Rail
kind: effect
tags: [segmented, rail, pill, snap, spring, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: snap_rail.dart
files:
  - snap_rail.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Snap Rail' (Interaction & Input)"
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-24
created_flutter: 3.44.0
created_dart: 3.12.0
created_deps: []
platforms_initial: [android]

# --- COMPONENT VERSION ---
version: 1.0.1

# --- DERIVED (computed from Test History by verify.dart, do not hand-edit) ---
latest_known_good: null
last_verified: null
status: null

preview: null
---

# Snap Rail

Segmented rail với pill cam trong mờ (fill 16%, viền 50%) spring giữa các ô
BẰNG NHAU — pill luôn rộng đúng một cột, không bao giờ theo bề rộng chữ.
Label đang chọn chuyển amber.

## Port notes

- Source thật: card `.demo-snap-rail` trong `src/content/body.html`, mục
  `42?` (effects-a.css dòng 1601-1666). Không có JS — driver là `:has()` +
  `:hover`, không hover thì pill về ô 1.
- Cơ chế gốc: **CSS transition, hover là lõi** (pill "preview" theo option
  đang hover). Map sang touch: hover-preview → **selection controlled** —
  tap chọn, pill snap theo `index`; trạng thái nghỉ của web (pill ở ô 1) ≈
  default `index: 0`.
- Điểm phân biệt với `tab_pill_glide` (đã có trong vault): ô chia ĐỀU
  (flex 1) nên pill một cột cố định, style trong mờ + label active amber —
  hai effect khác nhau trong cùng gallery, port riêng.
- Số liệu giữ nguyên: 240×44 padding 4 radius pill, pill = (inner)/3
  translateX(i·100%) 0.45s `Cubic(0.34,1.56,0.64,1)`, label 12/600
  bone-dim → amber 0.25s ease.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `snap_rail/` folder (1 dart file(s), see `files`)
- **Import:** `import 'snap_rail/snap_rail.dart';` — one line
- **Or:** `dart tools/export.dart snap_rail` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `labels` | `List<String>` | `['Day','Week','Month']` | Nhãn các ô |
| `index` | `int` | required | Ô đang chọn (controlled) |
| `onChanged` | `ValueChanged<int>?` | required | null = disabled |
| `width` / `height` | `double` | `240 / 44` | Kích thước rail |
| `backgroundColor` / `borderColor` | `Color` | `#232326 / #2A2A2E` | Khung |
| `labelColor` | `Color` | `#A8A6A0` | Label thường |
| `accentColor` | `Color` | `#FF8A00` | Pill + label active |
| `animate` | `bool` | `true` | False = pill nhảy tức thì |

## Caveats

- Ô chia đều theo `width` cố định — label dài hơn ô sẽ bị cắt (đúng triết lý
  "never size the pill to the text" của bản gốc); tăng `width` khi cần.

## Changelog

- **1.0.1** (2026-09-03) — pill dồn vào vách khi spring vọt quá ô đầu/cuối, không còn lòi ra khỏi rail (TweenAnimationBuilder kẹp cạnh, giữ nguyên curve 0.45s)

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `SnapRail` như bộ chọn khoảng thời gian/chế độ. Parent giữ `index`,
cập nhật trong `onChanged`; giữ nguyên pill một-cột và spring 0.45s.
