# Kế hoạch tích hợp bloub → Snipz

> Nguồn tham khảo: <https://github.com/jeremy-prt/bloub> (Vue 3 + TS, MIT, © 2026
> Jérémy Perret) — bản tái tạo avatar bot x.ai bằng SVG: một khối đen morph qua
> ~15 trạng thái, hai mắt là **lỗ thủng** trên thân, engine `sample(t)` thuần
> hàm theo thời gian, mọi hằng số **đo từ video gốc** (không được làm tròn).
>
> Tài liệu này là kế hoạch cho **4 hạng mục**, để duyệt trước khi code. Mỗi mục
> có: sản phẩm, kỹ thuật cụ thể, các bẫy cần né, và tiêu chí nghiệm thu.

---

## 0. Bức tranh chung

| # | Hạng mục | Sản phẩm | Bump | Cỡ |
|---|----------|----------|------|----|
| A | `shape_morph` — vector shape morphing | component mới (kind `composite`) | patch | S |
| B | `bloub_bot` — avatar bot morph 15 trạng thái | component mới (kind `composite`), 3 phase | patch × 3 | L |
| C | Quy ước "sample(t) thuần" cho component animation | sửa `docs/AUTHORING_PROMPT.md` + mở rộng `ComponentDemo` | (đi kèm D) | S |
| D | Viewer: freeze, state board, deep link + share PNG | D1–D3 một PR; **D4 share PNG tách nhánh/PR riêng** (đã chốt) | minor × 2 | M |
| E | Export SVG & **SVG động** từ `bloub_bot` (§5) | serializer thuần Dart trong component + nút share ở demo | patch | S–M |

**Thứ tự đề xuất: A → B1 → C+D1–D3 → D4 → E1 → B2 → B3.** A nhỏ, kiểm chứng
phần toán lõi (radial profile + Catmull-Rom trên `Canvas`) trước khi port cả
engine. C viết *sau khi* đã có A/B1 làm bằng chứng sống (quy ước rút từ code
thật, không phải lý thuyết suông). D cần `variants` mà C định nghĩa. D4 đi
nhánh riêng nên chen được bất kỳ lúc nào sau C. E1 chỉ cần B1 (chi tiết §5).

### Ba quyết định nền tảng (áp cho mọi mục)

**D1 — Không có "shared lib" giữa các component.** Luật vault (AUTHORING_PROMPT
luật 1, 2, 5) cấm component import ra ngoài folder của nó. Vậy nên `shape_morph`
và `bloub_bot` **mỗi bên giữ một bản sao** phần toán radial-profile (~150 dòng).
Trùng lặp là chủ đích — "tính tự đủ quan trọng hơn sự gọn gàng".

