---
# --- IDENTITY ---
id: shimmer_skeleton
title: Shimmer Skeleton
kind: effect
tags: [skeleton, shimmer, loading, placeholder, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: shimmer_skeleton.dart
files:
  - shimmer_skeleton.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Shimmer Skeleton' (Feedback & State)"
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

# Shimmer Skeleton

Skeleton loading dựng lại từ kinetics "Shimmer Skeleton": các thanh bo tròn
xếp chồng, vệt highlight mờ quét ngang 1.5s linear lặp vô hạn, thanh cuối
ngắn 60% gợi ý đoạn văn. Bề rộng theo parent; một `CustomPainter` vẽ tất cả
thanh với chung một gradient.

## Port notes

- Effect gốc: "Shimmer Skeleton", section **Feedback & State**, kinetics
  (`github.com/ckissi/kinetics`). Source: card trong `src/content/body.html`,
  style mục "27" trong `public/css/effects-b.css` (`.demo-shimmer`), không
  có JS.
- Cơ chế gốc: **CSS keyframes** — `background-size: 280%`,
  `background-position` chạy `140% → -140%` 1.5s linear.
- Số liệu giữ nguyên: gradient stops 0/20/40% (`#232326` → `#2A2A2E` →
  `#232326`), thanh cao 12 radius 6, gap 11, thanh cuối 60%, chu kỳ 1.5s.
  Toán background-position dịch nguyên văn: `x0 = (w - 2.8w) · P/100`.
- Theo quy ước sample(t): `frozenAt` + `animate`, tôn trọng
  `disableAnimations`.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `shimmer_skeleton/` folder (1 dart file(s), see `files`)
- **Import:** `import 'shimmer_skeleton/shimmer_skeleton.dart';` — one line
- **Or:** `dart tools/export.dart shimmer_skeleton` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `lines` | `int` | `3` | Số thanh |
| `lineHeight` | `double` | `12` | Cao mỗi thanh (radius = height/2) |
| `gap` | `double` | `11` | Khoảng cách dọc |
| `shortFactor` | `double` | `0.6` | Bề rộng thanh cuối (tỉ lệ) |
| `baseColor` | `Color` | `#232326` | Màu nền thanh |
| `highlightColor` | `Color` | `#2A2A2E` | Vệt highlight quét |
| `period` | `double` | `1.5` | Giây mỗi lượt quét |
| `animate` | `bool` | `true` | false = đứng im |
| `frozenAt` | `double?` | null | Render đúng 1 frame tại t giây, không ticker |

Bề rộng theo parent — bọc `SizedBox(width: ...)` để cố định (demo dùng 230).

## Caveats

- Ticker chạy khi hiển thị — list nhiều skeleton hãy tắt những cái khuất
  (`animate: false` / `TickerMode`), hoặc dùng chung một widget lớn thay vì
  n widget nhỏ.
- Highlight của kinetics rất mờ (`#2A2A2E` trên `#232326`) — đúng bản gốc;
  muốn nổi hơn thì tăng `highlightColor`.
- Cost: chưa đo (n RRect + 1 gradient shader mỗi frame).

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `ShimmerSkeleton` vào project này.

**Context**
- Chức năng: skeleton thanh ngang với vệt highlight quét (port kinetics
  "Shimmer Skeleton"). Tự chạy bằng Ticker; `frozenAt` render tĩnh.
- Public API: xem bảng API trong README. Class `ShimmerSkeleton`.
- Portability: single_file — copy cả `shimmer_skeleton/` (1 file), import duy nhất `shimmer_skeleton.dart`.
- Deps: không có — Flutter SDK only (widgets layer, không cần Material).

**Việc cần làm**
1. Copy folder `shimmer_skeleton/` vào <thư mục widget của project đích>.
2. Đặt vào chỗ chờ data, bọc `SizedBox(width: ...)`; swap sang nội dung thật
   khi load xong (hoặc dùng component `skeleton_content` nếu cần transition).

**Việc cần adapt theo project đích**
- Nền sáng: đổi `baseColor`/`highlightColor` (ví dụ `#E8E8E8`/`#F4F4F4`).
- Khớp layout thật: chỉnh `lines`/`lineHeight`/`gap` theo text sẽ thay thế.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
