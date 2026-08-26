---
# --- IDENTITY ---
id: equalizer_bars
title: Equalizer Bars
kind: effect
tags: [equalizer, audio, meter, bars, loading, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: equalizer_bars.dart
files:
  - equalizer_bars.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Equalizer Bars' (Surface & Motion)"
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-26
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

# Equalizer Bars

Năm thanh amber cao 56px pump từ 25% tới 100% chiều cao rồi hạ xuống, lệch
pha bằng negative delay như một audio meter nhỏ. Chuyển động là hàm tất định
của thời gian nên thumbnail và golden test có thể freeze đúng một frame.

## Port notes

- Effect gốc: "Equalizer Bars", section **Surface & Motion**, kinetics
  (`github.com/ckissi/kinetics`). Source thật gồm card `.demo-eq` trong
  `src/content/body.html` và mục 30 trong `public/css/effects-c.css`; không có
  hành vi tương ứng trong `public/js/main.js`.
- Cơ chế gốc: **CSS keyframes** lặp vô hạn. Flutter dùng một `Ticker` chung và
  sample từng bar theo `t`; không tạo controller riêng cho mỗi bar.
- Số liệu giữ nguyên: 5 bar, rộng 6, cao 56, gap 5, radius 3, amber
  `#FF8A00`; chu kỳ 1s ease-in-out; scaleY `0.25 → 1 → 0.25`; transform-origin
  ở đáy; delay `[0, -0.8, -0.4, -0.6, -0.2]` giây.
- Negative CSS delay được giữ đúng nghĩa bằng
  `local = (t - delay) mod period`. Tab React ghi stage cao 48 nhưng demo CSS
  sống là 56, nên port theo 56. Không có hover/cursor.
- Theo quy ước sample(t): `frozenAt` render frame tĩnh, `animate` dừng ticker,
  và component tôn trọng `MediaQuery.disableAnimations`.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `equalizer_bars/` folder (1 dart file(s), see `files`)
- **Import:** `import 'equalizer_bars/equalizer_bars.dart';` — one line
- **Or:** `dart tools/export.dart equalizer_bars` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `count` | `int` | `5` | Số bar; delay lặp nếu count lớn hơn 5 |
| `height` | `double` | `56` | Chiều cao tối đa và chiều cao layout |
| `barWidth` | `double` | `6` | Bề rộng mỗi bar |
| `gap` | `double` | `5` | Khoảng cách ngang |
| `radius` | `double` | `3` | Bo góc bar |
| `color` | `Color` | `#FF8A00` | Màu bar |
| `period` | `double` | `1` | Giây mỗi chu kỳ |
| `phaseDelays` | `List<double>` | `[0,-.8,-.4,-.6,-.2]` | CSS delay theo giây |
| `animate` | `bool` | `true` | false = dừng ticker |
| `frozenAt` | `double?` | null | Render đúng frame tại t giây, không ticker |

## Caveats

- Đây là loop trang trí, không đọc mức âm thanh thật. Với audio meter thật,
  truyền amplitude từ player vào một component controlled khác.
- Mỗi instance rebuild một row nhỏ theo vsync. Trong list dài, dùng
  `frozenAt`, `animate: false`, hoặc `TickerMode` cho item ngoài viewport.
- `phaseDelays` không được rỗng; giá trị sẽ lặp theo modulo cho bar dư.

## Changelog

- **1.0.0** (2026-08-26) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `EqualizerBars` ở trạng thái đang phát/đang nghe hoặc loading có
ngữ nghĩa âm thanh. Dùng `frozenAt` cho thumbnail/golden; dùng `animate: false`
khi component khuất. Đây là hiệu ứng giả lập, không nối trực tiếp vào stream
audio nếu chưa có yêu cầu amplitude controlled.
