---
# --- IDENTITY ---
id: pixel_card
title: Pixel Card
kind: carrier
tags: [pixel, card, interactive, reveal, shimmer, retro, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: pixel_card.dart
files:
  - pixel_card.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: adapted
source: https://github.com/DavidHDev/react-bits/blob/main/src/ts-tailwind/Components/PixelCard/PixelCard.tsx
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

# Pixel Card

Card viền bo bọc nội dung bất kỳ; chạm giữ thì lưới pixel màu hiện dần từ
tâm ra (mỗi pixel lớn lên, đạt cỡ max thì shimmer), thả tay thì rã dần và
ticker tự dừng khi mọi pixel về 0. Port class `Pixel` + vòng lặp canvas 2D
của react-bits "PixelCard" sang `CustomPainter` + một `Ticker`, giữ nguyên
4 variant (default/blue/yellow/pink).

## Port notes

- Nguồn: `src/ts-tailwind/Components/PixelCard/PixelCard.tsx` (Canvas 2D →
  CustomPainter, không shader).
- Giữ nguyên toàn bộ math của class `Pixel`: `speed = rand(0.1,0.9)×
  effectiveSpeed`, `sizeStep = rand×0.4`, `minSize 0.5` / `maxSizeInteger 2`,
  `delay` = khoảng cách tới tâm, `counterStep = rand×4 + (w+h)×0.01`, máy
  trạng thái appear → shimmer → disappear (bước rã cố định 0.1), vẽ với
  `centerOffset = 1 − size/2`. Giữ throttle 60fps (màn 120Hz vẫn step 60
  lần/giây như bản gốc) và hành vi **tự dừng khi allIdle**; giữ re-init lưới
  khi resize (`ResizeObserver` → `LayoutBuilder` + so sánh size).
- **Đổi trigger:** web dùng hover/focus — Android không có. Mapping:
  pointer-down = appear (mouseenter), pointer-up/cancel = disappear
  (mouseleave), qua `Listener` passive nên không nuốt tap của `child`.
  Thêm `active: bool?` — non-null thì bỏ touch, app tự điều khiển.
- Bỏ: `noFocus` + cặp focus/blur (không có focus ring trên touch),
  `prefers-reduced-motion` (không có media query trên Flutter — app muốn
  tắt thì truyền `speed: 0` hoặc đừng kích hoạt), `className`.
- `activeColor` trong data variant: bản ts-tailwind gốc khai báo nhưng cũng
  không dùng — giữ nguyên trong enum để app tự tint nội dung theo variant.
- Kích thước: web fix cứng 300×400 — bản port lấy theo parent constraints,
  chỉ fallback 300×400 khi unbounded. Chrome card (viền `#27272a`, bo 25)
  thành param với default y hệt.
- Thêm: `seed` (grid tái lập được), `backgroundColor`, `borderWidth: 0` để
  bỏ viền.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `pixel_card/` folder (1 dart file, see `files`)
- **Import:** `import 'pixel_card/pixel_card.dart';` — one line
- **Or:** `dart tools/export.dart pixel_card` → zip + paste-ready block

```dart
SizedBox(
  width: 300,
  height: 400,
  child: PixelCard(
    variant: PixelCardVariant.blue,
    child: const Text('press & hold'),
  ),
)

// App-driven (bỏ touch), ví dụ theo scroll/viewport:
PixelCard(active: isVisible, child: ...)
```

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `variant` | `PixelCardVariant` | `defaultVariant` | Preset gap/speed/colors (`defaultVariant`/`blue`/`yellow`/`pink`) |
| `gap` | `int?` | `null` | Bước lưới px; override variant |
| `speed` | `double?` | `null` | 0–100 (0 = đứng); override variant |
| `colors` | `List<Color>?` | `null` | Palette pixel; override variant |
| `active` | `bool?` | `null` | Non-null = app điều khiển (true = appear), touch bị bỏ qua; `false` cũng là stop switch |
| `seed` | `int?` | `null` | Seed random — grid giống nhau giữa các lần build |
| `borderColor` | `Color` | `#27272A` | Viền card (như bản gốc) |
| `borderWidth` | `double` | `1` | `0` = bỏ viền |
| `borderRadius` | `double` | `25` | Bo góc (như bản gốc) |
| `backgroundColor` | `Color?` | `null` | Nền card; null = trong suốt như bản gốc |
| `child` | `Widget?` | `null` | Nội dung, căn giữa, vẫn nhận tap |

`PixelCardVariant` expose `activeColor`/`gap`/`speed`/`colors` để app đọc
(ví dụ tint text theo `variant.activeColor`).

## Caveats

- **Không có factory `Shader`** (`paint_source: none`): hiệu ứng là particle
  động — hàng nghìn rect kích thước/trạng thái riêng mutate mỗi frame — không
  biểu diễn được bằng `ui.Gradient`/`ImageShader`, nên không dùng được qua
  `ShaderMask`. Đây là carrier: bọc content bằng widget này.
- Số pixel = `(w/gap)×(h/gap)`: 300×400 gap 10 (blue) ≈ 1.2k rect/frame;
  gap 3 (yellow) ≈ 13k rect/frame — gap nhỏ + card to là nặng. Cost thật
  trên Android tầm trung: **chưa đo**.
- Không tốn gì khi idle — ticker tự dừng sau khi disappear xong. Nhưng đang
  **giữ** (appear/shimmer) thì ticker chạy liên tục; `active: true` để lâu =
  shimmer vô hạn, nhớ tắt khi ngoài viewport.
- Trigger là pointer-down/up thô (`Listener`): kéo scroll ngang qua card
  cũng làm pixel hiện rồi tắt khi pointer cancel — hành vi chấp nhận được,
  giống hover lướt qua trên web.
- Rebuild grid (resize/đổi param) reset pixel về 0 giữa chừng — giống hệt
  re-init của bản gốc khi resize.
- **License gốc:** MIT + Commons Clause (react-bits) — dùng trong app/product
  thoải mái, KHÔNG được bán/redistribute bản thân component (kể cả bản port).

## Changelog

- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `PixelCard` vào project này.

**Context**
- Chức năng: card bọc nội dung, chạm giữ thì lưới pixel màu hiện từ tâm ra
  rồi shimmer, thả tay thì rã (port react-bits "PixelCard"). 4 preset qua
  `PixelCardVariant`; app điều khiển thay touch qua `active`.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `pixel_card/` (1 file), import
  duy nhất `pixel_card.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `pixel_card/` vào thư mục widget của project đích.
2. Bọc trong `SizedBox`/parent có kích thước (card fill parent; unbounded
   thì fallback 300×400).
3. Đặt nội dung thật vào `child` (căn giữa sẵn, tap bên trong vẫn hoạt động).

**Việc cần adapt theo project đích**
- Chọn `variant` gần palette project nhất, hoặc truyền `colors` riêng
  (override variant); viền/bo qua `borderColor`/`borderRadius`, `borderWidth: 0`
  nếu card style của project đã có viền.
- Muốn reveal theo viewport/scroll thay vì chạm: truyền `active` và tự set.
- Card to hoặc list nhiều card: đừng giảm `gap` dưới default của variant.

**Rào (constraints)**
- KHÔNG sửa math trong `_CardPixel`/painter. Chỉ đổi qua params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
