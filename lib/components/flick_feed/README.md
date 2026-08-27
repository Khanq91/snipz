---
# --- IDENTITY ---
id: flick_feed
title: Flick Feed
kind: composite
tags: [scroll, snap, momentum, flick, feed, velocity, gesture, feel, interactive, gsap]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: flick_feed.dart
files:
  - flick_feed.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/greensock/GSAP (ScrollTrigger snap/fastScrollEnd/preventOverlaps/anticipatePin, InertiaPlugin, utils/VelocityTracker)
author: "Khang"
license: "GSAP Standard License (các luật hành vi dựng lại, không copy code)"

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-27
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

# Flick Feed

Feed dọc giả lập để **cảm** bốn luật "feel" scroll của GSAP trên nội dung
thật, với công tắc **RULES ON/OFF** ngay trên màn: cùng một cú flick, bật/tắt
để thấy khác biệt thay vì đọc mô tả. HUD dưới đáy vẽ mini-map: vận tốc live,
điểm đáp tự nhiên dự đoán (chấm rỗng) và section được snap chọn (chấm đặc).

## Bốn luật — chúng là gì và vì sao đáng chép

### 1. Snap theo đà, có hướng (ScrollTrigger `snap` + InertiaPlugin)

Vấn đề: `PageView` snap trang GẦN NHẤT — flick mạnh cỡ nào cũng chỉ đi một
trang, còn scroll tự do thì dừng lơ lửng giữa hai section. GSAP làm khác:

- Lúc thả tay, giải **nghiệm đóng** điểm đáp tự nhiên từ vận tốc:
  `duration = clamp(|v| / resistance, 0.25, 2)` rồi
  `landing = pos + duration × 0.05 × v / 0.18549` (hằng số `0.18549` =
  quãng đường `power3.out` đã đi ở 5% thời gian — flick mạnh bay xa đúng
  theo tỉ lệ vật lý của ease).
- Chọn section top gần `landing` nhất **nhưng chỉ trong các ứng viên cùng
  hướng di chuyển** (`directional`) — không bao giờ giật lùi ngược đà.
- Tween tiếp quản sau `snapDelay` (0.12s) với duration giải ngược từ vận
  tốc và quãng đường: `dur = dist × 0.18549 / |v| / 0.05`, clamp
  `[0.1, 2]` (đúng default `snap.duration` của GSAP). Thả gần như đứng yên
  → "snap phải nhanh": `dur = min + (max − min) × 0.1`.

Kết quả: flick mạnh **bay qua vài section rồi đáp gọn** vào một section;
flick nhẹ nhích đúng một section; thả giữa chừng thì hít về gần nhất.

### 2. `fastScrollEnd` (ngưỡng 2500 px/s)

Vấn đề: lướt vèo qua 5 section, dừng lại, và cả đuôi animation reveal diễn
đuổi theo sau lưng. Luật GSAP: section nào bị lướt qua khi |v| vượt ngưỡng
thì reveal **nhảy thẳng về trạng thái hoàn tất** — chỉ section bạn đáp
xuống mới diễn. Tắt RULES rồi flick mạnh sẽ thấy ngay "cái đuôi".

### 3. `preventOverlaps`

Khi một section bắt đầu diễn reveal, mọi reveal còn dang dở của các section
**phía sau theo hướng cuộn** bị hoàn tất ngay — hai animation không bao giờ
tranh nhau. Cặp với fastScrollEnd thành bộ đôi "phía sau lưng luôn sạch".

### 4. `anticipate` (từ `anticipatePin`)

Bệnh gốc trên web là flicker 1 frame khi pin `position:fixed` — Flutter
KHÔNG có bệnh đó (SliverPersistentHeader pin trong cùng layout pass). Nhưng
Flutter có bệnh tương đương thật: mọi state lái bằng
`NotificationListener` + `setState` đều trễ **1 frame** — 3000 px/s ở
60fps là pop trễ ~50px. Pill "Section n/8" ở đây trigger tại
`offset + velocity × anticipate` (lookahead 0.12s) nên xuất hiện và đổi số
ĐÚNG LÚC khi fling nhanh. Tắt RULES là về trigger thô, nhìn rõ nhất khi
flick thật mạnh.

