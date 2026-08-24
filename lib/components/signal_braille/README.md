---
# --- IDENTITY ---
id: signal_braille
title: Signal Braille
kind: effect
tags: [status, braille, dots, discrete, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: signal_braille.dart
files:
  - signal_braille.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Signal Braille' (Feedback & State)"
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-24
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

# Signal Braille

Ma trận trạng thái sáu chấm lấy cảm hứng từ Braille, dựng lại từ kinetics
"Signal Braille". Các chấm đổi màu theo ba pha rời rạc thay vì quay hoặc nảy,
kèm nhãn `READY` yên tĩnh phía dưới.

## Port notes

- Source thật: card `.demo-signal-braille` trong `src/content/body.html`, CSS
  cuối `public/css/effects-b.css`; không có hành vi riêng trong `main.js`.
- Cơ chế gốc: **CSS keyframes** `steps(1)` chu kỳ đúng 2.1s. Ba khoảng
  `0–32% / 33–65% / 66–100%` lần lượt dùng card-2 / amber / wire.
- Delay giữ nguyên theo thứ tự DOM: `0, -0.7, -1.4, -0.7, 0, -1.4s`.
  Dot thứ 6 khớp cả `2n` và `3n`; rule `3n` đứng sau nên thắng.
- Số liệu giữ nguyên: lưới 2×3, dot 18px, gap 9px, padding đáy 28px; nhãn
  kế thừa body 16px/1.55, bold, bone; palette dot
  `#232326 / #FF8A00 / #5B8DEF`.
- Flutter dùng một `Ticker` và hàm sample thuần theo `t`; có `animate`,
  `frozenAt`, tôn trọng `disableAnimations`. Font mono web đổi sang font hệ
  thống vì luật zero-asset.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- Copy folder `signal_braille/`, import `signal_braille.dart`.
- Hoặc chạy `dart tools/export.dart signal_braille`.

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `label` | `String` | `'READY'` | Nhãn trạng thái |
| `dotSize` | `double` | `18` | Đường kính chấm |
| `gap` | `double` | `9` | Khoảng cách lưới |
| `labelGap` | `double` | `3` | Khoảng cách tới nhãn |
| `labelSize` | `double` | `16` | Cỡ chữ nhãn |
| `idleColor` | `Color` | `#232326` | Pha nghỉ |
| `activeColor` | `Color` | `#FF8A00` | Pha active |
| `signalColor` | `Color` | `#5B8DEF` | Pha signal |
| `labelColor` | `Color` | `#EDE9E0` | Màu nhãn |
| `animate` | `bool` | `true` | Bật/tắt ticker |
| `frozenAt` | `double?` | null | Frame xác định tại t giây |

## Caveats

- Mẫu pha là minh họa, không encode dữ liệu Braille thật.
- Tắt ticker bằng `animate: false` hoặc `TickerMode` khi ngoài viewport.
- Cost: chưa đo; chỉ rebuild sáu dot nhỏ mỗi frame.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `SignalBraille` làm machine-status indicator. Copy nguyên folder,
import entry file, đổi label/màu qua constructor; không sửa logic pha bên trong.
