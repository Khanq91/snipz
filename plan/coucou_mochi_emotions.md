Thêm **5 biểu cảm mới vào Coucou Mochi của Snipz**, giữ phong cách hình học và chuyển động hiện tại. Đây là phần mở rộng trên engine đã port, không phải các biểu cảm đã có đầy đủ trong Coucou gốc. 

| Ưu tiên | Biểu cảm / ID dự kiến | Mắt và dáng người | Timeline đề xuất | Particle / âm thanh | Tiêu chí hoàn thành |
|---|---|---|---|---|---|
| **P1** | **Side-eye — `suspicious`** | Liếc ngang; một mắt hẹp hơn; đầu nghiêng nhẹ. Giữ nét nghi ngờ, không thành tức giận | **2,4 giây:** 0–0,25s chuyển mắt; 0,25–0,45s nghiêng đầu; giữ đến 1,9s; 0,5s cuối trở về | Không particle; mặc định im lặng | Hai mắt vẫn nằm trong mặt; nhìn rõ ở kích thước thumbnail; không đổi màu thân sang trạng thái error |
| **P1** | **Ngơ ngác — `confused`** | Hai mắt mở không đều; nghiêng đầu qua một bên rồi chỉnh nhẹ về giữa; chớp mắt hai lần | **2,8 giây:** 0–0,3s phản ứng; 0,3–0,9s nghiêng; 0,9–1,5s chớp đôi; giữ đến 2,3s; trở về trong 0,5s | Một dấu `?` bật lên rồi tan; tùy chọn phát cue `question` một lần | Dấu hỏi không đè badge trạng thái; không giống nguyên xi state `question`; không nháy toàn bộ mặt khi đổi mắt |
| **P2** | **Chill — `chill`** | Mắt khép hờ; thở chậm; thân đung đưa nhẹ, không gục xuống | **6 giây mặc định:** vào trong 0,6s; nhịp thở khoảng 3,2s; thoát trong 0,6s. Có chế độ lặp | Không particle; mặc định im lặng | Phân biệt rõ với sleeping và yawn; không phát `Z`; vòng lặp nối mượt |
| **P2** | **Nghe nhạc — `music`** | Mắt vui hoặc khép nhẹ; nhún người và lắc đầu luân phiên; squash/stretch nhỏ | **4 giây mặc định:** vào trong 0,35s; nhịp mặc định 100 BPM; thoát trong 0,4s. Có chế độ lặp | Nốt nhạc nổi luân phiên, tối đa 4 nốt cùng lúc; không tự phát nhạc nền | Nhịp ổn định khi FPS thay đổi; particle có giới hạn; tạm dừng rồi tiếp tục không nhảy nhịp |
| **P3** | **Ngại ngùng — `shy`** | Má hồng tăng dần; nhìn tránh sang bên và hơi xuống; thân co nhẹ rồi thả lỏng | **3 giây:** 0–0,45s đỏ mặt; 0,45–0,8s né ánh nhìn; giữ đến 2,4s; trở về trong 0,6s | Không particle mặc định; không âm thanh | Khác love: không mắt trái tim, không tim bay; blush xuất hiện và biến mất liên tục |

**Quy tắc chung cần chốt trước khi triển khai:**

| Hạng mục | Quyết định dự kiến |
|---|---|
| Phân loại | Cả 5 là **emote**, không thêm business state mới |
| API hiện có | Giữ tương thích các lệnh đang dùng. Bổ sung 5 giá trị vào `CoucouMochiEmote` |
| Điều khiển lặp | Bổ sung tùy chọn lặp và lệnh dừng emote; chỉ bật lặp khi caller yêu cầu. `music` và `chill` vẫn chạy hữu hạn mặc định |
| Chuyển tiếp | Bắt đầu từ pose đang hiển thị; khi dừng, chuyển về pose của **state hiện tại**, không ép về idle |
| Xung đột | Dizzy, gulp và greeting có ưu tiên cao hơn. Emote mới thay emote cũ; đổi state hoặc tương tác trực tiếp kết thúc emote đang lặp |
| Gaze và blink | Side-eye/confused/shy giữ quyền điều khiển gaze trong đoạn diễn; blink tự nhiên không che mất chớp mắt có chủ đích |
| Badge | Giữ badge trạng thái. Dấu hỏi của confused là hiệu ứng riêng, bố trí tránh badge |
| Màu sắc | Giữ màu thân theo state; chỉ thay blush khi biểu cảm yêu cầu |
| Âm thanh | Tôn trọng mute/volume; cue chỉ phát khi bắt đầu, không phát lại mỗi vòng. Không thêm WAV mới trong phạm vi này |
| Nghe nhạc | BPM là tham số animation; **chưa** phân tích âm thanh hay đồng bộ với trình phát nhạc |
| Tạm dừng | Dùng chung animation clock; `TickerMode`, frozen preview và resume phải giữ hành vi hiện tại |
| Tính ổn định | Cùng seed và thời điểm phải cho cùng frame; số particle và dữ liệu lưu trữ không tăng vô hạn |

**Bảng công việc triển khai:**

