---
# --- IDENTITY ---
id: skeleton_content
title: Skeleton to Content
kind: effect
tags: [skeleton, shimmer, loading, placeholder, transition, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: skeleton_content.dart
files:
  - skeleton_content.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Skeleton to Content' (Feedback & State)"
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-24
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

# Skeleton to Content

Card skeleton chuyển thành nội dung thật, dựng lại từ kinetics "Skeleton to
Content": avatar tròn + 2 thanh text shimmer (1.4s ease-in-out); khi
`loaded` bật, skeleton mờ đi 0.3s còn avatar/tên/meta thật hiện lên kèm cú
trượt 8px với bezier glide. Controlled — parent giữ state `loaded`; ticker
shimmer tự dừng khi đã load.

Khác [`shimmer_skeleton`](../shimmer_skeleton/README.md) (chỉ thanh
placeholder): con này có cả pha resolve sang nội dung thật.

## Port notes

- Effect gốc: "Skeleton to Content", section **Feedback & State**, kinetics
  (`github.com/ckissi/kinetics`). Ba mảnh: card trong
  `src/content/body.html`, style mục "23" trong `public/css/effects-b.css`
  (`.demo-skel-*`), JS toggle class `loaded` trong `public/js/main.js`.
- Cơ chế gốc: **keyframes shimmer + CSS transition** khi toggle → Flutter:
  ticker cho shimmer, implicit animation cho toggle.
- Số liệu giữ nguyên: shimmer `shimmer-sweep` size 200%, stops 25/50/75
  (`#232326`/`#34343A`), position 200%→-200%, 1.4s ease-in-out; skeleton mờ
  0.3s ease; content hiện 0.4s `cubic-bezier(0.16, 1, 0.3, 1)` (`--glide`)
  + translateY 8→0; avatar 40px gradient 135° amber→amber-deep; card 220.
- Thay: click trên DOM → param `loaded` (controlled) + callback `onTap` —
  state về phía app, đúng luật data-in-param.
- Bỏ: `cursor: pointer` (không có trên mobile).
- Theo quy ước sample(t) cho phần shimmer: `frozenAt` + `animate`; ticker
  tự dừng khi `loaded` (bản gốc `animation: none`).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `skeleton_content/` folder (1 dart file(s), see `files`)
- **Import:** `import 'skeleton_content/skeleton_content.dart';` — one line
- **Or:** `dart tools/export.dart skeleton_content` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `loaded` | `bool` | required | false = skeleton shimmer, true = nội dung thật |
| `onTap` | `VoidCallback?` | null | Tap cả card (bản gốc toggle bằng click) |
| `name` | `String` | `'Ada Lovelace'` | Dòng tên |
| `meta` | `String` | `'Analytical Engine'` | Dòng phụ |
| `initial` | `String` | `'K'` | Chữ trong avatar thật |
| `width` | `double` | `220` | Bề rộng card |
| `baseColor` | `Color` | `#232326` | Nền skeleton |
| `highlightColor` | `Color` | `#34343A` | Vệt shimmer |
| `avatarColors` | `List<Color>` | amber → amber-deep | Gradient avatar thật (135°) |
| `nameColor` | `Color` | `#EDE9E0` | Màu tên |
| `metaColor` | `Color` | `#6E6C68` | Màu meta |
| `initialColor` | `Color` | `#0E0E10` | Màu chữ trong avatar |
| `animate` | `bool` | `true` | false = shimmer đứng im |
| `frozenAt` | `double?` | null | Render shimmer đúng 1 frame tại t giây |

## Caveats

- Nội dung cố định avatar + tên + meta (đúng card gốc) — layout khác thì
  cần bản mở rộng nhận `skeleton`/`content` builder, không nhét thêm param.
- Chiều cao Stack ăn theo hàng skeleton (40px avatar); tên/meta thật dài
  bị ellipsis 1 dòng.
- Ticker chỉ chạy khi `loaded == false` và đang hiển thị.
- Cost: chưa đo (3 shape gradient mỗi frame khi shimmer).

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `SkeletonContent` vào project này.

**Context**
- Chức năng: skeleton shimmer resolve thành avatar/tên/meta thật (port
  kinetics "Skeleton to Content"). Controlled qua `loaded`.
- Public API: xem bảng API trong README. Class `SkeletonContent`.
- Portability: single_file — copy cả `skeleton_content/` (1 file), import duy nhất `skeleton_content.dart`.
- Deps: không có — Flutter SDK only (widgets layer, không cần Material).

**Việc cần làm**
1. Copy folder `skeleton_content/` vào <thư mục widget của project đích>.
2. Nối `loaded` vào trạng thái fetch thật (future/stream); truyền
   `name`/`meta`/`initial` từ data khi có.

**Việc cần adapt theo project đích**
- Nền sáng: đổi `baseColor`/`highlightColor` + màu chữ.
- Danh sách nhiều card: mỗi card một `loaded` riêng theo item của nó.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
