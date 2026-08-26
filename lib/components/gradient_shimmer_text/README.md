---
# --- IDENTITY ---
id: gradient_shimmer_text
title: Gradient Shimmer Text
kind: effect
tags: [text, shimmer, gradient, sweep, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: gradient_shimmer_text.dart
files:
  - gradient_shimmer_text.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Gradient Shimmer Text' (Surface & Motion)"
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-26
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

# Gradient Shimmer Text

Chữ display được tô bằng gradient xám–amber–xám quét qua vô hạn: vệt sáng
trượt dọc chữ mỗi ba giây, đều tuyệt đối (linear).

## Port notes

- Effect gốc: "Gradient Shimmer Text", section **Surface & Motion**,
  kinetics. Đã đọc `.demo-shimmer-text` trong `effects-c.css`; không có JS.
- Cơ chế gốc: **CSS keyframes** — `background-position: 0 → -200%` trên
  gradient `linear-gradient(100deg, #6E6C68 30%, #FF8A00 50%, #6E6C68 70%)`
  size 200%, 3s linear, clip vào glyph.
- Flutter: `ShaderMask(BlendMode.srcIn)` + `ui.Gradient.linear` tile
  `repeated`. Vệt trượt dọc theo trục nghiêng của gradient (thay vì trục x)
  để chu kỳ dịch trùng khít chu kỳ tile — loop liền mạch; pha khởi đầu lệch
  hằng số so với CSS (vô hình trong loop).
- Font gốc Archivo 900/40px không bundle được (zero asset) → dùng font mặc
  định `w900` 40px, tracking −0.02em giữ nguyên; truyền `style` để đổi font.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `gradient_shimmer_text/` folder (1 dart file(s), see `files`)
- **Import:** `import 'gradient_shimmer_text/gradient_shimmer_text.dart';` — one line
- **Or:** `dart tools/export.dart gradient_shimmer_text` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `text` | `String` | `KINETIC` | Nội dung chữ |
| `style` | `TextStyle?` | null | Merge lên style gốc (w900/40/−0.02em); màu luôn từ gradient |
| `dimColor` | `Color` | `#6E6C68` | Hai đầu gradient |
| `highlightColor` | `Color` | `#FF8A00` | Vệt sáng giữa |
| `angleDegrees` | `double` | `100` | Góc gradient theo quy ước CSS |
| `period` | `double` | `3` | Giây mỗi lượt quét |
| `animate` | `bool` | `true` | Cho phép ticker chạy |
| `frozenAt` | `double?` | null | Render frame tại t giây, không ticker |

## Caveats

- `ShaderMask` tạo saveLayer — với đoạn chữ rất dài trên màn lớn nên đo perf.
- Vệt sáng chỉ hiện nửa sau mỗi chu kỳ (đúng demo gốc): nửa đầu chữ nằm ở
  vùng dim phẳng của gradient.
- Muốn đúng mặt chữ Archivo của bản web thì bundle font đó ở app và truyền
  qua `style` — component không mang asset.

## Changelog

- **1.0.0** (2026-08-26) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `GradientShimmerText` cho tiêu đề hero hoặc wordmark. Đổi `text`,
truyền `style` (font/cỡ), giữ `period` 3s cho cảm giác gốc; dùng `frozenAt`
cho thumbnail và tắt `animate` khi khuất.
