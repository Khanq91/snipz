---
# --- IDENTITY ---
id: card_resize
title: Card Resize
kind: effect
tags: [card, expand, spring, resize, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: card_resize.dart
files:
  - card_resize.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Card Resize' (Interaction & Input)"
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

# Card Resize

Card tap-to-expand: chỉ height animate bằng một cubic overshoot duy nhất
(64 → 124px), text phụ fade in trễ 100ms để không lộ ra lúc đang collapse.

## Port notes

- Source thật: card `.demo-spring-card` trong `src/content/body.html`, mục
  `1. Spring card resize` của `public/css/effects-a.css`, JS chỉ toggle
  `.expanded` khi click.
- Cơ chế gốc: **CSS transition + bezier giả spring**. Flutter dùng
  `AnimatedContainer` height 0.5s `Cubic(0.34, 1.56, 0.64, 1)`; text phụ
  `AnimatedOpacity` 0.4s với `Interval(0.25, 1, ease)` = delay 0.1s + fade
  0.3s ease của bản gốc (delay áp cả hai chiều, đúng CSS).
- Số liệu giữ nguyên: 220×(64→124), padding 18×16, radius 9, title 14/600,
  extra 12, palette card-2/line/bone/bone-dim.
- Readout `spring(320, 24)` chỉ là trang trí — demo thật chạy cubic-bezier.
- Hover đổi border-color đã bỏ (Android không có hover); click → tap.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `card_resize/` folder (1 dart file(s), see `files`)
- **Import:** `import 'card_resize/card_resize.dart';` — one line
- **Or:** `dart tools/export.dart card_resize` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `title` | `String` | `'Tap to expand'` | Dòng chính luôn hiển thị |
| `extra` | `String` | câu mô tả gốc | Text phụ hiện khi expanded |
| `width` | `double` | `220` | Bề rộng card |
| `collapsedHeight` / `expandedHeight` | `double` | `64 / 124` | Hai mốc height |
| `initiallyExpanded` | `bool` | `false` | Trạng thái ban đầu |
| `backgroundColor` / `borderColor` | `Color` | `#232326 / #2A2A2E` | Màu card |
| `titleColor` / `extraColor` | `Color` | `#EDE9E0 / #A8A6A0` | Màu chữ |
| `borderRadius` | `double` | `9` | Bo góc |
| `onChanged` | `ValueChanged<bool>?` | `null` | Báo trạng thái sau mỗi tap |
| `animate` | `bool` | `false`→tức thì | `true` |

## Caveats

- Height là số cố định (đúng bản gốc) — text `extra` dài hơn sẽ bị clip;
  chỉnh `expandedHeight` theo nội dung.
- Tôn trọng `MediaQuery.disableAnimations`.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `CardResize` như một expandable card tự quản trạng thái. Đặt
`title`/`extra` theo nội dung thật, chỉnh `expandedHeight` đủ chứa text, đổi
màu qua constructor; giữ nguyên curve và timing (linh hồn của effect).
