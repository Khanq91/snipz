---
# --- IDENTITY ---
id: toast_stack
title: Toast Stack
kind: effect
tags: [toast, stack, notification, queue, timed, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: toast_stack.dart
files:
  - toast_stack.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Toast Stack' (Feedback & State)"
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

# Toast Stack

Stack toast neo đáy, tối đa ba item, dựng lại từ kinetics "Toast Stack".
Toast mới slide lên với overshoot, tự ẩn sau 2.4s; item cũ nhất exit trước khi
bị loại khi hàng đợi vượt giới hạn.

## Port notes

- Source thật: `.demo-toaststack-*` trong `body.html`, mục `24. Toast stack`
  của `effects-b.css`, handler `24b` trong `main.js`.
- Cơ chế gốc: **CSS transition + JS tạo DOM/timer**. Enter dùng
  `translateY(100%) scale(.9) → 0/1`, 0.5s
  `Cubic(0.18,1.25,0.4,1)`; opacity 0.3s; dismiss sau 2400ms; cleanup 400ms.
- Flutter giữ controller riêng cho enter/opacity/lifecycle/exit của mỗi item.
  Không `Timer`; vượt `maxToasts` đánh dấu oldest exit một lần rồi loại an toàn.
- Số liệu giữ nguyên: width 200, height 130, gap 6, padding 9×14, dot 7,
  radius 9 (`--radius-sm`), exit xuống 20px scale .9, palette gốc.
- Sai lệch nhỏ: CSS đặt transform transition 0.5s nhưng JS remove DOM ở 0.4s;
  Flutter hoàn tất exit trong đúng cửa sổ cleanup 0.4s thay vì cắt animation.
  Nút Push toast chỉ thuộc demo.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- Copy folder `toast_stack/`, import `toast_stack.dart`.
- Hoặc chạy `dart tools/export.dart toast_stack`.

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `pushId` | `int` | `0` | Đổi giá trị để push toast |
| `messageBuilder` | `String Function(int)?` | null | Mặc định `Saved #id` |
| `initialMessages` | `List<String>` | `[]` | Stack khởi tạo/preview |
| `maxToasts` | `int` | `3` | Số item active tối đa |
| `width` / `height` / `gap` | `double` | `200 / 130 / 6` | Hình học stack |
| `displayDuration` | `Duration` | `2400ms` | Thời gian sống |
| `backgroundColor` | `Color` | `#232326` | Nền toast |
| `borderColor` | `Color` | `#2A2A2E` | Viền |
| `textColor` / `dotColor` | `Color` | `#EDE9E0 / #4CD08A` | Chữ/dot |
| `onDismissed` | `ValueChanged<int>?` | null | Nhận lại `pushId` khi loại |
| `animate` | `bool` | `true` | false = stack tĩnh, không auto-dismiss |

## Caveats

- `pushId` phải đổi cho mỗi event; dùng counter tăng dần là đơn giản nhất.
- Mỗi toast sống có bốn controller; mặc định cap 3 nên chi phí bị giới hạn.
- `initialMessages` dùng cho state tĩnh; toast phát sinh từ `pushId` mới có id
  nghiệp vụ để trả qua `onDismissed`.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `ToastStack` ở overlay neo đáy. Tăng `pushId` cho mỗi event, tạo nội
dung qua `messageBuilder`, và giữ `maxToasts` nhỏ để giới hạn controller sống.
