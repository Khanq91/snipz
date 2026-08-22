---
# --- IDENTITY ---
id: calm_login
title: Calm Login
kind: composite
tags: [screen, login, auth, google, apple, glass, sheet, sunset]

# --- TAXONOMY (§2) ---
paint_source: widget
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: calm_login.dart
files:
  - calm_login.dart: "entry, public API"
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

# Calm Login

Sign-in screen (port of FeralUI's LoginScreen): a deep sunset glow rises
from the bottom, a small frosted brand mark smiles, and a glass sheet
offers "Continue with Google / Apple / email". The Google and Apple marks
are the upstream SVG paths, parsed procedurally — no image assets.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `calm_login/` folder (1 dart file(s), see `files`)
- **Import:** `import 'calm_login/calm_login.dart';` — one line
- **Or:** `dart tools/export.dart calm_login` → zip + paste-ready block

## API

### `CalmLoginScreen`

| Param | Type | Default | Meaning |
|---|---|---|---|
| `onGoogle` / `onApple` / `onEmail` | `VoidCallback?` | — | The three sheet buttons. |
| `palette` | `CalmLoginPalette` | sunset | Glow / ink colors. |
| `title` / `body` / `terms` | `String` | upstream copy | The texts. |
| `animate` | `bool` | `true` | False = settled end state, no ticker. |

## Caveats

- Uses the real Google/Apple brand marks — check the platforms' branding
  rules before shipping the buttons in a real product.
- The `.glass` refraction of the upstream is approximated with
  `BackdropFilter` blur (the CSS fallback look).
- Entrances replay by giving the widget a new `Key`.

## Changelog

- **1.0.0** (2026-08-22) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `CalmLoginScreen` vào project này.

**Context**
- Chức năng: màn login — glow hoàng hôn, brand mark glass, sheet 3 nút Google/Apple/email.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `calm_login/` (1 file), import duy nhất `calm_login.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `calm_login/` vào <thư mục widget của project đích>.
2. Import entry file, wire 3 callback vào auth layer của project.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
