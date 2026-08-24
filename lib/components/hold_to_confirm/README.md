---
# --- IDENTITY ---
id: hold_to_confirm
title: Hold to Confirm
kind: effect
tags: [button, hold, confirm, ring, progress, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: hold_to_confirm.dart
files:
  - hold_to_confirm.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Hold to Confirm' (Interaction & Input)"
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

# Hold to Confirm

Nút tròn giữ-để-xác-nhận: ring cam fill tuyến tính 800ms khi đè; giữ đủ lâu
thì confirm + flash xanh 1.4s, thả sớm thì ring snap về 0 trong 0.2s.

## Port notes

- Source thật: card `.demo-hold-btn` trong `src/content/body.html`, mục
  `9. Hold to confirm` (effects-a.css: `stroke-dasharray/offset 207`,
  transition 0.8s linear khi `.holding`, 0.2s ease-out khi nhả); JS
  (`19. Hold to confirm` trong main.js): pointerdown → `.holding` + timer
  800ms promote `.done`, nhả sớm clearTimeout, `.done` tự gỡ sau 1400ms.
- Cơ chế gốc: **CSS transition + JS state machine**. Flutter dùng
  `AnimationController` 800ms linear cho ring (kiêm luôn vai trò timer —
  không `Timer`, freeze của viewer dừng được), controller 1400ms cho reset;
  thả sớm `animateBack` 200ms ease-out; đè lại giữa lúc snap-back thì
  `animateTo` từ giá trị hiện tại — đúng retarget của CSS transition.
- Ring: SVG viewBox 72, r 33, stroke 3, round cap, bắt đầu 12h (rotate -90°)
  → `CustomPainter` scale theo `size` (mặc định 84 như demo).
  `dasharray 207 = 2π·33` (full vòng) nên fraction map thẳng sang sweep.
- Số liệu giữ nguyên: 84px, hold 800ms linear, snap 200ms ease-out, reset
  1400ms, màu 300ms ease, palette card-2/line/amber/ok/graphite/bone-dim.
- `pointerleave` của web gộp vào `onPointerCancel` (touch không có leave).
- A11y: Semantics `onLongPress` confirm thẳng không cần giữ 800ms.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `hold_to_confirm/` folder (1 dart file(s), see `files`)
- **Import:** `import 'hold_to_confirm/hold_to_confirm.dart';` — one line
- **Or:** `dart tools/export.dart hold_to_confirm` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `onConfirm` | `VoidCallback?` | `null` | Gọi khi giữ đủ [holdDuration] |
| `holdDuration` | `Duration` | `800ms` | Thời gian phải giữ (semantics, không tắt bằng `animate`) |
| `resetDelay` | `Duration` | `1400ms` | Success state hiển thị bao lâu |
| `size` | `double` | `84` | Đường kính nút |
| `label` / `doneLabel` | `String` | `'Hold' / '✓'` | Nhãn hai trạng thái |
| `backgroundColor` / `borderColor` | `Color` | `#232326 / #2A2A2E` | Nút idle |
| `labelColor` | `Color` | `#A8A6A0` | Chữ idle |
| `trackColor` / `progressColor` | `Color` | `#2A2A2E / #FF8A00` | Ring |
| `doneColor` / `doneForegroundColor` | `Color` | `#4CD08A / #0E0E10` | Success |
| `animate` | `bool` | `true` | False = snap/màu tức thì (ring vẫn theo hold) |

## Caveats

- Ring vẫn animate khi `animate: false` — nó là feedback chức năng của thao
  tác giữ, không phải trang trí.
- Trong scrollable, `Listener` nhận pointerdown ngay cả khi user định scroll;
  scroll sẽ gửi pointercancel → tự hủy hold (hành vi mong muốn).

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `HoldToConfirm` cho hành động destructive/quan trọng. Nối
`onConfirm` vào action thật; đổi màu và nhãn qua constructor; giữ nguyên
timing 800/200/1400ms — đó là chữ ký của effect.
