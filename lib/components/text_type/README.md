---
# --- IDENTITY ---
id: text_type
title: Text Type
kind: effect
tags: [text, typewriter, typing, cursor, animated, loop]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: text_type.dart
files:
  - text_type.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://reactbits.dev/text-animations/text-type
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

# Text Type

Typewriter nhiều câu: gõ từng ký tự → dừng → xoá → câu kế → lặp, cursor
nhấp nháy fade. Hỗ trợ tốc độ ngẫu nhiên per-ký-tự, màu riêng từng câu, gõ
ngược, ẩn cursor lúc đang gõ. Dựng lại "Text Type" của react-bits
(setTimeout chain + GSAP blink → Timer + AnimationController).

Điều khiển ngoài qua `GlobalKey<TextTypeState>`: `start()`, `stop()`,
`restart()`.

## Port notes

- Nguồn: `src/ts-tailwind/TextAnimations/TextType/TextType.tsx`.
- Giữ: máy trạng thái type/pause/delete/advance nguyên thứ tự và timing
  (kể cả chi tiết `initialDelay` áp trước MỖI câu, và non-loop dừng lại với
  câu cuối đứng nguyên); blink yoyo easeInOut 0.5s; `variableSpeed`,
  `textColors` cycle, `reverseMode`, `hideCursorWhileTyping`.
- Bỏ: `startOnVisible` (IntersectionObserver) → `autoStart: false` +
  `start()` từ logic visibility của app (§9.2); `as`/`className` (DOM);
  cursor chỉ nhận `String` thay vì ReactNode tuỳ ý.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `text_type/` folder (1 dart file, see `files`)
- **Import:** `import 'text_type/text_type.dart';` — one line
- **Or:** `dart tools/export.dart text_type` → zip + paste-ready block

```dart
TextType(
  const ['Text typing effect', 'for your apps', 'Happy coding!'],
  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
  onSentenceComplete: (s, i) => debugPrint('done: $s'),
)
```

## API

`TextType` widget (positional `sentences` + named params):

| Param | Type | Default | Meaning |
|---|---|---|---|
| `sentences` | `List<String>` | required | Các câu gõ lần lượt |
| `typingSpeed` | `Duration` | `50ms` | Delay mỗi ký tự khi gõ |
| `initialDelay` | `Duration` | `0` | Delay trước MỖI câu |
| `pauseDuration` | `Duration` | `2s` | Giữ nguyên sau khi gõ xong |
| `deletingSpeed` | `Duration` | `30ms` | Delay mỗi ký tự khi xoá |
| `loop` | `bool` | `true` | `false` = dừng ở câu cuối (không xoá) |
| `style` | `TextStyle?` | `null` | Merge lên `DefaultTextStyle` |
| `textColors` | `List<Color>` | `[]` | Màu theo câu, cycle; rỗng = inherit |
| `showCursor` | `bool` | `true` | Hiện cursor |
| `hideCursorWhileTyping` | `bool` | `false` | Ẩn cursor lúc gõ/xoá, hiện lúc dừng |
| `cursorText` | `String` | `'\|'` | Glyph cursor |
| `cursorStyle` | `TextStyle?` | `null` | Style riêng cursor |
| `cursorBlinkDuration` | `Duration` | `500ms` | Một lượt fade (chu kỳ = 2×) |
| `variableSpeedMin`/`Max` | `Duration?` | `null` | Cặp: tốc độ gõ random trong khoảng |
| `reverseMode` | `bool` | `false` | Gõ ngược từng câu |
| `autoStart` | `bool` | `true` | Tự chạy khi mount |
| `onSentenceComplete` | `(String, int)?` | `null` | Sau khi xoá xong một câu |

`TextTypeState` (qua `GlobalKey`): `start()`, `stop()`, `restart()`.

## Caveats

- Mỗi ký tự là một `setState` — text ngắn thì không đáng kể; đừng chạy cả
  đoạn văn nghìn ký tự ở `typingSpeed` thấp trên máy yếu.
- Cursor blink là ticker chạy LIÊN TỤC kể cả khi máy trạng thái dừng —
  ngoài viewport thì `stop()` không tắt blink; muốn tắt hẳn phải remove
  widget khỏi tree (hoặc `showCursor: false`).
- Gõ theo `runes` (code point) — an toàn emoji cơ bản, nhưng grapheme ghép
  (cờ, tổ hợp ZWJ) sẽ hiện từng phần trong lúc gõ.
- Text xuống dòng tự nhiên theo width parent; cursor là `WidgetSpan` nên
  nằm cùng dòng với ký tự cuối.

## Changelog

- **1.0.0** (2026-08-18) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `TextType` vào project này.

**Context**
- Chức năng: typewriter nhiều câu có xoá + cursor blink (port react-bits),
  điều khiển ngoài qua `GlobalKey<TextTypeState>`.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `text_type/` (1 file), import
  duy nhất `text_type.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `text_type/` vào thư mục widget của project đích.
2. Thay `Text` hero/tagline bằng `TextType([...], style: ...)`.
3. Cần chạy-khi-thấy: `autoStart: false` + gọi `start()` từ visibility
   logic của project.

**Việc cần adapt theo project đích**
- `style`/`textColors` sang token của project.
- Câu cố định một lần: `loop: false`.

**Rào (constraints)**
- KHÔNG sửa máy trạng thái bên trong. Chỉ đổi qua params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
