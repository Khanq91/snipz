---
# --- IDENTITY ---
id: neon_glow_pulse
title: Neon Glow Pulse
kind: effect
tags: [neon, glow, pulse, badge, pill, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: neon_glow_pulse.dart
files:
  - neon_glow_pulse.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Neon Glow Pulse' (Surface & Motion)"
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

# Neon Glow Pulse

Pill neon viền amber có quầng sáng "thở" theo chu kỳ hai giây: text-shadow,
glow ngoài và glow trong cùng phồng lên rồi dịu xuống.

## Port notes

- Effect gốc: "Neon Glow Pulse", section **Surface & Motion**, kinetics. Đã
  đọc `.demo-neon` trong `effects-c.css`; không có logic trong `main.js`.
- Cơ chế gốc: **CSS keyframes** 2s `ease-in-out` lặp vô hạn, easing chạy lại
  cho từng chặng 0→50/50→100.
- Số giữ nguyên: text-shadow blur 4→12 + lớp thứ hai 0→22 (CSS nội suy
  shadow thiếu từ transparent — port lerp cả alpha); box-shadow ngoài blur
  6/spread −1 → blur 18/spread 0; inset blur 6→12 spread −2; padding 10×22,
  chữ 14/600, tracking 0.18em, radius 100.
- Flutter không có inset box-shadow: glow trong xấp xỉ bằng stroke blur clip
  trong pill; glow ngoài clip ra ngoài border-box đúng như CSS outset shadow.
- Font mono của demo thay bằng `fontFamily: 'monospace'` hệ thống (zero
  asset). Label `ONLINE` mở qua `child`.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `neon_glow_pulse/` folder (1 dart file(s), see `files`)
- **Import:** `import 'neon_glow_pulse/neon_glow_pulse.dart';` — one line
- **Or:** `dart tools/export.dart neon_glow_pulse` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `color` | `Color` | `#FF8A00` | Accent cho chữ, viền và mọi lớp glow |
| `borderRadius` | `double` | `100` | Bo góc pill |
| `borderWidth` | `double` | `1` | Độ dày viền |
| `padding` | `EdgeInsetsGeometry` | `22 × 10` | Padding quanh nội dung |
| `fontSize` | `double` | `14` | Cỡ chữ mặc định |
| `letterSpacingEm` | `double` | `0.18` | Tracking theo em, nhân với fontSize |
| `period` | `double` | `2` | Giây mỗi chu kỳ glow |
| `animate` | `bool` | `true` | Cho phép ticker chạy |
| `frozenAt` | `double?` | null | Render frame tại t giây, không ticker |
| `child` | `Widget?` | label `ONLINE` | Nội dung giữa pill |

## Caveats

- Glow vẽ tràn ra ngoài layout box (blur ngoài tới ~26px); chừa khoảng trống
  và tránh ancestor clip sát mép.
- `MaskFilter.blur` mỗi frame có chi phí GPU; tắt `animate` cho item khuất.
- Glow trong là xấp xỉ (Flutter thiếu inset shadow) — sát demo gốc ở mức
  nhìn, không phải từng pixel.

## Changelog

- **1.0.0** (2026-08-26) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `NeonGlowPulse` làm status badge hoặc CTA ambient. Truyền nội dung
qua `child`, đổi `color` theo ngữ nghĩa (online/error), dùng `frozenAt` cho
thumbnail và tắt `animate` khi widget khuất.
