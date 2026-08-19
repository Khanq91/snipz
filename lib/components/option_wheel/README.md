---
# --- IDENTITY ---
id: option_wheel
title: Option Wheel
kind: composite
tags: [picker, wheel, select, arc, drag, interactive]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: option_wheel.dart
files:
  - option_wheel.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: adapted
source: https://github.com/DavidHDev/react-bits/blob/main/src/ts-tailwind/Components/OptionWheel/OptionWheel.tsx
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

# Option Wheel

Picker dọc: các entry nằm trên **vòng cung** (bán kính giữ arc-length giữa
hai entry đúng một row height, nên `tilt` quyết định độ cong). Kéo dọc để
quay, tap entry để nhảy tới, thả thì snap về entry gần nhất; chuyển động ease
bằng exponential smoothing độc-lập-framerate. Entry xa mờ + nhòe dần. Origin
`adapted` vì toán layout vòng cung + smoothing port gần như từng dòng.

## Port notes

- Nguồn: `src/ts-tailwind/Components/OptionWheel/OptionWheel.tsx`.
- Giữ: toàn bộ toán — `R = rowH/tiltRad`, `ang = clamp(d·tiltRad, ±π/2)`,
  `y = R·sin`, `x = -mirror·R·(1-cos)·curve`, opacity/blur theo distance,
  color mix theo proximity, smoothing `k = 1-exp(-dt/τ)`, snap-shortest-path
  khi `loop`, cap ±1 bước mỗi scroll-wheel event, throttle tick 70ms.
- Bỏ: âm thanh `Audio` (`soundUrl`/`soundVolume`) → thay bằng callback
  `onTick` (gắn `HapticFeedback` hoặc player tùy app); keyboard arrows;
  ARIA roles.
- Thay: rAF → `Ticker` (tự stop khi settle); wheel event → vẫn hỗ trợ qua
  `PointerScrollEvent` (desktop); `font-extralight/medium` → `FontWeight
  w200/w500`; `color-mix` → `Color.lerp`.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `option_wheel/` folder (1 dart file, see `files`)
- **Import:** `import 'option_wheel/option_wheel.dart';` — one line
- **Or:** `dart tools/export.dart option_wheel` → zip + paste-ready block

```dart
SizedBox(
  height: 400,
  child: OptionWheel(
    items: const ['Ambient', 'House', 'Techno', 'Jazz'],
    onTick: HapticFeedback.selectionClick,
    onChanged: (i, item) => setGenre(item),
  ),
)
```

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `items` | `List<String>` | required (non-empty) | Các lựa chọn |
| `initialIndex` | `int` | `0` | Entry chọn ban đầu |
| `onChanged` | `(int, String)?` | `null` | Khi selection đổi |
| `onTick` | `VoidCallback?` | `null` | Mỗi lần đổi selection (throttle 70ms) — chỗ gắn haptic/sound |
| `textColor` / `activeColor` | `Color` | `#A6A6A6` / trắng | Màu chữ thường/chọn |
| `side` | `OptionWheelSide` | `left` | Neo mép trái hay phải |
| `fontSize` | `double` | `48` | Cỡ chữ |
| `spacing` | `double` | `1.4` | Row height = fontSize × spacing |
| `curve` | `double` | `1` | Độ sâu cuộn ngang (0 = cột thẳng) |
| `tilt` | `double` | `6` | Độ (góc) giữa hai entry kề nhau |
| `blur` | `double` | `2` | Sigma blur mỗi row khoảng cách (0 = tắt) |
| `fade` | `double` | `0.25` | Opacity mất mỗi row |
| `minOpacity` | `double` | `0.05` | Sàn opacity |
| `smoothing` | `Duration` | `200ms` | Hằng số thời gian ease |
| `inset` | `double` | `80` | Khoảng cách từ mép neo tới chữ |
| `loop` | `bool` | `false` | Quay vòng |
| `draggable` | `bool` | `true` | Cho kéo dọc |
| `textStyle` | `TextStyle?` | `null` | Style nền (color/weight/size vẫn do wheel) |

`OptionWheelState` (qua `GlobalKey`): `selected`, `select(index)`.

## Caveats

- `blur > 0` tốn một saveLayer (`ImageFiltered`) **mỗi entry mỗi frame** khi
  đang quay — list dài trên máy yếu nên đặt `blur: 0`.
- Entry đã mờ hết và nằm ngoài khung thì skip hẳn (không layout) — list rất
  dài vẫn ổn, nhưng mỗi frame đang quay vẫn rebuild các entry thấy được.
- Chữ đổi weight w200 ↔ w500 khi đổi selection làm metrics nhảy nhẹ (bản
  gốc cũng vậy).
- Cost thật trên thiết bị: chưa đo.

## Changelog

- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `OptionWheel` vào project này.

**Context**
- Chức năng: picker dọc dạng vòng cung, kéo/tap/scroll để chọn (port
  react-bits, adapted).
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `option_wheel/` (1 file), import
  duy nhất `option_wheel.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `option_wheel/` vào thư mục widget của project đích.
2. Đặt trong khung có chiều cao xác định (Expanded/SizedBox), nối
   `onChanged` vào state của project.

**Việc cần adapt theo project đích**
- `textColor`/`activeColor` theo theme; `fontSize`/`inset` theo layout.
- Haptic: `onTick: HapticFeedback.selectionClick`.

**Rào (constraints)**
- KHÔNG sửa toán layout/smoothing bên trong. Chỉ đổi qua params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
