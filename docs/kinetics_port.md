# KINETICS → FLUTTER — prompt port

> Dùng **kèm** `AUTHORING_PROMPT.md`. File này KHÔNG ghi đè luật nào của file đó —
> kinetics không có shader, nên mọi luật gốc (zero asset, một entry file, không
> `FragmentProgram`) áp dụng nguyên vẹn. File này chỉ bổ sung cách đọc source
> và cách map cơ chế web → Flutter.
> Tôi chỉ điền tên effect ở cuối. Mọi thứ khác đã cố định ở đây.

---

## Bước 0 — ĐỌC SOURCE THẬT, KHÔNG ĐOÁN TỪ SNIPPET

Repo kinetics đã clone ở máy:

```
D:\khang\data\flutterDev\project\clone_ui\kinetics
```

Đây là site tĩnh Astro chứa **153 effect** chia 3 section × 51:
`Interaction & Input` · `Feedback & State` · `Surface & Motion`.

Một effect KHÔNG nằm trong một file. Nó rải ở **3 mảnh**, nối nhau bằng class
`demo-*`. Quy trình tìm đủ 3 mảnh:

1. Grep tên effect (chuỗi trong `.name`) trong `src/content/body.html`
   → được block `.card` của nó. Ghi lại class `demo-*` trên stage
   (ví dụ `demo-magnet-zone`) và readout `.card-param` (ví dụ `spring(320, 24)`).
2. Grep class `demo-*` đó trong `public/css/effects-a.css` / `effects-b.css` /
   `effects-c.css` → style + `@keyframes` thật của demo.
3. Grep cùng class trong `public/js/main.js` → hành vi (toggle class, rAF loop,
   đọc pointer). Nhiều effect thuần CSS sẽ không có gì trong main.js — bình thường.

**Cạm bẫy chính của repo này:** mỗi card có 3 tab code (`CSS` / `React` /
`Prompt`) nhưng đó là bản **rút gọn để người xem copy**, thường thiếu chi tiết
so với demo sống. Nguồn sự thật là bộ ba `body.html` + `effects-*.css` +
`main.js`. Tab **Prompt** (mô tả bằng lời) thì hữu ích — đọc nó như spec đối
chiếu: port xong, so lại từng câu xem có khớp không.

`public/js/physics-demo.js` chỉ là oscilloscope của header trang, không thuộc
effect nào — bỏ qua.

Nếu không tìm thấy effect theo tên, **dừng lại hỏi tôi**, đừng dựng từ trí nhớ.

Đọc xong, báo cho tôi effect thuộc cơ chế nào (bước 1) trước khi code.

## Bước 1 — Phân loại theo cơ chế, quyết định đường đi

Kinetics không dùng thư viện animation nào — phân loại theo **cơ chế**, không
theo import:

| Cơ chế gốc | Dấu hiệu trong source | Đường Flutter |
|---|---|---|
| **CSS transition + bezier giả spring** | `transition: ... cubic-bezier(...)`, JS chỉ toggle class | Implicit animation (`AnimatedContainer`, `TweenAnimationBuilder`) với `Curve` map từ bezier. Dễ và sát nhất |
| **CSS `@keyframes`** | `@keyframes` trong effects-*.css, thường loop | `AnimationController` + `TweenSequence` (map % keyframe → weight), hoặc `CustomPainter` nếu vẽ hình |
| **JS rAF loop** | `requestAnimationFrame` trong main.js, tự tính vật lý | `AnimationController` + `SpringSimulation`, hoặc Ticker theo quy ước sample(t) của `AUTHORING_PROMPT.md` |
| **Hover/cursor-driven** | `mousemove`, `mouseleave`, `:hover` là lõi effect (magnetic, cursor-follow) | **Báo tôi trước.** Android không có hover — đề xuất map sang touch/drag hoặc bỏ, chờ tôi chọn |

Một effect có thể lai (transition + chút JS) — chọn đường theo phần lõi chuyển
động. Ưu tiên implicit animation khi được: ít code nhất, không phải quản
controller.

## Map số liệu vật lý — phần "toán" của kinetics

Cái đẹp của kinetics nằm trong **con số**: duration, bezier, spring constant,
offset. Port là giữ đúng số, dựng lại phần khung.

- `cubic-bezier(a, b, c, d)` → `Cubic(a, b, c, d)` — Flutter cho phép overshoot
  (y ngoài 0..1), copy nguyên 4 số. Bezier hay gặp
  `cubic-bezier(0.34, 1.56, 0.64, 1)` ≈ `Curves.easeOutBack`, nhưng cứ dùng
  `Cubic` với số gốc cho trung thực.
- Readout `spring(k, c)` trên card → `SpringDescription(mass: 1, stiffness: k,
  damping: c)` chạy qua `SpringSimulation`. Lưu ý: readout đôi khi chỉ là
  "trang trí" — nếu demo thật chạy bằng cubic-bezier thì port theo bezier,
  ghi readout vào README như tham khảo.
