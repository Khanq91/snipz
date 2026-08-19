---
# --- IDENTITY ---
id: pull_reveal_refresh
title: Pull Reveal Refresh
kind: effect
tags: [refresh, pull, scroll, header, gesture, haptic]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: pull_reveal_refresh.dart
files:
  - pull_reveal_refresh.dart: "entry, public API"
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
version: 1.0.1

# --- DERIVED (computed from Test History by verify.dart, do not hand-edit) ---
latest_known_good: null
last_verified: null
status: null

preview: null
---

# Pull Reveal Refresh

Pull-to-refresh kiểu "giãn header" (thay cho vòng xoay `RefreshIndicator`):
kéo xuống ở đỉnh danh sách → vùng header cao dần lộ ra và đẩy nội dung xuống;
nhả qua ngưỡng → haptic, header giữ mở trong lúc `onRefresh` chạy, xong thu
về 0. Header là builder tự do nhận `PullRevealStatus` (extent/progress/mode)
— cắm cảnh gì cũng được (demo ghép với `pixel_walker` để tái hiện app Claude
Code mobile).

## Port notes

- Nguồn: video demo pull-to-refresh của app **Claude Code mobile** (không có
  source — dựng lại hành vi từ quan sát, `origin: reimplemented`).
- Giữ: header giãn theo độ kéo và đẩy nội dung xuống, giữ mở khi refresh,
  thu gọn khi xong.
- Tự thêm: haptic khi kéo vượt ngưỡng, lực cản đàn hồi khi kéo quá
  `triggerExtent`, header builder tổng quát hoá (bản gốc hard-code cảnh).
- Nội dung bị **translate** thay vì relayout mỗi frame kéo — rẻ hơn cho list
  dài, đổi lại có caveat hở đáy (xem Caveats).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `pull_reveal_refresh/` folder (1 dart file, see `files`)
- **Import:** `import 'pull_reveal_refresh/pull_reveal_refresh.dart';` — one line
- **Or:** `dart tools/export.dart pull_reveal_refresh` → zip + paste-ready block

```dart
PullRevealRefresh(
  onRefresh: () async => loadData(),
  headerBuilder: (context, status) => MyHeader(
    progress: status.progress,          // 0→1 theo độ kéo
    busy: status.isRefreshing,
  ),
  child: ListView(
    physics: const AlwaysScrollableScrollPhysics(
      parent: ClampingScrollPhysics(),
    ),
    children: items,
  ),
)
```

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `child` | `Widget` | required | Scrollable bên trong; nên dùng `AlwaysScrollableScrollPhysics` |
| `onRefresh` | `Future<void> Function()` | required | Chạy khi nhả qua ngưỡng; header giữ mở tới khi Future xong (kể cả throw) |
| `headerBuilder` | `Widget Function(context, PullRevealStatus)` | required | Nội dung header, gọi lại mỗi frame extent đổi |
| `triggerExtent` | `double` | `96` | Ngưỡng armed; cũng là chiều cao giữ khi refreshing |
| `maxExtent` | `double` | `168` | Trần chiều cao khi kéo quá tay (lực cản tăng dần) |
| `hapticOnArm` | `bool` | `true` | `HapticFeedback.mediumImpact` đúng lúc vượt ngưỡng |
| `settleDuration` | `Duration` | `200ms` | Header lún về `triggerExtent` sau khi nhả |
| `collapseDuration` | `Duration` | `320ms` | Thu về 0 (refresh xong / nhả non ngưỡng) |
| `collapseCurve` | `Curve` | `easeOutCubic` | Ease thu gọn |
| `notificationDepth` | `int` | `0` | Depth của scrollable cần nghe (0 = ngoài cùng) |

`PullRevealStatus`: `mode` (idle/dragging/armed/refreshing/settling),
`extent`, `triggerExtent`, `maxExtent`, `progress` (extent/trigger 0→1),
`isRefreshing`.

## Caveats

- **Thiết kế cho `ClampingScrollPhysics`** (Android mặc định) — nhánh chính
  đọc `OverscrollNotification`. `BouncingScrollPhysics` (iOS) chạy qua nhánh
  fallback đọc overscroll âm: kéo vẫn đúng, nhưng lúc nhả để refresh, list
  spring về 0 trong khi header settle → có thể thấy giật nhẹ một nhịp.
- Nội dung được `Transform.translate` xuống (không relayout) → khi header mở,
  đáy child hở ra một dải bằng `extent`; widget đã tự clip, nhưng **nền phía
  sau phải cùng màu app** (đặt `PullRevealRefresh` trong container có màu
  nền, như demo).
- Kéo ngược lên khi header đang mở: header nuốt delta trước, nhưng list vẫn
  nhận cùng gesture nên nội dung có thể nhích theo một chút (trade-off giống
  `RefreshIndicator` notification-based).
- Không có API trigger refresh từ code (kiểu `show()`) — chưa cần thì chưa
  thêm.

## Changelog

- **1.0.1** (2026-08-19) — fix: kéo ngược lên khi list ngắn hơn viewport
  không thu được header (clamping physics báo overscroll dương, không có
  ScrollUpdate); giờ thu dần khi chưa buông tay và disarm khi xuống dưới
  ngưỡng — đúng hành vi bản gốc.
- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `PullRevealRefresh` vào project này.

**Context**
- Chức năng: pull-to-refresh giãn header với header builder tự do, haptic ở
  ngưỡng, dựng lại từ app Claude Code mobile.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `pull_reveal_refresh/` (1 file), import
  duy nhất `pull_reveal_refresh.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `pull_reveal_refresh/` vào thư mục widget của project đích.
2. Bọc scrollable hiện có; chuyển callback load data vào `onRefresh`; dựng
   header qua `headerBuilder` (ghép đẹp với `pixel_walker` nếu vault có).

**Việc cần adapt theo project đích**
- `triggerExtent`/`maxExtent` theo chiều cao header muốn lộ.
- Đặt trong container có màu nền app (xem Caveats về translate).
- List ngắn hơn viewport → nhớ `AlwaysScrollableScrollPhysics`.

**Rào (constraints)**
- KHÔNG sửa state machine (idle→dragging→armed→refreshing→settling) bên
  trong. Chỉnh cảm giác qua params duration/extent.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
