---
# --- IDENTITY ---
id: ease_lab
title: Ease Lab
kind: composite
tags: [ease, curve, easing, wiggle, bounce, squash, slowmo, rough, zoom, playground, gsap]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: folder
entry: ease_lab.dart
files:
  - ease_lab.dart: "entry, public API"
  - _curves.dart: "required by ease_lab.dart"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/greensock/GSAP
author: "Khang"
license: "GSAP Standard License (thuật toán ease dựng lại, không copy code)"

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-27
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

# Ease Lab

Bộ ease GSAP port thành Flutter `Curve` thuần + playground trưng bày: chọn
ease, xem đồ thị và preview chuyển động chạy cùng một đồng hồ. Giá trị chính
nằm ở `_curves.dart` (export từ entry, dùng độc lập được với mọi
`AnimationController`):

- `CubicPathEase` — engine CustomEase: chuỗi cubic Bézier bất kỳ → LUT O(1).
- `WiggleEase` — lắc quanh 0 rồi tắt dần, 5 type (easeOut/easeInOut/
  anticipate/uniform/random-có-seed). **Kết thúc ở 0, không phải 1** — tween
  tới biên độ đỉnh, giá trị tự về lại điểm xuất phát.
- `BounceEase` + `SquashEase` — bounce tham số hóa kèm curve squash-stretch
  đồng bộ thời gian (cùng strength/squash, cùng controller → bóng bẹp đúng
  khoảnh khắc chạm sàn).
- `SlowMoEase` — vào nhanh, lơ lửng đoạn giữa tuyến tính, ra nhanh; bản
  `yoyoMode` cho fade 0→1→0 đồng bộ.
- `RoughEase` — jitter quanh curve nền (seed cố định, template/taper/clamp).
- `ExpoScaleEase(start, end)` — bù cảm nhận mũ khi zoom: tween scale tuyến
  tính qua curve này = nội suy hình học `start·(end/start)^t`, nhìn đều tốc.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `ease_lab/` folder (2 dart file(s), see `files`)
- **Import:** `import 'ease_lab/ease_lab.dart';` — one line
- **Or:** `dart tools/export.dart ease_lab` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `initialEase` | `String` | `'wiggle'` | Ease mở đầu: wiggle/anticipate/bounce/slowmo/rough/expo |
| `period` | `double` | `2.4` | Giây cho một lượt chạy demo |
| `hold` | `double` | `0.7` | Giây nghỉ giữa hai lượt |
| `height` | `double` | `420` | Chiều cao tổng (preview + graph + chips) |
| `accent` | `Color` | `0xFF8B7CFF` | Màu chủ đạo |
| `onEaseSelected` | `ValueChanged<String>?` | `null` | Callback khi chọn chip |
| `animate` | `bool` | `true` | Cho ticker chạy |
| `frozenAt` | `double?` | `null` | Render đúng một frame tại t giây, không ticker |

Các class curve (API chính, xem doc comment trong `_curves.dart`):
`CubicPathEase(values, {precision})` / `.bezier(x1,y1,x2,y2)`,
`WiggleEase({wiggles, type, timingEase, amplitudeEase, seed})`,
`BounceEase({strength, squash, endAtStart})`, `SquashEase({strength, squash,
endAtStart})`, `SlowMoEase({linearRatio, power, yoyoMode})`,
`RoughEase({points, strength, taper, randomize, clamp, template, seed})`,
`ExpoScaleEase(start, end, [inner])`.

## Caveats

- `WiggleEase`, `SquashEase`, `SlowMoEase(yoyoMode: true)` và
  `BounceEase(endAtStart: true)` **kết thúc ở 0** — chúng override
  `Curve.transform` để né shortcut `t==1 → 1` của framework. Đừng bọc thêm
  qua `CurvedAnimation.flipped` hay `Interval` mà không thử lại.
- `ExpoScaleEase(start, end)` phải khớp đúng range scale thật của tween
  (sai range là zoom lệch nhịp — đúng hành vi GSAP).
- `RoughEase`/`WiggleEase(random)` dùng `Random(seed)` — cùng seed cùng
  frame trên cùng platform; muốn pattern khác thì đổi seed.
- Đồ thị lấy 121 mẫu — RoughEase nhiều điểm hơn 121 sẽ hiển thị mượt hơn
  thực tế (chuyển động vẫn đúng).

## Changelog

- **1.0.0** (2026-08-27) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `EaseLab` vào project này.

**Context**
- Chức năng: bộ Flutter Curve port từ GSAP (wiggle, bounce+squash, slow-mo,
  rough, expo-scale, cubic-path) + widget playground EaseLab để xem/chọn.
- Public API: xem bảng API trong README.
- Portability: folder — copy cả `ease_lab/` (2 file), import duy nhất `ease_lab.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `ease_lab/` vào <thư mục widget của project đích>.
2. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