**D2 — Engine tách 2 tầng, tầng model không import Flutter.** Giống tiền lệ
`lib/core/models.dart` ("No Flutter imports — usable from plain Dart unit
tests"): toàn bộ toán (silhouette, pose, engine, decor…) dùng class `BotPoint`
tự khai báo + `List<double>`, KHÔNG đụng `dart:ui`. Tầng painter
(`CustomPainter`) mới đổi frame-model thành `Path`/`Canvas`. Đổi lại: test
engine chạy bằng unit test thuần, không cần pump widget — đúng cái đã cho phép
bloub test không cần DOM.

**D3 — Bảng sinh từ RNG: vendor thành const, không port RNG JS.** bloub sinh
lịch chớp mắt, seed của 6 rings / 4 comet ribbons / 5 particles bằng
`mulberry32` (seed cố định) *lúc load module*. Port `mulberry32` sang Dart phải
tái tạo đúng semantics `Math.imul` / `>>> 0` của JS — dễ sai lệch âm thầm.
Thay vào đó: chạy một script Node một lần trên checkout bloub, in các bảng ra
literal, dán vào Dart dưới dạng `const`. Cùng bản chất với `profiles.ts` (data
đo đạc vendor sẵn). Ghi commit hash của bloub vào comment cạnh bảng để
regenerate được.

### Những gì KHÔNG lấy

- **Export GIF/MP4** — ngoài scope đợt này. Ghi nhận cho sau: bloub **tự viết**
  encoder GIF (LZW, không lib) nên port sang Dart cũng không cần dep — chỉ mở
  lại nếu cần avatar động cho nơi từ chối SVG (Discord/Slack). Export
  **SVG / SVG động** thì LẤY — thành hạng mục E (§5).
- **i18n (fr/en/zh)** — vault cá nhân.
- **Timeline editor / Customizer UI** như một màn hình app — giá trị của chúng
  vào qua *param của component* + demo controls, không thành feature viewer.
- **Intro sequence (arrivée), gaze theo con trỏ chuột** — mobile không có
  cursor; B4 (tuỳ chọn) sẽ map sang drag/pan nếu muốn.

### License & attribution

MIT, © 2026 Jérémy Perret. Frontmatter README của cả `shape_morph` lẫn
`bloub_bot`:

```yaml
origin: adapted
source: https://github.com/jeremy-prt/bloub
license: "MIT (bloub, © 2026 Jérémy Perret)"
```

Các mảng số đo đạc (profiles egg/hexagon/triangle, hằng số mắt, decor) vendor
nguyên xi — **cấm làm tròn**: README bloub ghi rõ làm tròn là phá độ giống,
và mấy con số phản trực giác (mắt nghiêng `\\` chứ không `//`, thân là hình
tròn hoàn hảo chứ không phải squircle) đều là số đo.

---

## 1. Hạng mục A — `shape_morph` (làm trước, mở đường)

**Ý tưởng:** đóng gói kỹ thuật lõi của bloub thành component tái dùng được:
*mọi hình đi qua profile radial 64 mẫu `r(theta)` → morph giữa hai hình bất kỳ
= lerp 64 số*, không cần package path-morphing. Vault đang có `morph_slider`
(morph ảnh bằng shader) nhưng chưa có vector morph.

### Sản phẩm

```
lib/components/shape_morph/
  shape_morph.dart        # entry
  shape_morph_demo.dart
  README.md
```

`kind: composite`, `paint_source: painter`, `portability: single_file`,
`deps: []`. Scaffold bằng `dart tools/new_component.dart shape_morph composite`.

### API đề xuất

```dart
/// Hình = 64 bán kính + pose (rot, cx, cy, sx, sy). Bất biến (immutable).
class RadialShape {
  const RadialShape(this.radii, {this.rot = 0, this.cx = 0, this.cy = 0,
      this.sx = 1, this.sy = 1});

  // Constructors phân tích — port 1:1 từ shape.ts của bloub:
  factory RadialShape.circle([double r = 1]);
  factory RadialShape.superellipse(double n, {double sx, double sy}); // n=4 ≈ squircle
  factory RadialShape.regularPolygon(int sides, {double radius, double cornerRadius, double rotationDeg}); // Minkowski + ray-cast
  factory RadialShape.polygon(List<Offset> points);        // ray-cast từ tâm
  factory RadialShape.unionOfCircles(List<(double x, double y, double r)>); // blob/mây
  factory RadialShape.capsuleHull(...);                    // hullOfCircles — thanh 2 đầu tròn

  static RadialShape lerp(RadialShape a, RadialShape b, double t); // + rot theo cung ngắn nhất
  Path toPath(Size size, {double tension = 1 / 6});        // Catmull-Rom → cubicTo
}

/// Widget vẽ hình morph theo [t] giữa danh sách [shapes].
class ShapeMorph extends StatelessWidget { ... }

/// Tween để cắm vào AnimationController bên ngoài.
class RadialShapeTween extends Tween<RadialShape> { ... }

/// Clip child bất kỳ theo hình morph → dùng được cho ảnh, video, container.
class RadialShapeClipper extends CustomClipper<Path> { ... }
```

(`ShapeBorder` cho button/card là ý hay nhưng **để sau** — không phình scope.)

### Kỹ thuật port (shape.ts → Dart)

| bloub | Dart | Ghi chú |
|---|---|---|
| `PROFILE_SAMPLES = 64`, `COS/SIN` precompute | `const int kSamples = 64` + `Float64List` tính 1 lần (static final) | mọi hình cùng số mẫu → điểm tương ứng 1-1 |
| `blend()` — lerp radii + rot cung ngắn nhất | `RadialShape.lerp` | rot: đưa `dRot` về (−π, π] trước khi lerp |
| `toPoints()` — rot → squash sx/sy → translate | trong `toPath` | **đúng thứ tự đó**: squash là ở toạ độ màn hình, SAU rotation |
| `closedPath()` — Catmull-Rom tension 1/6 → lệnh `C` | `Path..moveTo..cubicTo` vòng kín | công thức control point giữ nguyên: `c1 = p1 + (p2−p0)·k` |
| `profileFromPolygon()` — ray-cast O(64·n) | giữ nguyên | chạy 1 lần lúc dựng hình, **không bao giờ trong paint** |
| `unionOfCirclesProfile()` | giữ nguyên | chỉ đúng khi gốc toạ độ nằm TRONG union — ghi vào doc comment |
| `regularPolygonProfile()` — Minkowski sum với đĩa | giữ nguyên | đỉnh đặt ở `radius − cornerRadius` rồi bo bằng cung |
| `r2()` làm tròn chuỗi SVG | **bỏ** | Flutter build `Path` số trực tiếp, không có chuỗi |

### Cần để ý

1. **Alloc-free trong paint:** `Path` phải rebuild mỗi frame (không mutate
   được), nhưng mảng điểm trung gian dùng `Float64List` tái sử dụng. Repaint
   qua `CustomPainter(repaint: animation)`, không `setState` mỗi tick.
2. Hình không star-convex (tâm không "nhìn thấy" toàn bộ biên) sẽ bị ray-cast
   nuốt chi tiết — đó là giới hạn bản chất của r(theta), ghi rõ trong README
   (bloub cũng vậy: cái gì không biểu diễn được thì đi qua `profileFromPolygon`
   và chấp nhận xấp xỉ).
3. `scale` không áp dụng ở đây (không phải `kind: paint`), nhưng `tension` và
   số mẫu ảnh hưởng độ mượt khi vẽ to — 64 mẫu bloub đã chứng minh đủ cho 600px.

### Demo + nghiệm thu

Demo: morph tuần tự circle → squircle → hexagon → star(polygon) → blob(union)
với slider tay + auto-play; một tile phụ dùng `RadialShapeClipper` clip một
gradient. Nghiệm thu: `dart tools/validate.dart` sạch; test unit: lerp t=0/1
trả đúng 2 đầu, rot 170°→−170° đi qua 180° (không quay ngược cả vòng);
`flutter analyze` sạch.

---

## 2. Hạng mục B — `bloub_bot`

**Ý tưởng:** port `src/bot/` của bloub (~4.500 dòng TS, phần phải port thật
~2.000) thành component mascot/loading-indicator: một khối morph qua các trạng
thái idle/thinking/wink/…/orbit/burst/comet, có "sự sống" (gaze drift + chớp
mắt tất định), mắt là lỗ thủng thật.

### Cấu trúc file (folder, entry export hết file `_`)

```
lib/components/bloub_bot/
  bloub_bot.dart        # entry: widget BloubBot + export các file dưới
  _math.dart            # tau, clamp, lerp, easings, loopNoise
  _shape.dart           # Silhouette, blend, toPoints, profileFromPolygon, hullOfCircles, radiusAtAngle, capsule
  _profiles.dart        # data đo: egg/hexagon/triangle (64 số mỗi hình) — vendor
  _face.dart            # eyePoses (mô hình cầu 3D), liveliness, blinkScale, BẢNG lịch chớp mắt (D3)
  _decor.dart           # ArcSeed/arcRender (arc ellipse 3D chia front/back), bảng RINGS/SWOOSH/COMET/PARTICLES (D3), notif consts, bánh xe màu wheel()
  _states.dart          # Pose, EyeCfg, StateDef + catalog 15 states, POSES (t đẹp nhất mỗi state), SEQUENCE
  _engine.dart          # BloubBotEngine: sample(t) thuần + setState/reset/setShape/setExpression/setLook
  _expressions.dart     # (B3) 16 expression nghỉ
  _skins.dart           # (B3) 8 hình + bảng màu customizer
  _painter.dart         # tầng Flutter: BotFrame → Canvas
  bloub_bot_demo.dart
  README.md
```

`kind: composite`, `paint_source: painter`, `portability: folder`, `deps: []`,
không asset, không `.frag` — thoả cả 7 luật cứng.

### Kiến trúc 2 tầng

- `_math/_shape/_face/_decor/_states/_engine`: **Dart thuần** (D2). Frame model:

```dart
class BotFrame {           // mọi toạ độ theo đơn vị viewBox (bán kính nghỉ = 100)
  final List<BotPoint> bodyPoints;   // 64 điểm silhouette đã pose
  final double bodyAlpha;
  final List<RenderedEye> eyes;      // hình học capsule + ma trận 2x3 + alpha
  final List<DotRender> dots; final bool dotsBehind;
  final List<ArcRender> arcs;        // polyline front/back + gradient spec
  final NotifRender? notif; final NotifRender? notch;
}
```

  (Khác bloub một chút: engine trả **điểm**, không trả chuỗi path SVG — painter
  mới dựng `Path`. Chuỗi `d` của bloub chỉ tồn tại vì SVG cần text.)

- `_painter.dart`: `CustomPainter` với transform
  `translate(size/2) → scale(size / (2·158))` (158 = `DEMI_VIEWBOX`, chừa chỗ
  cho rings vươn tới 1.4R; bán kính nghỉ RAYON = 100).

### Mapping SVG → Canvas (thứ tự vẽ giữ nguyên bloub)

| Lớp SVG của bloub | Flutter |
|---|---|
| nửa SAU của arcs (vẽ trước → bị thân che) | `drawPath(back, strokePaint..shader: ui.Gradient.linear(3 stops)..strokeCap: round)` |
| particles sau thân (`dotsBehind`) | `drawCircle` / `drawPath` (giọt lệ có path riêng) |
| **path lót màu `paper` đúng hình thân** | `drawPath(bodyPath, paperPaint)` — BẮT BUỘC, xem bẫy #4 |
| thân + mắt qua `<mask>` (thân trắng, mắt/notch đen, mắt có alpha) | `saveLayer(bounds)` → vẽ thân màu `ink` → vẽ mắt & notch bằng `BlendMode.dstOut` với alpha của mắt → `restore` |
| dots trước thân | `drawCircle`/`drawPath` |
| pastille xanh `#2496e8` | `drawCircle` |
| nửa TRƯỚC của arcs | như nửa sau |

`saveLayer + dstOut` là bản dịch chính xác của mask SVG: mắt alpha lửng (đang
fade) = lỗ thủng "một phần", thứ mà `Path.combine(difference)` không làm được.
`bodyAlpha` áp bằng alpha của chính `saveLayer`.

### Chia phase

**B1 — lõi + 7 state "thân là chính"** (`idle`, `thinking` (3 chấm pulse),
`wink`, `wide`, `sleep`, `egg`, `hexagon`): `_math`, `_shape`, `_profiles`,
`_face`, `_states` (7 states), `_engine` đầy đủ logic transition, `_painter`
với lỗ mắt, demo chips chọn state + nút play tuần tự. Chưa có arcs/notif.

**B2 — decor states** (`alert`, `exclaim` — thanh "!" từ
`hullOfCircles`/`profileFromPolygon` + giọt lệ; `notify` — pastille + notch;
`play`, `orbit` — 6 rings; `swirl`, `burst` — particles xoáy vào sau thân;
`comet` — 4 ruy băng): thêm `_decor.dart` + phần arcs của painter.

**B3 — customizer về mặt API** : `_expressions.dart` (16 expression),
`_skins.dart` (8 hình analytic + màu), `setShape`/`setExpression` morph mượt,
và **bảng eyefit** (xem bẫy #7). Demo thêm hàng chip expression/shape.

**B4 (tuỳ chọn, chưa cam kết):** gaze theo cử chỉ — map `setLook` vào pan/drag
(bloub tắt follow cho touch vì không có cursor lơ lửng); player cycles (Block
list, `blockAt`, `offsetOf`, reset-khi-tua-lùi).

### API widget đề xuất (entry, B1)

```dart
BloubBot(
  {double size = 160,
   BloubBotState state = BloubBotState.idle,  // enum 15 giá trị
   Color? ink,                 // mặc định gần đen; theme-aware qua param, không đọc theme ngầm
   Color? paper,               // màu nền phía sau — cần cho lỗ mắt + sương mù particles
   double? frozenAt,           // null = chạy sống; số = đứng im tại t đó (tất định)
   bool animate = true,        // tắt ticker từ ngoài (luật "expose cách dừng")
   VoidCallback? onTap})
// B3 thêm: expression, shapeRadii/shapeId. Engine + painter export sẵn cho ai muốn tự lái.
```

### Bẫy phải né (rút từ chính docs + code bloub — đây là phần đắt nhất của port)

1. **`sample(t)` không được mutate.** Không "dọn" `prev` khi fade xong — đọc
   lại một thời điểm quá khứ phải ra đúng ảnh cũ. Bloub từng dính đúng lỗi này
   ở shape morph và có test riêng. Port test đó.
2. **Đổi state giữa lúc đang fade → đóng băng pose composite** làm gốc blend
   mới (`departFige`), và **chỉ** trong trường hợp đó (đóng băng mọi lần đổi sẽ
   giết animation của state đang rời — dấu "!" đứng sựng giữa đường).
3. **Clamp tỉ lệ fade.** `easeOutQuint` với t âm (đọc thời điểm trước khi đổi
   state) văng silhouette đi xa 30 lần — luôn `clamp(since / morph)`.
4. **Lỗ mắt nhìn xuyên thân.** Rings nửa sau + particles vẽ *sau lưng* thân —
   không có path lót màu `paper` thì chúng hiện *bên trong mắt*. Lót bằng
   `paper`, không phải trắng tinh.
5. **Chớp mắt là ép dẹt DỌC theo trục màn hình**, áp SAU ma trận tiếp tuyến
   (chỉ nhân các đầu ra y: `b·k`, `d·k`), không phải co theo trục capsule.
   Mắt culled khi `depth ≤ 0.02`, alpha nhân `clamp(depth / 0.12)`.
6. **Mọi thứ "đậu" trên thân phải theo bán kính thật** (`radiusAtAngle`): mắt
   và pastille đều nhân prorata bán kính theo hướng của chúng, không thì hình
   không tròn sẽ cắt mất chúng.
7. **eyefit là BẢNG tra, không phải solver chạy mỗi frame.** Bloub viết 7 bản
   solver per-frame, cả 7 đều rung/giật; bản đúng giải MỘT LẦN lúc load, ra
   bảng (shape × state nghỉ × expression), engine chỉ nội suy **giữa hai đầu
   mút của morph** — không bao giờ tra bằng mảng radii đã nội suy. B1/B2 chưa
   cần (chưa có customizer shape → offset = 0); B3 vendor bảng precomputed
   (D3) thay vì port solver 455 dòng.
8. **Montage giữ hoặc cắt, không bao giờ scale thời gian** — nếu làm B4:
   không nhân thời gian cục bộ với hệ số tốc độ; sàn `MIN_BLOCK` *suy ra* từ
   morph dài nhất (0.6s của orbit), không hard-code.
9. **`reset()` ≠ `setState()`**: tua về đầu chuỗi phải xoá lịch sử (không
   fade từ state cuối), không thì frame đầu lộ "quả bóng không mắt" như bug
   export GIF bloub từng gặp.
10. **Ticker: clamp dt ≤ 0.064s** (app về foreground không nhảy vọt), đồng hồ
    là biến cộng dồn của widget — engine không bao giờ tự đọc giờ. Setter nào
    cũng nhận `now` từ ngoài (kể cả `setLook` — có guard chặn NaN, vì engine
    GIỮ target cuối: một NaN lọt vào là ở lại vĩnh viễn).
11. **Không làm tròn số đo** — copy nguyên văn `EYE_SPLIT = 15.46`,
    `REST_GAZE = (28.49, 28.62, −13)`, `NOTIF_ANGLE = −42`… kèm comment đơn vị.

### Test (chạy bằng `dart test` thuần nhờ D2)

- Purity: `sample(t)` gọi 2 lần cùng `t` → frame bằng nhau; gọi xen kẽ
  quá khứ/hiện tại không đổi kết quả (port từ `engine.test.ts`).
- Continuity: đổi state cách nhau 100ms, khoảng cách điểm giữa 2 frame liên
  tiếp có cận trên (bloub đo: spaced ≈ 8–14px, bug cũ 26–43px).
- Frozen board determinism: 15 state render tại `POSES[id]` ra cùng kết quả
  giữa 2 lần chạy.

### Nghiệm thu B1

Demo chạy 60fps trên Android thật với 7 state; validate + analyze + test sạch;
so mắt với `#planche` của bloub (chạy `pnpm dev` bên checkout bloub) cho 7
state — silhouette và mắt trùng khớp về đại thể (không cần pixel-perfect vì
khác renderer, nhưng nghiêng mắt `\\`, tỉ lệ, nhịp chớp phải đúng).

---

## 3. Hạng mục C — Quy ước "sample(t) thuần" cho component animation

**Ý tưởng:** nâng bài học kiến trúc lớn nhất của bloub thành quy ước authoring
của vault: *tách frame-model (hàm thuần của thời gian) khỏi painter*. Đổi lại
được: freeze/tua tất định, golden test không cần pump, thumbnail rẻ.

### C1. Thêm mục vào `docs/AUTHORING_PROMPT.md` (draft để duyệt)

> ## Component có animation — quy ước sample(t)
>
> Áp dụng khi component có chuyển động liên tục (không áp cho animation
> rời rạc kiểu implicit animation của Flutter):
>
> 1. **Tách model/painter.** Trạng thái một frame = hàm thuần của thời gian
>    trôi `t` (giây). Painter chỉ vẽ frame, không tự tính giờ.
> 2. **Không `Random()` không seed, không `DateTime.now()`** trong đường vẽ.
>    Ngẫu nhiên = PRNG seed cố định hoặc bảng sinh sẵn; "sống động" =
>    `loopNoise` (tổng 3 sin chu kỳ nguyên tố cùng nhau) — tất định nhưng
>    không lặp thấy được.
> 3. **Expose `double? frozenAt`** — null: chạy sống; có giá trị: render đúng
>    một frame tại t đó, không ticker. Đây là cái cho phép state board,
>    thumbnail và golden test.
> 4. **Ticker do widget sở hữu, dispose đúng, có cờ `animate`** để tắt từ
>    ngoài; dt clamp (~64ms) để app resume không nhảy vọt.
> 5. Trong `<id>_demo.dart`, nếu component có nhiều trạng thái/biến thể rõ
>    rệt: khai báo `variants` (xem C2) để viewer dựng state board.

### C2. Mở rộng `lib/core/component_demo.dart` (không phá API cũ)

```dart
/// Một biến thể/trạng thái đặt tên của demo — nguồn của state board (§D).
class DemoVariant {
  const DemoVariant({required this.id, required this.label,
      required this.builder, this.frozenBuilder});
  final String id;            // dùng trong deep link ?variant=
  final String label;
  final WidgetBuilder builder;
  /// Bản đứng im tất định (component theo quy ước C1 thì có; null → board
  /// dùng builder + TickerMode(enabled: false)).
  final WidgetBuilder? frozenBuilder;
}

class ComponentDemo {
  // ... các field cũ giữ nguyên ...
  final List<DemoVariant> variants;   // default: const []
}
```

`registry.dart`, `validate.dart`, index không đổi (field runtime, không vào
frontmatter). `bloub_bot` (15 variants = 15 state, frozen tại `POSES[id]`) và
`shape_morph` (mỗi hình một variant) là 2 reference implementation.

### C3. Retrofit (ghi nhận, KHÔNG nằm trong scope đợt này)

Ứng viên hưởng lợi về sau: `pixel_loader`, `particle_field`, `gradient_waves`,
`pixel_walker`, `aurora_stack`. Không sửa hàng loạt — chỉ áp quy ước khi có
việc đụng vào từng con.

---

## 4. Hạng mục D — Viewer: freeze, state board, deep link, share PNG

Bốn tính năng nhỏ: D1–D3 chung một PR, **D4 tách nhánh/PR riêng** (đã chốt);
mỗi PR bump **minor** (năng lực mới của viewer). Tương đương bloub:
`#planche` → state board; `#etat=orbit&stop` → deep link.

### D1. Nút freeze trong `PreviewStage`

- Thêm nút pause/play vào control bar của cả 3 stage (`_framedStage`,
  `_effectStage`, paint/carrier switcher).
- Cơ chế: bọc demo trong `TickerMode(enabled: !_frozen)` — đóng băng **mọi**
  component chạy bằng `AnimationController`/`Ticker`, không cần component hợp
  tác. Zero API mới.
- **Giới hạn biết trước:** component animate bằng `Timer`/`Stream`/vòng
  `Future` sẽ không đứng — quy ước C1 (dùng ticker) chính là để lỗ hổng này
  khép dần. Ghi chú vào code comment.

### D2. Variant chips + state board

- `PreviewStage`: nếu `demo.variants.isNotEmpty` → hàng chip chọn variant
  (thay `demo.builder` bằng `variants[i].builder`).
- Route mới `/component/:id/states` (mục "States" trong menu 3-chấm, chỉ hiện
  khi có variants): grid 2 cột, mỗi ô = `frozenBuilder ?? (TickerMode-off +
  builder)`, bọc `RepaintBoundary`, tap ô → quay về detail với variant đó.
  Đây là bản `#planche` của snipz — và là cách duyệt nhanh 15 state của
  `bloub_bot` không tốn 15 vòng animation.

### D3. Deep link vào trạng thái

- `/component/:id?variant=orbit&frozen=1` — `router.dart` đã có tiền lệ đọc
  `state.uri.queryParameters` (route code). `DetailScreen` truyền
  `initialVariant`/`initialFrozen` xuống `PreviewStage`.

### D4. Share PNG từ preview *(đã chốt: tách nhánh/PR riêng, không gộp D1–D3)*

- `RepaintBoundary(key)` bọc **riêng phần stage** (không dính control bar),
  menu 3-chấm thêm "Share image": `boundary.toImage(pixelRatio: 3)` → PNG
  bytes → ghi file tạm vào `Directory.systemTemp` → `SharePlus.instance.share(
  ShareParams(files: [XFile(path)]))`. Không thêm dependency (share_plus có
  sẵn; không cần path_provider vì systemTemp đủ cho file share).
- Bẫy: gọi `toImage` sau khi frame đã vẽ (`addPostFrameCallback`); bọc
  try/catch + SnackBar khi fail (một số thiết bị/emulator cũ kén).

### Việc kèm theo

- Cập nhật `docs/AUTHORING_PROMPT.md` (mục C1) cùng PR này.
- Ghi chú bổ sung spec §8.5/§6 trong `docs/snipz_prompt.md` nếu spec là nguồn
  chân lý đang được duy trì (xác nhận lại khi làm).

---

## 5. Hạng mục E — Export SVG & SVG động từ `bloub_bot`

**Trả lời câu hỏi "có tạo được SVG / animated SVG như repo không": CÓ, cả
hai** — và ranh giới khả thi của mình trùng khớp với ranh giới của chính bloub.

### Repo gốc thực sự export gì (đã đọc `ui/export.ts`, `ui/anime.ts`, `ui/capture.ts`)

| Format | Cơ chế | Phạm vi |
|---|---|---|
| PNG 1024 | rasterize SVG qua canvas | avatar nghỉ |
| **SVG tĩnh** | serialize thẳng DOM đang hiển thị (SVG vốn tự chứa: fill hex literal, không CSS var) + viewBox chặt `ceil(R·max_radius·1.08)` | avatar nghỉ |
| **SVG động** | thay `transform="matrix(…)"` của 2 mắt trong `<mask>` bằng class, nhúng `<style>` **CSS `@keyframes`**: 90 khoá (30 khoá/s × 3s) ma trận lấy từ `engine.sample`; `transform-box: view-box; transform-origin: 0 0` (bắt buộc, không thì mắt văng khỏi bóng); `animation-direction: alternate` → loop không mối nối (drift không tuần hoàn, chơi xuôi rồi ngược tự khớp; chớp mắt ngược vẫn là chớp mắt). Browser nội suy giữa các khoá → mượt theo tần số màn hình. | **CHỈ avatar nghỉ** — thân đứng im, chỉ mắt sống |
| GIF động | encoder LZW **tự viết** | tồn tại chỉ vì avatar Discord/Slack từ chối SVG |
| Cycle GIF/MP4 | rasterize từng frame | cycle — SVG động bị loại **có đo đạc**: thân morph mỗi frame, path ~2.5 KB → 600 frame ≈ 1.5 MB chưa tính arcs |

### Port sang snipz — vì sao gần như miễn phí

Engine của ta (D2) trả `BotFrame` = đúng dữ liệu mà template Vue của bloub đổ
ra SVG (điểm silhouette, capsule + ma trận mắt, arcs, gradient spec). Thêm một
file `_svg.dart` trong folder `bloub_bot`: **thuần build chuỗi, zero dep, chạy
được trong unit test** — template Vue + `svgAutonome` của bloub chính là spec
markup (mask thân trắng/mắt đen, path lót `paper`, rect `ink`, defs gradient,
arcs front/back). Làm tròn 2 chữ số (bản sao `r2`) cho nhẹ file.

```dart
/// SVG tĩnh của BẤT KỲ state nào, đóng băng tại t (rộng hơn repo gốc,
/// vốn chỉ export từ view Personnaliser). ~3–6 KB.
String bloubBotSvg({required BloubBotState state, required double t, ...});

/// SVG động của avatar nghỉ — đúng cơ chế + đúng giới hạn của repo.
/// ~15–20 KB (90 khoá × 2 mắt, mỗi khoá một ma trận text).
String bloubBotAnimatedSvg({int keysPerSec = 30, double seconds = 3, ...});
```

Nút share nằm trong `bloub_bot_demo.dart` (demo miễn luật, dùng share_plus có
sẵn: ghi `.svg` vào `Directory.systemTemp` rồi share). Không cần route viewer.

### Giới hạn phải nói trước (kế thừa nguyên xi từ repo)

1. **SVG động chỉ cho thân đứng im** (idle; thêm expression/shape khi B3 xong).
   State morph thân và cycle: không làm — lý do size như bảng trên, bloub đã đo.
2. **App snipz không render file `.svg`** (không có flutter_svg, không thêm) —
   file SVG là để dùng NGOÀI: browser, **GitHub README (CSS animation trong
   `<img>` có chạy)**, web. Figma/Illustrator nhận bản tĩnh; bản động vào đó
   sẽ đứng im.
3. **Mắt export ĐẶC màu `paper`**, không phải lỗ trong suốt — chủ đích của
   bloub ("don't fix this into transparency"): nền tối vẫn thấy mắt.
4. Khung export chặt hơn viewBox màn hình (không thì avatar teo trong crop
   tròn của ảnh đại diện) — port cả hằng `MARGE = 1.08`.

### Phase & test

- **E1 (ngay sau B1):** SVG tĩnh cho 7 state thân + SVG động idle-neutral.
- **E2 (tự khắc khi B2/B3 xong):** serializer đọc `BotFrame` nên arcs/notif tự
  vào khi B2 thêm chúng; SVG động thêm expression/shape khi B3 có.
- Test: markup tất định (2 lần chạy ra cùng chuỗi), đếm số khoá keyframes,
  smoke-parse XML.

---

## 6. Trình tự giao hàng (mỗi dòng = 1 commit/PR, version từ `1.1.7+15`)

| # | Nội dung | Version | Kiểm trước khi chốt |
|---|----------|---------|---------------------|
| 0 | Tài liệu kế hoạch này (`docs/`) | không bump (docs-only) | — |
| 1 | A — `shape_morph` | `1.1.8+16` | `dart tools/validate.dart`, `flutter analyze`, `flutter test` |
| 2 | B1 — `bloub_bot` lõi + 7 state | `1.1.9+17` | như trên + dart test engine |
| 3 | C + D1–D3 — quy ước + freeze/board/deep-link | `1.2.0+18` | như trên + thử deep link trên Android |
| 4 | D4 — share PNG (**nhánh/PR riêng**) | `1.3.0+19` | thử share trên Android thật |
| 5 | E1 — export SVG tĩnh + SVG động idle | `1.3.1+20` | mở `.svg` bằng browser, dán thử vào GitHub README |
| 6 | B2 — decor states (alert…comet) | `1.3.2+21` | so planche với bloub |
| 7 | B3 — expressions + skins + eyefit (E2 tự theo) | `1.3.3+22` | như trên |
| (8) | B4 — gaze cử chỉ / cycles player | tuỳ chọn, bàn sau | — |

Số version cụ thể sẽ trượt theo thứ tự merge thực tế — quy tắc là: component
mới/port = patch, năng lực viewer = minor, build number luôn +1 (CLAUDE.md).
Mỗi component đi qua `dart tools/new_component.dart` để scaffold + tự đăng ký
registry + regenerate `assets/`.

---

## 7. Rủi ro & quyết định

**Rủi ro kỹ thuật**

- `saveLayer` mỗi frame (lỗ mắt): một layer nhỏ, Impeller xử lý tốt, nhưng cần
  đo trên máy Android thật ở B1 trước khi xây tiếp B2. Phương án lùi: khi mọi
  mắt có alpha = 1 (ngoài lúc fade) dùng `Path.fillType = evenOdd` gộp lỗ vào
  path thân, chỉ saveLayer trong lúc fade.
- Độ giống orbit/comet phụ thuộc gradient dọc stroke: SVG gradient áp theo
  `userSpaceOnUse` trên cả stroke; `ui.Gradient.linear` tương đương đủ tốt,
  nhưng cần so mắt ở B2.
- Bảng vendor theo D3 gắn với một commit bloub — upstream đổi số đo thì bảng
  lệch; chấp nhận (vault vốn snapshot-based), đã ghi hash để regenerate.

**Đã chốt (Khang, 2026-08-21)**

1. Tên component: **`bloub_bot`**.
2. Phạm vi B1: **7 state thân trước, decor để B2** — như bảng phase.
3. D4 share PNG: **tách nhánh/PR riêng**, không gộp với C+D1–D3.

**Còn chờ chốt**

4. Hạng mục E (export SVG/SVG động, §5): đã xác nhận khả thi — gật thì chạy
   theo trình tự bảng §6; không thì bỏ hàng 5, các mục khác không xê dịch.
