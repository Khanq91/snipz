---
# --- IDENTITY ---
id: gradient_waves
title: Gradient Waves
kind: paint
tags: [waves, gradient, animated, background, ocean]

# --- TAXONOMY (§2) ---
paint_source: painter
carriers_verified: []
carriers_failed: []
scale_aware: true

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: gradient_waves.dart
files:
  - gradient_waves.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

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
version: 1.0.0

# --- DERIVED (computed from Test History by verify.dart, do not hand-edit) ---
latest_known_good: null
last_verified: null
status: null

preview: null
---

# Gradient Waves

Animated ocean-like waves: stacked sine layers filled with a horizon→wave
gradient, fog-faded toward the back, crest highlight on each ridge. Dựng lại
ý tưởng "Gradient Waves" của react-bits — bản gốc là WebGL raymarching; bản
này stylize bằng `CustomPainter` thuần (không `.frag`, không asset — luật 4).

**Không có factory `Shader`** — sóng là *geometry* (path hình sin thay đổi
theo thời gian), không biểu diễn được bằng `ui.Gradient.*` tĩnh. Thay vào đó
widget nhận `child` để làm nền cho card/button; demo có sẵn carrier mẫu.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `gradient_waves/` folder (1 dart file, see `files`)
- **Import:** `import 'gradient_waves/gradient_waves.dart';` — one line
- **Or:** `dart tools/export.dart gradient_waves` → zip + paste-ready block

Button carrier example:

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(28),
  child: SizedBox(
    width: 220,
    height: 56,
    child: GradientWaves(
      scale: 3.5, // small carrier → more periods (§9.1)
      child: const Center(child: Text('Get started')),
    ),
  ),
)
```

## API

`GradientWaves` widget:

| Param | Type | Default | Meaning |
|---|---|---|---|
| `scale` | `double` | `1.0` | Detail density (§9.1): wave periods across the width ≈ `1.5 × scale`. Button 48–56px dùng 3–4 |
| `horizonColor` | `Color` | `0xFF5227FF` | Sky/background; far layers fog toward it |
| `waveColor` | `Color` | `0xFFFF9FFC` | Body color of the front layer |
| `crestColor` | `Color` | white | Ridge highlight + sky tint |
| `layers` | `int` | `4` | Stacked wave layers (clamped 1..8) |
| `amplitude` | `double` | `1.0` | Wave height multiplier (relative to paint height) |
| `speed` | `double` | `1.0` | Animation tempo |
| `animate` | `bool` | `true` | External stop switch — `false` halts the ticker, no frames scheduled |
| `child` | `Widget?` | `null` | Foreground content on top of the waves |

## Caveats

- **Not the raymarched original.** React-bits dùng fragment-shader
  raymarching (fog 3D, camera parallax). Vault cấm `FragmentProgram` (luật
  4) nên đây là bản 2.5D layered — cùng vibe, không cùng kỹ thuật.
- Repaints every frame while `animate: true` (~48 segments × layers path
  points — rẻ trên Android hiện đại, nhưng đừng chạy 10 instance cùng lúc).
- No `Shader` factory → không áp lên text qua `ShaderMask` được. Muốn chữ
  gradient động thì dùng `spectrum_sweep`.
- Paint luôn phủ kín nền (sky gradient) — không có mode transparent.

## Changelog

- **1.0.0** (2026-08-18) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `GradientWaves` vào project này.

**Context**
- Chức năng: nền sóng gradient động (layered sine waves, crest highlight,
  fog), painter thuần — không shader file, không asset.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `gradient_waves/` (1 file),
  import duy nhất `gradient_waves.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `gradient_waves/` vào thư mục widget của project đích.
2. Fullscreen: đặt `GradientWaves()` dưới cùng một `Stack`. Card/button:
   bọc `ClipRRect` + `SizedBox`, truyền content qua `child` (xem ví dụ
   README).

**Việc cần adapt theo project đích**
- `horizonColor`/`waveColor`/`crestColor`: đổi sang palette của project.
- `scale`: carrier nhỏ dưới 100px → tăng lên 3–4 (§9.1).
- Màn hình tĩnh/ít pin: đặt `animate: false` khi widget offscreen.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
