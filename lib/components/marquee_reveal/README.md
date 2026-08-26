---
# --- IDENTITY ---
id: marquee_reveal
title: Marquee Reveal
kind: effect
tags: [marquee, scroll, strip, loop, pause, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: marquee_reveal.dart
files:
  - marquee_reveal.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Marquee Reveal' (Surface & Motion)"
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

# Marquee Reveal

Dải card đánh số cuộn ngang vô hạn trong cửa sổ bo góc; giữ ngón tay lên là
dải dừng ngay tại chỗ, thả ra chạy tiếp — không tua lại.

## Port notes

- Effect gốc: "Marquee Reveal", section **Surface & Motion**, kinetics. Đã
  đọc `.demo-reveal-zone`/`-track`/`-card` trong `effects-c.css`; không JS.
- Cơ chế gốc: **CSS keyframes** `translateX(0 → -50%)` 6s linear vô hạn;
  `:hover` trên track đặt `animation-play-state: paused`.
- Hover → press: pointer down dừng đồng hồ, up/cancel chạy tiếp (đúng ngữ
  nghĩa play-state paused — giữ chỗ, không rewind).
- Số giữ nguyên: cửa sổ 220×100 radius 14 nền `#141417` viền `#2A2A2E`;
  card 80×64 radius 9 nền `#232326`, chữ mono 11 `#A8A6A0`, gap 12, 5 nhãn
  01–05 nhân đôi, 6s linear.
- Lệch có chủ ý: bản gốc translate −50% của track 908px trong khi chu kỳ
  thật là 460px → seam nhảy 6px mỗi vòng; port cuộn đúng chu kỳ một bộ nhãn
  nên loop liền mạch.
- Prompt tab tả "fade gradient hai mép" nhưng CSS sống không có mask — port
  theo CSS sống (chỉ clip).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `marquee_reveal/` folder (1 dart file(s), see `files`)
- **Import:** `import 'marquee_reveal/marquee_reveal.dart';` — one line
- **Or:** `dart tools/export.dart marquee_reveal` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `labels` | `List<String>` | `01…05` | Nhãn một chu kỳ, lặp liền mạch |
| `width` / `height` | `double` | `220 / 100` | Cửa sổ clip |
| `cardWidth` / `cardHeight` | `double` | `80 / 64` | Kích thước card |
| `gap` | `double` | `12` | Khoảng cách card |
| `borderRadius` / `cardRadius` | `double` | `14 / 9` | Bo góc cửa sổ / card |
| `backgroundColor` / `cardColor` / `borderColor` | `Color` | tokens gốc | Màu nền/card/viền |
| `labelStyle` | `TextStyle` | mono 11 `#A8A6A0` | Chữ trên card |
| `period` | `double` | `6` | Giây mỗi chu kỳ nhãn |
| `pauseOnPress` | `bool` | `true` | Giữ tay để dừng |
| `animate` | `bool` | `true` | Cho phép ticker chạy |
| `frozenAt` | `double?` | null | Render frame tại t giây, không ticker |

## Caveats

- Track dựng bằng widget và cache qua `child` của ValueListenableBuilder —
  mỗi frame chỉ translate, không re-layout text.
- `labels` dài làm track rộng tương ứng (2 bản sao); hàng trăm nhãn thì nên
  thu bớt.
- Press pause nuốt pointer down; đặt trong scrollable thì cân nhắc
  `pauseOnPress: false` để không tranh gesture.

## Changelog

- **1.0.0** (2026-08-26) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `MarqueeReveal` cho dải logo/tag/testimonial cuộn ambient. Truyền
`labels`, chỉnh `period` theo mật độ; `frozenAt` cho thumbnail, tắt
`animate` khi khuất.
