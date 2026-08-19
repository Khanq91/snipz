---
# --- IDENTITY ---
id: fluid_glass
title: Fluid Glass
kind: effect
tags: [glass, lens, magnifier, refraction, touch, navbar]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: fluid_glass.dart
files:
  - fluid_glass.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/DavidHDev/react-bits/blob/main/src/ts-tailwind/Components/FluidGlass/FluidGlass.tsx
author: "Khang"
license: MIT

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

# Fluid Glass

Kính "lỏng" trượt trên content bất kỳ: lens tròn / cube bo góc lướt theo
ngón tay (exponential damp — cảm giác `easing.damp3(…, 0.15)` của bản gốc),
hoặc thanh bar kính ghim đáy làm navbar. Kính **phóng đại thật** phần content
bên dưới (`RawMagnifier`) + rim highlight, sheen và shadow vẽ procedural.
Content dưới kính vẫn tương tác bình thường (layer kính xuyên pointer).

## Port notes

- Nguồn tham khảo: `src/ts-tailwind/Components/FluidGlass/FluidGlass.tsx` —
  bản gốc là **three.js**: load GLB mesh (lens/bar/cube), render scene vào
  FBO rồi khúc xạ qua `MeshTransmissionMaterial` + `ScrollControls`.
  **Không port thẳng được** trong luật vault (asset GLB + engine 3D); đây là
  bản `reimplemented` 2D chỉ lấy cái hồn: kính follow-pointer phóng đại
  content, ba mode giữ nguyên tên (`lens`/`bar`/`cube`).
- Giữ: ba mode, follow-pointer với damp 0.15s, bar ghim đáy không follow
  (lockToBottom + followPointer:false của gốc), navItems → slot `barChild`.
- Bỏ: refraction 3D thật, chromatic aberration, scroll scene/Images/
  Typography demo nội bộ (content là `child` của app), mouse hover (→ touch
  đè/rê).
- Khác gốc: phóng đại **đều** (uniform), không cong ở mép — muốn edge
  refraction thật phải viết `.frag` riêng (ghi ở Caveats).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `fluid_glass/` folder (1 dart file, see `files`)
- **Import:** `import 'fluid_glass/fluid_glass.dart';` — one line
- **Or:** `dart tools/export.dart fluid_glass` → zip + paste-ready block

```dart
// Lens theo ngón tay trên một poster
FluidGlass(child: PosterContent())

// Navbar kính ghim đáy
FluidGlass(
  mode: FluidGlassMode.bar,
  magnification: 1.08,
  barChild: Row(mainAxisSize: MainAxisSize.min, children: navButtons),
  child: PageContent(),
)
```

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `child` | `Widget` | required | Content dưới kính (vẫn tương tác được) |
| `mode` | `FluidGlassMode` | `lens` | `lens` / `cube` (follow touch) / `bar` (ghim đáy) |
| `lensSize` | `double` | `140` | Đường kính lens (cạnh cube) |
| `magnification` | `double` | `1.25` | Tỷ lệ phóng đại qua kính |
| `smoothing` | `double` | `0.15` | Hằng số thời gian (giây) lướt theo ngón tay; 0 = bám thô |
| `barHeight` | `double` | `56` | Cao bar |
| `barMargin` | `double` | `12` | Cách mép đáy |
| `barWidthFactor` | `double` | `0.92` | Bề ngang bar theo % khung |
| `barChild` | `Widget?` | `null` | Nội dung trong bar (nav row), nhận tap |
| `shadow` | `bool` | `true` | Bóng đổ dưới kính |
| `rimOpacity` | `double` | `1` | Độ đậm rim/sheen (0 = kính trần) |

## Caveats

- **Không phải refraction thật** — `RawMagnifier` phóng đại đều, mép không
  cong, không chromatic aberration. Đây là look-alike 2D của mode lens demo;
  bản gốc là 3D transmission material.
- `RawMagnifier` chụp mọi thứ vẽ **trước nó** trong scene — vì vậy shadow
  của kính được vẽ **phía trên và clip ra ngoài** hình kính (vẽ dưới là bị
  phóng đại làm tối content). Đừng đổi thứ tự layer khi sửa.
- Backend Impeller: magnifier là một backdrop layer mỗi frame — một kính thì
  ổn, đừng xếp nhiều `FluidGlass` chồng nhau. Cost thật trên thiết bị: chưa
  đo.
- Widget cần bound xác định (fills parent qua LayoutBuilder).
- Kính chỉ di chuyển khi có pointer down/move; không có idle drift.

## Changelog

- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `FluidGlass` vào project này.

**Context**
- Chức năng: kính phóng đại follow-touch / navbar kính (reimplemented 2D từ
  ý tưởng FluidGlass của react-bits).
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `fluid_glass/` (1 file), import
  duy nhất `fluid_glass.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `fluid_glass/` vào thư mục widget của project đích.
2. Bọc content cần hiệu ứng: `FluidGlass(child: ...)`; mode `bar` thì truyền
   `barChild` là nav row thật.

**Việc cần adapt theo project đích**
- `magnification` nhẹ (~1.08) cho bar, đậm (~1.3) cho lens.
- `lensSize`/`barHeight` theo layout.

**Rào (constraints)**
- KHÔNG đổi thứ tự layer shadow/magnifier/rim (xem Caveats). Chỉ đổi qua
  params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