### Khuyến mãi: VelocityTracker 2 mẫu của GSAP

Vận tốc scroll đo bằng đúng tracker của GSAP (`utils/VelocityTracker.js`):
sample tối đa mỗi 0.05s (~20Hz — theo frame là quá nhiễu), và chỉ xoay mẫu
khi giá trị đổi HOẶC quá 0.2s — **nhạy khi phản ứng, chậm khi về 0**, nên
event stream lắt nhắt vẫn đọc ra vận tốc thật còn ngón tay dừng hẳn thì về
0 sạch. HUD hiện số này live.

## Cách demo

Flick mạnh → xem HUD: chấm rỗng (đáp tự nhiên) vs chấm đặc (section được
chọn). Flick nhẹ → nhích một section. Thả lửng giữa hai section → hít nhanh.
Tắt RULES làm lại y hệt: dừng lơ lửng, đuôi animation diễn muộn, pill trễ.

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `flick_feed/` folder (1 dart file(s), see `files`)
- **Import:** `import 'flick_feed/flick_feed.dart';` — one line
- **Or:** `dart tools/export.dart flick_feed` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `sectionCount` | `int` | `8` | Số section |
| `sectionExtent` | `double` | `300` | Chiều cao cố định một section (mốc snap) |
| `rulesOn` | `bool` | `true` | Trạng thái đầu của công tắc RULES (đổi được trong UI) |
| `showHud` | `bool` | `true` | Mini-map vận tốc + marker đáp/snap |
| `resistance` | `double` | `400` | px/s vận tốc đổi 1 giây bay tự nhiên (GSAP inertia) |
| `snapDelay` | `double` | `0.12` | Giây sau khi thả trước khi tween snap tiếp quản |
| `snapMinDuration` / `snapMaxDuration` | `double` | `0.1` / `2.0` | Kẹp duration tween snap (default GSAP) |
| `fastScrollThreshold` | `double` | `2500` | px/s kích hoạt fastScrollEnd (default GSAP) |
| `anticipate` | `double` | `0.12` | Giây lookahead vận tốc cho pill chương |
| `revealDuration` | `double` | `0.8` | Giây một reveal (cố ý chậm cho dễ thấy luật) |
| `accent` | `Color` | `0xFF8B7CFF` | Màu chủ đạo (hue xoay dần theo section) |
| `onSectionSnapped` | `ValueChanged<int>?` | `null` | Snap đáp xong vào section nào |
| `animate` | `bool` | `true` | Cho ticker chạy |
| `frozenAt` | `double?` | `null` | Frame tĩnh đầu feed (không ticker, không gesture) |

## Caveats

- Cách tiếp cận là **settle-then-takeover** đúng như GSAP (để fling native
  chạy, sau `snapDelay` tween chiếm quyền) — KHÔNG phải custom
  ScrollPhysics. Ưu: giữ nguyên cảm giác đầu fling native + thuật toán y
  bản gốc; nhược: có một khoảnh khắc chuyển giao — chỉnh `snapDelay` nếu
  thấy khựng.
- Solver nghiệm đóng trùng với `inertia_throw` (~20 dòng) được **cố ý
  nhân bản** — luật vault: component tự đủ, không import chéo folder.
- Reveal chạy lại được (reset khi section rơi hẳn xuống dưới viewport) để
  thử luật nhiều lần — không phải bug.
- Component gesture-driven: `frozenAt` là frame tĩnh đầu feed, không replay
  kịch bản. Không autoDemo — thứ cần cảm là ngón tay của bạn.
- Các ngưỡng (`snapDelay`, `resistance`, `fastScrollThreshold`) là tham số
  feel — tune trên máy thật, số mặc định là điểm khởi đầu.

## Changelog

- **1.0.0** (2026-08-27) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `FlickFeed` vào project này.

**Context**
- Chức năng: feed demo 4 luật feel scroll của GSAP (snap theo đà có hướng,
  fastScrollEnd, preventOverlaps, anticipate) + tracker vận tốc 2 mẫu, có
  công tắc RULES ON/OFF và HUD trực quan hóa điểm đáp.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `flick_feed/` (1 file), import duy nhất `flick_feed.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `flick_feed/` vào <thư mục widget của project đích>.
2. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
