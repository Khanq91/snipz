---
# --- IDENTITY ---
id: true_focus
title: True Focus
kind: effect
tags: [text, focus, blur, frame, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: true_focus.dart
files:
  - true_focus.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: adapted
source: https://github.com/DavidHDev/react-bits/blob/main/src/ts-tailwind/TextAnimations/TrueFocus/TrueFocus.tsx
author: "Khang"
license: "MIT + Commons Clause License Condition v1.0 (react-bits, © David Haz)"

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-19
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

# True Focus

Port react-bits "True Focus": câu chữ tách thành từng từ (Wrap, gap 16, căn
giữa) — từ đang active nét, các từ khác blur; một khung focus 4 góc ngoặc
(16px, stroke 3px, glow) trượt cả vị trí lẫn kích thước từ từ trước sang từ
mới. Auto mode tự xoay vòng qua Timer; manual mode chuyển hover của web
thành **tap-to-focus** trên Android.

## Port notes

- Nguồn: `src/ts-tailwind/TextAnimations/TrueFocus/TrueFocus.tsx`
  (motion/react → `TweenAnimationBuilder` thuần Flutter, không package nào).
- **Hover → tap:** `onMouseEnter`/`onMouseLeave` không tồn tại trên touch.
  `manualMode` map sang `GestureDetector.onTap` — tap từ nào focus từ đó và
  giữ nguyên. Logic `lastActiveIndex` (khôi phục khi rời chuột) của bản gốc
  vì thế không cần — tap không có sự kiện "rời".
- **`glowColor` sửa đúng ý:** bản ts-tailwind gốc set CSS var `--glow-color`
  nhưng cả 4 drop-shadow lại dùng `var(--border-color)` — prop `glowColor`
  thực chất chết. Bản port dùng `glowColor` cho lớp glow đúng như API intent.
- Đo rect: `getBoundingClientRect` → GlobalKey/RenderBox
  (`localToGlobal(ancestor: stack)`) trong post-frame callback; bọc
  `LayoutBuilder` để resize/parent relayout kích hoạt đo lại.
- Easing: CSS `transition ... ease` → `Curves.ease` (blur); motion tween
  default → `Curves.easeInOut` (khung). Khung bay ra từ `Rect.zero` ở lần
  đầu — đúng hành vi `motion.div` khởi tạo `{0,0,0,0}` của bản gốc.
- Glow: `drop-shadow(0 0 4px)` → vẽ path 2 lần, lớp dưới
  `MaskFilter.blur(normal, 2)` (sigma ≈ radius/2).
- Thêm so với gốc: `animate` (stop switch từ ngoài, yêu cầu vault §9.2) và
  `textStyle` (thay `text-[3rem] font-black` — default fontSize 48 / w900,
  merge lên `DefaultTextStyle`, màu chữ lấy theo `DefaultTextStyle` nếu
  không truyền).
- `text` là positional bắt buộc (gốc default `'True Focus'`) — theo idiom
  của vault (`BlurText`).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `true_focus/` folder (1 dart file, see `files`)
- **Import:** `import 'true_focus/true_focus.dart';` — one line
- **Or:** `dart tools/export.dart true_focus` → zip + paste-ready block

```dart
// Auto mode — cycles every animationDuration + pauseBetweenAnimations:
TrueFocus(
  'True Focus',
  textStyle: const TextStyle(color: Colors.white),
);

// Manual mode — tap a word to focus it, no timer:
TrueFocus('tap each word', manualMode: true);
```

## API

`TrueFocus` widget (positional `text` + named params):

| Param | Type | Default | Meaning |
|---|---|---|---|
| `text` | `String` | required | Câu chữ, tách theo `separator` |
| `separator` | `String` | `' '` | Ký tự tách từ |
| `manualMode` | `bool` | `false` | Tắt timer; tap từng từ để focus |
| `blurAmount` | `double` | `5.0` | Sigma blur cho các từ không active |
| `borderColor` | `Color` | `0xFF008000` | Màu nét ngoặc (CSS `green`) |
| `glowColor` | `Color` | `0x9900FF00` | Màu glow (rgba(0,255,0,0.6)) |
| `animationDuration` | `Duration` | `500ms` | Thời gian blur transition + khung trượt |
| `pauseBetweenAnimations` | `Duration` | `1s` | Nghỉ thêm giữa 2 lần trượt (auto mode) |
| `textStyle` | `TextStyle?` | `null` | Merge lên default 48px/w900 + `DefaultTextStyle` |
| `animate` | `bool` | `true` | Stop switch — `false` hủy timer, đứng yên tại từ hiện tại |

## Caveats

- **Mỗi từ đang blur = 1 `ImageFiltered` = 1 saveLayer** (§9.2). Câu ngắn
  (headline) thì ổn; đừng ném cả đoạn văn dài vào trên máy yếu. Từ active
  được gỡ filter (sigma ≈ 0) nên luôn ít hơn tổng số từ 1 layer. Cost thật
  trên Android tầm trung: chưa đo.
- Khung glow vẽ bằng `MaskFilter.blur` — 8 draw call nhỏ mỗi frame khi đang
  trượt, rẻ hơn nhiều so với blur chữ.
- Blur sigma của Flutter ≈ CSS `blur(px)` nhưng không pixel-identical.
- Manual mode trên Android là **tap**, không phải hover — không có trạng
  thái "rời chuột" (xem Port notes).
- Gap giữa các từ cố định 16px (gốc `gap-4` cũng hard-code).
- Timer chỉ chạy khi có ≥ 2 từ; `animate: false` hoặc `manualMode: true`
  đều tắt timer. Timer được cancel trong `dispose`.
- Khung đo rect sau layout 1 frame — frame đầu tiên chưa có khung (bản gốc
  cũng render khung từ `{0,0,0,0}`).
- **License gốc:** MIT + Commons Clause (react-bits) — dùng trong app/product
  thoải mái, KHÔNG được bán/redistribute bản thân component (kể cả bản port).

## Changelog

- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `TrueFocus` vào project này.

**Context**
- Chức năng: headline tách từ — từ active nét, còn lại blur; khung 4 góc
  ngoặc phát sáng trượt giữa các từ (port react-bits "True Focus"). Auto
  cycle qua Timer hoặc manual tap-to-focus.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `true_focus/` (1 file), import
  duy nhất `true_focus.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `true_focus/` vào thư mục widget của project đích.
2. Đặt `TrueFocus(text, textStyle: ...)` vào chỗ headline, nền tối để glow
   nổi. Cần tương tác: `manualMode: true` (tap từng từ).

**Việc cần adapt theo project đích**
- `textStyle`: dùng text style/token của project (merge lên default
  48px/w900); `borderColor`/`glowColor` sang accent color của project
  (glow nên là accent với alpha ~0.6).
- Ngoài viewport / màn hình tĩnh: `animate: false` để tắt timer.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file.
- Câu dài nhiều từ: cân nhắc perf saveLayer (xem Caveats) trước khi dùng
  trên list/scroll.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