| Bước | File/phạm vi chính | Việc cần làm | Điều kiện qua bước |
|---|---|---|---|
| **1. Kiểm tra nền** | README, engine, widget, test hiện có | Đọc lại API và thay đổi mới nhất; chạy baseline; kiểm tra quy định repo | Biết trạng thái hiện tại, không ghi đè thay đổi từ session khác |
| **2. Cơ chế emote** | `coucou_mochi.dart`, `_engine.dart` | Thêm enum, thời lượng mặc định, điều khiển lặp/dừng, quy tắc ưu tiên và chuyển tiếp | API cũ hoạt động; không có emote lặp bị kẹt |
| **3. Side-eye + confused** | `_engine.dart`, `_painter.dart` | Thêm hình mắt, gaze, tilt, chớp đôi và dấu hỏi | Đạt tiêu chí P1 trước khi làm tiếp |
| **4. Chill + shy** | `_engine.dart`, `_painter.dart` | Thêm nhịp thở, đung đưa, blush và né ánh nhìn | Không xung đột sleeping/yawn/love |
| **5. Music** | `_engine.dart`, `_painter.dart` | Thêm chuyển động theo BPM và particle nốt nhạc | Lặp mượt, giới hạn particle, không tích lũy sai số nhịp |
| **6. Demo** | `coucou_mochi_demo.dart` | Thêm 5 nút và 5 preview; điều khiển lặp/dừng; BPM chỉ hiện khi chọn music | Dùng được trên màn hình hẹp; dễ so sánh các biểu cảm |
| **7. Kiểm thử** | `test/coucou_mochi_test.dart` | Kiểm tra keyframe, kết thúc/vòng lặp, ngắt ngang, pause/resume, mute và render | Test cũ và mới đều đạt |
| **8. Hoàn tất** | README, version, SESSION, assets sinh tự động | Ghi API/caveat, tăng version theo quy định, cập nhật session và sinh lại catalog | Analyze, validate, toàn bộ test và build APK đạt |

**Kiểm tra nghiệm thu bắt buộc:**

- Xem từng biểu cảm ở kích thước nhỏ, bình thường và mini.
- Thử ngắt giữa chừng bằng emote khác, đổi state, tap gây dizzy và gulp.
- Chạy music/chill lặp ít nhất 60 giây; kiểm tra particle và thời gian xử lý không tăng dần.
- Kiểm tra frozen preview và scrub ngược cho kết quả ổn định.
- Không làm thay đổi 25 frame tham chiếu launch/upload và các hành vi Coucou đã sửa.
- Chưa đánh dấu đã kiểm chứng trên thiết bị nếu mới chạy test/build.

## Kết quả triển khai — 2026-10-02

- Đã thêm `suspicious`, `confused`, `chill`, `music`, `shy` vào enum, giữ nguyên thứ tự các giá trị cũ và các lời gọi API cũ. Không thêm business state.
- Đã thêm `emote(..., loop: false, bpm: 100, questionCue: false)`, `stopEmote()`, cùng `initialEmote`/`emoteLoop`/`musicBpm` cho preview và mini. Chỉ chill/music nhận loop; BPM giới hạn 40–240. Thời lượng mặc định theo bảng trên.
- Chuyển tiếp giữ pose, màu và badge của state; có test thay emote, đổi state, greeting, gulp, dizzy, hover/gaze, pause/resume và scrub ngược. Dấu hỏi/nốt nhạc nằm phía trên bên phải, đối diện badge bên trái.
- Demo có 5 chip và 5 variant live/frozen; loop/stop; BPM chỉ hiện cho music; controls cuộn trên màn hình thấp. Scrubber 30 giây chia thành 5 đoạn, mỗi đoạn 6 giây.
- Đã xem atlas ở 220 px, 80 px, mini màu xanh và có badge: `build/mochi_emotions_review.png`. Đây là render bằng Flutter test, không phải ảnh chụp thiết bị.
- Music/chill được sample 60 giây ở 60 FPS cho cả thường/mini, không quá 4 nốt; so sánh thêm chi phí sample ở thời điểm một giờ sau. Không tích lũy burst theo vòng lặp; cache blink giới hạn 32 lịch gần nhất, scrub lịch sử tái dựng đúng seed.
- **Kiểm tra đạt:** `flutter analyze --no-pub` (0 issue); `flutter test --no-pub` (**153 test**); `dart tools/validate.dart` (**104 component, 0 warning**); `git diff --check`.
- Giữ nguyên test cũ và fixture 25 frame launch/upload; không sửa WAV hay `pubspec.lock`. Reference `D:\khang\project\coucou` không bị sửa.
- README component **1.1.0**; app **1.5.3+42**; SESSION giữ cùng batch nghiên cứu theo quy định; đã sinh lại index/source bundle.
- **Build đạt:** `flutter build apk --debug --no-pub`. APK: `build/app/outputs/flutter-apk/app-debug.apk`; kiểm tra bằng `aapt` xác nhận `com.snipz.snipz`, versionName `1.5.3`, versionCode `42`. Log: `build/mochi_android_build.log`; toàn bộ test: `build/mochi_full_test.log`.
- Chưa kiểm chứng thao tác, hiệu năng GPU hay âm thanh trên Android thật; không đổi `latest_known_good`, `last_verified` hoặc các trường xác nhận thiết bị. Không thêm WAV, nhạc nền, phân tích audio hay tích hợp player. Chưa commit/push.
