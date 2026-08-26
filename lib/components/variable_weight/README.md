---
# --- IDENTITY ---
id: variable_weight
title: Variable Weight
kind: effect
tags: [text, weight, variable-font, press, typographic]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: variable_weight.dart
files:
  - variable_weight.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Variable Weight' (Surface & Motion)"
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

# Variable Weight

Chữ display mảnh (wght 200) đè ngón tay lên là đặc dần thành 800, tracking
khép lại, màu chuyển amber kèm quầng glow — thả ra thì thư giãn về mảnh với
cùng đường cong.

## Port notes

- Effect gốc: "Variable Weight", section **Surface & Motion**, kinetics. Đã
  đọc `.demo-var-weight` trong `effects-c.css`; không có JS.
- Cơ chế gốc: **CSS transition trên `:hover`** — 5 kênh, 3 đồng hồ:
  `font-weight`/`font-variation-settings`/`letter-spacing` 0.55s
  `cubic-bezier(0.16, 1, 0.3, 1)`; `color` 0.35s ease; `text-shadow` 0.45s
  ease. Port dùng ba `AnimationController` đúng ba đồng hồ đó;
  `reverseCurve = curve.flipped` vì CSS chạy easing mới cho chiều về.
- Hover → press-and-hold (down = enter, up/cancel = leave) theo luật map
  của port guide; thêm `engaged` để điều khiển ngoài (state board).
- Số giữ nguyên: wght 200→800, tracking 0.04em→−0.02em (nhân fontSize 40),
  màu `#EDE9E0`→`#FF8A00`, glow blur 28 alpha 0.35.
- Font Archivo variable không bundle được (zero asset): dùng
  `FontVariation('wght')` trên font mặc định — mượt khi font hệ có trục
  wght (Roboto Android mới), nơi khác rơi về 9 nấc `FontWeight` đồng bộ.
  Muốn đúng bản web thì bundle variable font ở app, truyền `fontFamily`.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `variable_weight/` folder (1 dart file(s), see `files`)
- **Import:** `import 'variable_weight/variable_weight.dart';` — one line
- **Or:** `dart tools/export.dart variable_weight` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `text` | `String` | `MORPH` | Nội dung chữ |
| `fontSize` | `double` | `40` | Cỡ chữ |
| `fontFamily` | `String?` | null | Variable font của app nếu có |
| `idleWeight` / `engagedWeight` | `double` | `200 / 800` | Trục wght |
| `idleTrackingEm` / `engagedTrackingEm` | `double` | `0.04 / −0.02` | Tracking theo em |
| `idleColor` / `engagedColor` | `Color` | bone / amber | Màu chữ |
| `glowColor` / `glowBlur` / `glowOpacity` | — | amber / 28 / 0.35 | Glow lúc engaged |
| `weightDuration` / `colorDuration` / `glowDuration` | `Duration` | 550/350/450ms | Ba đồng hồ transition |
| `engaged` | `bool?` | null | null = press điều khiển; bool = controlled |
| `onEngagedChanged` | `ValueChanged<bool>?` | null | Báo state press nội bộ |
| `animate` | `bool` | `true` | false = snap không animate |

## Caveats

- Độ mượt của weight phụ thuộc font: cần font có trục `wght` (variable) để
  liền mạch; font tĩnh sẽ nhảy nấc 100 (fallback đồng bộ sẵn).
- Đổi weight là re-layout text mỗi frame — chữ ngắn thì rẻ, đừng dùng cho
  đoạn văn dài.
- Tracking đổi làm bề rộng chữ đổi; layout xung quanh nên dùng vùng rộng
  hơn bề rộng lớn nhất để khỏi xô đẩy.

## Changelog

- **1.0.0** (2026-08-26) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `VariableWeightText` cho wordmark hoặc hero tương tác. Truyền
variable font của app qua `fontFamily` để có độ mượt tối đa; dùng `engaged`
khi muốn driver ngoài (scroll, hover desktop).
