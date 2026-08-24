---
# --- IDENTITY ---
id: typing_indicator
title: Typing Indicator
kind: effect
tags: [typing, chat, dots, indicator, loading, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: typing_indicator.dart
files:
  - typing_indicator.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Typing Indicator' (Feedback & State)"
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

# Typing Indicator

Chỉ báo "đang gõ…" kiểu chat dựng lại từ kinetics "Typing Indicator": bong
bóng một góc vuông (đuôi chat) chứa 3 chấm nảy tuần tự — mỗi chấm nhấc 7px
và sáng lên ở mốc 30% của chu kỳ 1.2s, lệch nhau 0.16s nên nhịp nảy chạy
trái → phải. Có thể tắt bong bóng để nhúng vào bubble riêng.

## Port notes

- Effect gốc: "Typing Indicator", section **Feedback & State**, kinetics
  (`github.com/ckissi/kinetics`). Source: card trong `src/content/body.html`,
  style mục "28" trong `public/css/effects-b.css` (`.demo-typing`), không
  có JS.
- Cơ chế gốc: **CSS keyframes** — `demo-typing-bounce 1.2s ease-in-out
  infinite`, keyframe 0/60/100%: nghỉ (opacity 0.4), 30%: nhấc -7px opacity 1;
  delay 0.16s/chấm.
- Số liệu giữ nguyên: chấm 9px màu `#A8A6A0` (bone-dim), gap 7, bubble
  `#232326` viền `#2A2A2E` radius 18/18/18/5, padding 16×20, chu kỳ 1.2s,
  từng đoạn keyframe ease-in-out.
- Theo quy ước sample(t): frame thuần theo `t`, `frozenAt` + `animate`, tôn
  trọng `disableAnimations`.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `typing_indicator/` folder (1 dart file(s), see `files`)
- **Import:** `import 'typing_indicator/typing_indicator.dart';` — one line
- **Or:** `dart tools/export.dart typing_indicator` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `dotCount` | `int` | `3` | Số chấm |
| `dotSize` | `double` | `9` | Đường kính chấm |
| `gap` | `double` | `7` | Khoảng cách giữa chấm |
| `bounceHeight` | `double` | `7` | Độ nhấc tối đa (px) |
| `dotColor` | `Color` | `#A8A6A0` | Màu chấm |
| `bubbleColor` | `Color` | `#232326` | Nền bong bóng |
| `borderColor` | `Color` | `#2A2A2E` | Viền bong bóng |
| `showBubble` | `bool` | `true` | false = chỉ chấm, nhúng bubble riêng |
| `period` | `double` | `1.2` | Giây mỗi chu kỳ |
| `stagger` | `double` | `0.16` | Delay mỗi chấm |
| `animate` | `bool` | `true` | false = đứng im |
| `frozenAt` | `double?` | null | Render đúng 1 frame tại t giây, không ticker |

## Caveats

- Chấm nhấc lên **vẽ tràn** phía trên hàng chấm 7px — bubble có padding 16
  nên chứa đủ; nếu `showBubble: false` thì tự chừa chỗ phía trên.
- Góc vuông (đuôi) nằm dưới-trái — bubble cho tin nhắn bên trái; tin bên
  phải thì bọc `Transform.flip(flipX: true)` phần bubble riêng của bạn.
- Ticker chạy khi hiển thị — tắt bằng `animate: false` khi khuất (§9.2).
- Cost: chưa đo (3 Transform + Opacity mỗi frame — không đáng kể).

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `TypingIndicator` vào project này.

**Context**
- Chức năng: 3 chấm "đang gõ" nảy tuần tự trong bubble chat (port kinetics
  "Typing Indicator"). Tự chạy bằng Ticker; `frozenAt` render tĩnh.
- Public API: xem bảng API trong README. Class `TypingIndicator`.
- Portability: single_file — copy cả `typing_indicator/` (1 file), import duy nhất `typing_indicator.dart`.
- Deps: không có — Flutter SDK only (widgets layer, không cần Material).

**Việc cần làm**
1. Copy folder `typing_indicator/` vào <thư mục widget của project đích>.
2. Hiện khi peer đang gõ (thay message bubble cuối); gỡ khi có tin thật.

**Việc cần adapt theo project đích**
- Khớp bubble chat của app: hoặc đổi `bubbleColor`/`borderColor`, hoặc
  `showBubble: false` và đặt chấm vào bubble sẵn có.
- Nền sáng: đổi `dotColor` đậm hơn (ví dụ `#6E6C68`).

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
