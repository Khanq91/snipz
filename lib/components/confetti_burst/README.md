---
# --- IDENTITY ---
id: confetti_burst
title: Confetti Burst
kind: effect
tags: [confetti, particles, celebration, button, burst, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: confetti_burst.dart
files:
  - confetti_burst.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Confetti Burst' (Surface & Motion)"
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-26
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

# Confetti Burst

Nút pill bắn 16 mảnh confetti vuông từ tâm khi tap. Mỗi burst có góc tỏa
đều kèm jitter nhỏ, khoảng bay và góc xoay tất định theo seed; tap liên tiếp
tạo các burst độc lập có thể chồng lên nhau trong animation 900ms.

## Port notes

- Effect gốc: "Confetti Burst", section **Surface & Motion**, kinetics
  (`github.com/ckissi/kinetics`). Source thật gồm card `.demo-confetti-zone`
  trong `src/content/body.html`, mục 18 của `public/css/effects-c.css`, và
  spawner mục 14 trong `public/js/main.js`.
- Cơ chế gốc: **JS spawn + CSS keyframes**. Flutter sinh particle bằng
  `Random(seed)`, dùng một `Ticker` làm clock chung cho các batch độc lập, và
  vẽ toàn bộ bằng một `CustomPainter`; không dùng `Timer`.
- Số liệu giữ nguyên từ demo sống: 16 hình vuông 7×7 radius 2; palette
  `#FF8A00/#5B8DEF/#4CD08A/#EDE9E0`; góc đều cộng jitter `[0, 0.4)` rad;
  khoảng cách `[55, 110)` px; xoay `[0, 360)` độ; 900ms
  `Cubic(0.16, 1, 0.3, 1)`. Press scale xuống 0.94 trong 200ms bằng spring
  `Cubic(0.34, 1.56, 0.64, 1)`.
- Demo sống chỉ fly, rotate và fade — **không shrink**. Tab Prompt nói shrink
  nhưng CSS thật không có scale, nên port theo source thật và ghi rõ sai lệch.
- Random được seed để kết quả tất định; mỗi lần burst vẫn lấy đoạn kế tiếp
  trong chuỗi PRNG. Tap nhanh giữ các batch đang bay và chồng batch mới như
  JS gốc; mỗi batch được loại khỏi state khi đủ 900ms. Click map trực tiếp
  sang tap; không có hover lõi.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `confetti_burst/` folder (1 dart file(s), see `files`)
- **Import:** `import 'confetti_burst/confetti_burst.dart';` — one line
- **Or:** `dart tools/export.dart confetti_burst` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `onPressed` | `VoidCallback?` | required | Callback; null = disabled |
| `child` | `Widget` | `Text('Celebrate')` | Nội dung nút |
| `particleCount` | `int` | `16` | Số mảnh mỗi burst |
| `particleSize` / `particleRadius` | `double` | `7 / 2` | Kích thước và bo góc mảnh |
| `colors` | `List<Color>` | amber/blue/green/bone | Palette lặp quanh vòng |
| `seed` | `int` | `7` | Seed jitter, khoảng cách và rotation |
| `backgroundColor` / `foregroundColor` | `Color` | `#FF8A00 / #0E0E10` | Màu nút |
| `padding` | `EdgeInsetsGeometry` | `horizontal 24, vertical 13` | Padding nút |
| `textStyle` | `TextStyle` | `14px, w600` | Style mặc định của child text |
| `animate` | `bool` | `true` | false = không burst, callback vẫn chạy |

## Caveats

- Particle vẽ ngoài bounds nút tới khoảng 114px; đừng đặt component trong
  ancestor clip sát nút nếu muốn thấy trọn burst.
- Đổi `seed` reset chuỗi ngẫu nhiên. Với cùng seed và cùng chuỗi tap, output
  là tất định nhưng các burst kế tiếp không bắt buộc giống hệt nhau.
- `disableAnimations` và `animate: false` bỏ burst/press motion nhưng vẫn gọi
  callback để không làm thay đổi hành vi chức năng của nút.

## Changelog

- **1.0.0** (2026-08-26) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `ConfettiBurst` tại hành động hoàn tất/chúc mừng. Truyền nội dung
qua `child`, nối nghiệp vụ thật vào `onPressed`, và bảo đảm vùng cha không
clip bán kính burst. Giữ `animate: false` cho reduced-motion riêng của app
nếu app không cung cấp `MediaQuery.disableAnimations`.
