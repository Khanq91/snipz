---
# --- IDENTITY ---
id: scroll_expand
title: Scroll Expand
kind: effect
tags: [scroll, hero, expand, clip, sticky, media]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: scroll_expand.dart
files:
  - scroll_expand.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/DavidHDev/react-bits/blob/main/src/ts-tailwind/Animations/ScrollExpand/ScrollExpand.tsx
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-19
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

# Scroll Expand

Hero theo scroll: `media` bắt đầu là card bo góc inset
(`startWidth`/`startHeight` % của khung), scroll thì nở dần ra fullscreen
qua `scrollDistance` viewport; `title` bay lên mờ đi, `scrollHint` biến mất
sớm, `overlay` hiện ở phần ba cuối, scrim tối phủ dần. Stage "sticky" — chỉ
clip animate, không gì trôi. Widget tự có mặt scroll riêng (chiếm full
parent). Dựng lại "ScrollExpand" của react-bits (clip-path inset + sticky
track → ClipRRect custom clipper + ScrollController).

## Port notes

- Nguồn: `src/ts-tailwind/Animations/ScrollExpand/ScrollExpand.tsx`.
- Giữ: toàn bộ mapping progress — smoothstep clip inset + radius, media zoom
  `mediaZoom → 1`, title out `smoothstep(0.4, 0.88)` (dịch -28px, scale
  +6%), hint gone `smoothstep(0, 0.12)`, overlay in `smoothstep(0.68, 1)`
  (dịch 18px), scrim gradient 3 stop, title size `7.5%` bề ngang clamp
  20–84, exponential smoothing của scroll.
- Bỏ: `useWindowScroll` (không có window — widget luôn tự scroll),
  `mediaType`/`src`/`poster` (media là `Widget`, app tự đặt Image/video
  player), ResizeObserver (→ LayoutBuilder), prefers-reduced-motion.
- Thay: sticky + track DOM → Stack: stage ghim dưới, mặt
  `SingleChildScrollView` trong suốt cao `1 + scrollDistance + holdDistance`
  viewport đè lên nhận gesture.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `scroll_expand/` folder (1 dart file, see `files`)
- **Import:** `import 'scroll_expand/scroll_expand.dart';` — one line
- **Or:** `dart tools/export.dart scroll_expand` → zip + paste-ready block

```dart
// Fills its parent; give it the screen (e.g. body of a Scaffold).
ScrollExpand(
  title: 'Beyond the Horizon',
  scrollHint: 'scroll to expand',
  media: Image.network(url, fit: BoxFit.cover),
  overlay: MyCallToAction(),
)
```

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `media` | `Widget` | required | Nội dung fullscreen sau clip |
| `title` | `String` | `''` | Heading giữa màn, bay đi khi nở |
| `scrollHint` | `String` | `''` | Hint đáy màn, mất sau 12% progress |
| `overlay` | `Widget?` | `null` | Nội dung hiện ở cuối expansion |
| `startWidth` / `startHeight` | `double` | `42` / `58` | Cỡ card ban đầu (% khung) |
| `startRadius` / `endRadius` | `double` | `24` / `0` | Bo góc đầu/cuối |
| `mediaZoom` | `double` | `1.35` | Media zoom lúc thu nhỏ, về 1 khi nở |
| `scrollDistance` | `double` | `1.2` | Số viewport scroll cho 0→1 |
| `holdDistance` | `double` | `0.35` | Viewport scroll thêm sau khi nở hết |
| `smoothing` | `double` | `0.1` | Hằng số thời gian (giây) ease scroll; 0 = bám thô |
| `overlayScrim` | `double` | `0.45` | Opacity đỉnh của scrim |
| `enabled` | `bool` | `true` | false = ghim ở trạng thái nở hết |
| `titleStyle` / `hintStyle` | `TextStyle?` | `null` | Style chữ |
| `onProgress` | `ValueChanged<double>?` | `null` | Progress eased 0..1 |

## Caveats

- Mặt scroll trong suốt nằm **trên** stage nên nội dung trong `overlay`
  **không nhận tap** (nó nhận gesture scroll) — overlay hiện tại là
  display-only; cần nút bấm được thì đặt ngoài widget theo `onProgress`.
- Widget phải có bound cao xác định (fills parent) — đừng đặt trong
  scrollable khác không ràng chiều cao.
- Media luôn full-size + `Transform.scale`, chỉ clip thay đổi — không
  relayout khi scroll; cost là repaint vùng media. Cost thật trên thiết bị:
  chưa đo.
- `smoothing > 0` chạy Ticker trong lúc easing, settle là dừng.

## Changelog

- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `ScrollExpand` vào project này.

**Context**
- Chức năng: hero nở từ card inset ra fullscreen theo scroll, sticky stage
  (port react-bits).
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `scroll_expand/` (1 file),
  import duy nhất `scroll_expand.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `scroll_expand/` vào thư mục widget của project đích.
2. Cho nó full màn hình (body Scaffold / route riêng), truyền `media` là
   ảnh/video thật.

**Việc cần adapt theo project đích**
- `titleStyle` theo type scale của project.
- Overlay cần tương tác → để overlay display-only, đặt nút thật đè ngoài
  widget và hiện theo `onProgress` (xem Caveats).

**Rào (constraints)**
- KHÔNG sửa mapping smoothstep bên trong. Chỉ đổi qua params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
