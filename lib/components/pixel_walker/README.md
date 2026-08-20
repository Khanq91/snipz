---
# --- IDENTITY ---
id: pixel_walker
title: Pixel Walker
kind: paint
tags: [pixel, sprite, dither, skyline, mascot, refresh, header, animated, night, cat]

# --- TAXONOMY (§2) ---
paint_source: painter
carriers_verified: []
carriers_failed: []
scale_aware: true

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: pixel_walker.dart
files:
  - pixel_walker.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: null
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-19
created_flutter: 3.44.5
created_dart: 3.12.2
created_deps: []
platforms_initial: [android]

# --- COMPONENT VERSION ---
version: 1.1.0

# --- DERIVED (computed from Test History by verify.dart, do not hand-edit) ---
latest_known_good: null
last_verified: null
status: null

preview: null
---

# Pixel Walker

Cảnh pixel-art neo đáy: mascot đứng giữa, skyline thành phố + mây vẽ bằng
dither procedural (hash 2D, không asset). `progress` 0→1 hiện dần cảnh
(mascot trồi lên từ mép dưới); `walking` bật chu kỳ bước đi + các layer trôi
parallax. Hai scene: `city` (mặc định — cảnh gốc, dither trung tính) và
`nightCity` (thành phố đêm: nhà cao tầng cửa sổ sáng đèn, dãy núi parallax
phía xa, sao + trăng khuyết). Hai mascot có sẵn: bọ cam Clawd (mặc định) và
mèo Miu (`PixelSprite.miu()`); thay hình tuỳ ý qua param `sprite`. Sinh ra
làm header pull-to-refresh (ghép với `pull_reveal_refresh`) nhưng đứng độc
lập được — empty state, loading, splash.

## Port notes

- Nguồn: video demo pull-to-refresh của app **Claude Code mobile** (không có
  source code — dựng lại từ quan sát từng frame, `origin: reimplemented`).
- Giữ: bố cục cảnh (mascot giữa, skyline ngang tầm đầu, mây trên cao), dither
  trắng-xám trên nền tối, mascot nghiêng người khi bước, skyline trôi ngang
  khi refresh.
- Sprite mặc định là pixel-art tự vẽ *phỏng theo* mascot (12×10 ô, 4 frame);
  không copy asset gốc. Thay được toàn bộ qua param `sprite`.
- Tự thêm: `progress` (hiện dần theo độ kéo), `seed` (đổi bố cục skyline),
  `scale` (mật độ ô).
- Tự chế thêm (không có trong bản gốc): scene `nightCity` (cao tầng + cửa sổ
  đèn + núi + sao/trăng, vẫn 100% procedural) và mascot mèo Miu (16×11 ô,
  4 frame, 2 màu body/sọc).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `pixel_walker/` folder (1 dart file, see `files`)
- **Import:** `import 'pixel_walker/pixel_walker.dart';` — one line
- **Or:** `dart tools/export.dart pixel_walker` → zip + paste-ready block

```dart
SizedBox(
  height: 160,
  width: double.infinity,
  child: PixelWalker(progress: pullProgress, walking: isRefreshing),
)
```

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `progress` | `double` | `1.0` | 0→1 hiện dần: mascot trồi lên, dither dày dần, alpha tăng |
| `walking` | `bool` | `false` | true = mascot bước + các layer trôi parallax; false = tĩnh, **không ticker** |
| `scene` | `PixelWalkerScene` | `city` | `city` = cảnh gốc; `nightCity` = cao tầng + cửa sổ đèn + núi + sao/trăng |
| `scale` | `double` | `1.0` | Mật độ chi tiết: cỡ ô dither (3px×scale), ô mascot gấp đôi. Fullscreen nên 1.5–2 |
| `sprite` | `PixelSprite?` | Clawd-like | Sprite thay thế: frames ma trận ký tự + palette char→Color |
| `mascotColor` | `Color` | `#E8875C` | Màu mascot mặc định (chỉ dùng khi `sprite` null) |
| `skylineColor` | `Color` | `#B9B4AE` | Màu dither skyline; mây cùng màu ở 55% alpha, núi (nightCity) ở 60% |
| `windowColor` | `Color` | `#F2C069` | Màu cửa sổ sáng đèn (chỉ nightCity) |
| `starColor` | `Color` | `#C7D3E6` | Màu sao + trăng khuyết (chỉ nightCity) |
| `backgroundColor` | `Color` | transparent | Nền vẽ dưới cảnh |
| `speed` | `double` | `1.0` | Nhân tốc độ bước + trôi |
| `seed` | `int` | `7` | Bố cục skyline/mây/núi khác (deterministic) |

