---
# --- IDENTITY ---
id: vector_recall
title: Vector Recall
kind: effect
tags: [vector, embedding, search, ai, radar, status, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: vector_recall.dart
files:
  - vector_recall.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Vector Recall' (Feedback & State)"
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

# Vector Recall

Minh họa semantic search trên không gian embedding, dựng lại từ kinetics
"Vector Recall" (loop 5.6s): các điểm mờ rải quanh query node sáng, hai vòng
ring mảnh quét ra ngoài, 3 điểm gần nhất sáng lên và trôi 34% quãng đường về
phía query trong khi phần còn lại đứng im, readout cross-fade từ
"querying…" sang điểm cosine đúng lúc match đáp xuống.

## Port notes

- Effect gốc: "Vector Recall", section **Feedback & State**, kinetics
  (`github.com/ckissi/kinetics`). Source: card trong `src/content/body.html`
  (tọa độ điểm qua CSS custom property `--x/--y`), style mục "48" trong
  `public/css/effects-b.css` (`.demo-vector`), không có JS.
- Cơ chế gốc: **CSS keyframes phối 3 lớp** cùng bezier
  `cubic-bezier(0.16, 1, 0.3, 1)` (`--glide`): `recall-ring` (đường kính
  8→104px, opacity 0→0.75→0, ring 2 delay 0.55s), `recall-pull` (translate
  →34% giữa 24–48%, giữ tới 76%, delay 0/0.1/0.2s theo hit),
  `score-query`/`score-match` (ease-in-out, match trồi 3px). → Flutter: một
  ticker + `CustomPainter` cho ring/điểm, track keyframe thuần theo `t`.
- Số liệu giữ nguyên: khung 214×132 radius 14, 7 điểm đúng tọa độ gốc (3
  hit), điểm 6px, query 9px bone glow 55%, ring viền 1px amber 60%, chữ 9px.
- Sai lệch nhỏ: nền `radial-gradient` ellipse 70%×90% → radial tròn xấp xỉ;
  glow bằng `MaskFilter.blur` thay `box-shadow`; font mono → font hệ thống
  (luật zero-asset); `color-mix()` → alpha trực tiếp.
- Theo quy ước sample(t): `frozenAt` + `animate`, tôn trọng
  `disableAnimations`. Hai pha làm variants demo (querying / match).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `vector_recall/` folder (1 dart file(s), see `files`)
- **Import:** `import 'vector_recall/vector_recall.dart';` — one line
- **Or:** `dart tools/export.dart vector_recall` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `width` / `height` | `double` | `214` / `132` | Khung card |
| `points` | `List<(Offset, bool)>` | 7 điểm gốc | (offset từ tâm, isHit); hit thứ i lệch i×0.1s |
| `queryText` | `String` | `'querying…'` | Readout trước khi match |
| `matchText` | `String` | `'0.94 · match'` | Readout khi match đáp |
| `accentColor` | `Color` | `#FF8A00` | Hit + ring + điểm số (amber) |
| `queryColor` | `Color` | `#EDE9E0` | Query node |
| `pointColor` | `Color` | `#6E6C68` | Điểm thường + chữ querying |
| `borderColor` | `Color` | `#2A2A2E` | Viền khung |
| `backgroundColors` | `List<Color>` | `#1B1B1F` → `#232326` | Radial nền, trong → ngoài |
| `animate` | `bool` | `true` | false = đứng im |
| `frozenAt` | `double?` | null | Render đúng 1 frame tại t giây, không ticker |

Mốc pha trong chu kỳ 5.6s (cho `frozenAt`): `~1.0` querying (ring đang
quét), `~3.2` match (hit đã đáp, hiện điểm số).

## Caveats

- Minh họa tự lặp, không data-driven — muốn feed điểm/score thật thì đổi
  `points`/`matchText`, còn timeline là hằng trong source (`_period`).
- Tọa độ `points` thiết kế cho khung 214×132 — phóng to khung nên scale cả
  offsets, không thì điểm dồn giữa.
- `MaskFilter.blur` mỗi frame trên vài circle nhỏ — rẻ, nhưng là chỗ đầu
  tiên cần nhìn nếu profile thấy chậm. Cost: chưa đo.
- Ticker chạy khi hiển thị — tắt bằng `animate: false` khi khuất (§9.2).

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `VectorRecall` vào project này.

**Context**
- Chức năng: minh họa vector search — ring quét, điểm gần nhất trôi về
  query, readout cosine (port kinetics "Vector Recall"). Loop 5.6s.
- Public API: xem bảng API trong README. Class `VectorRecall`.
- Portability: single_file — copy cả `vector_recall/` (1 file), import duy nhất `vector_recall.dart`.
- Deps: không có — Flutter SDK only (widgets layer, không cần Material).

**Việc cần làm**
1. Copy folder `vector_recall/` vào <thư mục widget của project đích>.
2. Đặt vào empty-state/landing/docs của tính năng search AI; đổi
   `matchText` theo ngữ cảnh.

**Việc cần adapt theo project đích**
- Màu: đổi `accentColor` sang accent của app; nền sáng đổi
  `backgroundColors`/`borderColor`/`pointColor`.
- Khung to hơn: scale đồng bộ cả `width`/`height` lẫn offsets trong
  `points`.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
