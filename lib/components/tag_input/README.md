---
# --- IDENTITY ---
id: tag_input
title: Tag Input
kind: effect
tags: [tags, tokens, input, chips, pop, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: tag_input.dart
files:
  - tag_input.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Tag Input' (Interaction & Input)"
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

# Tag Input

Ô nhập tag: submit text thì chip cam pop vào từ scale 0.4 bằng spring; nút ×
(hoặc Backspace khi field trống) pop chip ra bằng scale-down fade nhanh.
Viền container sáng amber khi field focus.

## Port notes

- Source thật: card `.demo-taginput` trong `src/content/body.html`, mục
  `32. Tag input` của effects-a.css (`@keyframes demo-tag-pop` 0.4s spring,
  `demo-tag-out` 0.24s ease), JS (`39. Tag input` main.js): Enter thêm,
  × / Backspace-khi-trống xóa (xóa chờ 240ms animation rồi remove DOM).
- Cơ chế gốc: **CSS @keyframes + JS quản danh sách**. Flutter: mỗi tag một
  cặp `AnimationController` enter 0.4s (map spring qua transform, scale
  0.4→1 + opacity) / exit 0.24s ease — đúng pattern toast_stack.
- Số liệu giữ nguyên: box 240×(min48) padding 10×8 radius 9, gap 7, tag
  padding 11/6/4 pill 12/600, nút × 16px nền đen 18%, focus border 0.25s
  ease, palette card-2/line/amber/graphite/bone/bone-faint.
- Sai lệch có chủ ý: field gốc `flex: 1` chiếm phần còn lại của dòng —
  `Wrap` của Flutter không có con flexible nên field nhận slot cố định 96px.
- Backspace-khi-trống bắt qua `Focus.onKeyEvent` — chạy chắc chắn với bàn
  phím cứng; soft keyboard Android đa số có gửi key event backspace nhưng
  không phải IME nào cũng đảm bảo (caveat bên dưới).
- Component tự quản danh sách (uncontrolled, như bản gốc); `initialTags`
  seed ban đầu, thay đổi báo ra qua `onChanged`.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `tag_input/` folder (1 dart file(s), see `files`)
- **Import:** `import 'tag_input/tag_input.dart';` — one line
- **Or:** `dart tools/export.dart tag_input` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `initialTags` | `List<String>` | `['design','motion']` | Tag có sẵn khi mount |
| `hintText` | `String` | `'Add tag…'` | Placeholder |
| `width` | `double` | `240` | Bề rộng box |
| `backgroundColor` / `borderColor` | `Color` | `#232326 / #2A2A2E` | Box |
| `focusBorderColor` | `Color` | `#FF8A00` | Viền khi focus + cursor |
| `tagColor` / `tagTextColor` | `Color` | `#FF8A00 / #0E0E10` | Chip |
| `textColor` / `hintColor` | `Color` | `#EDE9E0 / #6E6C68` | Field |
| `onChanged` | `ValueChanged<List<String>>?` | `null` | Danh sách tag sau mỗi add/remove |
| `animate` | `bool` | `true` | False = add/remove tức thì |

## Caveats

- Backspace-khi-trống phụ thuộc IME gửi key event — Gboard có, một số IME
  khác có thể không; nút × luôn hoạt động.
- Cần Material ancestor (dùng `TextField`).
- Tag trùng chuỗi được phép (như bản gốc) — phân biệt bằng id nội bộ.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `TagInput` cho nhập keyword/label. Seed `initialTags` từ data thật,
đọc kết quả qua `onChanged`; giữ nguyên pop 0.4s spring / out 0.24s ease.
