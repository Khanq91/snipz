---
# --- IDENTITY ---
id: page_peel
title: Page Peel
kind: composite
tags: [page, card, stack, 3d, transition, tap, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: page_peel.dart
files:
  - page_peel.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Page Peel' (Surface & Motion)"
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-26
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

# Page Peel

Stack nhiều Widget theo thứ tự sau → trước, lật từng trang trên cùng quanh
cạnh trái rồi làm mờ để lộ trang bên dưới. Sau khi toàn bộ trang đã được lật,
lần `next` kế tiếp đưa cả stack về trạng thái ban đầu.

Đây là `composite` thay vì `effect` đơn vì component quản lý một collection
Widget, thứ tự lớp, chu kỳ tương tác và controller công khai — không chỉ bọc
một child bằng transform.

## Port notes

- Source thật: card `.demo-peel-zone` / `.demo-peel-card` trong
  `src/content/body.html`, mục `22. Page peel` của
  `public/css/effects-c.css` và handler `16. Page peel` trong
  `public/js/main.js`.
- Cơ chế gốc: **CSS transition + JS toggle class**. Container 150×110 đặt
  `perspective: 1000px`; mỗi card có origin `left center` và
  `backface-visibility: hidden`.
- Transform giữ nguyên: 600ms `Cubic(0.65, 0, 0.35, 1)` tới
  `rotateY(-130deg) translateX(-20px)`. Opacity chạy riêng 600ms theo CSS
  `ease` (`Cubic(0.25, 0.1, 0.25, 1)`) tới 0.
- Flutter dùng `Matrix4` với m34 = `-1 / 1000`, pivot trái giữa và ẩn mặt sau
  khi góc đi qua 90°. Mỗi page có controller riêng nên các lần nhấn nhanh vẫn
  có thể peel nhiều page đồng thời như các CSS transition độc lập.
- Thứ tự/chu kỳ giữ đúng demo sống, không theo snippet React rút gọn: source
  DOM là `[back, front]`; JS tìm phần tử chưa peel cuối cùng. Với hai page:
  tap 1 peel front → tap 2 peel back → tap 3 reset cả hai cùng lúc.
- Nút `Peel` chỉ thuộc demo. Component portable cho phép tap trực tiếp toàn
  stack hoặc gọi `PagePeelController.next()` từ control của app đích.
- Không có hover/cursor cần map. `animate: false` và
  `MediaQuery.disableAnimations` áp target ngay, giữ nguyên state/callback.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** toàn bộ folder `page_peel/` (1 Dart file portable, xem `files`)
- **Import:** `import 'page_peel/page_peel.dart';`
- **Or:** `dart tools/export.dart page_peel` → zip + paste-ready block

## API

| Param / method | Type | Default | Ý nghĩa |
|---|---|---|---|
| `pages` | `List<Widget>` | required | Pages theo thứ tự back → front; phần tử cuối peel trước |
| `controller` | `PagePeelController?` | `null` | Gửi lệnh `next()` / `reset()` từ bên ngoài |
| `width` / `height` | `double` | `150 / 110` | Kích thước stack, đúng demo gốc |
| `initialPeeledCount` | `int` | `0` | Số page trên cùng đã peel khi mount |
| `tapToAdvance` | `bool` | `true` | Tap stack gọi cùng chu kỳ với `controller.next()` |
| `animate` | `bool` | `true` | `false` áp peel/reset tức thì |
| `semanticsLabel` | `String` | `'Page stack'` | Nhãn accessibility cho vùng tương tác |
| `onPeeledCountChanged` | `ValueChanged<int>?` | `null` | Trả count 0…`pages.length` ngay sau mỗi bước |
| `onReset` | `VoidCallback?` | `null` | Báo khi stack reset |
| `PagePeelController.next()` | `void` | — | Peel page trên cùng; nếu đã hết thì reset |
| `PagePeelController.reset()` | `void` | — | Reset tất cả page từ bất kỳ bước nào |

## Caveats

- `pages` phải có ít nhất một phần tử; kích thước dương và
  `initialPeeledCount` phải nằm trong range. Constructor assert các invariant.
- Child page tự chịu trách nhiệm về màu, border, radius và nội dung. Component
  chỉ quản lý stack + motion để vẫn reusable cho card, ảnh hoặc form page.
- Transform được phép vẽ ra ngoài vùng 150×110 như CSS `overflow: visible`.
  Parent muốn cắt phần page đang lật phải tự bọc `ClipRect`.
- Owner của `PagePeelController` phải `dispose()` controller. Widget chỉ
  add/remove listener và dispose toàn bộ animation controller nội bộ.
- Tap khi transition đang chạy không bị khóa: page kế tiếp bắt đầu peel ngay,
  đúng handler web. Nếu flow nghiệp vụ cần tuần tự, disable control ở layer
  gọi cho tới khi phù hợp.

## Changelog

- **1.0.0** (2026-08-26) — reimplemented kinetics Page Peel

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `PagePeel` vào project này.

**Context**
- Chức năng: stack page back → front; mỗi next lật page trên cùng 600ms quanh
  cạnh trái, fade ra và reset cả stack ở bước sau page cuối.
- Public API: `PagePeel` + `PagePeelController`, xem bảng API.
- Portability: `single_file` — copy `page_peel.dart`, Flutter SDK only.

**Việc cần làm**
1. Tạo `PagePeelController` trong State của màn hình và dispose cùng State,
   hoặc bỏ controller nếu chỉ cần tap trực tiếp.
2. Truyền `pages` theo thứ tự back → front; giữ key/state của child ổn định.
3. Nối `onPeeledCountChanged` / `onReset` vào flow nghiệp vụ nếu cần.

**Việc cần adapt theo project đích**
- Style, border và nội dung nằm trong từng Widget của `pages`.
- Đổi `width` / `height` cho layout thật; không sửa transform/timing lõi.

**Rào (constraints)**
- Không đảo thứ tự `pages`: phần tử cuối luôn là trang trước.
- Không dispose controller bên trong child; owner tạo thì owner dispose.
- Không thay curve/duration nếu cần giữ fidelity với kinetics.
