---
# --- IDENTITY ---
id: radar_pulse
title: Radar Pulse
kind: effect
tags: [radar, sonar, ping, ripple, loader, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: radar_pulse.dart
files:
  - radar_pulse.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Radar Pulse' (Surface & Motion)"
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

# Radar Pulse

Chấm lõi amber phát sáng với ba vòng sonar giãn ra rồi tan biến, vòng mới
phóng đi trước khi vòng cũ kịp tắt.

## Port notes

- Effect gốc: "Radar Pulse", section **Surface & Motion**, kinetics. Đã đọc
  `.demo-radar`/`.demo-radar-core`/`.demo-radar-wave` trong `effects-c.css`;
  không có JS.
- Cơ chế gốc: **CSS keyframes** `radar-ping` 2.4s
  `cubic-bezier(0, 0.4, 0.2, 1)` vô hạn, 3 vòng delay 0/0.8/1.6s.
- Số giữ nguyên: stage 120, core 16 (radial amber→amber-deep 70%, glow blur
  14 alpha 0.5), vòng 24 viền 2, scale 0.4→4.2, opacity 0.9→0. Viền vòng
  scale theo transform như CSS (strokeWidth × scale).
- Lệch có chủ ý: CSS delay dương làm 1.6s đầu hai vòng sau đứng yên ở style
  gốc (chưa animate); port modulo về trạng thái steady ngay từ frame đầu.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `radar_pulse/` folder (1 dart file(s), see `files`)
- **Import:** `import 'radar_pulse/radar_pulse.dart';` — one line
- **Or:** `dart tools/export.dart radar_pulse` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `size` | `double` | `120` | Cạnh stage vuông |
| `waveCount` | `int` | `3` | Số vòng bay đồng thời, delay đều nhau |
| `color` | `Color` | `#FF8A00` | Màu vòng + lõi |
| `deepColor` | `Color` | `#B36200` | Stop ngoài của gradient lõi |
| `coreSize` | `double` | `16` | Đường kính lõi |
| `waveBaseSize` | `double` | `24` | Đường kính vòng chưa scale |
| `waveStrokeWidth` | `double` | `2` | Viền vòng chưa scale |
| `startScale` / `endScale` | `double` | `0.4 / 4.2` | Hành trình scale |
| `startOpacity` | `double` | `0.9` | Opacity lúc phóng |
| `period` | `double` | `2.4` | Giây mỗi vòng bay |
| `animate` | `bool` | `true` | Cho phép ticker chạy |
| `frozenAt` | `double?` | null | Render frame tại t giây, không ticker |

## Caveats

- Vòng scale 4.2 vượt stage 120 (100.8px sát mép); ancestor clip sát sẽ cắt
  đỉnh vòng — như bản web (`overflow:hidden` của card-stage).
- Glow lõi dùng `MaskFilter.blur` mỗi frame — rẻ ở size này, đo lại nếu
  phóng to nhiều instance.

## Changelog

- **1.0.0** (2026-08-26) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `RadarPulse` làm chỉ báo scanning/searching/live. Đổi `color` theo
ngữ nghĩa, `waveCount`/`period` chỉnh mật độ ping; `frozenAt` cho thumbnail,
tắt `animate` khi khuất.
