# Pixel-art animation brief — PixelWalker + PullRevealRefresh

Handoff cho việc vẽ mascot hoặc chỉnh chuyển động của hệ pixel-art Snipz.
Phiên bản 1.3.0 giữ sáu nhân vật và hai cảnh, bổ sung nhịp đi riêng, pose
chuẩn bị/hoàn tất và preview xác định theo thời gian. Art và engine vẫn nằm
trong một file, không cần ảnh sprite sheet hoặc dependency ngoài Flutter.

## 1. Các file cần đọc

| File | Vai trò |
|---|---|
| `lib/components/pixel_walker/pixel_walker.dart` | Sprite dạng ký tự, `PixelGait`, pose sampler, đồng hồ, painter procedural. |
| `lib/components/pixel_walker/README.md` | API public, cách dùng, giới hạn, changelog. |
| `lib/components/pixel_walker/pixel_walker_demo.dart` | Playground sáu mascot, scene, motion và frozen preview. |
| `lib/components/pull_reveal_refresh/pull_reveal_refresh.dart` | Gesture, extent và state machine của header. |
| `lib/components/pull_reveal_refresh/pull_reveal_refresh_demo.dart` | Ghép scene với kéo/nhả/loading; giữ header cho động tác hoàn tất. |
| `lib/components/pull_reveal_refresh/README.md` | Contract của refresh và caveat về scroll physics. |
| `CLAUDE.md` | Luật version, session và bàn giao của repo. |

`assets/sources/*.json` là snapshot được sinh từ README và source. Không sửa
tay; chạy tool của repo sau khi sửa component.

## 2. Ranh giới giữa refresh và sprite

`PullRevealRefresh` quyết định header cao bao nhiêu và phát
`PullRevealStatus`. `PixelWalker` chỉ vẽ, không biết về networking hoặc scroll
notification. Bộ điều khiển nối hai tầng nằm trong demo hoặc app sử dụng:

| Giai đoạn | Đầu vào cho cảnh |
|---|---|
| Kéo chưa đủ ngưỡng | `progress` mở cảnh; `readiness` tăng ở đoạn cuối của hành trình kéo. |
| Đủ ngưỡng | `readiness = 1`: mascot chuyển sang pose chuẩn bị. |
| Đang tải | `walking = true`, `motion = 1`: bước và parallax hoạt động. |
| Tải xong | Demo giữ callback refresh thêm 360ms, giảm `motion`, tăng `celebration` khi header còn mở. |
| Thu header | `progress` giảm; `celebration = 1`, `motion = 0` giữ pose nghỉ sau động tác hoàn tất. |

Điệu bộ hoàn tất là choreography của **demo**, không phải mode mới trong
core refresh. `onRefresh` của ứng dụng khác chỉ giữ header trong thời gian
Future của nó chưa hoàn tất; muốn có đoạn chào hoàn tất thì ứng dụng tự
chờ animation tương tự demo.

Core giữ nguyên luồng
`idle → dragging → armed → refreshing → settling → idle`, ngưỡng mặc định
96px, settle 200ms và collapse 320ms. Demo dùng trigger 110px / max 190px.
`status.progress` clamp ở 1, nên kéo quá ngưỡng chỉ làm vùng header cao thêm.

Lực cản khi kéo là `delta * (0.25 + 0.75 * room)`, với
`room = clamp(1 - extent / maxExtent)`. Haptic phát khi chuyển sang armed.
Nội dung list được translate, không relayout theo từng frame. Nhánh chính là
`ClampingScrollPhysics`; nhánh `BouncingScrollPhysics` vẫn có caveat về nhịp
spring lúc nhả. Đợt sprite này không thay đổi vật lý, haptic hay xử lý Future
hoàn tất tức thì trong core.

## 3. Art và cá tính của sáu mascot

| Mascot | Cá tính chuyển động |
|---|---|
| Clawd | Nhịp nhanh, thân nhún gọn, nhiều chân đảo liên tiếp. |
| Miu | Nhịp nhẹ, đuôi có các vị trí riêng trong chu kỳ, thân hơi nén/nghiêng khi chuẩn bị. |
| Capy | Nhịp chậm, thân nặng, độ nghiêng nhỏ; giữ nét mặt bình thản. |
| Quạc | Lạch bạch, nghiêng ngang rõ hơn, cánh và đuôi tạo điểm nhấn. |
| Cáu | Dịch ngang, thân ít nhấc; càng đổi tư thế thay vì nhún như vịt. |
| Axo | Nhún thấp, mang và đuôi thay đổi qua chu kỳ; chuyển động mềm. |

Sprite tiếp tục đổi frame theo nhịp rời rạc để giữ nét pixel. Độ nghiêng,
nhún và dịch ngang của toàn thân lấy từ hàm liên tục theo thời gian, không
còn phụ thuộc điều kiện frame lẻ. `PixelGait` xác định bộ chuyển động;
factory có sẵn chọn gait phù hợp cho từng nhân vật.

### Hợp đồng dữ liệu sprite

- `frames` là list các frame; mỗi frame là list dòng string.
- Các dòng phải có cùng chiều dài; mọi frame cùng kích thước.
- Ký tự tra màu trong `palette`; ký tự không có màu, thường là `.`, trong suốt.
- Frame 0 là pose nghỉ. Giữ silhouette và vị trí bàn chân ổn định giữa các
  frame; animator phụ trách chuyển động tổng thể của thân.
