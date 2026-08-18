---
# --- IDENTITY ---
id: particle_field
title: Particle Field
kind: paint
tags: [particles, animated, background, interactive, starfield]

# --- TAXONOMY (§2) ---
paint_source: painter
carriers_verified: []
carriers_failed: []
scale_aware: true

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: particle_field.dart
files:
  - particle_field.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://reactbits.dev/backgrounds/particles
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

# Particle Field

Drifting particle field: mỗi hạt dao động sin với phase/tần số riêng, hạt
"sâu" hơn thì nhỏ và mờ hơn (depth giả lập), cả field parallax theo ngón tay
khi chạm. Dựng lại "Particles" của react-bits (gốc WebGL point sprites) bằng
`CustomPainter` 2D — layout hạt deterministic theo `seed`.

**Không có factory `Shader`** — particle động là hàng trăm primitive vẽ theo
thời gian, không phải một `ui.Gradient.*`. Transparent mặc định nên phủ lên
mọi nền; nhận `child` để làm backdrop cho card/button.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `particle_field/` folder (1 dart file, see `files`)
- **Import:** `import 'particle_field/particle_field.dart';` — one line
- **Or:** `dart tools/export.dart particle_field` → zip + paste-ready block

Card carrier example:

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(24),
  child: SizedBox(
    width: 320,
    height: 180,
    child: ParticleField(
      scale: 2, // density is per-area — small carriers just need a bump
      backgroundColor: const Color(0xFF141024),
      child: const Center(child: Text('Card content')),
    ),
  ),
)
```

## API

`ParticleField` widget:

| Param | Type | Default | Meaning |
|---|---|---|---|
| `scale` | `double` | `1.0` | Detail density (§9.1): multiplies `density` |
| `density` | `double` | `6.0` | Particles per 10,000 logical px² (≈170 fullscreen) |
| `maxParticles` | `int` | `400` | Hard cap (perf guard) |
| `colors` | `List<Color>` | `[white]` | Palette, picked per particle at spawn |
| `baseSize` | `double` | `2.6` | Radius (px) of a front-most particle |
| `sizeRandomness` | `double` | `1.0` | 0 = uniform, 1 ≈ 0.3×–1.8× variation |
| `driftAmplitude` | `double` | `14.0` | Max sinusoidal drift (px, scaled by depth) |
| `speed` | `double` | `1.0` | Animation tempo |
| `twinkle` | `bool` | `true` | Slow per-particle opacity shimmer |
| `softParticles` | `bool` | `false` | Blurred dots (MaskFilter — costs perf) |
| `backgroundColor` | `Color?` | `null` | `null` = transparent overlay |
| `interactive` | `bool` | `true` | Parallax toward the touch point |
| `touchFactor` | `double` | `1.0` | Parallax strength |
| `seed` | `int` | `7` | Deterministic layout seed |
| `animate` | `bool` | `true` | External stop switch — halts the ticker |
| `child` | `Widget?` | `null` | Foreground content |

## Caveats

- Repaints every frame while `animate: true`. ~170 `drawCircle`/frame là rẻ;
  `softParticles: true` thêm MaskFilter blur cho mọi hạt — bật thì giữ count
  thấp trên máy yếu.
- `interactive` dùng `Listener` translucent: không nuốt tap của `child`,
  nhưng field nằm trong scrollable thì pointer-move của scroll cũng kéo
  parallax (chấp nhận được, hoặc tắt `interactive`).
- Hạt trôi tự do có thể ló ra sát mép — carrier bo góc nhớ bọc `ClipRRect`.
- Không có factory `Shader` → không áp lên text qua `ShaderMask`.

## Changelog

- **1.0.0** (2026-08-18) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `ParticleField` vào project này.

**Context**
- Chức năng: nền hạt trôi động, depth giả lập, parallax theo touch; painter
  thuần, transparent mặc định, layout deterministic theo seed.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `particle_field/` (1 file),
  import duy nhất `particle_field.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `particle_field/` vào thư mục widget của project đích.
2. Overlay lên nền có sẵn: đặt `ParticleField()` trong `Stack` (transparent
   mặc định). Làm nền card/button: bọc `ClipRRect` + truyền `child`.

**Việc cần adapt theo project đích**
- `colors` + `backgroundColor`: đổi sang palette của project.
- Máy yếu / nhiều instance: giảm `density` hoặc `maxParticles`, tắt
  `twinkle`, giữ `softParticles: false`.
- Widget offscreen: đặt `animate: false` để ngừng schedule frame.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
