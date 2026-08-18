---
# --- IDENTITY ---
id: gradient_waves
title: Gradient Waves
kind: paint
tags: [waves, gradient, animated, background, shader, raymarch]

# --- TAXONOMY (§2) ---
paint_source: shader
carriers_verified: []
carriers_failed: []
scale_aware: true

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: folder_with_assets
entry: gradient_waves.dart
files:
  - gradient_waves.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required:
  - lib/components/gradient_waves/gradient_waves.frag

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://reactbits.dev/backgrounds/gradient-waves
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-18
created_flutter: 3.44.5
created_dart: 3.12.2
created_deps: []
platforms_initial: [android]

# --- COMPONENT VERSION ---
version: 2.0.0

# --- DERIVED (computed from Test History by verify.dart, do not hand-edit) ---
latest_known_good: null
last_verified: null
status: null

preview: null
---

# Gradient Waves

Port 1:1 GLSL raymarch gốc của react-bits (plasma waves, fog 3D, camera
tilt/parallax, film grain) qua `FragmentProgram` + file `gradient_waves.frag`
đi kèm. Đây là bản trung thực — khác bản 1.x (layered sine painter) đã bị
thay thế. Drag trên màn hình = mouse-hover parallax của web.

Khác bản gốc: raymarch cap **64 steps** (gốc lên 110) cho GPU Android tầm
trung; `detail` chọn 24/40/64.

## Install

```yaml
# no pub dependencies — Flutter SDK only, BUT the shader must be declared:
flutter:
  shaders:
    - lib/components/gradient_waves/gradient_waves.frag
```

Đặt folder ở chỗ khác → đổi path trong `shaders:` và truyền `assetKey`
tương ứng cho widget/`loadGradientWavesProgram`.

## Reuse

- **Copy:** the whole `gradient_waves/` folder (1 dart + 1 frag, see `files`
  + `shaders_required`)
- **Import:** `import 'gradient_waves/gradient_waves.dart';` — one line
- **Or:** `dart tools/export.dart gradient_waves` → zip + paste-ready block

Fill nền: `GradientWaves()`. Carrier khác qua `ShaderMask` — factory trả
`ui.Shader` thật (§2.3):

```dart
final program = await loadGradientWavesProgram(); // once, app startup is fine

// Text carrier — animate by rebuilding with a growing `time`:
ShaderMask(
  blendMode: BlendMode.srcIn,
  shaderCallback: (bounds) => createGradientWavesShader(
    program,
    bounds,
    time: t, // seconds
    scale: 2, // small carrier → denser waves (§9.1)
  ),
  child: const Text('WAVES'),
)
```

## API

`createGradientWavesShader(program, bounds, {...})` — the primary API.
`configureGradientWavesShader(shader, size, {...})` — same params, reuses
one shader instance (per-frame cheap path). `GradientWaves` widget — fills
bounds, own clock + touch parallax, optional `child`.

| Param | Type | Default | Meaning |
|---|---|---|---|
| `scale` | `double` | `1.0` | Detail density (§9.1): nhân vào `waveScale` — carrier nhỏ tăng 2–3 |
| `horizonColor` | `Color` | `0xFF5227FF` | Nền trời / fog |
| `waveColor` | `Color` | `0xFFFF9FFC` | Thân sóng |
| `crestColor` | `Color` | trắng | Đỉnh sóng |
| `speed` | `double` | `0.4` | Tempo |
| `amplitude` | `double` | `2.5` | Chiều cao sóng (scene units) |
| `waveScale` | `double` | `0.6` | Tần số sóng |
| `waveRatio` | `double` | `0.9` | Tần số Y so với X |
| `swell` | `double` | `35` | Phình cong lớn |
| `turbulence` | `double` | `20` | Nhiễu loạn |
| `tilt` | `double` | `1.11` | Camera roll (rad) |
| `zoom` | `double` | `1.0` | FOV divisor |
| `height` | `double` | `5.5` | Offset dọc camera |
| `fogDepth` | `double` | `15` | Thấp = mù hơn |
| `detail` | `GradientWavesDetail` | `medium` | Steps 24/40/64 — xem Caveats |
| `brightness` / `opacity` | `double` | `1.0` | Output |
| `grain` / `grainIntensity` | `bool`/`double` | `true`/`0.05` | Film grain trên alpha (widget mặc định bật; factory mặc định tắt cho text sạch) |
| `touchParallax` / `parallaxStrength` | `bool`/`double` | `true`/`0.5` | Drag xoay camera (widget) |
| `animate` | `bool` | `true` | Stop switch — tắt ticker |
| `program` / `assetKey` | — | null / vault path | Preload hoặc đổi vị trí .frag |

