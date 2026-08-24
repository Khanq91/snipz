---
# --- IDENTITY ---
id: hold_to_talk
title: Hold to Talk
kind: effect
tags: [voice, waveform, hold, press, spring, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: hold_to_talk.dart
files:
  - hold_to_talk.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Hold to Talk' (Interaction & Input)"
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-24
created_flutter: 3.44.0
created_dart: 3.12.0
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

# Hold to Talk

Control hold-to-talk: 7 bar gần phẳng lúc idle; đè xuống thì bùng thành
waveform sống (mỗi bar một chu kỳ riêng, giữa nhanh rìa chậm) + ring nở
quanh nút; nhả thì bar sập bằng spring, flash SENT xanh 900ms rồi về rest.
Đây là voice capture — waveform là trạng thái, không phải confirm-ring.

## Port notes

- Source thật: card `.demo-talk` trong `src/content/body.html`, effects-a.css
  dòng 2277-2373 (`@keyframes talk-bar` ease-in-out alternate, duration
  0.52/0.34/0.26/0.2s đối xứng), main.js "Hold to talk" (pointer down/up +
  Space/Enter, sent 900ms).
- Cơ chế gốc: **@keyframes loop + CSS transition + JS press state**. Flutter:
  waveform = `Ticker` + hàm thuần `wave(i, t)` (triangle alternate qua
  `Curves.easeInOut`, 0.18→1) theo quy ước sample(t); chuyển trạng thái =
  chụp scale hiện tại rồi spring 0.4s `Cubic(0.34,1.56,0.64,1)` về mốc mới
  (0.18 sent / 0.12 idle) — đúng "collapse with a spring" của tab Prompt.
- Số liệu giữ nguyên: bar 4×36 radius 4 gap 4, nút min 132×40 pill (live:
  amber + scale 0.96, ring inset -6 border amber70% scale 0.86→1 0.45s
  spring), sent: viền/chữ ok + status 9px letter-spacing 0.14em trồi lên
  4px bằng spring, timer sent 900ms bằng `AnimationController`.
- Space/Enter keydown của web bỏ (không phải driver trên Android); Semantics
  button giữ cho a11y.
- Loop chỉ chạy khi ĐANG đè — idle không ticker; `animate: false` và pinned
  live render một frame wave tất định (t = 0.25s).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `hold_to_talk/` folder (1 dart file(s), see `files`)
- **Import:** `import 'hold_to_talk/hold_to_talk.dart';` — one line
- **Or:** `dart tools/export.dart hold_to_talk` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `label` / `sentLabel` | `String` | `'hold to talk' / 'SENT'` | Nhãn |
| `sentHold` | `Duration` | `900ms` | Thời gian flash SENT |
| `pinnedPhase` | `HoldToTalkPhase?` | `null` | Ghim idle/live/sent (preview) |
| `barColor` / `sentColor` | `Color` | `#FF8A00 / #4CD08A` | Wave + trạng thái |
| `buttonColor` / `borderColor` | `Color` | `#232326 / #2A2A2E` | Nút idle |
| `textColor` / `liveTextColor` | `Color` | `#EDE9E0 / #0E0E10` | Chữ nút |
| `onSent` | `VoidCallback?` | `null` | Bắn khi nhả (commit) |
| `animate` | `bool` | `true` | False = không loop, đổi trạng thái tức thì |

## Caveats

- Component chỉ làm PHẦN NHÌN của voice capture — không thu âm; nối `onSent`
  và pointer down/up với recorder thật ở consumer.
- Ring nở tràn ra ngoài nút 6px — đừng clip sát.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `HoldToTalk` làm nút thu giọng nói. Bọc quanh audio recorder: bắt
đầu thu ở pointer-down (thêm callback ngoài nếu cần), commit trong `onSent`;
giữ nguyên chu kỳ bar 0.52/0.34/0.26/0.2s và spring 0.4s.