- Custom sprite vẫn dùng được với `PixelSprite(frames: ..., palette: ...)`.
  Có thể chọn `gait`; widget/sampler nhận tiến độ pose phản ứng, không cần sửa painter.
- Màu custom nên truyền qua factory/palette. Không thêm asset chỉ để đổi màu.

`PixelSprite.samplePose(t, walking: ..., motion: ..., readiness: ...,
celebration: ...)` là điểm kiểm tra một pose xác định. Dùng cùng thời điểm và
đầu vào để so sánh art trước/sau mà không phụ thuộc tốc độ máy.

Mỗi mascot có sẵn có 7 frame riêng (1 nghỉ + 6 bước), 4–5 màu. Một chu kỳ có
hai bước; nhịp Clawd/Miu/Capy/Quạc/Cáu/Axo lần lượt là
2.15/1.45/0.85/1.60/1.90/1.05 vòng mỗi giây ở tốc độ 1. `celebration` lấy
tiến độ một lần nhún/nhảy và kéo dài thân; hai đầu 0 và 1 đều trung tính.

## 4. Đồng hồ và khả năng tái lập

- `walking: false` là cảnh tĩnh, không có ticker hoạt động. Thay đổi các đầu
  vào phản ứng vẫn cập nhật pose qua lần build của parent.
- `frozenAt` lấy một frame tại số giây được chỉ định nhân `speed × motion`;
  không chạy ticker, không áp dụng đoạn tăng tốc đầu.
- `TickerMode` và cài đặt giảm chuyển động của hệ thống cần được tôn trọng.
  Đồng hồ tạm dừng không bù thời gian đã trôi khi hoạt động lại.
- Đổi `speed` không nhân lại toàn bộ thời gian đã chạy; vị trí nền tiếp tục
  từ điểm hiện tại, tốc độ mới áp dụng cho phần thời gian tiếp theo.
- Clock live tích lũy `delta × speed × motion × ramp`, với ramp tăng mượt
  từ 0→1 trong 180ms đầu; sampler nhận thời gian pha
  đã nhân tốc độ và chỉ dùng `motion` để điều chỉnh biên độ. `speed: 0` hoặc
  `motion: 0` dừng ticker. Bắt đầu đi tăng biên độ trong 180ms; giảm `motion`
  từ parent trước khi tắt `walking` để dừng êm.
- Repaint dùng tín hiệu của painter; không cần rebuild toàn widget mỗi tick.
- `seed` quyết định bố cục procedural. Không dùng `Random()` trong `paint()`.

Playground có picker sáu mascot và công tắc **Xem từng nhịp** để chuyển sang
slider thời gian dùng `frozenAt`; mascot, scene và tốc độ đang chọn được giữ
nguyên. Đây là điều khiển trong demo, không phải scrubber/state board chung
của viewer. Thumbnail phải tĩnh.

## 5. Reveal, pixel grid và cảnh thấp

`progress` điều khiển hai thứ: mascot trồi lên **tuyến tính**, còn alpha và
mật độ dither dùng `easeOutCubic`. Ở pose nghỉ, chân mascot chạm đường đất
đúng `progress = 1`; giữ quan hệ này khi chỉnh reveal.

Ô nền là `3 * scale`, ô mascot gấp đôi ô nền. Painter vẽ các điểm vuông với
buffer tái dùng; pose sampling và các view buffer vẫn có thể tạo object nhỏ.
Không coi đây là cam kết không cấp phát hoặc FPS đã đo trên thiết bị.

| Layer | Tốc độ tương đối | Ghi chú |
|---|---|---|
| Sao/trăng | 0 | Neo vào vùng trời đang hiển thị. |
| Núi | 2.2 | Lớp xa của `nightCity`. |
| Mây | 3.0 | Lặp qua cả hai mép viewport. |
| Tòa nhà | 9.0 | Lớp gần, cửa sổ sáng trong cảnh đêm. |

Tất cả tốc độ chịu tác động của `speed` và lượng chuyển động. Thứ tự cảnh
đêm: sao → trăng → núi → mây → tòa nhà → mascot. Cảnh ngày: skyline → mây →
mascot. Header thấp phải giữ được bầu trời thay vì dùng cố định tọa độ dành
cho preview lớn. Kiểm tra cả chiều cao 110px của refresh lẫn khung 160px
trong playground; mây cần nối vòng liên tục ở viewport rộng.

## 6. Kiểm tra khi chỉnh tiếp

- Xem từng mascot ở nghỉ, chuẩn bị, bước và hoàn tất; so sánh cả `city` và
  `nightCity`, đặc biệt ở khung 110px.
- Scrub qua ranh giới một vòng bước để phát hiện nhảy pose; kiểm tra pause,
  resume và đổi tốc độ mà nền không nhảy vị trí.
- Kiểm tra custom sprite cũ vẫn hoạt động và `walking: false` không phát tick.
- Kiểm tra thu header không che hết động tác hoàn tất; không biến callback
  refresh thành timer của core nếu chỉ cần choreography cho một demo.
- Validate cấu trúc dữ liệu frame/palette, chạy test liên quan và ghi đúng kết
  quả thực tế; kiểm tra FPS riêng trên thiết bị trước khi công bố hiệu năng.
- Bump component/app version, cập nhật `SESSION.yaml`, regenerate index và
  source bundle theo luật repo. Giữ creation snapshot và Test History.
