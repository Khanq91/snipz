---
# --- IDENTITY ---
id: orbital_action_menu
title: Orbital Action Menu
kind: effect
tags: [menu, radial, orbit, fab, spring, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: orbital_action_menu.dart
files:
  - orbital_action_menu.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Orbital Action Menu' (Interaction & Input)"
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-24
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

# Orbital Action Menu

Menu radial mini: 4 action nhỏ chồng sau nút + cam ở tâm, bung ra 4 hướng
N/E/S/W (48px) bằng spring hơi overshoot; core xoay 45° (+→×) và co còn 0.88.

## Port notes

- Source thật: card `.demo-orbit-menu` trong `src/content/body.html`, CSS ở
  effects-a.css dòng 264-269. Không có JS — driver là `:hover` trên zone.
- Cơ chế gốc: **CSS transition, hover là lõi**. Map sang touch: **tap core
  toggle mở/đóng** (core vốn là button "Open actions" trong markup gốc nên
  đây là map tự nhiên nhất); tap một action bắn `onAction` và tự đóng
  (hover-out của web ≈ kết thúc thao tác).
- Số liệu giữ nguyên: zone 126×126, core 46 amber font 27 (rotate 45° +
  scale 0.88, 0.42s `Cubic(0.34,1.56,0.64,1)`), action 31 card-2/line font
  14, translate 48px, transform 0.46s spring + opacity 0.2s ease.
- Glyph mặc định ✦ ↗ ⌁ ⌘ (N/E/S/W) là text như bản gốc, thay qua `actions`.
- Sai lệch: bản web không tự đóng sau khi click action (vì hover vẫn giữ);
  bản touch đóng sau `onAction` — ghi rõ vì là quyết định UX cho mobile.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `orbital_action_menu/` folder (1 dart file(s), see `files`)
- **Import:** `import 'orbital_action_menu/orbital_action_menu.dart';` — one line
- **Or:** `dart tools/export.dart orbital_action_menu` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `actions` | `List<String>` | `['✦','↗','⌁','⌘']` | Glyph theo thứ tự N/E/S/W (tối đa 4) |
| `onAction` | `ValueChanged<int>?` | `null` | Bắn khi tap action (rồi tự đóng) |
| `initiallyOpen` | `bool` | `false` | Trạng thái ban đầu |
| `orbitRadius` | `double` | `48` | Bán kính quỹ đạo |
| `coreSize` / `actionSize` | `double` | `46 / 31` | Kích thước nút |
| `coreColor` / `coreIconColor` | `Color` | `#FF8A00 / #0E0E10` | Core |
| `actionColor` / `actionBorderColor` / `actionIconColor` | `Color` | card-2/line/bone-dim | Action |
| `onOpenChanged` | `ValueChanged<bool>?` | `null` | Báo trạng thái sau toggle |
| `animate` | `bool` | `true` | False = đổi trạng thái tức thì |

## Caveats

- Footprint 126×126 (vừa đủ quỹ đạo 48px + action 31px); tăng `orbitRadius`
  thì tự chừa thêm chỗ quanh component.
- Action khi đóng nằm sau core, không nhận tap (đúng
  `pointer-events: none` của bản gốc).

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `OrbitalActionMenu` như quick-action anchor. Map 4 glyph +
`onAction` theo lệnh thật; giữ nguyên bán kính 48, spring 0.42/0.46s và
core rotate 45°.
