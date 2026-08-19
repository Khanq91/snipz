---
# --- IDENTITY ---
id: gradual_blur
title: Gradual Blur
kind: effect
tags: [blur, backdrop, gradient, overlay, scroll, fade, frosted]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: gradual_blur.dart
files:
  - gradual_blur.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: adapted
source: https://github.com/DavidHDev/react-bits/blob/main/src/ts-tailwind/Animations/GradualBlur/GradualBlur.tsx
author: "Khang"
license: "MIT + Commons Clause License Condition v1.0 (react-bits, © David Haz)"

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

# Gradual Blur

Overlay "blur tăng dần": content phía sau sắc nét ở mép trong và mờ dần
(frosted) về mép `position` — kiểu fade-out đáy list bằng blur thay vì
gradient màu. Port từ react-bits "GradualBlur" (các div CSS
`backdrop-filter` chồng nhau, mask bằng linear-gradient). Widget là một
sized box thuần, xuyên pointer — app tự đặt vị trí bằng `Align`/`Positioned`
trong `Stack`.

## Port notes

- Nguồn: `src/ts-tailwind/Animations/GradualBlur/GradualBlur.tsx` — thuần
  CSS backdrop-filter, không GLSL → đi đường widget, zero asset.
- **Sai lệch cấu trúc chính:** bản gốc chồng `divCount` div full-size, mỗi
  div mask bằng linear-gradient. Flutter **không mask được**
  `BackdropFilter` bằng gradient (BackdropFilter composite thẳng backdrop,
  bỏ qua ShaderMask/Opacity của cha) → thay bằng `divCount` **dải kề nhau**
  dọc trục, mỗi dải = `ClipRect` + `BackdropFilter` riêng. Công thức blur
  từng bước giữ **nguyên xi** bản gốc: `progress = i/divCount` qua curve,
  rồi `exponential ? 2^(progress·4)·0.0625·strength :
  0.0625·(progress·divCount+1)·strength` (đơn vị rem, quy đổi 1rem = 16
  logical px; CSS `blur()` và sigma Flutter đều là stddev Gaussian nên map
  1:1). Hệ quả: ranh giới dải là bước nhảy cứng thay vì gradient chồng mượt
  — xem Caveats.
- 5 curve function port 1:1: `linear`, `bezier` (smoothstep), `easeIn`,
  `easeOut`, `easeInOut`.
- `height`/`width` (chuỗi rem, tách theo trục) → một param `size` (px, trục
  nào tùy `position`); default 96 = 6rem gốc.
- `opacity` trên mỗi div CSS → `ColorFilter.matrix` scale alpha compose vào
  blur filter (lớp mờ vẽ đè alpha lên backdrop sắc — xấp xỉ hành vi CSS).
- Presets port: `subtle`, `intense`, `smooth`, `sharp`, `header`, `footer`
  (qua `GradualBlur.preset`, merge order default < preset < props như gốc).
- **Bỏ** (hạ tầng web, không có tương đương mobile): `target: 'page'`
  (position fixed), `responsive` + mobile/tablet/desktop breakpoints,
  `hoverIntensity` (hover không tồn tại trên Android), `animated`/`'scroll'`
  + IntersectionObserver + `onAnimationComplete`, `zIndex`/`className`/
  `style`, presets `sidebar`/`page-header`/`page-footer`. Không thêm
  animation thay thế (luật vault: không animation khi không yêu cầu).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `gradual_blur/` folder (1 dart file, see `files`)
- **Import:** `import 'gradual_blur/gradual_blur.dart';` — one line
- **Or:** `dart tools/export.dart gradual_blur` → zip + paste-ready block

```dart
// Fade-blur đáy một list
Stack(children: [
  ListView(...),
  const Align(
    alignment: Alignment.bottomCenter,
    child: GradualBlur(), // bottom, 96px, strength 2
  ),
])

// Header blur qua preset, override nhẹ
GradualBlur.preset(GradualBlurPreset.header, strength: 1.5)
```

## API

`GradualBlur({...})` — widget chính. `GradualBlur.preset(preset, {...})` —
factory từ preset gốc, param truyền tay ghi đè preset.

