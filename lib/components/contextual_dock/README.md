---
# --- IDENTITY ---
id: contextual_dock
title: Contextual Dock
kind: effect
tags: [dock, icons, focus, neighbors, spring, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: contextual_dock.dart
files:
  - contextual_dock.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Contextual Dock' (Interaction & Input)"
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

# Contextual Dock

Dock icon với "trường focus" RỜI RẠC 3 bậc: icon đang chạm nâng
(-14px, scale 1.34) và đổi amber, hai icon kề nâng đúng một nửa
(-7px, 1.13), còn lại đứng yên — khác dock magnification liên tục.

## Port notes

- Source thật: card `.demo-dock` trong `src/content/body.html`, CSS ở
  effects-a.css dòng 270-272 (selector `:has(+ button:hover)` /
  `:hover + button` cho neighbors). Không có JS.
- Cơ chế gốc: **CSS transition, driver `:hover` + `:has()`** — hover là lõi
  effect. Map sang touch theo đúng tiền lệ component `dock` của vault
  (react-bits, hover→touch): **đè/rê ngón tay** trên thanh di chuyển focus,
  nhả thì dock settle về rest; nhả trên icon nào thì bắn `onPressed` của
  icon đó.
- Ba bậc là chữ ký của effect (khác `dock` đã có: falloff liên tục theo
  khoảng cách con trỏ) — giữ đúng discrete, không nội suy.
- Số liệu giữ nguyên: nút 31×31 radius 10, gap 7, padding 15×13, khung
  radius 20 bg card-2@80%, transform 0.3s `Cubic(0.34,1.56,0.64,1)`, màu
  0.2s ease, palette graphite-2/line/bone-dim/amber/graphite.
- Glyph mặc định ◇◒✳◈⌁ là text như bản gốc, thay qua `icons`.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `contextual_dock/` folder (1 dart file(s), see `files`)
- **Import:** `import 'contextual_dock/contextual_dock.dart';` — one line
- **Or:** `dart tools/export.dart contextual_dock` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `icons` | `List<String>` | `['◇','◒','✳','◈','⌁']` | Glyph các nút |
| `onPressed` | `ValueChanged<int>?` | `null` | Bắn khi nhả trên một nút |
| `focusedIndex` | `int?` | `null` | Ghim focus (preview); null = theo pointer |
| `backgroundColor` / `borderColor` | `Color` | card-2@80% / line | Khung |
| `buttonColor` / `iconColor` | `Color` | `#141417 / #A8A6A0` | Nút rest |
| `focusColor` / `focusIconColor` | `Color` | `#FF8A00 / #0E0E10` | Nút focus |
| `animate` | `bool` | `true` | False = đổi bậc tức thì |

## Caveats

- Icon nâng lên vẽ tràn phía trên khung — chừa ~24px headroom, đừng clip
  sát.
- Rê ngón che icon là hạn chế cố hữu của touch với dock kiểu này (đã chấp
  nhận từ port `dock`); tap nhanh vẫn cho feedback đủ đọc.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `ContextualDock` làm thanh công cụ nổi. Map `icons` + `onPressed`
theo action thật; giữ đúng ba bậc -14/1.34 và -7/1.13 với spring 0.3s.
