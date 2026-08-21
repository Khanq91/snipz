# AUTHORING PROMPT — dựng component mới cho Snipz vault

> Paste file này + mô tả UI bạn muốn dựng. Không cần đưa spec chính.

---

Bạn dựng **một** component Flutter để đưa vào vault cá nhân của tôi. Component sẽ được copy sang project khác, nên tính **tự đủ** quan trọng hơn mọi thứ khác — kể cả sự "gọn gàng" theo chuẩn thông thường.

File này tự đủ. **Đừng hỏi xin spec khác, đừng suy đoán về app quản lý vault** — nó không liên quan tới việc bạn đang làm.

## Input tôi đưa

- `id` (snake_case, ví dụ `aurora_stack`) và `kind` (`paint` | `carrier` | `effect` | `composite`)
- Mô tả UI muốn dựng (chữ, ảnh, hoặc link tham khảo)

Nếu tôi quên `id`/`kind`, tự đề xuất rồi làm tiếp — đừng dừng lại hỏi.

## Luật cứng — vi phạm là component vô dụng

1. **Không import gì ngoài** `dart:*`, `package:flutter/*`, và package pub tôi cho phép rõ ràng. Không tự thêm dependency. Cần một package mà tôi chưa nhắc → **hỏi trước**, đừng tự quyết.
2. **Không tham chiếu theme/constant/util của bất kỳ project nào.** Style vào qua constructor param **có default value**, hoặc lấy từ `Theme.of(context)`.
3. **Không global state, không DI, không Riverpod/Provider/GetIt/singleton.** Data vào qua param, event ra qua callback.
4. **Không asset ngoài** (ảnh, font, `.frag`). Làm procedural. Nếu bất khả thi → nói rõ, đừng lặng lẽ thêm.
5. **Một entry file trùng tên `id`** (`aurora_stack.dart`), chứa public API. Nếu cần file phụ: đặt cùng folder, **prefix `_`** (`_noise_layer.dart`), và entry phải `export` chúng.
6. **Tên public class không được trùng tên phổ biến.** `GlassCard`, không phải `Card`.
7. Chạy được trên **Android** (target chính). Không dùng API chỉ có ở một platform mà không có fallback.

## Hai thứ AI hay bỏ sót — làm cho đúng

**A. `kind: paint` BẮT BUỘC nhận param `scale`** (`double`, default `1.0`).
Paint thiết kế cho fullscreen nhét vào button 48px sẽ thành vệt màu phẳng — noise mất chi tiết, gradient thành một cục. Đây là lỗi thẩm mỹ, không phải lỗi kỹ thuật, nên compiler không bắt được. `scale` phải điều khiển **mật độ chi tiết**, không phải scale transform toàn bộ.

**B. Nếu paint biểu diễn được bằng `Shader`, expose factory trả `Shader`**, không chỉ trả Widget:

```dart
Shader createAuroraShader(Rect bounds, {double scale = 1.0, List<Color>? colors});
```

Lý do: có factory `Shader` thì paint này áp được lên **mọi thứ** qua `ShaderMask` — card, button, border, cả text — mà không cần viết thêm dòng nào. Không có nó thì paint chỉ dùng được đúng một chỗ. Vẫn cung cấp Widget wrapper tiện dụng, nhưng factory là thứ chính.

Dùng `ui.Gradient.sweep` / `ui.Gradient.linear` / `ui.Gradient.radial` / `ImageShader`. **Không dùng `FragmentProgram`** — nó bắt buộc file `.frag` khai báo trong pubspec, phá luật 4.

Nếu paint không shader hóa được (particle động, layer chồng nhiều lớp), nói rõ lý do trong README thay vì cố gượng ép.

## Component có animation — quy ước sample(t)

Áp dụng khi component có chuyển động liên tục (không áp cho animation rời rạc
kiểu implicit animation của Flutter):

1. **Tách model/painter.** Trạng thái một frame = hàm thuần của thời gian trôi
   `t` (giây). Painter chỉ vẽ frame, không tự tính giờ. (Tham chiếu:
   `bloub_bot/_engine.dart` — engine thuần Dart test được không cần widget.)
2. **Không `Random()` không seed, không `DateTime.now()`** trong đường vẽ.
   Ngẫu nhiên = PRNG seed cố định hoặc bảng sinh sẵn; "sống động" = loop noise
   (tổng vài sin chu kỳ nguyên tố cùng nhau) — tất định nhưng không lặp thấy
   được.
