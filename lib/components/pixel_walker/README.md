---
# --- IDENTITY ---
id: pixel_walker
title: Pixel Walker
kind: paint
tags: [pixel, sprite, dither, skyline, mascot, refresh, header, animated, night, forest, space, fantasy, synthwave, slime, mecha, ghost, cat, capybara, duck, crab, axolotl]

# --- TAXONOMY (§2) ---
paint_source: painter
carriers_verified: []
carriers_failed: []
scale_aware: true

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: pixel_walker.dart
files:
  - pixel_walker.dart: "entry, public API"
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
version: 1.4.1

# --- DERIVED (computed from Test History by verify.dart, do not hand-edit) ---
latest_known_good: null
last_verified: null
status: null

preview: null
---

# Pixel Walker

Cảnh pixel-art neo đáy với sáu mascot, bảy phiên bản art và sáu thế giới nền.
Clawd, mèo Miu, capybara Capy, vịt Quạc, cua Cáu và axolotl Axo đều có gait
riêng; sprite đổi frame pixel trong khi thân nghiêng, nhún và dịch chuyển liên
tục. Toàn bộ cảnh nền được dựng bằng code, không cần asset.

`progress` mở cảnh; `walking` bật bước và parallax; `readiness` tạo tư thế
chuẩn bị; `celebration` lấy mẫu một động tác hoàn tất. Dùng làm header refresh,
loading hoặc empty state. Playground có picker cho mascot, phiên bản, scene,
tốc độ và **Xem từng nhịp** để scrub thời gian mà vẫn giữ các lựa chọn hiện
tại. API mặc định vẫn dùng V1 Original; showcase mặc định dùng V2 Mochi buddies.

## Port notes

- Nguồn gốc: dựng lại cảnh pull-to-refresh của app **Claude Code mobile** từ
  video, không dùng source hoặc asset của app gốc (`origin: reimplemented`).
- Giữ bố cục mascot ở giữa và lớp pixel procedural chuyển động parallax.
- `city` và `nightCity` dựng lại từ video tham khảo; các scene và mascot còn
  lại là thiết kế thêm cho component này.
- Bản 1.3.0 thêm nhịp đi theo nhân vật, art nhiều sắc độ, pose phản ứng và
  sampling theo thời gian; vẫn là một file Flutter, không dependency ngoài SDK.

## Install / reuse

Copy cả folder `pixel_walker/` (entry `pixel_walker.dart`), import một dòng.
Hoặc chạy `dart tools/export.dart pixel_walker` để lấy gói copy-ready.

```dart
import 'pixel_walker/pixel_walker.dart';

SizedBox(
  height: 160,
  width: double.infinity,
  child: PixelWalker(
    sprite: PixelSprite.axolotl(version: PixelSpriteVersion.v7),
    scene: PixelWalkerScene.forest,
    walking: true,
    backgroundColor: const Color(0xFF071410),
  ),
)
```

## API

| Param | Type | Default | Ý nghĩa |
|---|---|---|---|
| `progress` | `double` | `1` | 0→1 mở cảnh; mascot trồi tuyến tính, dither/alpha có easing. |
| `walking` | `bool` | `false` | Bật bước và parallax; false là cảnh tĩnh, không ticker. |
| `motion` | `double` | `1` | 0→1 lượng chuyển động: nhân tốc độ đồng hồ và biên độ thân, dùng giảm dần bước/parallax khi dừng. |
| `readiness` | `double` | `0` | 0→1 tư thế chuẩn bị, giữ chân tại đường đất. |
| `celebration` | `double` | `0` | Tiến độ 0→1 của một động tác hoàn tất; hai đầu về tư thế trung tính. Parent tự điều khiển tiến độ. |
| `frozenAt` | `double?` | `null` | Render một thời điểm tính bằng giây, nhân `speed × motion`, không ticker hay pha tăng tốc; dùng cho thumbnail/scrub. |
| `scene` | `PixelWalkerScene` | `city` | Chọn một trong sáu thế giới procedural; xem bảng scene bên dưới. |
| `scale` | `double` | `1` | Ô nền `3px × scale`; ô mascot `6px × scale / sprite.pixelRatio`. |
| `sprite` | `PixelSprite?` | Clawd | Sprite custom dạng frame ký tự + palette. |
| `mascotColor` | `Color` | `#E8875C` | Màu chính Clawd khi `sprite` null; các sắc độ phụ được suy ra. |
| `skylineColor` | `Color` | `#B9B4AE` | Màu các chấm của layer nền, mây và địa hình. |
| `windowColor` | `Color` | `#F2C069` | Màu cửa sổ và các chi tiết phát sáng như đom đóm, beacon, rune. |
| `starColor` | `Color` | `#C7D3E6` | Màu sao, trăng và các điểm sáng trên nền không gian. |
| `backgroundColor` | `Color` | transparent | Nền dưới cảnh. |
| `speed` | `double` | `1` | Tốc độ bước và parallax; đổi tốc độ live giữ pha hiện tại. |
| `seed` | `int` | `7` | Bố cục procedural xác định theo seed. |

