---
# --- IDENTITY ---
id: pixel_blast
title: Pixel Blast
kind: paint
tags: [pixel, dither, ripple, interactive, animated, background, shader]

# --- TAXONOMY (§2) ---
paint_source: shader
carriers_verified: []
carriers_failed: []
scale_aware: true

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: folder_with_assets
entry: pixel_blast.dart
files:
  - pixel_blast.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required:
  - lib/components/pixel_blast/pixel_blast.frag

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://reactbits.dev/backgrounds/pixel-blast
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

# Pixel Blast

Port shader gốc của react-bits "Pixel Blast": pattern pixel 4 hình (vuông/
tròn/tam giác/thoi) sinh từ FBM noise, dither bằng ma trận Bayer, **tap tạo
ripple** vòng sáng lan ra (tối đa 10 đồng thời, ring buffer). Qua
`FragmentProgram` + file `pixel_blast.frag` đi kèm. Transparent mặc định —
phủ lên nền nào cũng được.

Khác bản gốc (ghi trong header `.frag`): `fwidth` không có trong Flutter
runtime effects → AA hằng số theo `pixelSize`; hiệu ứng **liquid** (touch
trail distortion) KHÔNG port được — nó cần touch-trail texture + render-to-
texture pass, ngoài khả năng một fragment shader đơn; noise post-process thì
fold thẳng vào shader chính (`noiseAmount`).

## Install

```yaml
# no pub dependencies — Flutter SDK only, BUT the shader must be declared:
flutter:
  shaders:
    - lib/components/pixel_blast/pixel_blast.frag
```

Đặt folder ở chỗ khác → đổi path trong `shaders:` và truyền `assetKey`
tương ứng cho widget/`loadPixelBlastProgram`.

## Reuse

- **Copy:** the whole `pixel_blast/` folder (1 dart + 1 frag, see `files` +
  `shaders_required`)
- **Import:** `import 'pixel_blast/pixel_blast.dart';` — one line
- **Or:** `dart tools/export.dart pixel_blast` → zip + paste-ready block

Fill nền: `PixelBlast()` (tap để ripple). Carrier khác qua `ShaderMask` —
factory trả `ui.Shader` thật (§2.3):

```dart
final program = await loadPixelBlastProgram(); // once

ShaderMask(
  blendMode: BlendMode.srcIn,
  shaderCallback: (bounds) => createPixelBlastShader(
    program,
    bounds,
    time: t, // seconds — rebuild to animate
    scale: 2, // small carrier → more pattern variation (§9.1)
    edgeFade: 0, // carriers usually want no vignette
  ),
  child: const Text('PIXELS'),
)
```

## API

`createPixelBlastShader(program, bounds, {...})` — the primary API.
`configurePixelBlastShader(shader, size, {...})` — same params, reuses one
shader instance (per-frame cheap path). `PixelBlast` widget — fills bounds,
own clock + tap ripples, optional `child`.

| Param | Type | Default | Meaning |
|---|---|---|---|
| `scale` | `double` | `1.0` | Detail density (§9.1): nhân vào `patternScale` |
| `variant` | `PixelBlastVariant` | `square` | square \| circle \| triangle \| diamond |
| `color` | `Color` | `0xFFB497CF` | Màu pixel (sRGB, dùng thẳng) |
| `pixelSize` | `double` | `3` | Cạnh pixel dither (logical px) |
| `patternScale` | `double` | `2` | Cỡ feature FBM |
| `patternDensity` | `double` | `1` | Bias độ phủ pattern |
| `pixelSizeJitter` | `double` | `0` | Jitter coverage ngẫu nhiên per-pixel |
| `enableRipples` | `bool` | `true` | Tap sinh vòng ripple |
| `rippleSpeed` | `double` | `0.3` | Tốc độ lan |
| `rippleThickness` | `double` | `0.1` | Độ dày vòng |
| `rippleIntensityScale` | `double` | `1` | Cường độ |
| `edgeFade` | `double` | `0.5` | Vignette mép (0 = tắt) |
| `noiseAmount` | `double` | `0` | Film noise (từ post-process gốc) |
| `transparent` | `bool` | `true` | Premultiplied alpha / opaque nền đen |
| `speed` | `double` | `0.5` | Tempo |
| `timeOffset` | `double` | `0` | Lệch pha khởi đầu (gốc random hóa) |
| `animate` | `bool` | `true` | Stop switch — tắt ticker; tap vẫn repaint 1 lần |
| `program` / `assetKey` | — | null / vault path | Preload hoặc đổi vị trí .frag |

Ripple qua factory: truyền `ripples: [(position: Offset, time: double)]`
(tối đa 10, `time` = giá trị `time` shader lúc tap).

## Caveats

- **Cost per pixel:** FBM 5 octave (8 hash/octave) + 10 nhánh ripple ≈ nhẹ
  hơn raymarch nhiều; fullscreen 60fps ổn trên Android tầm trung (Impeller).
  Máy yếu: giảm bằng `animate: false` khi offscreen — pattern chỉ đắt khi
  repaint.
- **Liquid không có** (xem đầu README) — đừng tìm prop `liquid*`.
- Cần `FragmentProgram` (Flutter 3.10+; vault tạo trên 3.44.5). Widget render
  trống 1 frame đầu khi program đang load.
- `transparent: true` xuất premultiplied alpha — compositing bình thường là
  đúng; đừng tự unpremultiply.
- Tap ripple dùng thời gian shader (`uTime`) — đổi `speed` giữa chừng làm
  ripple đang lan nhảy nhẹ (giống gốc nếu đổi prop giữa chừng).
- ShaderMask + text vẫn tốn `saveLayer` (§9.2) — của ShaderMask, không phải
  shader này.

## Changelog

- **1.0.0** (2026-08-18) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `PixelBlast` vào project này.

**Context**
- Chức năng: nền pixel dither FBM + tap ripples (port react-bits),
  FragmentProgram + file `pixel_blast.frag` đi kèm. Factory
  `createPixelBlastShader` trả `ui.Shader` cho ShaderMask; widget
  `PixelBlast` fill nền, transparent mặc định.
- Public API: xem bảng API trong README.
- Portability: folder_with_assets — copy cả folder `pixel_blast/` (1 dart +
  1 frag), import duy nhất `pixel_blast.dart`, VÀ khai báo `.frag` trong
  pubspec `shaders:` (xem Install).
- Deps: không có pub package — Flutter SDK only.

**Việc cần làm**
1. Copy folder `pixel_blast/` vào thư mục widget của project đích.
2. Thêm path `.frag` vào pubspec `shaders:` (path thật sau khi copy) và
   truyền `assetKey` nếu khác path mặc định trong `pixel_blast.dart`.
3. Overlay nền có sẵn: đặt `PixelBlast()` trong Stack (transparent mặc
   định). Carrier khác: `ShaderMask` + `createPixelBlastShader`.

**Việc cần adapt theo project đích**
- `color` sang palette của project; `variant` theo vibe (circle mềm nhất).
- Carrier nhỏ: tăng `scale`, đặt `edgeFade: 0` (§9.1).
- Màn hình tĩnh: `animate: false`.

**Rào (constraints)**
- KHÔNG sửa logic shader/dart bên trong. Chỉ đổi qua params.
- KHÔNG đổi thứ tự uniform trong `.frag` — Dart set theo index.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
