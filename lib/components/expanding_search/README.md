---
# --- IDENTITY ---
id: expanding_search
title: Expanding Search
kind: effect
tags: [search, input, expand, glide, focus, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: expanding_search.dart
files:
  - expanding_search.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Expanding Search' (Interaction & Input)"
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

# Expanding Search

Search pill thu gọn còn đúng icon (56px), glide mở ra 230px khi field được
focus. Chỉ width animate; icon ghim bên trái, text bị clip khi thu gọn.

## Port notes

- Source thật: card `.demo-search` trong `src/content/body.html`, mục
  `25. Expanding search` của effects-a.css — thuần CSS, không có JS.
- Cơ chế gốc: **CSS transition** trên width, driver là
  `:hover, :focus-within`. Android không có hover → chỉ giữ nhánh
  **focus** (chính là cách tab React của card làm: focus/blur); tap vào pill
  = focus (label wrapper của bản gốc), mất focus = thu gọn. Đây là map
  touch tự nhiên, không cần chế thêm gesture.
- Flutter: `AnimatedContainer` lồng hai lớp — ngoài glide width 0.4s
  `Cubic(0.16, 1, 0.3, 1)`, trong fade border-color 0.3s ease (line → amber
  khi focus) — đúng hai transition độc lập của bản gốc. Nội dung giữ layout
  expanded cố định qua `OverflowBox` + clip (overflow: hidden).
- Số liệu giữ nguyên: 56→230px, padding 14×12, icon 18 (glyph 24-viewBox:
  circle r7 + handle, stroke 2 round), font 14, gap 8, radius pill, palette
  card-2/line/amber/bone-dim/bone/bone-faint.
- Readout `width 0.4s glide` khớp transition thật.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `expanding_search/` folder (1 dart file(s), see `files`)
- **Import:** `import 'expanding_search/expanding_search.dart';` — one line
- **Or:** `dart tools/export.dart expanding_search` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `collapsedWidth` / `expandedWidth` | `double` | `56 / 230` | Hai mốc width |
| `hintText` | `String` | `'Search…'` | Placeholder |
| `expanded` | `bool?` | `null` | null = theo focus; set cứng cho preview |
| `textController` / `focusNode` | `…?` | `null` | Truyền vào để tự quản |
| `onChanged` / `onSubmitted` | `ValueChanged<String>?` | `null` | Sự kiện input |
| `backgroundColor` / `borderColor` | `Color` | `#232326 / #2A2A2E` | Pill |
| `focusBorderColor` | `Color` | `#FF8A00` | Viền + cursor khi focus |
| `iconColor` / `textColor` / `hintColor` | `Color` | `#A8A6A0 / #EDE9E0 / #6E6C68` | Nội dung |
| `animate` | `bool` | `true` | False = đổi width tức thì |

## Caveats

- Dùng `TextField` của Material — cần `MaterialApp`/`Material` ancestor
  (mặc định app nào cũng có).
- Tap ra ngoài field sẽ unfocus (hành vi mặc định TextField từ Flutter 3.7)
  → tự thu gọn; nếu muốn giữ mở khi còn text, set `expanded: true` từ ngoài.
- Text scale lớn có thể làm chữ vượt 230px — tăng `expandedWidth` theo.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `ExpandingSearch` vào app bar/toolbar. Truyền `textController` +
`onSubmitted` nối vào search thật; đổi màu qua constructor; giữ nguyên glide
curve `Cubic(0.16, 1, 0.3, 1)` và cặp width 56/230.