### Scene

| Scene | Các lớp nền |
|---|---|
| `city` | Skyline dither và mây trôi parallax. |
| `nightCity` | Nhà cao tầng có cửa sổ sáng, mây, núi, sao và trăng khuyết. |
| `forest` | Cây dither, núi xa, sao và đom đóm. |
| `spaceStation` | Mái vòm và beacon chuyển động, hành tinh có vành, sao. |
| `ancientRuins` | Kim tự tháp bậc, cột, rune sáng, núi và hai mặt trăng. |
| `cyberGrid` | Mặt trời synthwave, skyline cao tầng và sàn lưới trôi. |

### Sprite và gait

`PixelSprite(frames: ..., palette: ..., gait: PixelGait.clawd)` vẫn nhận được
custom sprite cũ chỉ truyền `frames`/`palette`. Mọi frame phải cùng kích thước,
mọi dòng cùng chiều dài; ký tự không có trong palette là trong suốt. Frame 0
là pose nghỉ, các frame còn lại tạo vòng bước. `gait` chọn nhịp và độ nghiêng,
nhún, dịch ngang; không còn quy tắc frame lẻ tự cộng bob.

Mỗi factory nhận `version: PixelSpriteVersion`. V1 giữ nguyên art, palette và
chuyển động cũ: 1 nghỉ + 6 bước, 4–5 màu; nhịp Clawd/Miu/Capy/Quạc/Cáu/Axo
là 2.15/1.45/0.85/1.60/1.90/1.05 vòng/giây.

| Phiên bản | Tạo hình | Dữ liệu |
|---|---|---|
| V1 Original | Bản gốc, giữ cả chuyển động. | Lưới cũ, `pixelRatio: 1`. |
| V2 Mochi buddies | Thân tròn, màu kem/pastel, nét mặt hiền, viền ấm. | 48×36, 1 nghỉ + 16 bước, 8 màu, `pixelRatio: 3`. |
| V3 Pocket pals | Chibi rõ nét, khăn nhỏ, trái quýt, sao biển và mang ngọc trai. | 48×36, 1 nghỉ + 16 bước, 10–11 màu, `pixelRatio: 3`. |
| V4 Bouncy Slime | Thân thạch trong, lõi sáng và giọt bắn nảy theo gait. | 48×36, 1 nghỉ + 16 bước, `pixelRatio: 3`. |
| V5 Cyber Mecha | Giáp máy, visor LED và luồng phản lực ở jetpack. | 48×36, 1 nghỉ + 16 bước, `pixelRatio: 3`. |
| V6 Wind-up Toy | Tạo hình đồ chơi cơ khí với chìa khóa cót chuyển động. | 48×36, 1 nghỉ + 16 bước, `pixelRatio: 3`. |
| V7 Astral Ghost | Mascot ma lơ lửng với halo, vệt khói và bụi sao. | 48×36, 1 nghỉ + 16 bước, `pixelRatio: 3`. |

V2 có nhịp cơ sở 1.05/0.95/0.68/1.10/1.05/0.82 vòng/giây theo thứ tự trên;
V3 nhanh hơn 8%, V4 chậm hơn 6%, V5 nhanh hơn 16%, V6 nhanh hơn 12%, V7 chậm
hơn 12%. `walkCyclesPerSecond` trả nhịp cuối cùng của sprite. Mỗi vòng có hai
bước; đuôi, mang, càng và phụ kiện theo sau chân. Bốn edition mới có thông số
pose liên tục riêng để đổi độ nảy, độ nghiêng và cảm giác lơ lửng.

