---
# --- IDENTITY ---
id: notification_slide_in
title: Notification Slide-in
kind: effect
tags: [notification, banner, spring, timed, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: notification_slide_in.dart
files:
  - notification_slide_in.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Notification Slide-in' (Feedback & State)"
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

# Notification Slide-in

Banner pill rơi từ mép trên, overshoot rồi tự ẩn, dựng lại từ kinetics
"Notification Slide-in". Tăng `requestId` để show hoặc retrigger an toàn.

## Port notes

- Source thật: `.demo-notify-zone/.demo-notify` trong `body.html`, mục
  `22. Notification slide-in` của `effects-b.css`, handler trong `main.js`.
- Cơ chế gốc: **CSS transition + JS timer**. Transform `translateY(-160%) → 0`
  trong 0.55s bằng `Cubic(0.18, 1.25, 0.4, 1)`; opacity 0.3s ease; JS gỡ
  `.show` sau đúng 2200ms.
- Flutter map đúng ngữ nghĩa CSS transition: `AnimatedSlide` + `AnimatedOpacity`
  retarget với **cùng** bezier cho cả vào lẫn ra (không `reverse()` — reverse
  làm curve chạy ngược, sai bản gốc). Đồng hồ tự ẩn là một
  `AnimationController` (không `Timer` — nút freeze của viewer dừng được).
- Retrigger khi đang hiện: chỉ gia hạn đồng hồ, KHÔNG replay cú rơi — đúng
  handler gốc (`classList.add('show')` no-op khi đã show).
- Số liệu giữ nguyên: zone 240×130, top 14, padding 11×18, gap 9, dot ok 8px,
  pill radius 100, text 13 và palette gốc. Nút Notify chỉ thuộc demo, không
  hardcode vào API.
- `disableAnimations` bỏ chuyển động nhưng vẫn giữ thời gian tự ẩn.
- Sai lệch chủ ý: CSS gốc `white-space: nowrap` để pill tràn tự do; Flutter
  ném overflow trong debug nên message dài được ellipsis 1 dòng thay vì tràn.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- Copy folder `notification_slide_in/`, import entry file.
- Hoặc chạy `dart tools/export.dart notification_slide_in`.

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `requestId` | `int` | `0` | Đổi giá trị để show/retrigger |
| `message` | `String` | `'New message received'` | Nội dung banner |
| `width` / `height` / `top` | `double` | `240 / 130 / 14` | Hình học vùng clip |
| `displayDuration` | `Duration` | `2200ms` | Thời gian trước khi exit |
| `backgroundColor` | `Color` | `#232326` | Nền pill |
| `borderColor` | `Color` | `#2A2A2E` | Viền pill |
| `textColor` | `Color` | `#EDE9E0` | Màu chữ |
| `dotColor` | `Color` | `#4CD08A` | Dot success |
| `onDismissed` | `VoidCallback?` | null | Gọi sau exit |
| `animate` | `bool` | `true` | false = state visible ổn định, không auto-dismiss |

## Caveats

- `requestId` phải đổi để retrigger; pattern đơn giản nhất là tăng counter.
- Widget tự clip theo `height`; đặt overlay toàn màn hình cần tự định vị wrapper.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `NotificationSlideIn` ở lớp overlay cục bộ. Tăng `requestId` khi có
sự kiện mới, truyền message và đồng bộ state ngoài qua `onDismissed` nếu cần.
