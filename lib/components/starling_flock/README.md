---
# --- IDENTITY ---
id: starling_flock
title: Starling Flock
kind: effect
tags: [particles, flock, murmuration, ambient, animated, animejs]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: starling_flock.dart
files:
  - starling_flock.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/juliangarnier/anime (examples/timeline-refresh-starlings)
author: "Khang"
license: null

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-23
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

# Starling Flock

Đàn sáo (murmuration) hàng nghìn chấm: mỗi "con chim" lượn (~3s, inOut) tới
một điểm ngẫu nhiên trong vòng tròn vô hình đang trôi, thở và đổi bán kính
liên tục — cả đàn co cụm, dãn ra, đổi hướng như đàn sáo thật. Port ví dụ
`timeline-refresh-starlings` của anime.js v4, chạy hoàn toàn tự động, mọi
ngẫu nhiên đều từ PRNG có seed (cùng seed = cùng vũ điệu). Dùng làm nền
ambient cho hero/section.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `starling_flock/` folder (1 dart file(s), see `files`)
- **Import:** `import 'starling_flock/starling_flock.dart';` — one line
- **Or:** `dart tools/export.dart starling_flock` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `count` | `int` | `1200` | Số chim (bản gốc 2500 cho desktop) |
| `backgroundColor` | `Color` | `0xFFF6F4F2` | Nền; `transparent` để overlay |
| `colors` | `List<Color>?` | `null` | Bảng màu chim; null = ramp nâu sẫm gốc hsl(15..25,60%,10..18%) |
| `dotRadius` | `double` | `1.7` | Bán kính một chấm |
| `seed` | `int` | `7` | Seed PRNG — đổi seed đổi vũ điệu |
| `animate` | `bool` | `true` | `false` dừng ticker |
| `frozenAt` | `double?` | `null` | Render đúng 1 frame tại t giây, không ticker |

## Caveats

- Vẽ bằng `drawRawPoints` gom 6 bucket màu → 6 draw call cho cả đàn; 1200
  chim mượt trên máy tầm trung, 2500 vẫn ổn trên máy khá.
- Engine mở màn đã "seek" sẵn 20s (như bản gốc) nên đàn vào form ngay,
  không có đoạn túa ra từ tâm.
- Chấm là điểm tròn đồng kích thước, không phải sprite chim — đúng bản gốc.

## Changelog

- **1.0.0** (2026-08-23) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `StarlingFlock` vào project này.

**Context**
- Chức năng: nền ambient đàn sáo bay lượn tự động; đặt fullscreen phía sau nội dung hoặc trong một card lớn.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `starling_flock/` (1 file), import duy nhất `starling_flock.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `starling_flock/` vào <thư mục widget của project đích>.
2. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
