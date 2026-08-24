---
# --- IDENTITY ---
id: undo_snackbar
title: Undo Snackbar
kind: effect
tags: [snackbar, undo, destructive, progress, timed, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: undo_snackbar.dart
files:
  - undo_snackbar.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Undo Snackbar' (Feedback & State)"
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

# Undo Snackbar

Snackbar sau thao tác phá huỷ với cửa sổ Undo 3 giây và thanh thời gian cạn
dần, dựng lại từ kinetics "Undo Snackbar". Tăng `requestId` để show hoặc reset.

## Port notes

- Source thật: `.demo-undo-*` trong `body.html`, mục `20. Undo snackbar` của
  `effects-b.css`, handler `20a` trong `main.js`.
- Cơ chế gốc: **lai CSS transition + keyframes + JS timer**. Bar slide từ
  `translateY(140%)` trong 0.4s bằng `Cubic(0.34,1.56,0.64,1)`; progress
  `scaleX(1→0)` linear đúng 3s; JS hide khi hết 3000ms hoặc bấm Undo.
- Flutter map đúng ngữ nghĩa CSS transition: `AnimatedSlide` retarget với
  **cùng** spring bezier cho cả vào lẫn ra (không `reverse()`). Controller
  lifecycle làm cả đồng hồ lẫn progress nên không cần `Timer` (nút freeze
  của viewer dừng được).
- Retrigger khi đang hiện: bar đứng yên, chỉ drain restart từ 100% — đúng
  handler gốc (force reflow chỉ để restart animation drain). Undo gọi
  callback rồi chạy exit ngay.
- Số liệu giữ nguyên: width 240, padding ngang 14, gap 12, bar progress 2px,
  radius 9 (`--radius-sm`), text 13 và palette gốc. Trigger Delete thuộc
  demo, không nằm trong component reusable.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- Copy folder `undo_snackbar/`, import `undo_snackbar.dart`.
- Hoặc chạy `dart tools/export.dart undo_snackbar`.

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `requestId` | `int` | `0` | Đổi giá trị để show/reset |
| `message` / `undoLabel` | `String` | `'Item deleted' / 'Undo'` | Nội dung |
| `width` | `double` | `240` | Bề rộng bar |
| `undoDuration` | `Duration` | `3000ms` | Cửa sổ Undo |
| `backgroundColor` | `Color` | `#141417` | Nền |
| `borderColor` | `Color` | `#2A2A2E` | Viền |
| `textColor` / `accentColor` | `Color` | `#EDE9E0 / #FF8A00` | Chữ/progress |
| `onUndo` | `VoidCallback?` | null | Thực thi khôi phục |
| `onDismissed` | `VoidCallback?` | null | Gọi sau khi bar rời màn hình |
| `animate` | `bool` | `true` | false = frame visible ổn định |

## Caveats

- Component chỉ trình bày và phát callback; transaction/restore do parent giữ.
- `requestId` phải đổi để retrigger. Khi `animate: false`, auto-dismiss dừng.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `UndoSnackbar` sau thao tác phá huỷ. Tăng `requestId`, phục hồi dữ liệu
trong `onUndo`, và dùng `onDismissed` để dọn state overlay nếu cần.
