---
# --- IDENTITY ---
id: dock
title: Dock
kind: composite
tags: [dock, magnify, spring, toolbar, navigation, interactive]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: dock.dart
files:
  - dock.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/DavidHDev/react-bits/blob/main/src/ts-tailwind/Components/Dock/Dock.tsx
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

# Dock

Dock phóng đại kiểu macOS: giữ ngón tay và rê ngang thanh dock, item gần
điểm chạm phồng từ `baseItemSize` lên `magnification`, size settle qua lò xo
(mass 0.1, stiffness 150, damping 12 — đúng hằng số bản gốc). Item đang chỉ
hiện label phía trên; nhả tay trên item nào thì kích hoạt item đó (tap thẳng
cũng được). Dựng lại "Dock" của react-bits (motion/react springs → Ticker +
tích phân lò xo tay).

## Port notes

- Nguồn: `src/ts-tailwind/Components/Dock/Dock.tsx`.
- Giữ: map khoảng-cách→size tuyến tính trên `[-distance, 0, distance]`, hằng
  số spring, style item (tròn, nền `#120F17`, viền neutral-700), label pill
  phía trên item.
- Bỏ: outer container tự cao lên khi hover (đẩy layout trang — jank trên
  mobile), keyboard focus/Enter (Android).
- Thay: **hover chuột → touch**: magnification bám điểm chạm khi ngón tay
  đè/rê trên thanh (đây là phần hồn của component nên map sang touch thay vì
  bỏ); nhả tay trên item = click. Tâm item tính từ size đang animate (giống
  layout DOM tự đẩy nhau), không đọc RenderBox.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `dock/` folder (1 dart file, see `files`)
- **Import:** `import 'dock/dock.dart';` — one line
- **Or:** `dart tools/export.dart dock` → zip + paste-ready block

```dart
Dock(
  items: [
    DockItemData(
      icon: Icon(Icons.home, color: Colors.white),
      label: 'Home',
      onPressed: () => go('/'),
    ),
    // ...
  ],
)
```

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `items` | `List<DockItemData>` | required | icon + label + onPressed |
| `distance` | `double` | `200` | Bán kính ảnh hưởng của điểm chạm |
| `baseItemSize` | `double` | `50` | Đường kính item lúc nghỉ |
| `magnification` | `double` | `70` | Đường kính ngay dưới điểm chạm |
| `panelHeight` | `double` | `64` | Chiều cao thanh |
| `itemGap` | `double` | `16` | Khoảng cách item |
| `stiffness` / `damping` / `mass` | `double` | `150`/`12`/`0.1` | Hằng số lò xo |
| `backgroundColor` | `Color` | trong suốt | Nền thanh |
| `itemColor` | `Color` | `#120F17` | Nền item + label |
| `borderColor` | `Color` | `#404040` | Viền thanh/item/label |
| `labelStyle` | `TextStyle?` | trắng 12 | Style label |

## Caveats

- Widget tự cao `magnification + 36` (chỗ cho item phồng + label); item vẽ
  tràn lên trên thanh qua `OverflowBox` — đừng bọc trực tiếp trong ClipRect
  sát mép trên.
- Ticker chỉ chạy khi có ngón tay đè hoặc lò xo chưa settle — đứng yên không
  tốn frame.
- Spring underdamped chủ đích (giống bản gốc) — item rung nhẹ khi settle.
  Muốn tắt: tăng `damping` (~2·√(stiffness·mass) là critically damped).
- Label đặt theo tâm item, item sát mép có thể tràn label ra ngoài panel một
  chút (bản gốc cũng vậy).

## Changelog

- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `Dock` vào project này.

**Context**
- Chức năng: dock phóng đại theo điểm chạm với spring vật lý (port
  react-bits, hover→touch).
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `dock/` (1 file), import duy
  nhất `dock.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `dock/` vào thư mục widget của project đích.
2. Đặt cuối màn hình (bottomNavigationBar hoặc Stack + Positioned bottom),
   truyền `items` với callback điều hướng thật.

**Việc cần adapt theo project đích**
- `itemColor`/`borderColor` theo theme; icon theo bộ icon của project.
- Số item nhiều → giảm `baseItemSize`/`itemGap` cho vừa bề ngang.

**Rào (constraints)**
- KHÔNG sửa tích phân lò xo bên trong. Chỉnh cảm giác qua
  `stiffness`/`damping`/`mass`.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
