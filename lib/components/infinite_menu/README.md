---
# --- IDENTITY ---
id: infinite_menu
title: Infinite Menu
kind: composite
tags: [menu, sphere, 3d, drag, gallery, interactive, images]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: infinite_menu.dart
files:
  - infinite_menu.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: adapted
source: https://github.com/DavidHDev/react-bits/blob/main/src/ts-tailwind/Components/InfiniteMenu/InfiniteMenu.tsx
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

# Infinite Menu

Quả cầu disc ảnh kéo-xoay vô hạn (port react-bits "InfiniteMenu"): 42 disc
đặt trên icosphere, kéo để xoay (arcball quaternion + quán tính), thả tay thì
disc gần nhất **snap** về chính diện thành item active; overlay hiện
title/description và nút hành động. Bản gốc là WebGL2 instanced rendering —
bản này dựng lại toàn bộ pipeline bằng **CustomPainter** (chiếu phối cảnh
CPU, depth-sort, vẽ ellipse ảnh), zero asset, zero dependency.

## Port notes

- Nguồn: `src/ts-tailwind/Components/InfiniteMenu/InfiniteMenu.tsx` — WebGL2
  thuần + `gl-matrix`, KHÔNG phải three.js. Thuật toán (icosphere subdivide-1
  spherize R=2, `ArcballControl` slerp/snap, camera dolly khi kéo, scale disc
  theo độ sâu `s = |z|/R·0.6 + 0.4`, `finalScale = s·0.25`) port gần như
  từng dòng → `origin: adapted`. Phần GL (VAO/instancing/atlas texture) thay
  bằng painter.
- **Toán giữ nguyên:** `ArcballControl` (kể cả arcball-projection với sheet
  hyperbolic ngoài cầu và cú flip trục x của GL), logic snap
  (`findNearestVertexIndex` + `snapTargetDirection`), camera dolly
  (`targetZ += vel·80 + 2.5` khi giữ tay, damping 5/7), timing rAF clamp 32ms.
  Quat/vec3 tự viết trong file (~120 dòng) để khỏi import `vector_math`.
- **Xấp xỉ so với GL:** (1) disc trong GL được uốn cong lên mặt cầu
  (re-normalize trong vertex shader) — bản này vẽ disc phẳng tiếp tuyến,
  chỉ khác ở góc nhìn xiên sát mép; (2) hiệu ứng smear theo vận tốc
  (vertex stretch) thay bằng scale dị hướng theo trục
  `cross(center, rotationAxis)` chiếu vào mặt disc — cùng hướng, hình dạng
  đơn giản hơn; (3) alpha theo độ sâu trong fragment shader thực tế KHÔNG
  hiển thị ở bản gốc (blending không bật) nên không port.
- **Ảnh:** atlas texture → mỗi item một `ImageProvider` (app cấp), crop
  vuông giữa + cover y như logic UV của fragment shader. Chưa load thì disc
  hiện placeholder xám.
- Bỏ: canvas/DOM, ResizeObserver (→ `LayoutBuilder`), `link` mở tab
  (→ callback `onPressed`), cursor grab/grabbing.
- Thêm so với gốc: ticker **tự dừng** khi cầu đã snap xong và đứng yên
  (bản gốc chạy rAF vĩnh viễn), `animate` để dừng từ ngoài (§9.2),
  `showOverlay` để tự dựng UI riêng, callbacks `onActiveItemChanged` /
  `onMovementChanged`.

## Install

```yaml
# no pub dependencies — Flutter SDK only
```

## Reuse

- **Copy:** file `infinite_menu.dart` (single file)
- **Import:** `import 'infinite_menu/infinite_menu.dart';`
- **Or:** `dart tools/export.dart infinite_menu` → zip + paste-ready block

```dart
InfiniteMenu(
  items: [
    for (final p in products)
      InfiniteMenuItem(
        image: NetworkImage(p.imageUrl),
        title: p.name,
        description: p.tagline,
        onPressed: () => openProduct(p),
      ),
  ],
)
```

