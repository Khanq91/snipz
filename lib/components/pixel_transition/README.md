---
# --- IDENTITY ---
id: pixel_transition
title: Pixel Transition
kind: effect
tags: [pixel, transition, reveal, card, interactive, retro]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: pixel_transition.dart
files:
  - pixel_transition.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://reactbits.dev/animations/pixel-transition
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-18
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

# Pixel Transition

Card đổi nội dung sau bức màn pixel: lưới gridSize² ô phủ lên theo thứ tự
ngẫu nhiên trong `stepDuration`, đổi nội dung ở đỉnh, rồi gỡ ô theo thứ tự
ngẫu nhiên khác trong `stepDuration` nữa. Tap để toggle (hành vi touch của
bản gốc). Dựng lại "Pixel Transition" của react-bits (GSAP stagger DOM →
CustomPainter + một controller).

## Port notes

- Nguồn: `src/ts-tailwind/Animations/PixelTransition/PixelTransition.tsx`.
- Giữ: hai stagger `from: 'random'` độc lập (mỗi ô có thời điểm hiện/ẩn
  ngẫu nhiên riêng), swap nội dung đúng tại `stepDuration`, restart giữa
  chừng = kill & re-random, styling mặc định (nền #222, bo 15, viền trắng 2,
  vuông 1:1).
- Bỏ: nhánh hover/focus desktop (`mouseenter`/`mouseleave`/`focus`/`blur`) —
  Android chỉ có tap; DOM manipulation thay bằng một `CustomPainter` (không
  tạo gridSize² element).
- Thêm: `interactive` (tắt tap), `onChanged`, điều khiển ngoài qua
  `GlobalKey<PixelTransitionState>` (`show`/`toggle`/`active`).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `pixel_transition/` folder (1 dart file, see `files`)
- **Import:** `import 'pixel_transition/pixel_transition.dart';` — one line
- **Or:** `dart tools/export.dart pixel_transition` → zip + paste-ready block

```dart
SizedBox(
  width: 300,
  child: PixelTransition(
    firstChild: Image.network(catUrl, fit: BoxFit.cover),
    secondChild: const Center(child: Text('Meow!')),
    pixelColor: Colors.white,
    onChanged: (showingSecond) => debugPrint('$showingSecond'),
  ),
)
```

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `firstChild` | `Widget` | required | Nội dung nghỉ |
| `secondChild` | `Widget` | required | Nội dung sau màn pixel |
| `gridSize` | `int` | `7` | Ô mỗi cạnh (tổng gridSize²) |
| `pixelColor` | `Color` | trắng | Màu ô phủ |
| `stepDuration` | `Duration` | `300ms` | MỘT lượt stagger; cả transition = 2× |
| `once` | `bool` | `false` | Kích hoạt rồi ở lại `secondChild` |
| `interactive` | `bool` | `true` | Tap toggle; false = chỉ điều khiển ngoài |
| `aspectRatio` | `double?` | `1.0` | Tỷ lệ card; null = theo parent |
| `backgroundColor` | `Color` | `#222` | Nền card |
| `borderRadius` | `double` | `15` | Bo góc |
| `borderColor` / `borderWidth` | — | trắng / `2` | Viền |
| `onChanged` | `ValueChanged<bool>?` | `null` | Khi target đổi (true = second) |

`PixelTransitionState` (qua `GlobalKey`): `show(bool)`, `toggle()`, `active`.

## Caveats

- Cả hai child luôn nằm trong tree (`Offstage`) — child ẩn không paint nhưng
  vẫn build/layout; đừng đặt nội dung cực nặng ở nhánh ẩn.
- Painter vẽ tối đa gridSize² rect mỗi frame trong 2×`stepDuration` — gridSize
  ≤ 20 thoải mái; không có cost khi đứng yên (animation hữu hạn, không ticker
  nền).
- Ô vẽ chờm +1px che seam khi kích thước cell lẻ — pixelColor bán trong suốt
  sẽ lộ vệt chồng; dùng màu đặc.
- `once: true` chặn tap quay lại nhưng `show(false)` từ ngoài vẫn được (chủ
  đích — bản gốc cũng chỉ chặn ở handler).

## Changelog

- **1.0.0** (2026-08-18) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `PixelTransition` vào project này.

**Context**
- Chức năng: card đổi nội dung sau màn pixel ngẫu nhiên (port react-bits),
  tap toggle, điều khiển ngoài qua `GlobalKey<PixelTransitionState>`.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `pixel_transition/` (1 file),
  import duy nhất `pixel_transition.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `pixel_transition/` vào thư mục widget của project đích.
2. Bọc trong `SizedBox(width: ...)` (card tự giữ tỷ lệ `aspectRatio`).
3. Đặt `firstChild`/`secondChild` là nội dung thật (ảnh, text, bất kỳ).

**Việc cần adapt theo project đích**
- `pixelColor` sang accent của project; `backgroundColor`/viền theo card
  style sẵn có (hoặc `borderWidth: 0`).
- Reveal-once khi scroll tới: `once: true` + gọi `show(true)` từ scroll
  listener của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong (rank/stagger). Chỉ đổi qua params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
