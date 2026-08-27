---
# --- IDENTITY ---
id: scramble_text
title: Scramble Text
kind: effect
tags: [text, scramble, decode, hacker, matrix, reveal, animated, gsap]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: scramble_text.dart
files:
  - scramble_text.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/greensock/GSAP/blob/master/src/ScrambleTextPlugin.js
author: "Khang"
license: "GSAP Standard License (thuật toán dựng lại, không copy code)"

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-27
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

# Scramble Text

Text "giải mã" kiểu Matrix/hacker: chuỗi đích hiện dần từ trái sang (hoặc phải
sang) trong khi phần chưa hiện nhiễu loạn qua các ký tự ngẫu nhiên. Port
thuật toán ScrambleTextPlugin của GSAP: pool nhiễu 20 chuỗi sinh sẵn có seed
(mỗi frame là hàm thuần của `t` — scrub/golden test được), pool nhảy mỗi
`0.05/speed` giây, biên reveal `⌊ratio·len + 0.5⌋`, độ dài morph bậc 3 khi
chuyển giữa các text khác độ dài. Hợp cho heading hero, terminal, badge
trạng thái.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `scramble_text/` folder (1 dart file(s), see `files`)
- **Import:** `import 'scramble_text/scramble_text.dart';` — one line
- **Or:** `dart tools/export.dart scramble_text` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `texts` | `List<String>` | (bắt buộc) | Các text hiện lần lượt, mỗi cycle một text |
| `style` | `TextStyle?` | `null` | Style phần đã reveal (mặc định DefaultTextStyle) |
| `scrambleStyle` | `TextStyle?` | `null` | Style phần nhiễu (mặc định `style` 45% alpha) |
| `duration` | `double` | `1.8` | Giây cho một lượt reveal |
| `hold` | `double` | `1.4` | Giây giữ nguyên text đã hiện trước cycle sau |
| `revealDelay` | `double` | `0` | Giây nhiễu thuần trước khi bắt đầu reveal |
| `curve` | `Curve` | `linear` | Ease của biên reveal |
| `charset` | `ScrambleCharset` | `upperCase` | Bảng ký tự nhiễu (upper/lower/cả hai/custom) |
| `customChars` | `String?` | `null` | Bảng chữ khi `charset: custom` |
| `speed` | `double` | `1.0` | Tốc độ đảo nhiễu (pool nhảy mỗi `0.05/speed`s) |
| `tweenLength` | `bool` | `true` | Morph độ dài hiển thị giữa 2 text khác độ dài |
| `rightToLeft` | `bool` | `false` | Reveal từ phải sang |
| `perWord` | `bool` | `false` | Reveal theo nguyên từ (nhiễu vẫn theo ký tự) |
| `loop` | `bool` | `true` | Lặp vô hạn qua `texts` |
| `seed` | `int` | `421` | Seed pool nhiễu — cùng seed, cùng frame |
| `animate` | `bool` | `true` | Cho ticker chạy |
| `frozenAt` | `double?` | `null` | Render đúng một frame tại t giây, không ticker |

## Caveats

- Font proportional làm bề rộng dòng nhấp nhô khi nhiễu đảo (đúng hành vi
  GSAP). Muốn đứng yên tuyệt đối thì dùng font mono (`fontFamily:
  'monospace'`) như variant Hacker.
- `perWord` tách từ bằng dấu cách đơn; text nhiều khoảng trắng liên tiếp nên
  chuẩn hóa trước.
- Nhiễu theo grapheme của bảng chữ cái — emoji trong `texts` được đếm đúng
  cluster (dùng `characters` qua Flutter SDK), nhưng bảng nhiễu nên là ASCII
  cho đều bề rộng.
- `disableAnimations` (reduced motion) → hiện thẳng text cuối, không nhiễu.

## Changelog

- **1.0.0** (2026-08-27) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `ScrambleText` vào project này.

**Context**
- Chức năng: text giải mã kiểu Matrix — nhiễu ký tự rồi hiện dần, lặp qua
  nhiều chuỗi, tùy biến bảng ký tự/tốc độ/hướng.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `scramble_text/` (1 file), import duy nhất `scramble_text.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `scramble_text/` vào <thư mục widget của project đích>.
2. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