## Caveats

- **Cost = steps × pixels, mỗi step một lần eval plasma.** Cap 64. Trên
  Android tầm trung (Impeller): fullscreen `medium` (40) là mức an toàn;
  `high` (64) chỉ nên dùng cho vùng nhỏ hoặc flagship; máy yếu/màn 120Hz
  → `low` (24) hoặc `animate: false` (raymarch chỉ chạy khi repaint).
- Cần Flutter hỗ trợ `FragmentProgram` (3.10+; vault tạo trên 3.44.5).
  Widget hiện `horizonColor` phẳng đúng 1 frame đầu khi program đang load.
- Output **premultiplied alpha** (giống bản gốc) — compositing bình thường
  là đúng; đừng đọc raw pixel rồi tự unpremultiply.
- ShaderMask + text vẫn tốn `saveLayer` (§9.2) — của ShaderMask, không phải
  shader này.
- Grain hash theo logical px (gốc theo physical px) — hạt to hơn chút trên
  màn dpr cao; muốn tắt: `grain: false`.
- Liquid-crisp AA của bản web (dpr 2) phụ thuộc resolution thiết bị —
  không có MSAA option.

## Changelog

- **2.0.0** (2026-08-18) — thay bản stylized painter bằng port GLSL raymarch
  gốc qua FragmentProgram; thêm factory `ui.Shader` (§2.3), grain, zoom/
  tilt/swell/turbulence/fog đầy đủ theo props web. API painter cũ bị bỏ.
- **1.0.0** (2026-08-18) — created (layered sine painter, đã thay thế)

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `GradientWaves` vào project này.

**Context**
- Chức năng: nền sóng raymarch GLSL (port react-bits), FragmentProgram +
  file `gradient_waves.frag` đi kèm. Factory `createGradientWavesShader`
  trả `ui.Shader` cho ShaderMask; widget `GradientWaves` fill nền.
- Public API: xem bảng API trong README.
- Portability: folder_with_assets — copy cả folder `gradient_waves/`
  (1 dart + 1 frag), import duy nhất `gradient_waves.dart`, VÀ khai báo
  `.frag` trong pubspec `shaders:` (xem Install).
- Deps: không có pub package — Flutter SDK only.

**Việc cần làm**
1. Copy folder `gradient_waves/` vào thư mục widget của project đích.
2. Thêm path `.frag` vào pubspec `shaders:` (path thật sau khi copy) và
   truyền `assetKey` nếu khác path mặc định trong `gradient_waves.dart`.
3. Fullscreen: `GradientWaves()`. Text/carrier khác: `ShaderMask` +
   `createGradientWavesShader` (xem ví dụ README).

**Việc cần adapt theo project đích**
- 3 màu sang palette của project; `detail` theo tier thiết bị target.
- Carrier nhỏ: tăng `scale` 2–3 (§9.1).
- Màn hình tĩnh: `animate: false`.

**Rào (constraints)**
- KHÔNG sửa logic shader/dart bên trong. Chỉ đổi qua params.
- KHÔNG đổi thứ tự uniform trong `.frag` — Dart set theo index.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
