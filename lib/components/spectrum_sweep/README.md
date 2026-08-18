---
# --- IDENTITY ---
id: spectrum_sweep
title: Spectrum Sweep
kind: paint
tags: [gradient, sweep, spectrum, shader]

# --- TAXONOMY (§2) ---
paint_source: shader
carriers_verified: [fullscreen, card, button, text]
carriers_failed:
  - icon: "7 màu quanh 24–48px alias thành vành nhiễu — mất bản chất spectrum"
scale_aware: true

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: spectrum_sweep.dart
files:
  - spectrum_sweep.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: original
source: null
author: "Khang"
license: null

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-18
created_flutter: 3.44.5
created_dart: 3.12.2
created_deps: []
platforms_initial: [android]

# --- COMPONENT VERSION ---
version: 1.0.0

# --- DERIVED (computed from Test History by verify.dart, do not hand-edit) ---
latest_known_good: 3.44.5
last_verified: 2026-08-18
status: verified

preview: null
---

# Spectrum Sweep

Seamless angular spectrum gradient built on `ui.Gradient.sweep` — a real
`Shader` with zero assets (decision #1). The primary API is the factory
`createSpectrumSweepShader(bounds, ...)`; per the §2.3 contract that means it
reaches **every** carrier (text included) through plain `ShaderMask` +
`BlendMode.srcIn`, no combinator files. `SpectrumSweep` is a convenience
widget for the fill case.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `spectrum_sweep/` folder (1 dart file, see `files`)
- **Import:** `import 'spectrum_sweep/spectrum_sweep.dart';` — one line
- **Or:** `dart tools/export.dart spectrum_sweep` → zip + paste-ready block

Text carrier example:

```dart
ShaderMask(
  blendMode: BlendMode.srcIn,
  shaderCallback: (bounds) => createSpectrumSweepShader(bounds),
  child: const Text('SPECTRUM'),
)
```

## API

`createSpectrumSweepShader(Rect bounds, {...})` — the primary API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `bounds` | `Rect` | required | Sweep centers on `bounds.center` |
| `scale` | `double` | `1.0` | Detail density (§9.1): full color cycles around the circle, rounded to a whole number so the seam never shows |
| `rotation` | `double` | `0` | Radians; spin the sweep (animate externally) |
| `colors` | `List<Color>?` | spectrum palette | Palette, cycled `scale` times |

`SpectrumSweep` widget: same `scale` / `rotation` / `colors`, fills its bounds.

## Carriers

Verified qua carrier switcher của app (widget test
`test/carrier_switcher_test.dart` — không cần `carrierBuilders`, chỉ dùng
factory §2.3).

| Carrier | Result | Note |
|---|---|---|
| fullscreen | pass | demo mặc định |
| card | pass | — |
| button | pass | — |
| text | pass | ShaderMask + srcIn; saveLayer mỗi frame (§9.2) — switcher chỉ render khi tap chip |
| border | untested | — |
| icon | fail | 7 màu quanh 24–48px alias thành vành nhiễu — mất bản chất spectrum |
| divider | untested | — |

## Caveats

- Static shader — costs nothing per frame until you animate `rotation`
  yourself (rebuilds the shader each frame; fine, sweep creation is cheap).
- On tiny carriers (icon) many cycles alias into stripes — keep `scale: 1`
  below ~48px.
- Text masking still pays the usual `saveLayer` (§9.2) — that cost belongs to
  `ShaderMask`, not this shader.

## Changelog

- **1.0.0** (2026-08-18) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|
| 2026-08-18 | 3.44.5 | 3.12.2 | — | android | pass | initial: analyze + tests clean |

## AI Integration Prompt

Tích hợp component `SpectrumSweep` vào project này.

**Context**
- Chức năng: sweep gradient phổ màu liền mạch, expose factory trả `Shader`
  thật (`createSpectrumSweepShader`) + widget wrapper `SpectrumSweep`.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `spectrum_sweep/` (1 file),
  import duy nhất `spectrum_sweep.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `spectrum_sweep/` vào thư mục widget của project đích.
2. Fill nền: dùng `SpectrumSweep`. Áp lên text/border/icon: dùng
   `ShaderMask` + `createSpectrumSweepShader` như ví dụ trong README.

**Việc cần adapt theo project đích**
- `colors`: đổi sang palette của project (giữ màu đầu = màu cuối tự động).
- `scale`: vùng nhỏ dưới 48px giữ `1`.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor/factory params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
