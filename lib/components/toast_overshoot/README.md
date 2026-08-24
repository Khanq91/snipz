---
# --- IDENTITY ---
id: toast_overshoot
title: Toast Overshoot
kind: effect
tags: [toast, notification, overshoot, spring, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: toast_overshoot.dart
files:
  - toast_overshoot.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Toast Overshoot' (Interaction & Input)"
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

# Toast Overshoot

Toast pill trượt lên từ dưới (140% chiều cao của chính nó), vượt quá điểm nghỉ
rồi settle, tự ẩn sau 2.2s. Trigger lại khi đang hiện chỉ reset timer.

## Port notes

- Source thật: card `.demo-toast-zone`/`.demo-toast` trong
  `src/content/body.html`, mục `4. Toast overshoot` của
  `public/css/effects-a.css`, JS toggle `.show` + `setTimeout` 2200ms
  (clearTimeout khi retrigger).
- Cơ chế gốc: **CSS transition + bezier overshoot**. Flutter dùng implicit
  animation (`AnimatedSlide` 1.4 fraction + `AnimatedScale` 0.9 + 
  `AnimatedOpacity`): transform 0.55s `Cubic(0.18, 1.25, 0.4, 1)`, opacity
  0.3s ease. Implicit retarget từ giá trị hiện tại với cùng curve = đúng ngữ
  nghĩa transition CSS cả chiều ẩn (không mirror curve) lẫn khi bị ngắt giữa
  chừng.
- Auto-hide chạy bằng `AnimationController` 2200ms (không `Timer`) — nút
  freeze của viewer dừng được qua `TickerMode`.
- Số liệu giữ nguyên: translateY 140%, scale 0.9→1, padding 18×11, font 13,
  dot 8px ok-green, radius pill, palette card-2/line/bone.
- Readout `overshoot(1.08)` chỉ là trang trí — demo thật chạy cubic-bezier.
- Không có hover lõi; click → tap ở nút trigger phía demo.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `toast_overshoot/` folder (1 dart file(s), see `files`)
- **Import:** `import 'toast_overshoot/toast_overshoot.dart';` — one line
- **Or:** `dart tools/export.dart toast_overshoot` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `pushId` | `int` | `0` | Đổi giá trị (≠0) để show; đang hiện thì reset timer |
| `message` | `String` | `'Changes saved'` | Nội dung toast |
| `autoHideDuration` | `Duration` | `2200ms` | Thời gian hiển thị |
| `initiallyVisible` | `bool` | `false` | Render sẵn trạng thái settled (preview) |
| `backgroundColor` / `borderColor` | `Color` | `#232326 / #2A2A2E` | Màu pill |
| `textColor` / `dotColor` | `Color` | `#EDE9E0 / #4CD08A` | Chữ + dot |
| `onDismissed` | `VoidCallback?` | `null` | Gọi khi auto-hide xong |
| `animate` | `bool` | `true` | False = không motion, không auto-hide |

## Caveats

- Component là chính cái pill — consumer tự đặt vị trí (Stack/Positioned,
  bottom-center như demo). Khi ẩn nó vẫn chiếm chỗ layout (trong suốt).
- Tôn trọng `MediaQuery.disableAnimations` (trạng thái nhảy tức thì, auto-hide
  vẫn chạy).

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `ToastOvershoot` như transient status toast. Parent giữ một int
`pushId`, tăng nó mỗi lần muốn show; đặt pill ở bottom-center bằng
Stack/Positioned. Giữ nguyên curve overshoot và timing 0.55s/2.2s.
