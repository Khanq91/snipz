---
# --- IDENTITY ---
id: stepper
title: Step Flow
kind: composite
tags: [stepper, steps, onboarding, form, wizard, transition, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: stepper.dart
files:
  - stepper.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: adapted
source: https://github.com/DavidHDev/react-bits/blob/main/src/ts-tailwind/Components/Stepper/Stepper.tsx
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

# Step Flow

Card wizard nhiều bước port từ react-bits "Stepper": hàng indicator tròn 32px
nối bằng connector fill dần màu tím (#5227FF), checkmark tự vẽ nét khi bước
hoàn thành, vùng nội dung slide theo hướng đi tới/đi lùi với chiều cao bám
theo bước mới, footer Back / Continue. Bấm Complete ở bước cuối → nội dung
sập về 0, footer ẩn. Tên class là `StepFlow` vì `Stepper` trùng class
material của Flutter.

## Port notes

- Nguồn: `src/ts-tailwind/Components/Stepper/Stepper.tsx` (motion/framer →
  widget + AnimationController thuần, không shader).
- Giữ đúng bản gốc: màu indicator 3 trạng thái (#222/#a3a3a3 inactive,
  #5227FF + dot #120F17 active, #5227FF + check đen complete, đổi màu 300ms);
  connector track neutral-600 2px fill 0→100% trong 400ms; check vẽ nét
  pathLength 0→1 (300ms easeOut, delay 0.1s — làm bằng tween 400ms +
  `Interval(0.25, 1)` với `PathMetrics.extractPath`); slide 400ms — vào từ
  `-100%` khi đi tới / `+100%` khi đi lùi (đúng variant gốc
  `dir >= 0 ? '-100%' : '100%'`), ra tới `+50%/-50%` kèm fade; chiều cao
  animate theo child mới; hoàn thành → height 0 + footer ẩn; indicator bấm
  được để nhảy bước (`disableStepIndicators` → mờ 50% + không bấm được);
  padding p-8/px-8/mt-10, bo 32 (rounded-4xl), viền 1px #222, max-w 448
  (max-w-md), nút Continue pill green-500.
- Thay: `children` + component `<Step>` (chỉ là div px-8) → `steps:
  List<Widget>` — không cần wrapper class (và `Step` cũng trùng tên
  material); `x: '%'` của framer → `FractionalTranslation` (% theo bề rộng
  child, giống hệt ngữ nghĩa framer); đo chiều cao bằng `useLayoutEffect` →
  `AnimatedSize` (child vào ở in-flow nên tự đo); spring height
  `duration 0.4` → `Curves.easeOutBack` 400ms (overshoot nhẹ tương tự
  spring); ease slide mặc định của framer tween → `Curves.easeInOut`.
- Thêm nhỏ: `completeButtonText` (bản gốc hardcode 'Complete'); các màu
  Tailwind expose thành param có default đúng giá trị gốc.
- Bỏ: hover đổi màu nút (Android không có hover — InkWell lo phần pressed);
  wrapper aspect-ratio `sm:aspect-[4/3]` ngoài cùng (hạ tầng layout web —
  demo tự căn giữa); `className`/`buttonProps` passthrough (không có DOM).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `stepper/` folder (1 dart file, see `files`)
- **Import:** `import 'stepper/stepper.dart';` — one line
- **Or:** `dart tools/export.dart stepper` → zip + paste-ready block

```dart
StepFlow(
  steps: [
    WelcomeStep(),
    ProfileStep(),
    DoneStep(),
  ],
  onStepChange: (step) => debugPrint('step $step'),
  onFinalStepCompleted: () => Navigator.of(context).pop(),
)
```

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `steps` | `List<Widget>` | required | Nội dung từng bước, đánh số 1-based |
| `initialStep` | `int` | `1` | Bước hiển thị đầu tiên (1-based) |
| `onStepChange` | `ValueChanged<int>?` | null | Gọi với số bước mới khi đổi bước (không gọi lúc complete) |
| `onFinalStepCompleted` | `VoidCallback?` | null | Gọi khi bấm Complete ở bước cuối |
| `backButtonText` | `String` | `'Back'` | Chữ nút lùi (ẩn ở bước 1) |
| `nextButtonText` | `String` | `'Continue'` | Chữ nút tiến |
| `completeButtonText` | `String` | `'Complete'` | Chữ nút tiến ở bước cuối |
| `disableStepIndicators` | `bool` | `false` | true = indicator mờ 50%, không bấm nhảy bước |
| `renderStepIndicator` | `StepFlowIndicatorBuilder?` | null | Tự vẽ indicator `(step, currentStep, onStepClick)` |
| `activeColor` | `Color` | `#5227FF` | Nền indicator active/complete + fill connector |
| `inactiveColor` | `Color` | `#222222` | Nền indicator chưa tới |
| `inactiveTextColor` | `Color` | `#A3A3A3` | Số trong indicator chưa tới |
| `activeDotColor` | `Color` | `#120F17` | Dot 12px trong indicator active |
| `checkColor` | `Color` | đen | Nét checkmark |
| `connectorColor` | `Color` | `#525252` | Track connector (neutral-600) |
| `nextButtonColor` | `Color` | `#22C55E` | Nền pill Continue (green-500) |
| `backTextColor` | `Color` | `#A3A3A3` | Chữ nút Back (neutral-400) |
| `borderColor` | `Color` | `#222222` | Viền card 1px |
| `backgroundColor` | `Color?` | null | Nền card; null = trong suốt như bản gốc |
| `borderRadius` | `double` | `32` | Bo góc card (rounded-4xl) |
| `maxWidth` | `double` | `448` | Bề rộng tối đa card (max-w-md) |

## Caveats

- Cần Material ancestor (MaterialApp/Theme) — footer dùng
  `TextButton`/`InkWell`.
- Card **trong suốt** mặc định (giống bản gốc, thiết kế cho nền tối) — trên
  nền sáng truyền `backgroundColor` hoặc đổi bộ màu.
- Chiều cao dùng `Curves.easeOutBack` thay spring thật của framer — overshoot
  gần giống nhưng không cùng physics; muốn êm hẳn thì đổi curve trong source
  (hằng `_slideDuration`/curve nằm một chỗ trong `_buildContent`).
- Đổi `steps` (số lượng ít hơn `currentStep` hiện tại) khi đang chạy không
  được clamp — giữ số bước ổn định sau khi mount.
- Trong lúc slide 400ms, hit-test đi theo vị trí đã translate
  (`FractionalTranslation` mặc định) — transient, không đáng kể.
- Animation hữu hạn: không có ticker nền khi đứng yên (AnimationController
  chỉ chạy 400ms mỗi lần đổi bước; mọi thứ còn lại là implicit animation).
- **License gốc:** MIT + Commons Clause (react-bits) — dùng trong app/product
  thoải mái, KHÔNG được bán/redistribute bản thân component (kể cả bản port).

## Changelog

- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `StepFlow` vào project này.

**Context**
- Chức năng: card wizard nhiều bước (port react-bits "Stepper") — indicator
  tròn bấm nhảy bước, connector fill animate, nội dung slide theo hướng +
  chiều cao bám child, footer Back/Continue, complete thì sập nội dung.
- Public API: xem bảng API trong README. Class tên `StepFlow` (KHÔNG phải
  `Stepper` — tên đó trùng material).
- Portability: single_file — copy cả folder `stepper/` (1 file), import duy
  nhất `stepper.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `stepper/` vào thư mục widget của project đích.
2. Truyền `steps` là nội dung thật (mỗi bước một widget, tự thêm padding dọc
   nếu cần); đặt card trong `Center`/`SingleChildScrollView` của màn hình.
3. Nối `onStepChange`/`onFinalStepCompleted` vào flow của project (lưu
   state, điều hướng khi hoàn thành).

**Việc cần adapt theo project đích**
- Nền sáng: truyền `backgroundColor` + đổi `inactiveColor`/`borderColor`.
- Palette project: đổi `activeColor`/`nextButtonColor`; chữ nút qua
  `backButtonText`/`nextButtonText`/`completeButtonText` (i18n).
- Form validation: chặn tiến bước bằng cách tự vẽ footer? KHÔNG — footer là
  của component; validate trong `onStepChange` không chặn được. Cần chặn thì
  bọc logic ở bước hiện tại (ví dụ disable nội dung) hoặc yêu cầu bản mở
  rộng.

**Rào (constraints)**
- KHÔNG sửa logic slide/height/indicator bên trong. Chỉ đổi qua params.
- KHÔNG tách entry file ra nhiều file.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
