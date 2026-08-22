---
# --- IDENTITY ---
id: calm_onboard
title: Calm Onboard
kind: composite
tags: [screen, onboarding, pager, swipe, day-night, sun, moon, stars, arc-slider, parallax]

# --- TAXONOMY (§2) ---
paint_source: widget
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: calm_onboard.dart
files:
  - calm_onboard.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: adapted
source: https://github.com/mortspace
author: "Khang"
license: "unspecified — FeralUI reference copy carried no LICENSE (© mortspace)"

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-22
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

# Calm Onboard

Onboarding as one continuous day (port of FeralUI's OnboardScreen): three
swipeable pages scrub the sun and moon along a great circle while the sky
cross-fades morning → golden hour → night, stars/clouds/birds come and go,
and a dotted arc slider mirrors the drag. Page settling is a real spring
(slower entering night). The landscape is a procedural painting replacing
the upstream `land.webp`.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `calm_onboard/` folder (1 dart file(s), see `files`)
- **Import:** `import 'calm_onboard/calm_onboard.dart';` — one line
- **Or:** `dart tools/export.dart calm_onboard` → zip + paste-ready block

## API

### `CalmOnboardScreen`

| Param | Type | Default | Meaning |
|---|---|---|---|
| `onNext` | `VoidCallback?` | — | Skip button, and the CTA on the night page. |
| `onPhase` | `ValueChanged<bool>?` | — | Fires with `true`/`false` entering/leaving night. |
| `pages` | `List<CalmOnboardPage>` | upstream copy | Exactly 3 pages (title + body). |
| `initialPage` | `int` | `0` | 0 morning · 1 midday · 2 night. |
| `palette` | `CalmOnboardPalette` | sunset | Warm `--sc-*` colors (sky mixes derive from them). |
| `animate` | `bool` | `true` | False = settled still, no ticker; swipe/arc still work. |

## Caveats

- The whole-body swipe layer stops 140 px above the bottom so the arc + CTA
  stay tappable — same as the upstream `.ob-scrub`.
- The upstream file's CSS for `.ob-copy`/`.ob-foot`/`.ob-arc` was missing;
  their styling here is reconstructed to match the family.
- Landscape, clouds, birds, crescent are procedural (no assets).
- One ticker rebuilds the screen per frame; use `animate: false` in grids.

## Changelog

- **1.0.0** (2026-08-22) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `CalmOnboardScreen` vào project này.

**Context**
- Chức năng: onboarding 3 trang kéo ngang — mặt trời/trăng chạy cung tròn, trời chuyển ngày→đêm, arc slider scrub được.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `calm_onboard/` (1 file), import duy nhất `calm_onboard.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `calm_onboard/` vào <thư mục widget của project đích>.
2. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối `onNext`/`onPhase` vào flow điều hướng của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
