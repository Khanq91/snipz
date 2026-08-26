---
# --- IDENTITY ---
id: bouncing_ball
title: Bouncing Ball
kind: effect
tags: [ball, bounce, squash, stretch, loader, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: bouncing_ball.dart
files:
  - bouncing_ball.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Bouncing Ball' (Surface & Motion)"
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

# Bouncing Ball

Quả bóng amber nảy mỗi giây với squash-and-stretch: bẹt xuống khi chạm đất,
vươn dọc khi bay lên, bóng đổ elip co giãn và đậm nhạt đồng bộ bên dưới.

## Port notes

- Effect gốc: "Bouncing Ball", section **Surface & Motion**, kinetics. Đã
  đọc `.demo-bounce`/`-ball`/`-shadow` trong `effects-c.css`; không có JS.
- Cơ chế gốc: **hai CSS keyframes đồng bộ** trên cùng đồng hồ 1s
  `cubic-bezier(0.7, 0, 0.3, 1)`, easing chạy lại mỗi chặng 0→50/50→100.
- Số giữ nguyên: bóng 34px `radial(circle at 35% 30%, amber, amber-deep)`,
  translateY −54→0, scaleY 1.05→0.8, scaleX 1→1.15 (origin giữa như CSS);
  shadow 38×9 đen, scale 0.5→1, opacity 0.25→0.5; stage 80×110, bóng cách
  đáy 14, shadow cách đáy 8.
- Gradient bán kính theo farthest-corner từ focus 35%/30% và biến dạng theo
  squash, đúng hành vi background dưới transform.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `bouncing_ball/` folder (1 dart file(s), see `files`)
- **Import:** `import 'bouncing_ball/bouncing_ball.dart';` — one line
- **Or:** `dart tools/export.dart bouncing_ball` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `width` / `height` | `double` | `80 / 110` | Kích thước stage |
| `ballSize` | `double` | `34` | Đường kính bóng |
| `color` / `deepColor` | `Color` | amber / amber-deep | Gradient bóng |
| `shadowColor` | `Color` | black | Màu bóng đổ |
| `bounceHeight` | `double` | `54` | Độ cao nảy |
| `shadowWidth` / `shadowHeight` | `double` | `38 / 9` | Elip bóng đổ chưa scale |
| `ballBottom` / `shadowBottom` | `double` | `14 / 8` | Khoảng cách tới đáy stage |
| `period` | `double` | `1` | Giây mỗi lần nảy |
| `animate` | `bool` | `true` | Cho phép ticker chạy |
| `frozenAt` | `double?` | null | Render frame tại t giây, không ticker |

## Caveats

- Bezier (0.7, 0, 0.3, 1) là symmetric ease — vật lý "trọng lực" của demo
  đến từ cách chọn mốc keyframe, không phải simulation thật.
- Mọi thứ vẽ trong stage box; scale shadow/bóng không tràn ra ngoài.

## Changelog

- **1.0.0** (2026-08-26) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `BouncingBall` làm loader vui mắt hoặc empty-state. Đổi `color`
theo brand, `period` chỉnh nhịp; `frozenAt` cho thumbnail, tắt `animate`
khi khuất.
