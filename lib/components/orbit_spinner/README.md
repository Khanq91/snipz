---
# --- IDENTITY ---
id: orbit_spinner
title: Orbit Spinner
kind: effect
tags: [spinner, loader, loading, ring, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: orbit_spinner.dart
files:
  - orbit_spinner.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Orbit Spinner' (Feedback & State)"
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

# Orbit Spinner

Vòng loading tối giản dựng lại từ kinetics "Orbit Spinner": nửa vòng cung
amber xoay đều trên track mờ, một vòng/0.8s linear. `CustomPainter` hai nét
arc — không widget lồng nhau, không layout trick.

## Port notes

- Effect gốc: "Orbit Spinner", section **Feedback & State**, kinetics
  (`github.com/ckissi/kinetics`). Source: card trong `src/content/body.html`,
  style mục "20" trong `public/css/effects-b.css` (`.demo-spinner`), không
  có JS.
- Cơ chế gốc: **CSS keyframes** — `border: 4px` với `border-top/right-color`
  amber trên phần tử tròn + `rotate(1turn) 0.8s linear infinite`.
- Số liệu giữ nguyên: 44px, nét 4px, chu kỳ 0.8s, amber `#FF8A00`, track
  `#232326`.
- Diễn giải: border-top + border-right của phần tử tròn = **nửa vòng liền**
  (mối nối nằm trên đường chéo 45°) → vẽ bằng một arc sweep 180°.
- Theo quy ước sample(t): frame = hàm thuần của `t`, có `frozenAt` +
  `animate`, ticker tôn trọng `MediaQuery.disableAnimations`.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `orbit_spinner/` folder (1 dart file(s), see `files`)
- **Import:** `import 'orbit_spinner/orbit_spinner.dart';` — one line
- **Or:** `dart tools/export.dart orbit_spinner` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `size` | `double` | `44` | Đường kính ngoài |
| `strokeWidth` | `double` | `4` | Bề dày nét |
| `color` | `Color` | `#FF8A00` | Nửa vòng xoay (amber) |
| `trackColor` | `Color` | `#232326` | Vòng nền |
| `period` | `double` | `0.8` | Giây mỗi vòng |
| `animate` | `bool` | `true` | false = đứng im (freeze/reduced motion) |
| `frozenAt` | `double?` | null | Render đúng 1 frame tại t giây, không ticker |

## Caveats

- Ticker chạy liên tục khi hiển thị — ngoài viewport hãy đặt `animate:
  false` hoặc bọc `TickerMode(enabled: false)` (§9.2).
- Cost: chưa đo (hai nét arc mỗi frame — không đáng kể).

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `OrbitSpinner` vào project này.

**Context**
- Chức năng: vòng loading nửa cung xoay 0.8s (port kinetics "Orbit Spinner").
  Tự chạy bằng Ticker; `frozenAt` render tĩnh.
- Public API: xem bảng API trong README. Class `OrbitSpinner`.
- Portability: single_file — copy cả `orbit_spinner/` (1 file), import duy nhất `orbit_spinner.dart`.
- Deps: không có — Flutter SDK only (widgets layer, không cần Material).

**Việc cần làm**
1. Copy folder `orbit_spinner/` vào <thư mục widget của project đích>.
2. Đặt vào chỗ loading (thay `CircularProgressIndicator`); chỉnh `size`/màu.

**Việc cần adapt theo project đích**
- Color/theme token: đổi `color`/`trackColor` sang token của project.
- Ngoài viewport/danh sách dài: truyền `animate: false` khi khuất.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