`PixelSprite(frames, palette)` — frame 0 là pose đứng; frame lẻ được nghiêng +
bob khi đi. Có sẵn hai sprite: `PixelSprite.clawd({color})` (mặc định, bọ cam
12×10) và `PixelSprite.miu({body, stripe})` (mèo nhìn nghiêng 16×11, sọc lưng
+ đuôi vẫy theo nhịp bước). Muốn mascot khác chỉ cần tự vẽ ma trận ký tự —
không đụng code vẽ.

Parallax của `nightCity` (chậm → nhanh): sao/trăng đứng yên, núi 2.2, mây
3.0, toà nhà 9.0 (cùng city). Toà nhà vẽ đè lên mây để tháp cao có chiều sâu.

## Caveats

- **Không có factory `Shader`**: cảnh gồm 3 layer parallax + sprite animation
  theo thời gian — không biểu diễn được bằng `ui.Gradient`/`ImageShader`
  (FragmentProgram thì phá luật no-asset). Muốn áp lên text/border thì bọc
  `ShaderMask` không được — dùng `ClipRect` + đặt cảnh làm nền thay thế.
- Perf: vẽ bằng 3 lệnh `drawRawPoints` trên buffer `Float32List` tái dùng
  (~1–2k điểm ở 480px/scale 1) — không cấp phát trong `paint()`. Cost thật:
  chưa đo trên thiết bị.
- `walking: false` là trạng thái nghỉ đúng nghĩa: ticker dừng, không frame
  nào được schedule — giữ trong tree lâu dài an toàn.
- Widget tự `ClipRect` (mascot trồi từ dưới mép khi `progress < 1`).

## Changelog

- **1.1.0** (2026-08-20) — thêm scene `nightCity` (nhà cao tầng cửa sổ sáng
  đèn, núi parallax, sao + trăng khuyết — vẫn procedural, không asset) chọn
  qua param `scene`; thêm mascot mèo `PixelSprite.miu()`; params mới
  `windowColor`/`starColor`. Mặc định không đổi: scene `city` + Clawd như cũ.
- **1.0.1** (2026-08-19) — độ trồi của mascot theo `progress` tuyến tính
  (bỏ ease): chân chạm đất đúng lúc progress = 1, tự nó thành chỉ báo "đủ
  ngưỡng refresh" khi ghép với pull_reveal_refresh.
- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `PixelWalker` vào project này.

**Context**
- Chức năng: cảnh pixel-art (mascot đi bộ + skyline dither parallax) điều
  khiển bằng `progress`/`walking`, dựng lại từ pull-to-refresh của app Claude
  Code mobile; `scene` chọn cảnh `city`/`nightCity`, mascot có sẵn Clawd và
  mèo Miu (`sprite: PixelSprite.miu()`).
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `pixel_walker/` (1 file), import duy
  nhất `pixel_walker.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `pixel_walker/` vào thư mục widget của project đích.
2. Đặt trong `SizedBox`/header có kích thước xác định; nối `progress` vào độ
   kéo (hoặc để mặc định 1.0), `walking` vào trạng thái loading.

**Việc cần adapt theo project đích**
- `mascotColor`/`skylineColor`/`backgroundColor` theo palette project.
- Vùng render lớn → tăng `scale` (1.5–2) cho pixel không quá mịn.

**Rào (constraints)**
- KHÔNG sửa logic dither/sprite bên trong. Đổi hình mascot qua param
  `sprite`, không sửa `_clawdFrames`.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
