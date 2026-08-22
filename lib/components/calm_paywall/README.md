---
# --- IDENTITY ---
id: calm_paywall
title: Calm Paywall
kind: composite
tags: [screen, paywall, subscription, features, price, orb, glass, sunset]

# --- TAXONOMY (§2) ---
paint_source: widget
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: calm_paywall.dart
files:
  - calm_paywall.dart: "entry, public API"
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

# Calm Paywall

Soft-sell paywall (port of FeralUI's PaywallScreen): the small breathing
orb mascot over a lightened sunset gradient, a frosted feature list whose
rows stagger in with warm tick badges, a price pill, the trial CTA and a
restore link. All copy and prices are constructor params.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `calm_paywall/` folder (1 dart file(s), see `files`)
- **Import:** `import 'calm_paywall/calm_paywall.dart';` — one line
- **Or:** `dart tools/export.dart calm_paywall` → zip + paste-ready block

## API

### `CalmPaywallScreen`

| Param | Type | Default | Meaning |
|---|---|---|---|
| `onStart` | `VoidCallback?` | — | "Start free trial". |
| `onRestore` | `VoidCallback?` | — | "Restore purchase". |
| `palette` | `CalmPaywallPalette` | sunset | All colors. |
| `features` | `List<String>` | upstream copy | The tick rows. |
| `priceLead` / `priceTail` | `String` | `'7 days free'` / `', then $4.99/month'` | Price pill (lead is bold). |
| `title` / `body` / `buttonLabel` / `restoreLabel` | `String` | upstream copy | The texts. |
| `animate` | `bool` | `true` | False = settled end state, no ticker. |

## Caveats

- Feature rows are single-line (ellipsized) like the upstream
  `white-space: nowrap`.
- Entrances replay by giving the widget a new `Key`.

## Changelog

- **1.0.0** (2026-08-22) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `CalmPaywallScreen` vào project này.

**Context**
- Chức năng: paywall mềm — orb thở, danh sách feature glass, price pill, CTA trial.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `calm_paywall/` (1 file), import duy nhất `calm_paywall.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `calm_paywall/` vào <thư mục widget của project đích>.
2. Import entry file, nối `onStart`/`onRestore` vào billing layer.

**Việc cần adapt theo project đích**
- Color/theme token + giá: đổi default param sang giá trị thật của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