Widget fill parent (cần bounded constraints). Nền mặc định đen như bản gốc —
`backgroundColor: Colors.transparent` để composite lên nền riêng.

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `items` | `List<InfiniteMenuItem>` | required | Ảnh + title + description + `onPressed` mỗi item |
| `scale` | `double` | `1.0` | Hệ số khoảng cách camera (`3·scale`) như bản gốc — to/nhỏ quả cầu. KHÔNG phải scale §9.1 |
| `animate` | `bool` | `true` | Stop switch — `false` đóng băng ticker + bỏ qua input |
| `showOverlay` | `bool` | `true` | Title/description/nút ↗ của item active |
| `backgroundColor` | `Color` | `Colors.black` | Nền (gốc clear đen opaque) |
| `textColor` | `Color` | `Colors.white` | Màu chữ overlay |
| `accentColor` | `Color` | `#00FFFF` | Nút hành động (gốc: cyan, viền đen 5px) |
| `titleStyle` / `descriptionStyle` | `TextStyle?` | null | Override style chữ overlay |
| `filterQuality` | `FilterQuality` | `medium` | Chất lượng scale ảnh disc |
| `onActiveItemChanged` | `ValueChanged<int>?` | null | Index item vừa snap về chính diện |
| `onMovementChanged` | `ValueChanged<bool>?` | null | Đang kéo/trôi hay đứng yên (gốc dùng để ẩn overlay) |

`InfiniteMenuItem`: `image` (ImageProvider, required), `title`, `description`,
`onPressed`.

## Caveats

- `kind: composite`, `paint_source: none` — nội dung là ảnh động theo input,
  không biểu diễn được bằng `ui.Shader`, không có factory ShaderMask.
- Per frame khi đang xoay: xoay 42 đỉnh + ~21 disc visible × (clip oval AA +
  `drawImageRect`). Cost thật trên Android tầm trung: **chưa đo**. Đứng yên
  thì ticker tự dừng → cost 0.
- Disc phẳng thay vì cong theo mặt cầu (xem Port notes) — khác biệt chỉ thấy
  ở disc sát mép nhìn xiên.
- 42 vị trí disc; item < 42 thì lặp (`index % items.length`) y như bản gốc.
  Ảnh nên vuông ~512px; ảnh chữ nhật bị crop vuông giữa.
- Overlay đặt text trái/phải theo tỉ lệ width — màn hình rất hẹp nên tự dựng
  overlay riêng (`showOverlay: false` + 2 callbacks).
- Kéo quá nhanh rồi thả: sphere trôi theo quán tính rồi mới snap — đúng hành
  vi gốc, không phải bug.
- **License gốc:** MIT + Commons Clause (react-bits) — dùng trong app/product
  thoải mái, KHÔNG được bán/redistribute bản thân component (kể cả bản port).

## Changelog

- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `InfiniteMenu` vào project này.

**Context**
- Chức năng: quả cầu disc ảnh kéo-xoay, thả tay snap item về chính diện
  (port react-bits "InfiniteMenu", WebGL2 → CustomPainter). Overlay
  title/description/nút hành động có sẵn, tắt được.
- Public API: xem bảng API trong README (`InfiniteMenu` + `InfiniteMenuItem`).
- Portability: single_file — copy `infinite_menu.dart`, import 1 dòng.
- Deps: không có pub package — Flutter SDK only. Không cần pubspec entry.

**Việc cần làm**
1. Copy `infinite_menu.dart` vào thư mục widget của project đích.
2. Đặt `InfiniteMenu(items: ...)` trong một parent có bounded constraints
   (Expanded/SizedBox/Positioned.fill). Mỗi item cần `ImageProvider`
   (NetworkImage/AssetImage/Memory...) — ảnh vuông đẹp nhất.
3. Gắn `onPressed` mỗi item (thay cho `link` của bản web).

**Việc cần adapt theo project đích**
- `accentColor`/`textColor`/`titleStyle` theo palette project.
- Màn hình có nền riêng: `backgroundColor: Colors.transparent`.
- Muốn UI active-item riêng: `showOverlay: false` + `onActiveItemChanged`
  + `onMovementChanged`.
- Ngoài viewport/tab ẩn: `animate: false` (ticker vốn tự dừng khi đứng yên,
  nhưng tắt hẳn vẫn sạch hơn).

**Rào (constraints)**
- KHÔNG sửa toán bên trong (`_ArcballControl`, hằng số snap/dolly/scale) —
  chúng là hành vi đặc trưng của component. Chỉnh qua params.
- KHÔNG thêm dependency (vector_math v.v.) — file cố ý tự đủ.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
