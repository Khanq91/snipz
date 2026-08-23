---
# --- IDENTITY ---
id: drum_clock
title: Drum Clock
kind: composite
tags: [clock, 3d, drum, playback, time, animated, animejs]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: drum_clock.dart
files:
  - drum_clock.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/juliangarnier/anime (examples/clock-playback-controls)
author: "Khang"
license: null

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-23
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

# Drum Clock

Đồng hồ số HH:MM:SS.cc mà mỗi chữ số nằm trên một trống xoay 3D: các trống
chậm đứng yên rồi "quất" cuộn 650ms ngay trước mỗi lần đổi số (bezier
overshoot 1,0,.6,1.2 — vọt quá rồi nảy lại), hai trống centi-giây quay đều
liên tục. Kèm `DrumClockController`: play/pause/đảo chiều/đổi tốc độ (ramp
mượt 1.5s) và glide-seek tới một mốc giờ. Port ví dụ
`clock-playback-controls` của anime.js v4; các cú wrap 59→00, 23→00 tự cuộn
đủ số bước còn lại trong một cú quay.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `drum_clock/` folder (1 dart file(s), see `files`)
- **Import:** `import 'drum_clock/drum_clock.dart';` — one line
- **Or:** `dart tools/export.dart drum_clock` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `controller` | `DrumClockController?` | `null` | Bộ điều khiển ngoài; null tự tạo (10:08:30, đang chạy) |
| `showCentis` | `bool` | `true` | Hiện 2 trống centi-giây |
| `fontSize` | `double` | `40` | Cỡ số (mọi kích thước drum scale theo) |
| `color` | `Color` | `0xFFEDEAE4` | Màu số |
| `backgroundColor` | `Color` | `0xFF191817` | Nền + fade chìm mép trên/dưới; `transparent` tắt fade |
| `fontFamily` | `String` | `'monospace'` | Font số |
| `animate` | `bool` | `true` | `false` dừng ticker |
| `frozenAt` | `double?` | `null` | Đứng yên tại mốc giờ (giây trong ngày), không ticker |

`DrumClockController`: `play()`, `pause()`, `reverse()`, `setSpeed(v, {ramp})`
(mặc định ramp 1.5s out(3)), `seekTo(Duration, {glide})` (mặc định glide 1.5s
inOut(3)), `jumpTo(Duration)`; đọc `time`, `speed`, `playing`. Là
`ChangeNotifier` — notify khi đổi trạng thái điều khiển (không notify mỗi frame).

## Caveats

- Component KHÔNG tự đọc giờ hệ thống (luật thuần khiết của vault) — truyền
  giờ thật qua `DrumClockController(initialTime: ...)` như trong demo.
- Trống centi-giây quay đều nên luôn có motion — cân nhắc `showCentis:
  false` nếu đặt cạnh nội dung cần yên tĩnh.
- Widget rebuild mỗi frame khi chạy (bản chất đồng hồ); ~40-60 Transform
  layer sau culling — nhẹ với Impeller.

## Changelog

- **1.0.0** (2026-08-23) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `DrumClock` vào project này.

**Context**
- Chức năng: đồng hồ trống 3D + controller play/pause/reverse/speed/seek; dùng làm màn hình giờ, screensaver, hoặc demo time-control.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `drum_clock/` (1 file), import duy nhất `drum_clock.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `drum_clock/` vào <thư mục widget của project đích>.
2. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
