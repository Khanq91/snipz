---
# --- IDENTITY ---
id: firefly_swarm
title: Firefly Swarm
kind: effect
tags: [particles, fireflies, touch, glow, ambient, animated, animejs]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: firefly_swarm.dart
files:
  - firefly_swarm.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/juliangarnier/anime (examples/additive-fireflies)
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

# Firefly Swarm

225 "đom đóm" 3 tông màu vo ve quanh một vành tròn bám theo ngón tay: chạm
để gọi bầy, giữ để vành nở ×2.5 và bầy tản rộng, thả tay thì bầy trôi theo
một điểm tự lượn lissajous. Port ví dụ `additive-fireflies` của anime.js v4;
nhịp reroll 250ms + composition blend của bản gốc được thay bằng đuổi mũ
(exponential pursuit) theo từng hạt với target trên vành.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `firefly_swarm/` folder (1 dart file(s), see `files`)
- **Import:** `import 'firefly_swarm/firefly_swarm.dart';` — one line
- **Or:** `dart tools/export.dart firefly_swarm` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `count` | `int` | `225` | Số đom đóm (15² như bản gốc) |
| `colors` | `List<Color>` | đỏ/cam/coral | Tông màu, gán ngẫu nhiên theo seed |
| `backgroundColor` | `Color` | `0xFF120D0B` | Nền; `transparent` để overlay |
| `dotRadius` | `double` | `3.2` | Bán kính hạt cơ sở (mỗi hạt scale ×0.6..1.5) |
| `ringRadius` | `double` | `64` | Bán kính vành nghỉ; giữ tay nở ×2.5 |
| `interactive` | `bool` | `true` | `false` bỏ qua touch |
| `showRing` | `bool` | `true` | Vòng tròn mờ đánh dấu con trỏ |
| `seed` | `int` | `3` | Seed PRNG |
| `animate` | `bool` | `true` | `false` dừng ticker |
| `frozenAt` | `double?` | `null` | Render đúng 1 frame tại t giây, không ticker |

## Caveats

- Mỗi hạt vẽ 2 lần (glow gradient + lõi) → 450 draw call với count mặc
  định; máy rất yếu giảm `count` xuống ~120.
- Trên nền sáng nên đổi `colors` sang tông đậm — glow alpha .5 tính cho
  nền tối.

## Changelog

- **1.0.0** (2026-08-23) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `FireflySwarm` vào project này.

**Context**
- Chức năng: hiệu ứng bầy đom đóm bám ngón tay (chạm = gọi bầy, giữ = tản rộng); đặt fullscreen hoặc làm nền section tối.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `firefly_swarm/` (1 file), import duy nhất `firefly_swarm.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `firefly_swarm/` vào <thư mục widget của project đích>.
2. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
