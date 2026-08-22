---
# --- IDENTITY ---
id: calm_welcome
title: Calm Welcome
kind: composite
tags: [screen, onboarding, welcome, mascot, orb, gradient, calm, sunset]

# --- TAXONOMY (§2) ---
paint_source: widget
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: calm_welcome.dart
files:
  - calm_welcome.dart: "entry, public API"
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

# Calm Welcome

Welcome screen of a calm/mindfulness app (port of FeralUI's WelcomeScreen):
a warm sunset gradient rises from the bottom, a glossy orb mascot with a
sleepy smile breathes at the top, and the copy, CTA and login link stagger
in on the upstream timeline. Fills its box; designed at 390x844.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `calm_welcome/` folder (1 dart file(s), see `files`)
- **Import:** `import 'calm_welcome/calm_welcome.dart';` — one line
- **Or:** `dart tools/export.dart calm_welcome` → zip + paste-ready block

## API

### `CalmWelcomeScreen`

| Param | Type | Default | Meaning |
|---|---|---|---|
| `onNext` | `VoidCallback?` | — | "Get started" tapped. |
| `onLogin` | `VoidCallback?` | — | "I already have an account" tapped. |
| `palette` | `CalmWelcomePalette` | sunset | All colors (the upstream `--sc-*` custom properties). |
| `title` / `body` / `buttonLabel` / `linkLabel` | `String` | upstream copy | The texts. |
| `animate` | `bool` | `true` | False = settled end state, no ticker (thumbnails, tests). Reduced-motion does the same. |

## Caveats

- Entrances replay on remount — give the widget a new `Key` to replay
  (upstream's `playKey`).
- One ticker drives the whole screen and rebuilds it per frame; fine for a
  single fullscreen instance, use `animate: false` in grids.
- System font stands in for SF Pro/Inter.

## Changelog

- **1.0.0** (2026-08-22) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `CalmWelcomeScreen` vào project này.

**Context**
- Chức năng: màn hình welcome app mindfulness — gradient hoàng hôn trồi lên, orb mascot thở, copy + nút vào theo stagger.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `calm_welcome/` (1 file), import duy nhất `calm_welcome.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `calm_welcome/` vào <thư mục widget của project đích>.
2. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
