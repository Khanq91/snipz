---
# --- IDENTITY ---
id: pixel_loader
title: Pixel Loader
kind: effect
tags: [pixel, loading, loader, mascot, sprite, splash, reveal, retro, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: true

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: pixel_loader.dart
files:
  - pixel_loader.dart: "entry, public API"
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
created: 2026-08-20
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

# Pixel Loader

Màn loading kiểu "Loading session...": mascot pixel coral giậm chân tại chỗ
~6fps trên nền tối, label tĩnh bên dưới; khi load xong chạy đúng choreography
gốc — squash ~160ms → hard cut (không fade-out) → content fade-in ~300ms
ease-out. `PixelLoader` là wrapper trọn gói (nhận `loading` + `child`),
`PixelLoaderIndicator` là riêng cụm mascot+label để dùng độc lập.

## Port notes

- Nguồn: video màn "Loading session..." của app **Claude Code mobile**
  (không có source — dựng lại từ phân tích từng frame của Khang,
  `origin: reimplemented`).
- Số liệu bám theo bản đo 720×1600 @24fps: sprite 132×97px vật lý (11×8
  macro-pixel ~12px), mắt = 2 ô lộ nền cách nhau 4 ô, cụm loading tâm ~47%
  chiều cao, đổi pose mỗi ~166ms (6fps), chu kỳ 1s
  (đứng→khuỵu→nghiêng phải→khuỵu→nghiêng trái→khuỵu), khuỵu thấp hơn đúng
  1 ô với đáy đứng yên, nghiêng ±5° kiểu bậc thang, exit squash 139×87
  (~scaleX 1.05 / scaleY 0.90) giữ ~160ms, loader biến mất hard cut, content
  fade-in ~300ms ease-out sau ~40ms màn trống, text đứng im tuyệt đối.
- Giữ: toàn bộ nhịp trên, kể cả các "đừng làm": không tween giữa pose, không
  anti-alias, không fade-out loader, không animate label.
- Pose khuỵu/squash là frame riêng (không scale transform); hai pose nghiêng
  suy tự động từ pose đứng bằng shear lượng tử hoá theo ô — sprite tự chế
  cũng nghiêng đúng kiểu bậc thang.
- Tự thêm: `sprite` thay mascot (ma trận ký tự như pixel_walker nhưng class
  riêng `PixelLoaderSprite` — copy 2 folder chung project không đụng nhau),
  `scale`, `alignment`, các Duration chỉnh nhịp, `animated` để dừng ticker,
  `onRevealComplete`.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `pixel_loader/` folder (1 dart file(s), see `files`)
- **Import:** `import 'pixel_loader/pixel_loader.dart';` — one line
- **Or:** `dart tools/export.dart pixel_loader` → zip + paste-ready block

```dart
PixelLoader(
  loading: isLoading,          // flip sang false → squash → cut → fade-in child
  onRevealComplete: () => ..., // optional
  child: SessionScreen(),
)
```

## API

### `PixelLoader` — wrapper trọn gói

| Param | Type | Default | Meaning |
|---|---|---|---|
| `loading` | `bool` | (bắt buộc) | true = hiện loader; chuyển false để chạy exit + reveal; quay lại true = cắt về loader ngay |
| `child` | `Widget?` | null | Nội dung fade-in sau loader; sau reveal cây chỉ còn đúng child |
| `label` | `String?` | `'Loading session...'` | Chữ tĩnh dưới sprite; null = ẩn |
| `labelStyle` | `TextStyle?` | null | Merge đè style mặc định (12.5px w400 `#EAEAEA`) |
| `sprite` | `PixelLoaderSprite?` | coral | Sprite thay thế (3 pose: stand/crouch/squash) |
| `creatureColor` | `Color` | `#D77655` | Màu mascot mặc định (khi `sprite` null) |
| `backgroundColor` | `Color` | `#141414` | Nền phủ kín lúc load + transition; mắt mascot lộ màu này |
| `scale` | `double` | `1.0` | Cỡ macro-pixel: 1.0 → ô 6px, sprite mặc định rộng 66px (đúng video trên màn 360px logical) |
| `alignment` | `Alignment` | `(0, -0.06)` | Vị trí cụm sprite+label — tâm ~47% chiều cao như bản gốc |
| `gap` | `double?` | null → 2.5 ô | Khoảng sprite → label (~15px tại scale 1) |
| `animated` | `bool` | `true` | false = mascot đứng im, không ticker |
| `stepDuration` | `Duration` | 166ms | Một nhịp của chu kỳ đi bộ (6 nhịp ≈ 1s) |
| `squashDuration` | `Duration` | 160ms | Giữ pose squash trước hard cut |
| `revealDuration` | `Duration` | 300ms | Fade-in của child (ease-out) |
| `onRevealComplete` | `VoidCallback?` | null | Gọi khi child hiện xong |

### `PixelLoaderIndicator` — riêng cụm mascot + label

| Param | Type | Default | Meaning |
|---|---|---|---|
| `sprite` / `creatureColor` / `label` / `labelStyle` / `scale` / `gap` / `stepDuration` | — | như trên | Cùng nghĩa với `PixelLoader` (riêng `label` mặc định null) |
| `completed` | `bool` | `false` | true = đứng im ở pose squash (trạng thái "xong") |
| `animated` | `bool` | `true` | false = đứng im pose đứng, không ticker |

### `PixelLoaderSprite`

`PixelLoaderSprite(stand:, crouch:, squash:, palette:)` — mỗi pose là list
dòng ký tự, tra màu qua `palette`, `.` = trong suốt (mắt mascot mặc định là ô
trống → tự mang màu nền). Các pose được phép khác kích thước (vẽ neo
đáy-giữa): khuỵu nên thấp hơn stand 1 ô với đáy giữ nguyên, squash nên rộng
hơn + lùn hơn. Hai pose nghiêng suy tự động từ `stand`.
`PixelLoaderSprite.coral({color})` = mascot mặc định 11×8.

## Caveats

- Cần vùng kích thước xác định (body Scaffold, `Expanded`, `SizedBox`) —
  bên trong là `Stack` fit expand; đặt trong vùng unbounded sẽ lỗi layout.
- `child` được mount tại thời điểm hard cut (opacity 0 trong ~40ms) để layout
  chạy xong trước khi fade; child rất nặng vẫn có thể jank frame đầu — khi đó
  app tự chuẩn bị data trước rồi mới flip `loading`.
- Ticker chỉ chạy khi loader còn hiện và `animated`; painter chỉ repaint khi
  đổi pose (~6 lần/giây). Sau reveal, cây widget còn đúng `child` — không
  ticker, không layer.
- `kind: effect`, không có dạng `Shader`: đây là view/wrapper animation theo
  thời gian, không phải paint tĩnh áp lên carrier.
- Label render bằng `Text` với style tự đủ, nhưng vẫn cần `Directionality`
  (có sẵn dưới `MaterialApp`/`WidgetsApp`).

## Changelog

- **1.0.0** (2026-08-20) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `PixelLoader` vào project này.

**Context**
- Chức năng: màn loading pixel-mascot dựng lại từ app Claude Code mobile —
  `PixelLoader(loading:, child:)` tự lo squash → hard cut → fade-in child;
  `PixelLoaderIndicator` là riêng cụm mascot+label.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `pixel_loader/` (1 file), import duy nhất `pixel_loader.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `pixel_loader/` vào <thư mục widget của project đích>.
2. Bọc màn hình cần loading: `PixelLoader(loading: <state>, child: <màn>)`
   trong vùng kích thước xác định; flip `loading` false khi data sẵn sàng.

**Việc cần adapt theo project đích**
- `backgroundColor`/`creatureColor`/`label` theo palette + ngôn ngữ project.
- Vùng render lớn hơn phone thường → tăng `scale` cho pixel không quá mịn.
- Nối `onRevealComplete` vào state layer nếu cần biết lúc transition xong.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
