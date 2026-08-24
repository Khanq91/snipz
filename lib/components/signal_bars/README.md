---
# --- IDENTITY ---
id: signal_bars
title: Signal Bars
kind: effect
tags: [signal, connecting, bars, indicator, loading, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: signal_bars.dart
files:
  - signal_bars.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Signal Bars' (Feedback & State)"
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

# Signal Bars

Chỉ báo "đang kết nối" dựng lại từ kinetics "Signal Bars": 4 cột cao dần,
lớp fill xanh sáng lên tuần tự trái → phải (lệch 0.18s), giữ, rồi tắt và
lặp — như thiết bị dò sóng. Chu kỳ 2.4s ease-in-out.

## Port notes

- Effect gốc: "Signal Bars", section **Feedback & State**, kinetics
  (`github.com/ckissi/kinetics`). Source: card trong `src/content/body.html`,
  style mục "31" trong `public/css/effects-b.css` (`.demo-signal`), không
  có JS.
- Cơ chế gốc: **CSS keyframes** — `::after` phủ màu `--ok`, opacity
  keyframe 0%:0 → 12%:1 → giữ 70% → 82%:0, delay `i × 0.18s`.
- Số liệu giữ nguyên: cao cột 32/55/78/100% của 56px, rộng 14, gap 6,
  radius 4, nền `#232326` viền `#2A2A2E`, fill `#4CD08A`, chu kỳ 2.4s.
- Sai lệch nhỏ: CSS phủ fill lên toàn bộ khung (đè cả mép trong của
  border); bản Flutter clip fill vào trong viền (radius-1) — nhìn gọn hơn,
  khác biệt ~1px.
- Theo quy ước sample(t): `frozenAt` + `animate`, tôn trọng
  `disableAnimations`.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `signal_bars/` folder (1 dart file(s), see `files`)
- **Import:** `import 'signal_bars/signal_bars.dart';` — one line
- **Or:** `dart tools/export.dart signal_bars` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `heights` | `List<double>` | `[0.32, 0.55, 0.78, 1.0]` | Cao từng cột (tỉ lệ của `height`), trái → phải |
| `height` | `double` | `56` | Cao hàng cột |
| `barWidth` | `double` | `14` | Rộng mỗi cột |
| `gap` | `double` | `6` | Khoảng cách cột |
| `radius` | `double` | `4` | Bo góc cột |
| `barColor` | `Color` | `#232326` | Nền cột rỗng |
| `borderColor` | `Color` | `#2A2A2E` | Viền cột |
| `fillColor` | `Color` | `#4CD08A` | Lớp sáng (xanh ok) |
| `period` | `double` | `2.4` | Giây mỗi chu kỳ |
| `stagger` | `double` | `0.18` | Delay mỗi cột |
| `animate` | `bool` | `true` | false = đứng im |
| `frozenAt` | `double?` | null | Render đúng 1 frame tại t giây, không ticker |

## Caveats

- Đây là animation loop "đang kết nối", KHÔNG phải hiển thị mức sóng tĩnh —
  cần mức tĩnh thì dùng `frozenAt` chọn khoảnh khắc, hoặc yêu cầu bản mở
  rộng có param `level`.
- Ticker chạy khi hiển thị — tắt bằng `animate: false` khi khuất (§9.2).
- Cost: chưa đo (4 Container + ClipRRect mỗi frame).

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `SignalBars` vào project này.

**Context**
- Chức năng: 4 cột sáng tuần tự kiểu "đang dò sóng/kết nối" (port kinetics
  "Signal Bars"). Tự chạy bằng Ticker; `frozenAt` render tĩnh.
- Public API: xem bảng API trong README. Class `SignalBars`.
- Portability: single_file — copy cả `signal_bars/` (1 file), import duy nhất `signal_bars.dart`.
- Deps: không có — Flutter SDK only (widgets layer, không cần Material).

**Việc cần làm**
1. Copy folder `signal_bars/` vào <thư mục widget của project đích>.
2. Hiện trong trạng thái connecting/reconnecting; thay bằng icon mức sóng
   thật khi đã kết nối.

**Việc cần adapt theo project đích**
- Màu: đổi `fillColor` sang accent của app; nền sáng đổi `barColor`/viền.
- Kích thước: co bằng `height`/`barWidth`/`gap` (giữ tỉ lệ `heights`).

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
