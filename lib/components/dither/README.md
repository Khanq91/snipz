---
# --- IDENTITY ---
id: dither
title: Dither Waves
kind: paint
tags: [dither, retro, pixel, waves, noise, animated, background, shader]

# --- TAXONOMY (§2) ---
paint_source: shader
carriers_verified: []
carriers_failed: []
scale_aware: true

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: folder_with_assets
entry: dither.dart
files:
  - dither.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required:
  - lib/components/dither/dither.frag

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: adapted
source: https://github.com/DavidHDev/react-bits/blob/main/src/ts-tailwind/Backgrounds/Dither/Dither.tsx
author: "Khang"
license: "MIT + Commons Clause License Condition v1.0 (react-bits, © David Haz)"

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

# Dither Waves

Port GLSL gốc của react-bits "Dither": sóng Perlin fbm (domain-warp) quantize
qua ma trận Bayer 8×8 thành look retro-CRT. Bản gốc render 2 pass (wave →
dither postprocess); vì wave là procedural nên hai pass gộp thành **một**
`.frag` — kết quả pixel-identical. Qua `FragmentProgram` + file `dither.frag`
đi kèm. Opaque (mix từ đen) — dùng làm nền, không phải overlay.

## Port notes

- Nguồn: `src/ts-tailwind/Backgrounds/Dither/Dither.tsx` (three.js/R3F chỉ là
  fullscreen quad + EffectComposer — toàn bộ visual nằm trong 2 chuỗi GLSL,
  nên đi chế độ shader thay vì báo "three.js không đáng port").
- Gộp pass: `texture2D(inputBuffer, uvPixel)` = evaluate wave tại `uvPixel`.
- Bỏ: mouse hover interaction (`mousePos`/`mouseRadius`/`enableMouseInteraction`)
  — Android không có hover; `disableAnimation` → param `animate` (đảo nghĩa).
- `const float[64]` Bayer table → công thức closed-form per-bit (runtime
  effects + const array không đáng tin) — giá trị giống hệt.
- `uv.y` flip một lần cho khớp hướng GL của bản gốc.
- Thêm `uScale` (§9.1) — bản gốc không có.

## Install

```yaml
# no pub dependencies — Flutter SDK only, BUT the shader must be declared:
flutter:
  shaders:
    - lib/components/dither/dither.frag
```

Đặt folder ở chỗ khác → đổi path trong `shaders:` và truyền `assetKey`
tương ứng cho widget/`loadDitherProgram`. Nhét nhầm vào `assets:` thì
`FragmentProgram.fromAsset` fail im lặng.

## Reuse

- **Copy:** the whole `dither/` folder (1 dart + 1 frag, see `files` +
  `shaders_required`)
- **Import:** `import 'dither/dither.dart';` — one line
- **Or:** `dart tools/export.dart dither` → zip + paste-ready block

Fill nền: `DitherWaves()`. Carrier khác qua `ShaderMask` — factory trả
`ui.Shader` thật (§2.3):

```dart
final program = await loadDitherProgram(); // once

ShaderMask(
  blendMode: BlendMode.srcIn,
  shaderCallback: (bounds) => createDitherShader(
    program,
    bounds,
    time: t, // seconds — rebuild to animate
    scale: 3, // small carrier → more wave detail (§9.1)
  ),
  child: const Text('RETRO'),
)
```

## API

`createDitherShader(program, bounds, {...})` — the primary API.
`configureDitherShader(shader, size, {...})` — same params, reuses one
shader instance (per-frame cheap path). `DitherWaves` widget — fills bounds,
own clock, optional `child`.

| Param | Type | Default | Meaning |
|---|---|---|---|
| `scale` | `double` | `1.0` | Detail density (§9.1): nhân domain noise |
| `waveSpeed` | `double` | `0.05` | Tốc độ trôi sóng |
| `waveFrequency` | `double` | `3` | FBM lacunarity (octave sau mịn hơn bao nhiêu) |
| `waveAmplitude` | `double` | `0.3` | FBM gain (octave sau đóng góp bao nhiêu) |
| `waveColor` | `Color` | `0xFF808080` | Màu đỉnh sóng (mix từ đen) |
| `colorNum` | `double` | `4` | Số mức quantize mỗi kênh (clamp ≥ 2) |
| `pixelSize` | `double` | `2` | Cạnh cell dither/pixelate (logical px) |
| `animate` | `bool` | `true` | Stop switch — tắt ticker, giữ phase |
| `program` / `assetKey` | — | null / vault path | Preload hoặc đổi vị trí .frag |

## Caveats

- **Cost per pixel:** 4 octave Perlin × 2 lần fbm (domain warp) = 8 lần
  cnoise/pixel — nặng hơn hash noise nhưng không raymarch. Fullscreen trên
  Android tầm trung: chưa đo. Máy yếu: tăng `pixelSize` KHÔNG giảm cost
  (mỗi device pixel vẫn evaluate); giảm bằng `animate: false` khi tĩnh.
- Opaque, không có mode transparent — bản gốc mix từ đen. Muốn overlay lên
  nền khác thì dùng ShaderMask/BlendMode ở tầng app.
- Mouse-follow của bản web KHÔNG port (xem Port notes) — không có prop tương ứng.
- `colorNum` < 2 bị clamp (chia cho 0); `pixelSize` < 1 bị clamp.
- Cần `FragmentProgram` (Flutter 3.10+; vault tạo trên 3.44.5). Widget render
  trống 1 frame đầu khi program đang load.
- **License gốc:** MIT + Commons Clause (react-bits) — dùng trong app/product
  thoải mái, KHÔNG được bán/redistribute bản thân component (kể cả bản port).

## Changelog

- **1.0.0** (2026-08-18) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `DitherWaves` vào project này.

**Context**
- Chức năng: nền sóng noise retro dither Bayer 8×8 (port react-bits
  "Dither"), FragmentProgram + file `dither.frag` đi kèm. Factory
  `createDitherShader` trả `ui.Shader` cho ShaderMask; widget `DitherWaves`
  fill nền, opaque.
- Public API: xem bảng API trong README.
- Portability: folder_with_assets — copy cả folder `dither/` (1 dart +
  1 frag), import duy nhất `dither.dart`, VÀ khai báo `.frag` trong pubspec
  `shaders:` (xem Install).
- Deps: không có pub package — Flutter SDK only.

**Việc cần làm**
1. Copy folder `dither/` vào thư mục widget của project đích.
2. Thêm path `.frag` vào pubspec `shaders:` (path thật sau khi copy) và
   truyền `assetKey` nếu khác path mặc định trong `dither.dart`.
3. Nền màn hình: đặt `DitherWaves()` dưới cùng Stack (opaque). Carrier khác:
   `ShaderMask` + `createDitherShader`.

**Việc cần adapt theo project đích**
- `waveColor` sang palette project; `colorNum` thấp (2–3) = retro gắt hơn.
- Carrier nhỏ: tăng `scale` (§9.1).
- Màn hình tĩnh: `animate: false`.

**Rào (constraints)**
- KHÔNG sửa logic shader/dart bên trong. Chỉ đổi qua params.
- KHÔNG đổi thứ tự uniform trong `.frag` — Dart set theo index.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
