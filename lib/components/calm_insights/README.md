---
# --- IDENTITY ---
id: calm_insights
title: Calm Insights
kind: composite
tags: [screen, insights, chart, mood, week, curve, segmented, takeaways]

# --- TAXONOMY (§2) ---
paint_source: painter
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: calm_insights.dart
files:
  - calm_insights.dart: "entry, public API"
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

# Calm Insights

Weekly mood insights (port of FeralUI's InsightsScreen): a Catmull-Rom
mood curve that draws itself on and morphs when switching weeks, the other
week ghosting behind as dots, tappable day pills with a selection ring,
a springy segmented control and two takeaway rows that swap per week.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `calm_insights/` folder (1 dart file(s), see `files`)
- **Import:** `import 'calm_insights/calm_insights.dart';` — one line
- **Or:** `dart tools/export.dart calm_insights` → zip + paste-ready block

## API

### `CalmInsightsScreen`

| Param | Type | Default | Meaning |
|---|---|---|---|
| `onNext` | `VoidCallback?` | — | The glass chevron. |
| `weeks` | `List<CalmInsightsWeek>` | upstream data | Exactly 2 weeks: label, headline, 7 mood indices (0..6), 2 takeaway lines. |
| `initialDay` | `int` | `5` | Selected day (0 = Monday). |
| `animate` | `bool` | `true` | False = settled end state, no ticker (pickers still work). |

## Caveats

- Takeaway icons are Material (`trending_up`, `military_tech`) standing in
  for the upstream HugeIcons.
- The ghost curve's dotted stroke is drawn as dots along the path metric —
  visually equivalent to the CSS dasharray.

## Changelog

- **1.0.0** (2026-08-22) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `CalmInsightsScreen` vào project này.

**Context**
- Chức năng: insights mood theo tuần — curve morph giữa 2 tuần, chọn ngày, takeaways đổi theo tuần.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `calm_insights/` (1 file), import duy nhất `calm_insights.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `calm_insights/` vào <thư mục widget của project đích>.
2. Import entry file, truyền `weeks` từ data thật (đúng 2 tuần, mỗi tuần 7 mood 0..6).

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
