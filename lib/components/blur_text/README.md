---
# --- IDENTITY ---
id: blur_text
title: Blur Text
kind: effect
tags: [text, blur, reveal, animated, stagger]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: blur_text.dart
files:
  - blur_text.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://reactbits.dev/text-animations/blur-text
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-18
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

# Blur Text

Text reveal theo từng từ/ký tự: mỗi segment bắt đầu blur + transparent +
lệch dọc, qua keyframe nửa-nét có overshoot nhẹ, rồi đứng nét tại chỗ. Một
`AnimationController` duy nhất lái tất cả segment qua interval so le. Dựng
lại "Blur Text" của react-bits (Framer Motion → Flutter thuần).

Replay/stop từ ngoài qua `GlobalKey<BlurTextState>`.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `blur_text/` folder (1 dart file, see `files`)
- **Import:** `import 'blur_text/blur_text.dart';` — one line
- **Or:** `dart tools/export.dart blur_text` → zip + paste-ready block

```dart
final key = GlobalKey<BlurTextState>();

BlurText(
  'Isn\'t this so cool?!',
  key: key,
  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
  onComplete: () => debugPrint('done'),
);
// later: key.currentState?.replay();
```

## API

`BlurText` widget (positional `text` + named params):

| Param | Type | Default | Meaning |
|---|---|---|---|
| `text` | `String` | required | Nội dung |
| `unit` | `BlurTextUnit` | `words` | `words` \| `characters` |
| `direction` | `BlurTextSlideDirection` | `top` | Trượt vào từ trên hay dưới |
| `stagger` | `Duration` | `120ms` | Delay giữa 2 segment liên tiếp |
| `stepDuration` | `Duration` | `350ms` | Mỗi keyframe step (segment = 2×) |
| `curve` | `Curve` | `easeOut` | Easing cả timeline segment (gốc dùng linear) |
| `style` | `TextStyle?` | `null` | Merge lên `DefaultTextStyle` |
| `startBlur` | `double` | `10.0` | Sigma lúc bắt đầu |
| `slideOffset` | `double` | `40.0` | Quãng trượt dọc (px) |
| `alignment` | `WrapAlignment` | `start` | Căn hàng các segment |
| `autoPlay` | `bool` | `true` | Tự chạy khi mount / khi `text` đổi |
| `onComplete` | `VoidCallback?` | `null` | Sau khi segment cuối đứng nét |

`BlurTextState` (qua `GlobalKey`): `replay()`, `play()`, `stop()`,
`skipToEnd()`.

## Caveats

- Mỗi segment đang blur là một `ImageFiltered` → một `saveLayer` (§9.2).
  Headline vài chục segment thì ổn; **đừng** chạy `characters` trên cả đoạn
  văn dài trên máy yếu. Filter tự gỡ khi segment xong (sigma ≈ 0).
- `Wrap` xuống dòng giữa các segment — mode `characters` có thể gãy giữa từ
  (bản gốc cũng vậy).
- Không đo được text-align phức tạp (justify) — chỉ `WrapAlignment`.

## Changelog

- **1.0.0** (2026-08-18) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `BlurText` vào project này.

**Context**
- Chức năng: text reveal blur→sharp theo từ/ký tự, stagger, replay được từ
  ngoài qua `GlobalKey<BlurTextState>`.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `blur_text/` (1 file), import
  duy nhất `blur_text.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `blur_text/` vào thư mục widget của project đích.
2. Thay `Text` headline bằng `BlurText(text, style: ...)`. Cần re-trigger
   (pull-to-refresh, tab switch) → giữ `GlobalKey<BlurTextState>` và gọi
   `replay()`.

**Việc cần adapt theo project đích**
- `style`: dùng text style/token của project (merge lên DefaultTextStyle).
- Đoạn text dài: giữ `unit: words`, tăng `stagger` nếu muốn chậm rãi.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
