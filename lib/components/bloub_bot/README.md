---
# --- IDENTITY ---
id: bloub_bot
title: Bloub Bot
kind: composite
tags: [bot, avatar, mascot, morph, eyes, animated, loading, ai, character]

# --- TAXONOMY (§2) ---
paint_source: painter
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: folder
entry: bloub_bot.dart
files:
  - bloub_bot.dart: "entry, public API"
  - _decor.dart: "required by bloub_bot.dart"
  - _engine.dart: "required by bloub_bot.dart"
  - _face.dart: "required by bloub_bot.dart"
  - _math.dart: "required by bloub_bot.dart"
  - _painter.dart: "required by bloub_bot.dart"
  - _profiles.dart: "required by bloub_bot.dart"
  - _shape.dart: "required by bloub_bot.dart"
  - _states.dart: "required by bloub_bot.dart"
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

# Bloub Bot

Avatar bot morph — port từ [bloub](https://github.com/jeremy-prt/bloub), bản
tái tạo avatar bot x.ai đo từng frame từ video gốc. Một khối `ink` morph qua
các trạng thái (idle, thinking, wink, wide, sleep, egg, hexagon…), hai mắt là
**lỗ thủng thật** trên thân (tự clip khi trượt ra mép), sống trên một mặt cầu
3D. "Sự sống" lúc nghỉ = gaze drift + chớp mắt theo lịch tất định + thở nhẹ.
Dùng làm mascot trợ lý AI, loading indicator, empty-state.

## Kiến trúc

- **Engine thuần thời gian**: `BloubBotEngine.sample(t)` là hàm thuần —
  pause/tua/`frozenAt` đều cho đúng một ảnh, test không cần widget tree.
  Mọi state ngoài vào qua **setter có date** (`setState(id, now)`), không bao
  giờ qua biến đọc trong `sample`.
- **Mọi hình là radial profile 64 mẫu** → morph = lerp bán kính.
- **Mắt là lỗ**: painter dùng `saveLayer` + `BlendMode.dstOut` (bản dịch của
  SVG mask), có path lót màu `paper` phía sau — vì decor vẽ sau lưng thân
  không được ló qua mắt.
- Số liệu (profile trứng/lục giác/tam giác, hướng đầu nghỉ, lịch chớp mắt…)
  **vendor nguyên xi từ bloub — cấm làm tròn**. Lịch chớp mắt và các seed
  ngẫu-nhiên-có-hạt được sinh lại bằng node từ checkout bloub (mulberry32
  seed cố định) thay vì port RNG của JS.

## Install

```yaml
# no external pub dependencies — Flutter SDK only
```

## Reuse

- **Copy:** cả folder `bloub_bot/` (entry + 8 file `_`)
- **Import:** `import 'bloub_bot/bloub_bot.dart';` — one line

```dart
// Mascot sống, đổi trạng thái theo app logic:
BloubBot(
  size: 200,
  state: isThinking ? BloubBotState.thinking : BloubBotState.idle,
  paper: Theme.of(context).colorScheme.surface, // màu NỀN phía sau widget
)

// Ảnh tĩnh tất định (thumbnail, golden test):
BloubBot(size: 120, frozenAt: botStatePoses[BloubBotState.wink]!)
```

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `size` | `double` | `160` | Cạnh hình vuông render |
| `state` | `BloubBotState` | `idle` | Trạng thái; đổi là morph (engine tự date transition) |
| `ink` | `Color?` | `#0A0A0C` | Màu thân (số đo gốc) |
| `paper` | `Color?` | theme `surface` | Màu nền PHÍA SAU widget — mắt là lỗ lót màu này, phải khớp nền thật |
| `frozenAt` | `double?` | `null` | Đóng băng tại t giây trong state — không ticker, ảnh tất định |
| `animate` | `bool` | `true` | Tắt ticker từ ngoài |

Tầng thấp hơn cho ai muốn tự lái: `BloubBotEngine` (sample/setState/reset/
setShape/setExpression/setLook), `BloubBotPainter`, `botStates`,
`botSequence`, `botStatePoses`.

## Caveats

- `paper` phải khớp màu nền thật phía sau widget, không thì "lỗ" mắt lộ sai
  màu (đây là hành vi gốc của bloub, không phải bug).
- Mỗi frame có một `saveLayer` (lỗ mắt) — rẻ trên Impeller, nhưng đừng đặt
  hàng chục con chạy sống cùng lúc; bản đứng im (`frozenAt`) thì thoải mái.
- Các state decor (alert, notify, exclaim, play, orbit, swirl, burst, comet),
  expression + shape customizer: chưa có ở bản này — vào ở các version sau.

## Changelog

- `1.0.0` — created: engine + painter + 7 body states (idle, thinking, wink,
  wide, sleep, egg, hexagon), gaze drift + blink calendar + breath.
