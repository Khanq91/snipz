---
# --- IDENTITY ---
id: reveal_list
title: Reveal List
kind: carrier
tags: [list, scroll, stagger, entrance, selection]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: reveal_list.dart
files:
  - reveal_list.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://reactbits.dev/components/animated-list
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

# Reveal List

List cuộn dọc: item pop-in (scale 0.7→1 + fade, `easeOutBack`) lần đầu nó lọt
≥50% viewport, batch đầu tiên chạy so le; tap để chọn (selection đưa ngược
vào `itemBuilder` để style); gradient fade ở mép trên/dưới khi còn nội dung
phía đó. Dựng lại "Animated List" của react-bits cho mobile — arrow-key
navigation của web thay bằng tap selection. Tên class là `RevealList` vì
Flutter SDK đã có `AnimatedList` (luật 6).

Mỗi item chỉ reveal **một lần** trong đời list — cuộn đi rồi cuộn lại không
replay (kể cả khi ListView recycle item).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `reveal_list/` folder (1 dart file, see `files`)
- **Import:** `import 'reveal_list/reveal_list.dart';` — one line
- **Or:** `dart tools/export.dart reveal_list` → zip + paste-ready block

```dart
RevealList(
  itemCount: items.length,
  edgeFadeColor: backdropColor, // match whatever is behind the list
  onItemSelected: (i) => openDetail(items[i]),
  itemBuilder: (context, i, selected) => MyTile(
    item: items[i],
    highlighted: selected,
  ),
)
```

## API

`RevealList` widget:

| Param | Type | Default | Meaning |
|---|---|---|---|
| `itemCount` | `int` | required | Số item |
| `itemBuilder` | `(context, index, selected) => Widget` | required | Item UI; `selected` = đang được chọn |
| `onItemSelected` | `ValueChanged<int>?` | `null` | Sau khi tap chọn |
| `initialSelectedIndex` | `int` | `-1` | `-1` = chưa chọn gì |
| `controller` | `ScrollController?` | `null` | Tự tạo/dispose nếu null |
| `padding` | `EdgeInsetsGeometry` | `all(16)` | Padding của ListView |
| `itemSpacing` | `double` | `12` | Khoảng cách giữa item |
| `physics` / `shrinkWrap` | — | mặc định | Passthrough xuống ListView |
| `showEdgeFades` | `bool` | `true` | Gradient mép trên/dưới |
| `edgeFadeColor` | `Color?` | scaffold bg | Màu fade — phải trùng backdrop |
| `edgeFadeHeight` | `double` | `90` | Chiều cao vùng fade |
| `entranceDuration` | `Duration` | `260ms` | Một entrance |
| `entranceStagger` | `Duration` | `80ms` | Delay/item cho batch đầu |
| `visibleFraction` | `double` | `0.5` | Phần item phải lọt viewport để trigger |

## Caveats

- Chỉ scroll dọc. Item chưa reveal vẫn chiếm chỗ layout (opacity 0) — đúng
  chủ đích để scroll extent ổn định.
- Edge fade là overlay màu đặc → `edgeFadeColor` phải trùng màu nền sau
  list, không thì lộ vệt (mặc định lấy `Theme.of(context).scaffoldBackgroundColor`).
- Visibility check chạy mỗi scroll notification (đo `RenderBox` các item
  chưa reveal) — list vài trăm item vô tư; item đã reveal bị bỏ qua.
- Keyboard navigation (web) không port — mobile-first.

## Changelog

- **1.0.0** (2026-08-18) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `RevealList` vào project này.

**Context**
- Chức năng: list cuộn với entrance scale+fade khi item vào viewport, tap
  selection, edge fade gradient. Item UI hoàn toàn do host cung cấp qua
  `itemBuilder`.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `reveal_list/` (1 file), import
  duy nhất `reveal_list.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `reveal_list/` vào thư mục widget của project đích.
2. Thay `ListView` hiện có bằng `RevealList`, chuyển item widget vào
   `itemBuilder`, nối `onItemSelected` vào navigation/state của project.

**Việc cần adapt theo project đích**
- `edgeFadeColor`: đặt trùng màu nền sau list.
- Style selected: dùng flag `selected` trong `itemBuilder` với token của
  project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
