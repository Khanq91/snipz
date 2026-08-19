---
# --- IDENTITY ---
id: bounce_cards
title: Bounce Cards
kind: composite
tags: [cards, stack, elastic, stagger, entrance, gallery]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: bounce_cards.dart
files:
  - bounce_cards.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/DavidHDev/react-bits/blob/main/src/ts-tailwind/Components/BounceCards/BounceCards.tsx
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

# Bounce Cards

Fan bài: các card vuông bo góc viền trắng xếp chồng xòe theo pose (xoay +
lệch), pop vào từng cái một bằng elastic bounce (scale 0 → 1, stagger).
Card là widget bất kỳ. Replay/stop từ ngoài qua
`GlobalKey<BounceCardsState>`. Dựng lại "BounceCards" của react-bits (GSAP
`elastic.out` stagger → AnimationController + `ElasticOutCurve`).

## Port notes

- Nguồn: `src/ts-tailwind/Components/BounceCards/BounceCards.tsx`.
- Giữ: 5 pose mặc định đúng bản gốc (`rotate(10°) translate(-170px)`…), thứ
  tự compose transform của CSS (`rotate` trước `translate` — offset đi trong
  hệ đã xoay), delay 0.5s + stagger 0.06s, ease đàn hồi (`elastic.out(1, .8)`
  → `ElasticOutCurve(0.8)`), viền 8 trắng, bo 30, shadow.
- Bỏ: hover đẩy card hàng xóm (`pushSiblings`/`resetSiblings`) — Android
  không có hover; muốn tương tự thì bọc card trong GestureDetector ở tầng
  app.
- Thay: `images: string[]` → `cards: List<Widget>` (không asset, linh hoạt
  hơn); transform string CSS → `BounceCardPose(rotationDeg, offset)`.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `bounce_cards/` folder (1 dart file, see `files`)
- **Import:** `import 'bounce_cards/bounce_cards.dart';` — one line
- **Or:** `dart tools/export.dart bounce_cards` → zip + paste-ready block

```dart
BounceCards(
  width: 600,
  height: 300,
  cards: [for (final url in urls) Image.network(url, fit: BoxFit.cover)],
)
```

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `cards` | `List<Widget>` | required | Nội dung card, vẽ theo thứ tự (cuối trên cùng) |
| `width` / `height` | `double` | `400` | Khung chứa |
| `cardSize` | `double` | `200` | Cạnh card vuông |
| `poses` | `List<BounceCardPose>?` | fan 5 card gốc | Pose nghỉ mỗi card; thiếu thì lặp pose cuối |
| `delay` | `Duration` | `500ms` | Chờ trước card đầu |
| `stagger` | `Duration` | `60ms` | Giãn cách giữa các card |
| `bounceDuration` | `Duration` | `500ms` | Thời lượng pop một card |
| `curve` | `Curve` | `ElasticOutCurve(0.8)` | Ease pop |
| `borderWidth` / `borderColor` | — | `8` / trắng | Viền card |
| `borderRadius` | `double` | `30` | Bo góc |
| `shadow` | `bool` | `true` | Đổ bóng |
| `autoPlay` | `bool` | `true` | false = chờ `play()` |

`BounceCardsState` (qua `GlobalKey`): `play()`, `stop()`.

## Caveats

- Hiệu ứng hover đẩy card của bản web **không port** (không có hover trên
  touch) — xem Port notes.
- Card scale bằng `Transform` nên child vẫn layout full size từ frame đầu;
  animation hữu hạn, không có ticker nền sau khi settle.
- `poses` lệch quá `width/height` thì card tràn khung (Stack
  `clipBehavior: none` chủ đích, giống bản gốc) — parent có ClipRect sẽ cắt.

## Changelog

- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `BounceCards` vào project này.

**Context**
- Chức năng: fan card pop vào bằng elastic stagger (port react-bits), replay
  qua `GlobalKey<BounceCardsState>`.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `bounce_cards/` (1 file), import
  duy nhất `bounce_cards.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `bounce_cards/` vào thư mục widget của project đích.
2. Truyền `cards` là ảnh/nội dung thật; chỉnh `width`/`height` theo layout.

**Việc cần adapt theo project đích**
- `poses` theo số card thật (mỗi card một pose).
- Muốn chạy khi scroll tới: `autoPlay: false` + gọi `play()` từ scroll
  listener của project.

**Rào (constraints)**
- KHÔNG sửa logic stagger/transform bên trong. Chỉ đổi qua params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
