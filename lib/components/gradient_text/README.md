---
# --- IDENTITY ---
id: gradient_text
title: Gradient Text
kind: effect
tags: [text, gradient, animated, mask, border]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: gradient_text.dart
files:
  - gradient_text.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://reactbits.dev/text-animations/gradient-text
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

# Gradient Text

Gradient chạy qua text (CSS `background-clip: text` → `ShaderMask` +
`ui.Gradient.linear`): gradient trải 300% chiều trục, trượt qua lại (yoyo)
hoặc trượt tới vô hạn (seamless — màu đầu lặp ở cuối). Mode `showBorder`
chạy cùng gradient quanh viền pill. Dựng lại "Gradient Text" của react-bits.

Kèm factory `createGradientTextShader` trả `ui.Shader` thật — áp được lên
bất kỳ thứ gì qua `ShaderMask`/`Paint.shader`, không riêng text.

## Port notes

- Nguồn: `src/ts-tailwind/TextAnimations/GradientText/GradientText.tsx`.
- Giữ: toán background-position (offset = −2 × extent × progress trên ảnh
  gradient 300%), duplicate màu đầu ở cuối, diagonal chỉ trượt ngang (comment
  gốc: tránh interference), cấu trúc border (gradient dưới + box đen inset).
- Bỏ: `pauseOnHover` (Android không có hover) → thay bằng stop switch
  `animate`; `backdrop-blur` + `cursor-pointer` của container (trang trí web).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `gradient_text/` folder (1 dart file, see `files`)
- **Import:** `import 'gradient_text/gradient_text.dart';` — one line
- **Or:** `dart tools/export.dart gradient_text` → zip + paste-ready block

```dart
GradientText(
  child: Text('Shiny', style: TextStyle(fontSize: 36, color: Colors.white)),
)

// Gradient lên thứ khác — factory trả ui.Shader thật:
ShaderMask(
  blendMode: BlendMode.srcIn,
  shaderCallback: (b) => createGradientTextShader(b, progress: p),
  child: const Icon(Icons.bolt, size: 64),
)
```

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `child` | `Widget` | required | Nội dung bị mask (thường `Text`, màu opaque bất kỳ) |
| `colors` | `List<Color>` | tím/hồng/lavender | Stops; màu đầu tự lặp ở cuối |
| `animationSpeed` | `double` | `8` | Giây mỗi lượt quét |
| `direction` | `GradientTextDirection` | `horizontal` | horizontal \| vertical \| diagonal |
| `yoyo` | `bool` | `true` | Quét qua-lại; `false` = trượt tới vô hạn |
| `animate` | `bool` | `true` | Stop switch — đóng băng tại phase hiện tại |
| `showBorder` | `bool` | `false` | Viền gradient quanh pill |
| `borderRadius` | `double` | `20` | Bo pill (gốc 1.25rem) |
| `borderWidth` | `double` | `1` | Dày viền |
| `borderFillColor` | `Color` | đen | Nền trong viền |
| `padding` | `EdgeInsetsGeometry?` | 8×4 khi border | Padding nội dung |

`createGradientTextShader(bounds, {colors, progress, direction})` →
`ui.Shader`. `progress` 0..1 = một chu kỳ; >1 trượt tiếp seamless.

## Caveats

- `ShaderMask` = một `saveLayer` mỗi frame khi animate (§9.2) — headline thì
  ổn; đừng bọc cả list dài. Ngoài viewport: `animate: false`.
- Child cần alpha đúng (text màu opaque); mask thay màu, giữ alpha.
- `showBorder` với `borderRadius` nhỏ hơn `borderWidth` sẽ ra góc trong
  vuông — giữ radius ≥ width.

## Changelog

- **1.0.0** (2026-08-18) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `GradientText` vào project này.

**Context**
- Chức năng: gradient động chạy qua text (mask theo alpha), optional viền
  pill gradient; port react-bits. Factory `createGradientTextShader` trả
  `ui.Shader` cho carrier bất kỳ.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả folder `gradient_text/` (1 file),
  import duy nhất `gradient_text.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `gradient_text/` vào thư mục widget của project đích.
2. Bọc `Text` headline: `GradientText(child: Text(...))` — text giữ style
   sẵn có, chỉ cần màu opaque.

**Việc cần adapt theo project đích**
- `colors` sang palette project (2–4 màu là đẹp nhất).
- Màn hình tĩnh / ngoài viewport: `animate: false`.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi qua params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
