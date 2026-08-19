# REACT BITS → FLUTTER — prompt port

> Dùng **kèm** `AUTHORING_PROMPT.md`. File này bổ sung và **ghi đè luật 4 + mục B** của file đó khi component gốc là shader.
> Tôi chỉ điền tên component ở cuối. Mọi thứ khác đã cố định ở đây.

---

## Bước 0 — ĐỌC SOURCE THẬT, KHÔNG ĐOÁN TỪ TRANG WEB
❎: Đường dẫn không dùng ở đây | ✅: Đường dẫn đúng ở máy hiện tại
Repo react-bits đã clone ở máy. Đường dẫn source: 
[✅] D:\khang\data\flutterDev\project\react-bits
[❎] D:\project\react-bits
```
src/ts-tailwind/<Category>/<ComponentName>/
```

Category là một trong: `Animations/`, `Backgrounds/`, `Components/`, `TextAnimations/`.

**Bắt buộc đọc file thật trước khi viết dòng Flutter nào.** Trang `reactbits.dev` chỉ có ảnh render và một câu mô tả — dựng từ đó là đoán, và sẽ ra thứ hao hao chứ không giống. Nếu không tìm thấy folder, **dừng lại hỏi tôi**, đừng dựng từ trí nhớ.

Đọc xong, báo cho tôi biết component gốc thuộc loại nào (bước 1) trước khi code.

## Bước 1 — Phân loại nguồn, quyết định đường đi

| Nguồn dùng | Dấu hiệu trong code | Đường Flutter |
|---|---|---|
| **OGL / GLSL** | `import { Renderer, Program } from 'ogl'`, có chuỗi `fragment` GLSL | **Chế độ shader** (bên dưới) — port GLSL sang `.frag` |
| **Canvas 2D** | `getContext('2d')`, vòng lặp vẽ particle | `CustomPainter` + `AnimationController`. Zero asset, kiểm soát perf tốt hơn |
| **motion / framer-motion / GSAP** | `motion.div`, `useAnimate`, `gsap.to` | Widget + `AnimationController`/`TweenSequence` thuần Flutter. Dễ và sát bản gốc nhất |
| **three.js** | `import * as THREE` | **Báo tôi trước.** Thường không đáng port; nếu có bản shader tương đương thì đề xuất |

Ưu tiên: nếu component đạt được bằng widget/CustomPainter thuần thì **đừng** dùng shader — asset là chi phí thật khi mang sang project khác.

## Chế độ shader — chỉ khi nguồn là GLSL

Khi và chỉ khi bước 1 rơi vào OGL/GLSL, các luật sau **ghi đè** `AUTHORING_PROMPT.md`:

- Được phép tạo file `.frag` trong folder component
- `portability: folder_with_assets`
- `shaders_required: [<id>.frag]` — khai báo ở pubspec key **`shaders:`**, KHÔNG phải `assets:`. Ghi rõ điều này trong README, vì nhét nhầm vào `assets:` thì `FragmentProgram.fromAsset` fail im lặng
- README mục Reuse phải nói: mang sang project khác cần copy `.frag` **và** thêm dòng pubspec

### Checklist port GLSL — mấy chỗ Shadertoy/OGL không chạy trên Flutter

1. Đầu file: `#version 460 core` + `#include <flutter/runtime_effect.glsl>`
2. Dùng `FlutterFragCoord()`, **không** dùng `gl_FragCoord` trực tiếp
3. Output: khai `out vec4 fragColor` (không phải `gl_FragColor`)
4. Uniform **chỉ được** `float` / `vec2` / `vec3` / `vec4` / `mat4` / `sampler2D`. Không `bool`, không `int`, không array, không struct → gộp cờ vào float, gộp param vào vec
5. **Không có `iTime`/`iResolution` tự động** — tự khai `uniform float uTime; uniform vec2 uResolution;` và truyền từ Dart mỗi frame
6. Vòng lặp nên có **bound hằng số**. Raymarch loop viết `for (int i = 0; i < STEPS; i++)` với `STEPS` là `#define`, không phải uniform
7. Không dùng hàm phụ thuộc extension (`textureLod` với bias, derivative nâng cao). Nếu gốc có, tìm cách thay
8. Mobile mặc định precision thấp hơn desktop → gradient mượt dễ bị **banding**. Nếu thấy, thêm dither noise nhẹ vào output
9. Bỏ mọi tương tác chuột (`uMouse` theo hover). Android không có hover — hoặc bỏ hẳn, hoặc map sang touch nếu tôi yêu cầu rõ

