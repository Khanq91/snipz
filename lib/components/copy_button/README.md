---
# --- IDENTITY ---
id: copy_button
title: Copy Button
kind: effect
tags: [copy, clipboard, button, crossfade, spring, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: copy_button.dart
files:
  - copy_button.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Copy Button' (Interaction & Input)"
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

# Copy Button

Nút copy-to-clipboard: glyph copy thu nhỏ mờ đi, check xanh spring vào, label
đổi "Copy" → "Copied", tự revert sau 1.4s. Tap lại khi đang copied chỉ reset
timer.

## Port notes

- Source thật: card `.demo-copy-btn` trong `src/content/body.html`, mục
  `16. Copy button` của effects-a.css, JS (`31. Copy button` main.js): write
  clipboard (lỗi vẫn hiện feedback), add `.copied`, revert 1400ms
  (clearTimeout khi tap lại).
- Cơ chế gốc: **CSS transition + JS timer**. Flutter: mỗi icon =
  `AnimatedOpacity` 0.2s ease + `AnimatedScale` 0.5↔1 0.3s
  `Cubic(0.34, 1.56, 0.64, 1)`; border-color 0.2s ease; revert bằng
  `AnimationController` 1400ms (không `Timer`).
- Trung thực cả chỗ KHÔNG animate: màu chữ/icon đổi tức thì (CSS không khai
  `color` trong transition list), chỉ border-color có fade; border copied =
  ok 45% alpha (`color-mix(ok 45%, transparent)`).
- Icon vẽ bằng `CustomPainter` từ hình học 24-viewBox (copy = rect 11×11 r2 +
  góc sheet; check = polyline 5,12.5→10,17.5→19,7), stroke 2 round — zero
  asset.
- Số liệu giữ nguyên: padding 20×11, gap 9, icon 18, font 14/600, radius
  pill, palette card-2/line/bone/ok.
- Clipboard dùng `flutter/services` (SDK, không phải dependency ngoài).
- Hover đổi border đã bỏ; click → tap.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `copy_button/` folder (1 dart file(s), see `files`)
- **Import:** `import 'copy_button/copy_button.dart';` — one line
- **Or:** `dart tools/export.dart copy_button` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `value` | `String` | required | Text ghi vào clipboard |
| `label` / `copiedLabel` | `String` | `'Copy' / 'Copied'` | Nhãn hai trạng thái |
| `revertDelay` | `Duration` | `1400ms` | Thời gian giữ trạng thái copied |
| `backgroundColor` / `borderColor` | `Color` | `#232326 / #2A2A2E` | Pill |
| `foregroundColor` | `Color` | `#EDE9E0` | Chữ + icon idle |
| `okColor` | `Color` | `#4CD08A` | Check, chữ và viền khi copied |
| `onCopied` | `VoidCallback?` | `null` | Gọi mỗi lần tap |
| `animate` | `bool` | `true` | False = crossfade tức thì (timer vẫn chạy) |

## Caveats

- `Clipboard.setData` là async fire-and-forget — feedback hiện ngay cả khi
  clipboard fail (đúng bản gốc); cần chắc chắn thì tự gọi Clipboard trong
  `onCopied`.
- Tôn trọng `MediaQuery.disableAnimations`.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `CopyButton` cạnh giá trị cần copy (code snippet, API key…). Truyền
text vào `value`, đổi màu qua constructor; giữ nguyên cặp transition
0.2s/0.3s spring và revert 1.4s.
