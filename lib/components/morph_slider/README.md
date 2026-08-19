---
# --- IDENTITY ---
id: morph_slider
title: Morph Slider
kind: composite
tags: [slider, carousel, shader, morph, image, swipe, animated]

# --- TAXONOMY (§2) ---
paint_source: shader
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: folder_with_assets
entry: morph_slider.dart
files:
  - morph_slider.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required:
  - lib/components/morph_slider/morph_slider.frag

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: adapted
source: https://github.com/DavidHDev/react-bits/blob/main/src/ts-tailwind/Components/MorphSlider/MorphSlider.tsx
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

# Morph Slider

Slider ảnh chạy shader: hai slide hòa vào nhau qua một trong bốn phép morph
GLSL — `melt` (fbm noise), `ripple` (sóng tròn từ điểm chạm), `shear` (cắt
lát ngang), `swirl` (xoáy tâm) — kèm chromatic aberration ở mép chuyển và
"drift" lắc nhẹ lúc nghỉ. Swipe ngang (kéo dở thì theo ngón tay, thả >40%
mới sang), mũi tên, chấm chỉ số, caption, autoplay. Port `adapted`: fragment
shader đi theo bản gốc gần như từng dòng.

## Port notes

- Nguồn: `src/ts-tailwind/Components/MorphSlider/MorphSlider.tsx` (OGL) —
  fragment shader port sang `morph_slider.frag` qua checklist: `texture2D` →
  `texture`, `gl_FragColor` → `out fragColor`, varying `vUv` →
  `FlutterFragCoord()/uResolution`, `uniform int uMode` → `float` (Flutter
  không cho int uniform), vòng fbm bound `#define FBM_STEPS 5`.
- Tọa độ gốc trên-trái (GL là dưới-trái): mọi mode đều đối xứng trục và
  `uPointer` truyền cùng hệ từ Dart nên toán không đổi.
- Giữ: cover-UV theo aspect từng ảnh, drag semantics (đổi hướng giữa chừng
  được, thả >0.4 commit / ngược lại revert 0.5s), reduced-motion (uReduce
  tắt displacement + aberration), overlay vignette.
- Bỏ: keyboard arrows, hover-pause autoplay (→ autoplay chỉ skip khi đang
  kéo/đang chuyển), WebGL context-lost, DPR cap.
- Thay: GSAP tween → `AnimationController` (`power2.inOut` → param `curve`,
  mặc định `Curves.easeInOut`); ảnh URL → `ImageProvider` (app tự chọn
  Network/Asset/Memory); thêm `paused` để tắt ticker drift khi ngoài
  viewport (§9.2).

## Install

```yaml
# no external pub dependencies — Flutter SDK only
# NHƯNG phải khai báo shader trong pubspec của project đích:
flutter:
  shaders:
    - <path tới>/morph_slider/morph_slider.frag
```

> Khai ở key **`shaders:`**, KHÔNG phải `assets:` — nhét nhầm vào `assets:`
> thì `FragmentProgram.fromAsset` fail im lặng (màn đen).

## Reuse

- **Copy:** the whole `morph_slider/` folder (1 dart file + `morph_slider.frag`)
- **Import:** `import 'morph_slider/morph_slider.dart';` — one line
- **Pubspec:** thêm dòng `shaders:` như trên, và nếu path folder khác thì
  sửa cả đường dẫn trong `FragmentProgram.fromAsset` ở đầu
  `morph_slider.dart` cho khớp.

```dart
AspectRatio(
  aspectRatio: 16 / 10,
  child: MorphSlider(
    items: [
      MorphSliderItem(image: NetworkImage(url1), caption: 'One'),
      MorphSliderItem(image: NetworkImage(url2), caption: 'Two'),
    ],
    transition: MorphTransition.ripple,
  ),
)
```

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `items` | `List<MorphSliderItem>` | required | Ảnh (`ImageProvider`) + caption |
| `startIndex` | `int` | `0` | Slide đầu |
| `transition` | `MorphTransition` | `melt` | melt / ripple / shear / swirl |
| `duration` | `Duration` | `1100ms` | Thời lượng một transition |
| `curve` | `Curve` | `easeInOut` | Ease transition |
| `intensity` | `double` | `0.55` | Độ mạnh displacement |
| `noiseScale` | `double` | `2.4` | Tần số noise của melt |
| `aberration` | `double` | `0.35` | Chromatic aberration ở mép chuyển |
| `drift` | `double` | `0.4` | Lắc idle; `0` = tắt cả ticker lúc nghỉ |
| `autoplay` | `bool` | `false` | Tự sang slide |
| `autoplayDelay` | `Duration` | `4s` | Nhịp autoplay |
| `loop` | `bool` | `true` | Quay vòng |
| `radius` | `double` | `16` | Bo góc khung |
| `overlayColor` | `Color` | đen | Màu vignette mép |
| `backgroundColor` | `Color` | `#0C0C0E` | Nền chờ ảnh decode |
| `showCaptions` / `showControls` / `showIndicators` | `bool` | `true` | Bật/tắt UI phủ |
| `paused` | `bool` | `false` | Tắt ticker drift (offscreen) |
| `onIndexChanged` | `ValueChanged<int>?` | `null` | Slide hiển thị đổi |

`MorphSliderState` (qua `GlobalKey`): `index`, `next()`, `prev()`,
`goTo(dir)`.

## Caveats

- **Cần `morph_slider.frag` trong pubspec `shaders:`** — thiếu là khung chỉ
  còn nền `backgroundColor`.
- `drift > 0` nghĩa là shader vẽ lại **mỗi frame kể cả lúc nghỉ** (wobble
  idle là tính năng của bản gốc). Tiết kiệm pin: `drift: 0` (ticker dừng
  hẳn giữa các transition) hoặc `paused: true` khi ngoài viewport.
- Shader mode `melt` gọi fbm (5 octave) 2 lần/pixel — fullscreen trên máy
  tầm trung nên để khung cỡ card thay vì full màn. Cost thật: chưa đo.
- Ảnh chưa decode xong: khung hiện `backgroundColor` (bản gốc hiện texture
  xám 4×4) — sang slide có ảnh chưa load sẽ thấy nền trơn tới khi decode
  xong.
- Không expose `CarrierShaderSpec` (§2.3): shader này cần 2 sampler ảnh +
  state transition, không phải paint độc lập áp lên carrier được.

## Changelog

- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `MorphSlider` vào project này.

**Context**
- Chức năng: slider ảnh chuyển cảnh bằng shader morph 4 chế độ (port
  react-bits, adapted).
- Public API: xem bảng API trong README.
- Portability: folder_with_assets — copy cả folder `morph_slider/` (1 dart +
  1 frag), import `morph_slider.dart`, **thêm dòng pubspec `shaders:`**.
- Deps pub: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `morph_slider/` vào thư mục widget của project đích.
2. Thêm vào pubspec: `flutter: shaders: - <path>/morph_slider.frag` (đúng
   key `shaders:`), sửa path trong `FragmentProgram.fromAsset` cho khớp.
3. Truyền `items` với `ImageProvider` thật; bọc khung có tỷ lệ
   (AspectRatio/SizedBox).

**Việc cần adapt theo project đích**
- `transition`/`duration`/`radius` theo motion spec.
- Trong list scroll: `paused: true` khi item ngoài viewport.

**Rào (constraints)**
- KHÔNG sửa file `.frag` (toán đi theo bản gốc). Chỉnh cảm giác qua params.
- KHÔNG tách entry file ra nhiều file.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