`pixelRatio` tách độ phân giải khỏi kích thước: V2–V7 chiếm khung tối đa
96×72px ở `scale: 1`, vừa header 110px. Factory cache frame và palette bất
biến; màu custom tạo palette riêng. Bỏ qua tham số màu dùng màu riêng của
edition; truyền màu tường minh vẫn đổi body/detail/eye. Component vẫn chỉ
một file, không cần sprite sheet hoặc dependency ngoài Flutter.

| Factory | Gait | Cá tính |
|---|---|---|
| `PixelSprite.clawd({color})` | `clawd` | Bước nhanh, nhiều chân, thân nhún gọn. |
| `PixelSprite.miu({body, stripe})` | `miu` | Bước nhẹ, đuôi thay đổi qua chu kỳ. |
| `PixelSprite.capy({body, dark, eye})` | `capy` | Chậm và có trọng lượng, nghiêng ít. |
| `PixelSprite.duck({body, beak, eye})` | `duck` | Lạch bạch, nghiêng ngang rõ. |
| `PixelSprite.crab({body, eyeWhite, eye})` | `crab` | Dịch ngang, thân ít nhấc, càng thay phiên. |
| `PixelSprite.axolotl({body, accent, eye})` | `axolotl` | Nhún thấp, mang và đuôi thay đổi mềm. |

`PixelSprite.samplePose(time, walking: true, motion: 1, readiness: 0,
celebration: 0)` lấy pose xác định từ **thời gian đã nhân tốc độ**. Kết quả
`PixelSpritePose` có `frameIndex`, `lean` (radian), `bob`/`sway` (đơn vị ô
mascot), `scaleX` và `scaleY`. `motion` của sampler điều chỉnh biên độ, không
nhân lại tham số thời gian; widget quản lý tốc độ đồng hồ riêng.

### Ghép với refresh

```dart
PixelWalker(
  progress: status.progress,
  walking: status.isRefreshing,
  readiness: status.mode == PullRevealMode.armed ? 1 : 0,
  sprite: PixelSprite.duck(),
)
```

Demo `pull_reveal_refresh` tăng readiness ở đoạn cuối hành trình kéo. Khi tải
xong, demo chờ một animation 360ms để giảm `motion` và chạy `celebration`
trước khi Future `onRefresh` hoàn tất. Core refresh không tự thêm thời gian
chờ hoặc thay đổi state machine; app tái sử dụng tự sở hữu choreography này.

## Rendering và caveats

- `walking: false`, `frozenAt`, `TickerMode` bị tắt và chế độ giảm chuyển động
  đều không chạy ticker. Pause/resume không bù thời gian đã bị dừng.
- `motion: 0` hoặc `speed: 0` cũng dừng ticker. Bắt đầu đi có đoạn tăng biên
  độ 180ms; muốn dừng êm, parent giảm `motion` trước khi tắt `walking`.
- Pose phản ứng không tự chạy animation: parent thay đổi `readiness` hoặc
  `celebration`. Điều này cho phép dùng trực tiếp tiến độ gesture/controller.
- Reveal của mascot giữ tuyến tính: ở pose nghỉ, chân chạm đất khi
  `progress = 1`. Widget tự clip khi mascot còn nằm dưới mép.
- Vùng trời thích nghi với header thấp; mây được lặp qua viewport. Parallax
  xa→gần: sao/trăng đứng yên, núi 2.2, mây 3.0, nhà 9.0. Trong cảnh đêm,
  tòa nhà vẽ đè mây.
- Point buffer được tái dùng; pose sampling và view buffer có thể tạo object
  nhỏ. Chưa có số FPS/chi phí GPU được đo trên thiết bị cho phiên bản này.
- Không có factory `Shader`: đây là painter nhiều layer và sprite. Để dùng
  làm nền một hình dạng, đặt cảnh dưới `ClipRect`/clip phù hợp.
