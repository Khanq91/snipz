---
# --- IDENTITY ---
id: elastic_slider
title: Elastic Slider
kind: composite
tags: [slider, elastic, spring, interactive, control, input]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: elastic_slider.dart
files:
  - elastic_slider.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://reactbits.dev/components/elastic-slider
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

# Elastic Slider

Slider đàn hồi kiểu iOS: kéo quá hai đầu thì track **giãn** theo ngón tay
(overflow qua sigmoid decay, cap 50px), icon phía đó bị đẩy theo + pulse,
thả ra thì spring-back nảy. Chạm vào là cả control phóng to nhẹ (1→1.2,
opacity 0.7→1, track 6→12px). Dựng lại "Elastic Slider" của react-bits
(motion/react → Flutter thuần).

## Port notes

- Nguồn: `src/ts-tailwind/Components/ElasticSlider/ElasticSlider.tsx`.
- Giữ: toàn bộ tương tác — hàm `decay` sigmoid, scaleX = 1 + overflow/width,
  scaleY 1→0.8, transform-origin phía đối diện ngón tay, icon shift
  `overflow/scale`, pulse [1, 1.4, 1] 250ms khi vượt biên.
- Bỏ: hover (`onHoverStart` grow) — gộp vào pointer-down; framer spring
  `bounce: 0.5` → `SpringSimulation` (stiffness 200, damping 14, ζ ≈ 0.5).
- Thêm: `onChanged`/`onChangeEnd` (Flutter cần event ra qua callback; bản
  gốc chỉ giữ state nội bộ), get/set `value` qua
  `GlobalKey<ElasticSliderState>`.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `elastic_slider/` folder (1 dart file, see `files`)
- **Import:** `import 'elastic_slider/elastic_slider.dart';` — one line
- **Or:** `dart tools/export.dart elastic_slider` → zip + paste-ready block

```dart
ElasticSlider(
  initialValue: 40,
  isStepped: true,
  stepSize: 10,
  leftIcon: const Icon(Icons.volume_mute),
  rightIcon: const Icon(Icons.volume_up),
  onChanged: (v) => player.setVolume(v / 100),
)
```

## API

`ElasticSlider` widget. Chiều rộng theo parent — bọc `ConstrainedBox`
(bản gốc w-48 ≈ 192px).

| Param | Type | Default | Meaning |
|---|---|---|---|
| `initialValue` | `double` | `50` | Giá trị ban đầu (gốc `defaultValue`) |
| `minValue` | `double` | `0` | Đầu range (gốc `startingValue`) |
| `maxValue` | `double` | `100` | Cuối range |
| `isStepped` | `bool` | `false` | Snap theo `stepSize` |
| `stepSize` | `double` | `1` | Bước snap |
| `leftIcon` / `rightIcon` | `Widget?` | `null` | Hai đầu; null = Text "−"/"+" |
| `onChanged` | `ValueChanged<double>?` | `null` | Mỗi lần value đổi khi drag |
| `onChangeEnd` | `ValueChanged<double>?` | `null` | Một lần khi thả |
| `showValueLabel` | `bool` | `true` | Số tròn dưới track |
| `trackColor` / `fillColor` | `Color` | gray-400/500 | Màu track/fill |
| `iconColor` | `Color` | gray-400 | Màu icon fallback + label |
| `labelStyle` | `TextStyle?` | `null` | Merge lên style label mặc định |
| `maxOverflow` | `double` | `50` | Cap giãn đàn hồi (px) |

`ElasticSliderState` (qua `GlobalKey`): get/set `value`.

## Caveats

- Widget tự giữ value (uncontrolled, giống bản gốc) — muốn set từ ngoài thì
  dùng `GlobalKey<ElasticSliderState>().currentState?.value = x`, không có
  mode controlled.
- Animation chỉ chạy khi tương tác (không có ticker nền) — không cần stop
  switch; spring tự settle rồi im.
- `Transform.scale` cả row khi chạm → có thể vẽ đè lên widget sát cạnh;
  chừa lề dọc ~8px quanh slider.
- Chưa có semantics/a11y (Slider của Material có sẵn — đây là component
  thẩm mỹ).

## Changelog

- **1.0.0** (2026-08-18) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `ElasticSlider` vào project này.

**Context**
- Chức năng: slider đàn hồi (kéo quá biên giãn track, spring-back khi thả),
  port react-bits. Value ra qua `onChanged`/`onChangeEnd`.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `elastic_slider/` (1 file),
  import duy nhất `elastic_slider.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `elastic_slider/` vào thư mục widget của project đích.
2. Đặt trong `ConstrainedBox(maxWidth: ~240)`, nối `onChanged` vào state
   của project (volume, brightness, progress...).

**Việc cần adapt theo project đích**
- `trackColor`/`fillColor`/`iconColor` sang palette project.
- `leftIcon`/`rightIcon` sang icon set project đang dùng.
- Cần semantics → cân nhắc bọc `Semantics(slider: true, ...)`.

**Rào (constraints)**
- KHÔNG sửa logic bên trong (decay/spring). Chỉ đổi qua params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
