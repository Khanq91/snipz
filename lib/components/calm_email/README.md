---
# --- IDENTITY ---
id: calm_email
title: Calm Email
kind: composite
tags: [screen, form, email, password, sign-in, glass, fields, sunset]

# --- TAXONOMY (§2) ---
paint_source: widget
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: calm_email.dart
files:
  - calm_email.dart: "entry, public API"
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

# Calm Email

Email sign-in form (port of FeralUI's EmailScreen): frosted fields that
glow on focus, a warm CTA that enables once the form is plausible
(email contains `@`, password ≥ 6 chars), forgot-password and create-account
links, on a soft sunset glow floor.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `calm_email/` folder (1 dart file(s), see `files`)
- **Import:** `import 'calm_email/calm_email.dart';` — one line
- **Or:** `dart tools/export.dart calm_email` → zip + paste-ready block

## API

### `CalmEmailScreen`

| Param | Type | Default | Meaning |
|---|---|---|---|
| `onBack` | `VoidCallback?` | — | The glass back button. |
| `onSignIn` | `VoidCallback?` | — | CTA (only while the form is valid). |
| `onForgot` / `onCreate` | `VoidCallback?` | — | The two links. |
| `palette` | `CalmEmailPalette` | sunset | All colors. |
| `title` / `body` | `String` | upstream copy | Headings. |
| `animate` | `bool` | `true` | False = settled end state, no ticker. |

## Caveats

- Field icons are Material (`mail_outline`, `lock_outline`) standing in for
  the upstream HugeIcons; the back chevron is `arrow_back_ios_new`.
- The demo screen owns its `TextEditingController`s — the entered text is
  not surfaced; wire your own state by forking if you need the values.

## Changelog

- **1.0.0** (2026-08-22) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `CalmEmailScreen` vào project này.

**Context**
- Chức năng: form đăng nhập email/password kính mờ, nút Sign in tự enable khi form hợp lệ.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `calm_email/` (1 file), import duy nhất `calm_email.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `calm_email/` vào <thư mục widget của project đích>.
2. Import entry file, nối `onSignIn`/`onBack` vào auth + navigation.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
