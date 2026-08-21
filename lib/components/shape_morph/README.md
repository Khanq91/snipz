---
# --- IDENTITY ---
id: shape_morph
title: Shape Morph
kind: composite
tags: [shape, morph, blob, vector, path, clip, animated, radial]

# --- TAXONOMY (§2) ---
paint_source: painter
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: shape_morph.dart
files:
  - shape_morph.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: adapted
source: https://github.com/jeremy-prt/bloub
author: "Khang"
license: "MIT (bloub, © 2026 Jérémy Perret)"

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-21
created_flutter: 3.47.1
created_dart: 3.13.1
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

# Shape Morph

Morph vector giữa các hình bất kỳ **không cần package**: mọi hình đi qua
"radial profile" 64 mẫu `r(theta)` — hai hình bất kỳ có điểm tương ứng 1-1,
nên morph chỉ là lerp 64 con số (kỹ thuật lõi của bloub, engine avatar x.ai).
Kèm bộ dựng hình: circle, superellipse/squircle, đa giác đều bo góc
(Minkowski), polygon tùy ý (ray-cast), union đĩa tròn (blob/mây), capsule
hull. `ShapeMorph` vẽ trực tiếp, `RadialShapeClipper` clip child bất kỳ,
`RadialShapeTween` cắm vào `AnimationController`.

## Port notes

- Nguồn: `src/bot/shape.ts` của bloub — port 1:1 `blend` (lerp radii + rot
  theo cung ngắn nhất), `toPoints` (rot → squash màn hình → translate, đúng
  thứ tự đó), `closedPath` (Catmull-Rom tension 1/6 → `cubicTo`),
  `profileFromPolygon`, `hullOfCircles`, `superellipseProfile`,
  `unionOfCirclesProfile`, `regularPolygonProfile`, `radiusAtAngle`.
- Bỏ: `r2` (làm tròn chuỗi SVG — Flutter build `Path` số trực tiếp),
  `polyPath`/`capsulePath` (chuỗi SVG, thuộc phần bot).
- Thay: widget stateless nhận `t` thuần (quy ước sample(t)) thay vì tự giữ
  clock; thêm `RadialShape.sequence` để tua qua danh sách keyframe.

## Install

```yaml
# no external pub dependencies — Flutter SDK only
```

## Reuse

- **Copy:** file `shape_morph.dart` (single file)
- **Import:** `import 'shape_morph/shape_morph.dart';`

```dart
// Blob morph tự chạy: đưa t từ AnimationController vào widget.
AnimatedBuilder(
  animation: controller,
  builder: (context, _) => ShapeMorph(
    shapes: [RadialShape.circle(), RadialShape.superellipse(4)],
    t: controller.value,
    color: Colors.indigo,
  ),
)

// Clip ảnh theo hình hexagon bo góc:
ClipPath(
  clipper: RadialShapeClipper(
    RadialShape.regularPolygon(6, cornerRadius: 0.18, rotationDeg: -90),
  ),
  child: Image.network(url, fit: BoxFit.cover),
)
```

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `RadialShape(radii, {rot, cx, cy, sx, sy})` | ctor | — | 64 bán kính + pose; `sx/sy` squash ở tọa độ màn hình SAU rotation |
| `.circle([r])` / `.superellipse(n)` / `.regularPolygon(sides)` / `.polygon(points)` / `.unionOfCircles(circles)` / `.capsuleHull(...)` | factory | — | bộ dựng hình; ray-cast chạy MỘT lần lúc dựng |
| `RadialShape.lerp(a, b, t)` | static | — | morph; rotation đi cung ngắn nhất |
| `RadialShape.sequence(shapes, t, {loop})` | static | — | tua qua keyframes, `t ∈ [0, n-1]` (`[0, n]` khi loop) |
| `.toPath({radius, center, tension})` | method | tension `1/6` | Catmull-Rom → `Path`; tension 0 = cạnh thẳng |
| `.radiusAt(angle)` | method | — | bán kính theo hướng bất kỳ (neo badge lên biên) |
| `.normalized([max])` | method | `1` | đưa bán kính đỉnh về `max` để các hình "nặng" bằng nhau |
| `ShapeMorph(shapes:, t:, loop:, color:, fit:, tension:)` | widget | — | vẽ blob morph, stateless — thời gian vào qua `t` |
| `RadialShapeClipper(shape, {fit, tension})` | clipper | — | clip child bất kỳ |
| `RadialShapeTween` | tween | — | dùng với `AnimationController` |

## Caveats

- Giới hạn bản chất của `r(theta)`: hình phải **star-convex** (mọi tia từ tâm
  cắt biên đúng một lần). Hình khác đi qua `.polygon()` — ray-cast giữ giao
  điểm XA NHẤT, tức một xấp xỉ.
- `unionOfCircles` chỉ chính xác khi gốc tọa độ nằm TRONG union.
- Mỗi lần đổi `t` là một lần build `Path` (64 cubic) — rẻ, nhưng đừng gọi
  `toPath` nhiều lần cho cùng một frame; blend trước bằng `sequence`/`lerp`
  rồi vẽ một lần.

## Changelog

- `1.0.0` — created (port từ bloub `shape.ts`).
