---
# --- IDENTITY ---
id: star_border
title: Star Border
kind: carrier
tags: [border, glow, button, star, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: star_border.dart
files:
  - star_border.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: adapted
source: https://github.com/DavidHDev/react-bits/blob/main/src/ts-tailwind/Animations/StarBorder/StarBorder.tsx
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

# Star Border

Port react-bits "StarBorder": viền "sao băng" — hai vệt glow radial-gradient
trượt dọc mép trên và mép dưới của khung bo góc, mờ dần khi chạy rồi đảo
chiều (CSS `linear infinite alternate`). Nội dung nằm trên mặt button tối
(gradient đen → gray-900, viền 1px); glow lộ ra qua khe dọc điều khiển bởi
`thickness`. Đây là carrier, **không phải button** — không có onTap.
Public widget: `StarBorderGlow`.

## Port notes

- Nguồn: `src/ts-tailwind/Animations/StarBorder/StarBorder.tsx`. Hai blob +
  keyframes lấy từ comment `tailwind.config.js` cuối file: blob 300%×50%,
  `radial-gradient(circle, color, transparent 10%)` (falloff rất gắt —
  chính nó tạo cảm giác "sao"), translate ±100% bề rộng chính nó, opacity
  1→0, `linear infinite alternate` → `AnimationController.repeat(reverse:
  true)` với `duration = speed`.
- Hình học dịch nguyên xi sang `CustomPainter`: blob dưới `right:-250%`
  (tâm x = 2w) chạy sang trái, `bottom:-11px`; blob trên đối xứng, chạy
  sang phải, `top:-10px`. `opacity-70` tĩnh nhân với keyframe → alpha =
  `0.7 × (1 − t)`. CSS `circle` size theo farthest-corner → bán kính =
  nửa đường chéo của blob 3w×0.5h.
- Bỏ: prop đa hình `as` + `className` + spread DOM props (chỉ có nghĩa trên
  web). Bản gốc render mặc định thành `<button>` — bản Flutter chủ ý KHÔNG
  làm button; app tự bọc `InkWell`/`GestureDetector` khi cần tap.
- Mặt trong hard-code của bản gốc (đen → gray-900, viền gray-800, padding
  16×26, chữ trắng 16px căn giữa) chuyển thành param có default đúng giá trị
  đó: `innerGradientColors`, `innerBorderColor`, `padding`; chữ áp qua
  `DefaultTextStyle.merge` nên style con tự ghi đè được.
- Thêm `animate` (stop switch, spec §9.2) — bản gốc không có. `animate:
  false` từ đầu → đứng ở frame giữa chu kỳ (t = 0.5) cho glow hiện rõ
  (tại t = 0 cả hai blob nằm ngoài vùng clip, không thấy gì).
- Đổi tên class: `StarBorder` → `StarBorderGlow`, vì Flutter đã có sẵn
  class `StarBorder` (ShapeBorder) trong framework.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** cả folder `star_border/` (1 file dart, xem `files`)
- **Import:** `import 'star_border/star_border.dart';` — một dòng
- **Or:** `dart tools/export.dart star_border` → zip + paste-ready block

Cần tap → app tự bọc:

```dart
InkWell(
  borderRadius: BorderRadius.circular(20),
  onTap: () {},
  child: const StarBorderGlow(child: Text('Click me')),
)
```

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `child` | `Widget` | required | Nội dung trên mặt trong |
| `color` | `Color` | `Colors.white` | Màu vệt glow chạy quanh viền |
| `speed` | `Duration` | `6s` | Thời gian một lượt chạy (alternate → một chu kỳ đủ = 2×) |
| `thickness` | `double` | `1` | Khe viền lộ glow — padding dọc quanh mặt trong (gốc: `padding: Npx 0`) |
| `animate` | `bool` | `true` | Stop switch — false thì đứng yên, không chạy ticker |
| `borderRadius` | `double` | `20` | Bo góc của clip ngoài lẫn mặt trong |
| `innerGradientColors` | `List<Color>` | `[đen, 0xFF111827]` | Gradient dọc của mặt trong (gốc: black → gray-900) |
| `innerBorderColor` | `Color` | `0xFF1F2937` | Viền 1px mặt trong (gốc: gray-800) |
| `padding` | `EdgeInsetsGeometry` | `16 dọc × 26 ngang` | Padding quanh `child` |

## Caveats

- Class đặt tên `StarBorderGlow` (không phải `StarBorder`) chính vì material
  đã có sẵn `StarBorder` — nhờ vậy import chung material không đụng nhau.
- Không phải button — không có onTap/hover/focus. Bọc `InkWell` ở tầng app
  (xem Reuse).
- Chi phí: 2 lần `drawRect` + 2 `ui.Gradient.radial` mỗi frame — rất nhẹ,
  nhưng vẫn là ticker chạy liên tục; màn hình tĩnh hoặc ngoài viewport thì
  đặt `animate: false`. Cost thật trên Android tầm trung: chưa đo.
- Glow chỉ đọc được trên nền tối (glow trắng/sáng trên nền sáng sẽ chìm).
- Hai offset `-10px`/`-11px` giữ nguyên giá trị tuyệt đối của bản gốc — với
  widget cao bất thường (blob = 50% chiều cao) hình dáng glow đổi theo,
  giống hệt hành vi CSS gốc.
- **License gốc:** MIT + Commons Clause (react-bits) — dùng trong app/product
  thoải mái, KHÔNG được bán/redistribute bản thân component (kể cả bản port).

## Changelog

- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `StarBorderGlow` vào project này.

**Context**
- Chức năng: viền "sao băng" animated (port react-bits "StarBorder") — hai
  vệt glow chạy dọc mép trên/dưới, mặt trong là button face tối nhận `child`
  bất kỳ. Carrier, không phải button.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `star_border/` (1 file), import
  duy nhất `star_border.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `star_border/` vào thư mục widget của project đích.
2. Import entry file (class tên `StarBorderGlow` — không đụng `StarBorder`
   có sẵn của material).
3. Đặt `StarBorderGlow(child: ...)` trên nền tối. Cần tap → bọc
   `InkWell`/`GestureDetector` bên ngoài (component không có onTap).

**Việc cần adapt theo project đích**
- `color` sang màu accent của project; `speed` nhanh hơn (2–4s) cho cảm giác
  năng động.
- Nền sáng: đổi `innerGradientColors`/`innerBorderColor` và chọn `color` đậm.
- Màn hình tĩnh hoặc widget ngoài viewport: `animate: false`.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file.
- KHÔNG thêm onTap vào component — bọc ở tầng app.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