| Param | Type | Default | Meaning |
|---|---|---|---|
| `position` | `GradualBlurPosition` | `bottom` | Mép blur mạnh nhất (`top`/`bottom`/`left`/`right`) |
| `size` | `double` | `96` | Bề dày overlay theo trục blur (px; gốc 6rem). Trục còn lại fill parent |
| `strength` | `double` | `2` | Hệ số cường độ blur (cùng đơn vị với bản gốc) |
| `divCount` | `int` | `5` | Số dải blur — nhiều hơn = chuyển mượt hơn, đắt hơn |
| `curve` | `GradualBlurCurve` | `linear` | Remap progress: `linear`/`bezier`/`easeIn`/`easeOut`/`easeInOut` |
| `exponential` | `bool` | `false` | Blur tăng theo `2^(p·4)` thay vì bậc thang tuyến tính |
| `opacity` | `double` | `1` | 0..1 — độ đậm lớp mờ đè lên backdrop sắc |

Preset (`GradualBlurPreset`): `subtle` (64px, strength 1, opacity 0.8, 3 dải),
`intense` (160px, strength 4, 8 dải, exponential), `smooth` (128px, bezier,
10 dải), `sharp` (80px, linear, 4 dải), `header` (top, 128px, easeOut),
`footer` (bottom, 128px, easeOut).

## Caveats

- **Banding tại ranh giới dải:** khác bản gốc (gradient mask chồng lấn),
  các dải kề nhau có sigma nhảy bậc — strength cao / divCount thấp sẽ thấy
  vạch ngang mờ. Tăng `divCount` (8–10) để mượt; `curve: bezier` cũng đỡ.
- **Cost = divCount backdrop readback mỗi frame.** Mỗi dải là một saveLayer
  đọc lại backdrop. divCount ≤ ~8 cho Android tầm trung; cost thật trên
  thiết bị: chưa đo. Overlay tĩnh trên list đang scroll vẫn phải
  re-composite mỗi frame scroll.
- `BackdropFilter` chỉ blur thứ vẽ **trước nó trong cùng scene** — phải đặt
  widget *phía trên* content trong `Stack`. Không blur được sibling vẽ sau.
- `opacity` là xấp xỉ (alpha-composite lớp mờ lên backdrop sắc), không cam
  kết giống pixel với CSS opacity trên mọi browser.
- Widget cần parent bound xác định (trục fill dùng `double.infinity`) — đặt
  trong `Stack`/`Align` có bound, đừng thả vào scrollable không bound.
- Các tính năng web (`animated`, `responsive`, `hoverIntensity`,
  `target: page`…) KHÔNG port — xem Port notes, không có prop tương ứng.
- **License gốc:** MIT + Commons Clause (react-bits) — dùng trong
  app/product thoải mái, KHÔNG được bán/redistribute bản thân component
  (kể cả bản port).

## Changelog

- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `GradualBlur` vào project này.

**Context**
- Chức năng: overlay blur tăng dần về một mép (port react-bits
  "GradualBlur") — N dải `BackdropFilter` kề nhau, sized box xuyên pointer,
  app tự position trong `Stack`.
- Public API: xem bảng API trong README (`GradualBlur` +
  `GradualBlur.preset`).
- Portability: single_file — copy cả folder `gradual_blur/` (1 file),
  import duy nhất `gradual_blur.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `gradual_blur/` vào thư mục widget của project đích.
2. Đặt overlay phía trên content cần blur trong `Stack`:
   `Align(alignment: Alignment.bottomCenter, child: GradualBlur())` — hoặc
   `GradualBlur.preset(GradualBlurPreset.footer)`.

**Việc cần adapt theo project đích**
- `size` theo layout (chừa padding cuối list ≥ `size` để item cuối không bị
  che vĩnh viễn).
- Máy yếu: giảm `divCount` (4–5) và `strength`; cần mượt: tăng `divCount`.

**Rào (constraints)**
- KHÔNG sửa công thức blur/curve bên trong — chỉnh qua params.
- KHÔNG bọc `GradualBlur` trong `Opacity`/`ShaderMask` để chỉnh độ đậm —
  BackdropFilter bỏ qua chúng; dùng param `opacity`.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
