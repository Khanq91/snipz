---
# --- IDENTITY ---
id: split_flap_text
title: Split Flap Text
kind: effect
tags: [text, flip, departure-board, retro, mechanical, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: split_flap_text.dart
files:
  - split_flap_text.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/DavidHDev/react-bits/blob/main/src/ts-tailwind/TextAnimations/SplitFlapText/SplitFlapText.tsx
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

# Split Flap Text

Bảng giờ sân bay: mỗi ký tự là một tile tối, lật cơ học qua `flipsPerChar`
ký tự ngẫu nhiên rồi đáp xuống ký tự đích; các phrase trong `words` xoay vòng
mỗi `cycleDelay`, tile lật lan từ trái sang phải (`stagger`). Chỉ tile có ký
tự thật sự đổi mới lật. Dựng lại "SplitFlapText" của react-bits (CSS 3D
keyframes + rAF → Transform perspective + một Ticker).

## Port notes

- Nguồn: `src/ts-tailwind/TextAnimations/SplitFlapText/SplitFlapText.tsx`.
- Giữ: cơ chế bốn lớp (top/bottom tĩnh + front flap gập xuống, back flap mở
  ra với 45% hold đầu), sequence random-rồi-target, step semantics (current =
  ký tự trước, next = ký tự đang lật tới), stagger theo index, pad/truncate
  về bề rộng board, kích thước tile .78em × 1.08em, hairline giữa, đổ tối
  flap theo góc (brightness keyframes → overlay đen).
- Bỏ: `prefers-reduced-motion` media query → thay bằng
  `MediaQuery.disableAnimations` (nhảy thẳng tới phrase mới); ARIA.
- Thay: CSS animation per-flap (GPU, remount bằng key) → một `Ticker` chung
  tính step + fraction cho mọi tile; `cubic-bezier(.23,1,.32,1)` →
  `Curves.easeOutQuart`; font stack monospace web → `fontFamily: 'monospace'`
  + fallback.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `split_flap_text/` folder (1 dart file, see `files`)
- **Import:** `import 'split_flap_text/split_flap_text.dart';` — one line
- **Or:** `dart tools/export.dart split_flap_text` → zip + paste-ready block

```dart
SplitFlapText(
  words: const ['LAUNCH READY', 'SYNC ONLINE', 'SIGNAL LIVE'],
)
```

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `words` | `List<String>` | 3 phrase mẫu | Các phrase xoay vòng |
| `text` | `String?` | `null` | Non-null: một phrase tĩnh, bỏ qua `words` |
| `flipDuration` | `Duration` | `120ms` | Một nhịp lật (sàn 40ms) |
| `stagger` | `Duration` | `60ms` | Trễ thêm mỗi tile theo index |
| `cycleDelay` | `Duration` | `2400ms` | Nghỉ giữa hai phrase |
| `charset` | `String` | `alphanumeric` | Bộ ký tự lật đệm (`SplitFlapText.alpha`/`alphanumeric`/`numeric` hoặc chuỗi tùy ý) |
| `flipsPerChar` | `int` | `8` | Số ký tự ngẫu nhiên trước khi đáp |
| `tileColor` / `textColor` | `Color` | `#111827` / `#F8FAFC` | Màu tile/chữ |
| `tileRadius` | `double` | `8` | Bo góc tile |
| `gap` | `double` | `6` | Khoảng cách tile |
| `fontSize` | `double` | `52` | Cỡ chữ (tile scale theo) |
| `loop` | `bool` | `true` | false = dừng ở phrase cuối |
| `padTo` | `int` | `12` | Số tile tối thiểu (phrase dài hơn thì thắng) |
| `autoPlay` | `bool` | `true` | false = đứng ở phrase đầu chờ `start()` |
| `textStyle` | `TextStyle?` | `null` | Style nền cho ký tự |

`SplitFlapTextState` (qua `GlobalKey`): `start()`, `stop()`.

## Caveats

- Khi đang lật, mỗi frame setState cả row — board rất dài (30+ tile) trên
  máy yếu sẽ nặng; lúc nghỉ giữa các phrase **không** tốn frame nào.
- Mỗi tile đang lật = 2 lớp Transform perspective + 4 ClipRect; đó là cost
  đỉnh, hết lượt lật là về tĩnh. Cost thật trên thiết bị: chưa đo.
- `fontFamily: 'monospace'` ăn theo font hệ thống Android (Roboto Mono) —
  muốn đồng nhất tuyệt đối giữa thiết bị thì truyền `textStyle` với font của
  app.
- `stop()` giữa chừng đóng băng tile đang lật ở tư thế hiện tại (gọi
  `start()` chạy tiếp cycle mới).

## Changelog

- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `SplitFlapText` vào project này.

**Context**
- Chức năng: bảng chữ lật cơ học xoay vòng phrase (port react-bits).
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `split_flap_text/` (1 file),
  import duy nhất `split_flap_text.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `split_flap_text/` vào thư mục widget của project đích.
2. Truyền `words` thật; bọc `FittedBox(fit: BoxFit.scaleDown)` nếu bề ngang
   có thể tràn.

**Việc cần adapt theo project đích**
- `tileColor`/`textColor` theo theme; `fontSize` theo layout.
- Nội dung số (giờ, giá) → `charset: SplitFlapText.numeric` cho nhịp lật
  gọn hơn.

**Rào (constraints)**
- KHÔNG sửa cơ chế bốn-lớp/step bên trong. Chỉ đổi qua params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