### Ngân sách perf mobile — bắt buộc

- **Cap số bước raymarch.** Web chạy 100 bước thoải mái; Android tầm trung thì không. Bắt đầu ~32–48, expose thành `#define` để tôi chỉnh
- Cân nhắc render ở **độ phân giải thấp rồi upscale** nếu shader nặng. Nếu làm, expose param
- Không cấp phát object mỗi frame trong `paint()`
- Đo và ghi cost thật vào README mục **Caveats** (ví dụ: "~8ms/frame trên Snapdragon tầm trung ở fullscreen"). Không đoán con số — nếu chưa đo được thì ghi "chưa đo"

## Bỏ gì của bản web, giữ gì

**Bỏ:** hover/mouse-follow, scroll-linked animation, `window.resize` listener, SSR guard, `IntersectionObserver`, mọi thứ liên quan DOM.
**Giữ:** phần toán. Đó là thứ tạo ra cái đẹp, phần còn lại là hạ tầng web.
**Thay:** resize → `LayoutBuilder`; intersection → param `paused` để app tự tắt khi ngoài viewport (§9.2 của spec chính).

## Carrier — ĐỪNG tự viết biến thể

Nếu paint expose được factory trả `ui.Shader` (kể cả `FragmentShader`, nó cũng là `ui.Shader`) thì card/button/text/border **tự động có** qua `ShaderMask` ở tầng app. 

→ **Không viết sẵn `XxxButton`, `XxxCard`, `XxxText`.** Viết là nhân 4 lượng code, phá luật một-entry-file, và trùng với thứ đã có sẵn trong app.
→ Nếu không expose được `Shader` (particle động, nhiều layer chồng), ghi lý do vào README mục Caveats.

## Attribution — đọc kỹ, dễ ghi sai

| Bạn đã làm gì | `origin` | `source` | `license` |
|---|---|---|---|
| Port GLSL gần như từng dòng, giữ nguyên thuật toán | `adapted` | **bắt buộc** — link file cụ thể trong repo | **license của react-bits**, copy đúng từ file `LICENSE` trong repo. Đừng đoán, đừng ghi "MIT" nếu chưa mở file kiểm |
| Chỉ xem output rồi tự viết lại bằng cách khác | `reimplemented` | link tham khảo | của tôi |

Port shader gần như luôn rơi vào `adapted` — thuật toán đi theo code. Ghi trung thực; `validate.dart` check #9 sẽ bắt nếu `adapted` mà thiếu `source`/`license`.

## Output

Đúng 3 file theo `AUTHORING_PROMPT.md`, cộng `<id>.frag` nếu ở chế độ shader.

README phải có thêm mục **Port notes**: nguồn gốc file nào, đã bỏ tính năng web nào, sai lệch nào so với bản gốc và tại sao.

## Tự kiểm

1. Đã đọc file source thật chưa, hay đang dựng từ mô tả?
2. Có dùng shader trong khi widget/CustomPainter làm được không?
3. GLSL đã qua đủ 9 mục checklist chưa?
4. Raymarch/loop đã cap chưa? Cost đã ghi vào Caveats chưa?
5. Có lỡ viết biến thể button/card không?
6. `origin` và `license` đã đúng bảng attribution chưa?

---

## COMPONENT CẦN PORT

<điền tên + category, ví dụ: `GradientWaves` (Backgrounds)>

`id`: <snake_case>
`kind`: <paint | carrier | effect | composite>