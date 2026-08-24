---
# --- IDENTITY ---
id: step_progress
title: Step Progress
kind: effect
tags: [steps, stepper, progress, indicator, spring, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: step_progress.dart
files:
  - step_progress.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Step Progress' (Feedback & State)"
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-24
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

# Step Progress

Indicator bước ngang dựng lại từ kinetics "Step Progress": các node tròn đánh
số nối bằng connector track, thanh fill spring tới `(step-1)/(count-1)` bề
rộng với overshoot nhẹ, mọi node tới bước hiện tại pop active (scale 1.18 +
đổi màu amber). Controlled component — truyền `step` mới là chạy; đứng yên
không có ticker (toàn implicit animation).

Khác [`stepper`](../stepper/README.md) (Step Flow — wizard card đầy đủ có nội
dung + footer): đây chỉ là indicator trần, gắn vào flow nào cũng được.

## Port notes

- Effect gốc: "Step Progress", section **Feedback & State**, kinetics
  (`github.com/ckissi/kinetics`). Ba mảnh source: card trong
  `src/content/body.html`, style mục "19. Step progress" trong
  `public/css/effects-b.css`, JS toggle trong `public/js/main.js`.
- Cơ chế gốc (bước 1 của `docs/kinetics_port.md`): **CSS transition + bezier
  giả spring** — JS chỉ đổi `data-step` và toggle class. → Flutter path:
  implicit animation, không controller.
- Số liệu giữ nguyên: bezier `cubic-bezier(0.34, 1.56, 0.64, 1)` (`--spring`
  của kinetics); fill 0.5s; node pop 0.4s scale 1.18; màu nền/viền node 0.3s
  ease; node 30px, track 3px radius 3; palette amber `#FF8A00` / card-2
  `#232326` / line `#2A2A2E` / bone-faint `#6E6C68` / graphite `#0E0E10`.
  Readout `spring(300, 24)` trên card chỉ là trang trí — demo thật chạy bằng
  bezier, port theo bezier.
- Tổng quát hóa: CSS gốc hardcode `scaleX(0.333/0.666/1)` cho 4 bước —
  thay bằng công thức `(step-1)/(count-1)` (khớp bản React của chính card).
- Màu số trong node đổi tức thời (CSS gốc không transition property `color`)
  — giữ đúng.
- Bỏ/thay: hover viền amber của nút Next (Android không có hover — nút thuộc
  demo, InkWell lo pressed feedback); font JetBrains Mono → font hệ thống
  (luật zero-asset).
- Sai lệch chủ ý: khi lùi bước, phần overshoot âm của scaleX bị clamp về 0
  (CSS gốc sẽ vẽ tràn đối xứng ra ngoài mép trái track trong một tích tắc).
  Overshoot dương (quá mép phải ở bước cuối) giữ nguyên như bản gốc.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `step_progress/` folder (1 dart file(s), see `files`)
- **Import:** `import 'step_progress/step_progress.dart';` — one line
- **Or:** `dart tools/export.dart step_progress` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `step` | `int` | required | Bước hiện tại, 1-based; clamp về `count` nếu vượt |
| `count` | `int` | `4` | Tổng số node (tối thiểu 2) |
| `nodeSize` | `double` | `30` | Đường kính node tròn |
| `trackHeight` | `double` | `3` | Bề dày connector track |
| `activeColor` | `Color` | `#FF8A00` | Fill bar + nền node active (amber) |
| `nodeColor` | `Color` | `#232326` | Nền node chưa tới |
| `trackColor` | `Color` | `#232326` | Nền track |
| `borderColor` | `Color` | `#2A2A2E` | Viền 1px node chưa tới |
| `numberColor` | `Color` | `#6E6C68` | Màu số node chưa tới |
| `activeNumberColor` | `Color` | `#0E0E10` | Màu số node active |

Bề rộng theo parent — bọc trong `SizedBox(width: ...)` để cố định (demo dùng
210 như bản gốc).

## Caveats

- Node active pop scale 1.18 **vẽ tràn** ra ngoài box `nodeSize` (giống CSS
  gốc) — chừa vài px không gian quanh widget, đừng đặt trong clip sát mép.
- Fill bar overshoot quá mép phải track ở bước cuối (~0.25s) — chủ ý, đó là
  cái "spring". Không đặt track trong `ClipRect` nếu muốn giữ hiệu ứng.
- Palette default là bộ tối của kinetics — trên nền sáng đổi `nodeColor` /
  `trackColor` / `borderColor` / `numberColor`.
- Duration/bezier là hằng trong source (một chỗ, đầu class) — muốn chỉnh sửa
  trực tiếp, không expose param để giữ API gọn.
- Animation hữu hạn: không có ticker khi đứng yên (toàn implicit animation,
  không controller nào phải dispose).

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `StepProgress` vào project này.

**Context**
- Chức năng: indicator bước ngang (port kinetics "Step Progress") — node tròn
  đánh số, fill bar spring theo bước, node pop active. Controlled: truyền
  `step` 1-based, không giữ state trong component.
- Public API: xem bảng API trong README. Class `StepProgress`.
- Portability: single_file — copy cả `step_progress/` (1 file), import duy nhất `step_progress.dart`.
- Deps: không có — Flutter SDK only (widgets layer, không cần Material).

**Việc cần làm**
1. Copy folder `step_progress/` vào <thư mục widget của project đích>.
2. Bọc `SizedBox(width: ...)` đặt tại màn hình flow/wizard/checkout; rebuild
   với `step` mới khi flow tiến/lùi (state nằm ở phía app).

**Việc cần adapt theo project đích**
- Color/theme token: default là palette tối của kinetics — đổi 6 param màu
  sang token của project (nền sáng bắt buộc đổi `nodeColor`/`trackColor`).
- Chừa không gian quanh widget cho node pop 1.18 và fill overshoot (xem
  Caveats) — đừng clip sát mép.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