- `@keyframes` với mốc % → `TweenSequence` với `weight` tỉ lệ theo khoảng %.
- `transition-delay` / `animation-delay` xen kẽ nhiều phần tử →
  `Interval(...)` trên cùng một controller, đừng tạo nhiều controller.
- Duration CSS (`0.5s`) → `Duration(milliseconds: 500)` — đừng "làm tròn đẹp".

## KHÔNG có chế độ shader

Toàn bộ mục shader của `reactbits_port.md` không áp dụng ở đây. Mọi port từ
kinetics là `portability: single_file`, zero asset, không đụng `pubspec.yaml`.
Nếu bạn thấy mình muốn viết `.frag` cho một effect kinetics thì đã phân loại
sai — quay lại bước 1.

## Bỏ gì của bản web, giữ gì

**Bỏ:** `:hover`/`:focus-visible` như trạng thái riêng, cursor-follow (trừ khi
tôi duyệt map sang touch ở bước 1), `prefers-reduced-motion`, media query,
scroll-linked, mọi thứ DOM.
**Giữ:** số liệu vật lý (mục trên) và **cấu trúc trạng thái** — effect kinetics
là micro-interaction, cái hồn nằm ở chuỗi trạng thái (idle → press → settle),
giữ đúng chuỗi đó.
**Thay:** hover → press/tap (`GestureDetector`/`Listener`, down = enter,
up/cancel = leave); `:active` → `onTapDown`/`onTapUp`; resize →
`LayoutBuilder`; animation loop vô hạn → có cờ `animate` tắt được từ ngoài
(luật có sẵn trong `AUTHORING_PROMPT.md`).

## Kind — effect của kinetics thường LÀ button/card

Khác react-bits (đa số là paint nền), effect kinetics đa số là
micro-interaction gắn vào một phần tử cụ thể: nút, card, toggle, badge. Nên:

- `kind` thường là `effect` hoặc `composite`, hiếm khi `paint`.
- Effect vốn là button thì component **được phép** là button — đó chính là
  component, không phải "biến thể tự chế". Luật cấm biến thể vẫn giữ ở chiều
  ngược lại: **không** tự nhân ra `XxxCard`/`XxxText`/`XxxBorder` từ một
  effect vốn chỉ là button.
- Phần tử demo bên trong (label, icon) nhận qua param (`child`, `label`) với
  default giống demo gốc — đừng hardcode chữ của kinetics.

## Attribution — quy ước cố định cho repo này

Repo kinetics (`github.com/ckissi/kinetics`) **không có file LICENSE** — mặc
định all-rights-reserved, không được phép dịch code từng dòng. Vì vậy mọi port
từ kinetics đi theo **một đường duy nhất**:

| Trường | Giá trị |
|---|---|
| `origin` | `reimplemented` |
| `source` | `https://github.com/ckissi/kinetics` + tên effect + section |
| `license` | của tôi (MIT) |

Điều kiện để `reimplemented` là trung thực: chỉ lấy **thông số và hành vi quan
sát được** (duration, bezier, spring params, chuỗi trạng thái, mô tả trong tab
Prompt) rồi dựng lại bằng Flutter idiom. **Không dịch cấu trúc code CSS/JS
từng dòng sang Dart.** Với CSS vài dòng thì ranh giới này rộng; nhưng nếu gặp
effect mà không copy nguyên logic JS thì không dựng nổi (rAF loop phức tạp),
**dừng lại báo tôi** thay vì lặng lẽ chép — vì `adapted` không có license là
ngõ cụt với repo này.

## Output

Đúng 3 file theo `AUTHORING_PROMPT.md` (`<id>.dart`, `<id>_demo.dart`,
`README.md`). Không file nào khác.

README phải có thêm mục **Port notes**: effect gốc tên gì, section nào, cơ chế
gốc là gì (bước 1), số liệu nào giữ nguyên, hover/cursor đã map sang gì, và
sai lệch nào so với bản gốc kèm lý do.

## Tự kiểm

1. Đã đọc đủ 3 mảnh (`body.html` + `effects-*.css` + `main.js`) chưa, hay chỉ
   đọc tab code rút gọn?
2. Số liệu (duration, bezier, spring) có đúng số gốc không, hay đã "làm tròn"?
3. Effect có phần hover/cursor không — nếu có, đã hỏi tôi ở bước 1 chưa?
4. Có lỡ dịch từng dòng CSS/JS thay vì dựng lại không? (`origin` phải đứng
   vững là `reimplemented`.)
5. Port xong có khớp từng câu với tab Prompt của card không? Lệch chỗ nào đã
   ghi vào Port notes chưa?
6. Loop vô hạn đã có cờ tắt chưa? Controller dispose đúng chưa?

---

## EFFECT CẦN PORT

<điền tên + section, ví dụ: `Magnetic Button` (Interaction & Input)>

`id`: <snake_case>
`kind`: <paint | carrier | effect | composite>
