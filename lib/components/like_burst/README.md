---
# --- IDENTITY ---
id: like_burst
title: Like Burst
kind: effect
tags: [like, heart, burst, particles, toggle, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: like_burst.dart
files:
  - like_burst.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Like Burst' (Interaction & Input)"
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

# Like Burst

Nút like: heart pop scale 1.35 mỗi lần toggle, fill amber khi liked, và khi
bật thì bắn 8 particle theo vòng tròn đều — bay ra, thu nhỏ về 0, mờ dần.

## Port notes

- Source thật: card `.demo-like-btn` trong `src/content/body.html`, mục
  `11. Like burst` của effects-a.css (transition heart 0.3s spring, particle
  `@keyframes like-fly` 0.6s glide), JS (`21. Like burst` main.js): toggle
  `.liked`, `.pop` 320ms, spawn 8 particle góc đều, khoảng cách
  `22 + random()*14`.
- Cơ chế gốc: **CSS transition (pop) + @keyframes (particle) + JS spawner**.
  Flutter: pop = `AnimatedScale` 1→1.35 (0.3s `Cubic(0.34,1.56,0.64,1)`),
  giữ 320ms bằng `AnimationController` rồi thả về; particle = một controller
  0.6s + `CustomPainter` áp curve `Cubic(0.16, 1, 0.3, 1)` cho cả translate,
  scale (6px→0) lẫn opacity.
- Random khoảng cách particle dùng `Random(seed)` cố định (luật sample(t):
  không wall-clock randomness) — chuỗi burst tất định nhưng mỗi lần khác nhau.
- Số liệu giữ nguyên: heart 22 (glyph 24-viewBox chuẩn, stroke 2), padding
  18×10, gap 9, count 13 tabular, palette card-2/line/amber/bone-dim/bone.
- Sai lệch có chủ ý: (1) particle xuất phát đúng tâm heart (bản gốc hardcode
  `left: 22px` trên zone — lệch tâm vài px); (2) fill heart fade 200ms theo
  transition khai báo trong CSS (browser thật nhảy tức thì vì `none→color`
  không interpolate được); (3) burst mới restart controller thay vì chồng
  thêm particle (chỉ khác khi unlike→like lại trong <0.6s).
- Không có hover lõi; click → tap.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `like_burst/` folder (1 dart file(s), see `files`)
- **Import:** `import 'like_burst/like_burst.dart';` — one line
- **Or:** `dart tools/export.dart like_burst` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `liked` | `bool` | required | Trạng thái controlled |
| `onChanged` | `ValueChanged<bool>?` | required | null = disabled |
| `count` | `int` | `128` | Số like KHÔNG tính của user; hiển thị `count + (liked?1:0)` |
| `backgroundColor` / `borderColor` | `Color` | `#232326 / #2A2A2E` | Pill |
| `heartColor` / `likedColor` | `Color` | `#A8A6A0 / #FF8A00` | Heart + particle |
| `countColor` / `likedCountColor` | `Color` | `#A8A6A0 / #EDE9E0` | Số đếm |
| `seed` | `int` | `7` | Seed khoảng cách particle |
| `animate` | `bool` | `true` | False = không pop/burst, đổi state tức thì |

## Caveats

- Particle bay ra NGOÀI bounds của nút (tối đa ~36px) — Stack clip none; đừng
  bọc trong widget clip sát nút.
- Pop/burst kích hoạt từ thay đổi `liked` (didUpdateWidget) — set từ code
  cũng chạy hiệu ứng, đúng như click.

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `LikeBurst` như controlled like button. Parent giữ `liked` (và tổng
like thật trong `count`, trừ like của user); cập nhật trong `onChanged`. Giữ
nguyên spring/glide curve và timing 300/320/600ms.
