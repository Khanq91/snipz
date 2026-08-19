---
# --- IDENTITY ---
id: animated_content
title: Animated Content
kind: effect
tags: [entrance, scroll, reveal, fade, slide, wrapper]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: animated_content.dart
files:
  - animated_content.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/DavidHDev/react-bits/blob/main/src/ts-tailwind/Animations/AnimatedContent/AnimatedContent.tsx
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

# Animated Content

Wrapper cho hiệu ứng entrance chạy **một lần** khi widget scroll vào viewport:
child trượt từ `distance`, fade từ `initialOpacity`, scale từ `scale` về vị trí
thật. Tùy chọn tự biến mất sau `disappearAfter`. Dựng lại "AnimatedContent"
của react-bits (GSAP + ScrollTrigger → AnimationController + listener trên
`ScrollPosition` của Scrollable tổ tiên).

## Port notes

- Nguồn: `src/ts-tailwind/Animations/AnimatedContent/AnimatedContent.tsx`.
- Giữ: bộ param đầy đủ (distance/direction/reverse/threshold/delay/scale/
  opacity, nhánh disappear với hướng ngược + scale 0.8), semantics trigger
  `start: top (1-threshold)%` once.
- Bỏ: GSAP/ScrollTrigger, `container` selector DOM, ease string (→ `Curve`
  của Flutter: `power3.out` → `Curves.easeOutCubic`, `power3.in` →
  `Curves.easeInCubic`).
- Thay: phát hiện vào viewport bằng listener trên `Scrollable.maybeOf` —
  không có Scrollable tổ tiên thì chạy ngay sau frame đầu; `autoTrigger:
  false` + `GlobalKey<AnimatedContentState>` để tự điều khiển.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `animated_content/` folder (1 dart file, see `files`)
- **Import:** `import 'animated_content/animated_content.dart';` — one line
- **Or:** `dart tools/export.dart animated_content` → zip + paste-ready block

```dart
ListView(children: [
  AnimatedContent(child: MyCard()),
  AnimatedContent(
    direction: Axis.horizontal,
    reverse: true,
    delay: Duration(milliseconds: 200),
    child: MyCard(),
  ),
])
```

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `child` | `Widget` | required | Nội dung được animate |
| `distance` | `double` | `100` | Quãng trượt vào (px) |
| `direction` | `Axis` | `vertical` | Trục trượt |
| `reverse` | `bool` | `false` | Đảo phía trượt vào |
| `duration` | `Duration` | `800ms` | Thời lượng entrance |
| `curve` | `Curve` | `easeOutCubic` | Ease entrance |
| `initialOpacity` | `double` | `0` | Opacity trước khi chạy |
| `animateOpacity` | `bool` | `true` | false = không fade |
| `scale` | `double` | `1` | Scale xuất phát |
| `threshold` | `double` | `0.1` | Mép trên vượt `(1-threshold)` viewport thì chạy |
| `delay` | `Duration` | `0` | Chờ thêm sau trigger |
| `disappearAfter` | `Duration?` | `null` | Non-null: đợi rồi animate ra |
| `disappearDuration` | `Duration` | `500ms` | Thời lượng biến mất |
| `disappearCurve` | `Curve` | `easeInCubic` | Ease biến mất |
| `autoTrigger` | `bool` | `true` | false = chỉ chạy qua `play()` |
| `onComplete` / `onDisappearanceComplete` | `VoidCallback?` | `null` | Callback mốc |

`AnimatedContentState` (qua `GlobalKey`): `play()`, `reset()`.

## Caveats

- Trigger đọc vị trí qua `RenderBox.localToGlobal` mỗi lần scrollable tick —
  rẻ, nhưng chỉ nhìn **Scrollable gần nhất**; lồng nhiều tầng scroll thì tầng
  ngoài không được theo dõi.
- Trong `ListView.builder`, item ra khỏi cache rồi quay lại sẽ được build
  lại → hiệu ứng chạy lại (bản gốc DOM giữ node nên chỉ chạy một lần). Muốn
  đúng một lần tuyệt đối: giữ cờ ở state cha và `autoTrigger: false`.
- Widget luôn build child (chỉ ẩn bằng Opacity/Transform) — child nặng vẫn
  tốn layout khi chưa hiện.

## Changelog

- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `AnimatedContent` vào project này.

**Context**
- Chức năng: entrance-on-scroll một lần (slide/fade/scale), tùy chọn tự biến
  mất; port react-bits.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `animated_content/` (1 file),
  import duy nhất `animated_content.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `animated_content/` vào thư mục widget của project đích.
2. Bọc từng item cần hiệu ứng: `AnimatedContent(child: ...)` bên trong
   ListView/ScrollView sẵn có.

**Việc cần adapt theo project đích**
- `duration`/`curve`/`distance` theo motion spec của project.
- Cần chạy đúng-một-lần kể cả khi item bị rebuild → giữ cờ đã-chạy ở state
  cha, đặt `autoTrigger: false` và gọi `play()` có điều kiện.

**Rào (constraints)**
- KHÔNG sửa logic trigger bên trong. Chỉ đổi qua params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