- Xem thêm [animation brief](../../../docs/pixel_art_animation_brief.md) khi
  thêm art hoặc thay đổi motion.
## Changelog

- **Unreleased** — thêm V4 Bouncy Slime, V5 Cyber Mecha, V6 Wind-up Toy và
  V7 Astral Ghost; thêm các scene forest, spaceStation, ancientRuins và
  cyberGrid, cùng picker scene/edition trong hai demo.

- **1.4.1** (2026-10-23) — sửa hướng bước V3: chân chạm đất quét sang trái
  cùng chiều nền; chân nhấc đưa sang phải. Đồng bộ mũi chân Miu/Quạc và
  chân cua qua cùng sampler, giữ pha nhấc chân, thân và phụ kiện.

- **1.4.0** (2026-10-23) — thêm V2 Mochi buddies và V3 Pocket pals cho đủ
  sáu mascot; sprite 48×36, 16 frame bước với chuyển động phần phụ lệch nhịp.
  Thêm `PixelSpriteVersion`, `pixelRatio`, `walkCyclesPerSecond`; giữ V1 làm
  mặc định API và bảo toàn hình/chuyển động. Showcase có dropdown phiên bản,
  mặc định V2 và giữ mascot/scene/tốc độ/thời điểm scrub khi chuyển.

- **1.3.0** (2026-10-23) — làm mới art của sáu mascot, thêm `PixelGait` và
  pose sampler liên tục cho nhịp đi riêng; thêm `motion`, `readiness`,
  `celebration`, `frozenAt`. Đồng hồ giữ pha khi pause/đổi tốc độ, tôn trọng
  `TickerMode` và giảm chuyển động. Chỉnh vùng trời cho header thấp và nối
  vòng mây; demo có chọn mascot, tốc độ và slider xem từng nhịp. Demo refresh
  ghép pose chuẩn bị cùng đoạn hoàn tất 360ms trước khi thu header.

- **1.2.1** (2026-08-20) — cua Cáu: mắt 1 ô màu tối (chìm trên nền tối) →
  mắt lồi 2×2 có lòng trắng `eyeWhite` + đồng tử lé vào trong; khung 16×9 →
  16×10.
- **1.2.0** (2026-08-20) — thêm 4 mascot theo thứ tự đề xuất: capybara Capy
  (18×10, mặt đơ), vịt Quạc (14×10, lạch bạch, đuôi hất), cua Cáu (16×9,
  front-facing, càng thay phiên giơ lên kiểu "cáu nhưng ngáo"), axolotl Axo
  (18×10, quạt mang rung, đuôi lượn). Demo có picker đủ 6 mascot.
- **1.1.0** (2026-08-20) — thêm scene `nightCity` (nhà cao tầng cửa sổ sáng
  đèn, núi parallax, sao + trăng khuyết — vẫn procedural, không asset) chọn
  qua param `scene`; thêm mascot mèo `PixelSprite.miu()`; params mới
  `windowColor`/`starColor`. Mặc định không đổi: scene `city` + Clawd như cũ.
- **1.0.1** (2026-08-19) — độ trồi của mascot theo `progress` tuyến tính
  (bỏ ease): chân chạm đất đúng lúc progress = 1, tự nó thành chỉ báo "đủ
  ngưỡng refresh" khi ghép với pull_reveal_refresh.
- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp `PixelWalker` bằng cách copy nguyên folder và import entry
`pixel_walker.dart`. Component chỉ phụ thuộc Flutter SDK, không cần asset.

1. Đặt trong khung có kích thước xác định; chọn `sprite` và `scene` qua API.
2. Nối `progress` với độ kéo, `walking` với loading. Nếu cần chuẩn bị/hoàn
   tất, parent điều khiển `readiness`/`celebration` và giảm `motion` khi dừng.
3. Chọn `backgroundColor`, palette và `scale` phù hợp ứng dụng. Dùng
   `frozenAt` cho ảnh tĩnh; không bật ticker cho thumbnail.
4. Giữ entry một file, seed xác định và reveal tuyến tính. Thêm mascot qua
   `PixelSprite`, không sửa painter chỉ để đổi hình hoặc màu.
5. Flutter thấp hơn `latest_known_good`: đọc Test History trước khi dùng.