3. **Expose `double? frozenAt`** — null: chạy sống; có giá trị: render đúng
   một frame tại t đó, không ticker. Đây là cái cho phép state board,
   thumbnail rẻ và golden test.
4. **Chuyển động chạy bằng `Ticker`/`AnimationController`** (dispose đúng, có
   cờ `animate` tắt từ ngoài; dt clamp ~64ms cho app resume). KHÔNG dùng
   `Timer`/`Stream` cho animation — nút freeze của viewer dừng ticker qua
   `TickerMode`, Timer thì nó không dừng được.
5. Trong `<id>_demo.dart`, nếu component có nhiều trạng thái/biến thể rõ rệt:
   khai báo `variants` (`DemoVariant` trong `core/component_demo.dart`, kèm
   `frozenBuilder` khi có `frozenAt`) — viewer tự dựng chip chọn biến thể,
   state board và deep link `?variant=`.

## Output — đúng 3 file

**1. `<id>.dart`** — entry, portable. Header comment:

```dart
/// <Tên component>
/// Origin: reimplemented — dựng lại từ ý tưởng của Khang
/// Deps: flutter only
/// Flutter: <version>
/// Entry file. Copy cả folder này sang project khác là dùng được.
```

**2. `<id>_demo.dart`** — file này **được miễn mọi luật trên**, tự do dùng gì cũng được. Nó có hai việc: (a) render preview, (b) là **usage example tử tế** khi tôi copy sang project khác. Viết như code mẫu production, không phải scratchpad.

```dart
final auroraStackDemo = ComponentDemo(
  id: 'aurora_stack',
  builder: (context) => ...,
  thumbnailBuilder: (context) => ...,   // optional, nếu preview chính nặng
);
```

**3. `README.md`** — frontmatter + nội dung:

```yaml
---
id: aurora_stack
title: Aurora Stack
kind: paint
tags: [aurora, gradient, animated]

paint_source: shader          # shader | painter | widget | none
carriers_verified: []         # ĐỂ RỖNG — tôi tự verify sau, không đoán hộ
carriers_failed: []
scale_aware: true

portability: single_file      # single_file | folder | folder_with_assets
entry: aurora_stack.dart
files:
  - aurora_stack.dart: "entry, public API"

deps: []                      # package pub thật sự dùng

origin: reimplemented         # original (ý tưởng của tôi) | reimplemented (dựng lại UI tôi thấy)
source: null                  # link tham khảo nếu có, không có thì null
author: "Khang"
license: MIT

created: <hôm nay>
created_flutter: <hỏi tôi hoặc để placeholder>
created_dart: <như trên>
created_deps: []
platforms_initial: [android]

version: 1.0.0
latest_known_good: null       # ĐỂ NULL — script tự điền khi tôi chạy verify
last_verified: null
status: verified              # chỉ: verified | needs_patch | broken. KHÔNG có "stale"
---
```

Phần thân README: mô tả 2–3 dòng, **Install** (snippet `pubspec.yaml` copy-paste được, hoặc ghi rõ "flutter only"), **API** (bảng param/type/default/ý nghĩa), **Caveats** (perf, platform, giới hạn đã biết), **Changelog** (`1.0.0` — created).

## Rào

- **Không tách file "cho gọn".** Một file là mặc định. Chỉ tách khi thật sự cần, và khi tách thì theo luật 5.
- **Không viết abstraction/config/builder pattern không được yêu cầu.** Component này dùng ở một chỗ, không phải thư viện.
- **Không đoán hộ `carriers_verified`** — tôi phải tự thử mới biết.
- **Không thêm animation nếu tôi không yêu cầu.** Animation là chi phí perf trên mobile.
- Có `AnimationController` → phải dispose đúng, và expose cách dừng từ bên ngoài.

## Tự kiểm trước khi trả lời

1. Copy folder này sang project Flutter trống → chạy được ngay không?
2. Có import nào ra ngoài folder không?
3. `kind: paint` → có `scale` chưa? Có factory `Shader` chưa (hoặc đã giải thích tại sao không)?
4. Tên public class có trùng tên phổ biến không?
5. `<id>_demo.dart` có đọc được như một ví dụ tử tế không?

## Sau khi bạn xong

Tôi chạy `dart tools/validate.dart`. Nếu fail, tôi paste lỗi lại — bạn sửa cho tới khi sạch. Đừng tự tin là đúng, cứ chờ kết quả validate.