---
# --- IDENTITY ---
id: irregular_typewriter
title: Irregular Typewriter
kind: effect
tags: [text, typewriter, cursor, terminal, animated, animejs]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: irregular_typewriter.dart
files:
  - irregular_typewriter.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/juliangarnier/anime (examples/irregular-playback-typewriter)
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

# Irregular Typewriter

Chữ tự gõ với nhịp KHÔNG đều như người thật: thời điểm hiện từng ký tự sinh
từ trọng số ngẫu nhiên có seed (bùng nhanh một cụm, khựng lại một nhịp) —
port `easings.irregular` của anime.js v4 thành lịch reveal tường minh. Con
trỏ khối nhảy bậc theo ký tự cuối và nháy 750ms. Hỗ trợ wrap nhiều dòng
(phần chưa gõ đo layout bằng span trong suốt nên chữ không nhảy dòng lại).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `irregular_typewriter/` folder (1 dart file(s), see `files`)
- **Import:** `import 'irregular_typewriter/irregular_typewriter.dart';` — one line
- **Or:** `dart tools/export.dart irregular_typewriter` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `text` | `String` | (bắt buộc) | Nội dung gõ |
| `style` | `TextStyle` | mono 22 sáng | Style chữ |
| `cursorColor` | `Color?` | `null` | Màu con trỏ khối; null = màu chữ |
| `charInterval` | `Duration` | `125ms` | Nhịp trung bình mỗi ký tự |
| `irregularity` | `double` | `2.0` | 0 = đều tăm tắp, 2 = như bản gốc, cao hơn = khựng dữ hơn |
| `loop` | `bool` | `true` | Gõ lại sau `holdDuration`; `false` gõ một lần |
| `holdDuration` | `Duration` | `2600ms` | Giữ dòng hoàn chỉnh trước khi gõ lại |
| `textAlign` | `TextAlign` | `left` | Căn chữ |
| `seed` | `int` | `5` | Seed nhịp gõ |
| `animate` | `bool` | `true` | `false` render cả dòng tĩnh |
| `frozenAt` | `double?` | `null` | Render đúng 1 frame tại t giây, không ticker |

## Caveats

- Reduced-motion / `animate:false` hiện nguyên dòng (không gõ) — chủ đích.
- Đo caret bằng `TextPainter.getOffsetForCaret` nên emoji/cluster phức tạp
  vẫn đúng vị trí, nhưng chữ RTL chưa được tính cho con trỏ khối.

## Changelog

- **1.0.0** (2026-08-23) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `IrregularTypewriter` vào project này.

**Context**
- Chức năng: dòng chữ tự gõ nhịp người thật + con trỏ khối nháy; dùng cho hero text, terminal UI, lời thoại.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `irregular_typewriter/` (1 file), import duy nhất `irregular_typewriter.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `irregular_typewriter/` vào <thư mục widget của project đích>.
2. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
