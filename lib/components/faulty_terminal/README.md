---
# --- IDENTITY ---
id: faulty_terminal
title: Faulty Terminal
kind: paint
tags: [terminal, crt, glitch, scanline, retro, hacker, animated, background, shader]

# --- TAXONOMY (§2) ---
paint_source: shader
carriers_verified: []
carriers_failed: []
scale_aware: true

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: folder_with_assets
entry: faulty_terminal.dart
files:
  - faulty_terminal.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required:
  - lib/components/faulty_terminal/faulty_terminal.frag

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: adapted
source: https://github.com/DavidHDev/react-bits/blob/main/src/ts-tailwind/Backgrounds/FaultyTerminal/FaultyTerminal.tsx
author: "Khang"
license: "MIT + Commons Clause License Condition v1.0 (react-bits, © David Haz)"

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-19
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

# Faulty Terminal

Port GLSL gốc của react-bits "FaultyTerminal": nền terminal CRT glitch —
grid ô "digit" sáng theo fbm noise nhiều lớp, thanh scanline chạy, dòng bị
xé ngang (displace) kèm flicker, kính CRT cong (barrel), tùy chọn chromatic
aberration và dither đầu ra. Qua `FragmentProgram` + file
`faulty_terminal.frag` đi kèm. Opaque (composite trên đen) — dùng làm nền,
không phải overlay.

## Port notes

- Nguồn: `src/ts-tailwind/Backgrounds/FaultyTerminal/FaultyTerminal.tsx`
  (OGL — toàn bộ visual nằm trong chuỗi fragment GLSL → chế độ shader).
- Bỏ: **toàn bộ tương tác chuột** (`uMouse`/`uMouseStrength`/`uUseMouse`/
  `mouseReact`/`mouseStrength`) — Android không có hover; không có prop
  tương ứng.
- Giữ: `pageLoadAnimation` (fade từng ô theo delay ngẫu nhiên, chạy theo
  thời gian chứ không theo chuột) — Dart drive `uPageLoadProgress` trong
  2000ms sau mount; tắt thì truyền 1.0. Cờ `uUsePageLoadAnimation` được
  gấp lại: tại progress = 1.0 mọi ô đều nhân 1.0 nên chỉ cần skip branch.
- GLSL gốc có **global mutable** `float time;` gán trong `main()` — SkSL
  runtime effect cấm; restructure: `t` truyền qua tham số xuống
  noise/fbm/pattern/digit/getColor. Toán giữ nguyên (kể cả rotation thứ 3
  trong fbm mà bản gốc tính xong không dùng — vẫn không dùng).
- `vUv` từ vertex shader → dựng lại bằng `FlutterFragCoord()/uResolution`,
  flip `uv.y` một lần cho khớp hướng GL (như dither.frag).
- `uScale` của bản gốc vốn đã nhân UV — chính là detail-density scale §9.1,
  map thẳng param `scale` của vault vào nó, không thêm uniform mới.
- Seed `Math.random() * 100` của bản gốc → param `timeOffset` (null =
  random mỗi mount, truyền số cố định để deterministic).
- `pause` của bản gốc → param `animate` (đảo nghĩa). Khi dừng,
  page-load fade hiện như đã xong (bản gốc cũng chạy fade tới cùng bất kể
  `pause` vì rAF vẫn quay).
- `dither: number | boolean` của bản gốc → chỉ `double` (0 = tắt, 1 = như
  `true` bản web).

## Install

```yaml
# no pub dependencies — Flutter SDK only, BUT the shader must be declared:
flutter:
  shaders:
    - lib/components/faulty_terminal/faulty_terminal.frag
```

Đặt folder ở chỗ khác → đổi path trong `shaders:` và truyền `assetKey`
tương ứng cho widget/`loadFaultyTerminalProgram`. Nhét nhầm vào `assets:`
thì `FragmentProgram.fromAsset` fail im lặng.

## Reuse

- **Copy:** the whole `faulty_terminal/` folder (1 dart + 1 frag, see
  `files` + `shaders_required`)
- **Import:** `import 'faulty_terminal/faulty_terminal.dart';` — one line
- **Or:** `dart tools/export.dart faulty_terminal` → zip + paste-ready block

Mang sang project khác cần copy `.frag` **và** thêm dòng pubspec `shaders:`
(xem Install). Fill nền: `FaultyTerminal()`. Carrier khác qua `ShaderMask` —
factory trả `ui.Shader` thật (§2.3):

```dart
final program = await loadFaultyTerminalProgram(); // once

ShaderMask(
  blendMode: BlendMode.srcIn,
  shaderCallback: (bounds) => createFaultyTerminalShader(
    program,
    bounds,
    time: t, // seconds — rebuild to animate
    scale: 3, // small carrier → more digit detail (§9.1)
    tint: const Color(0xFF86EFAC),
  ),
  child: const Text('SYSTEM FAILURE'),
)
```

## API

`createFaultyTerminalShader(program, bounds, {...})` — the primary API.
`configureFaultyTerminalShader(shader, size, {...})` — same params, reuses
one shader instance (per-frame cheap path). `FaultyTerminal` widget — fills
bounds, own clock, optional `child`.

| Param | Type | Default | Meaning |
|---|---|---|---|
| `scale` | `double` | `1.0` | Detail density (§9.1): nhân UV — chính là `scale` của bản gốc |
| `gridMul` | `Offset` | `(2, 1)` | Hệ số grid ô digit theo trục x/y (×15 bên trong) |
| `digitSize` | `double` | `1.5` | Cỡ khối chấm sáng trong mỗi ô |
| `timeScale` | `double` | `0.3` | Tốc độ toàn bộ animation |
| `scanlineIntensity` | `double` | `0.3` | Cường độ thanh scanline trên phần glow |
| `glitchAmount` | `double` | `1` | Hệ số xé ngang: 1 = gốc, 0 ≈ tắt, >1 mạnh hơn |
| `flickerAmount` | `double` | `1` | Hệ số cổng flicker của glitch |
| `noiseAmp` | `double` | `1` | Biên độ fbm noise thắp sáng digit |
| `chromaticAberration` | `double` | `0` | Tách kênh RGB (px vật lý); ≠0 tốn ×3 getColor |
| `dither` | `double` | `0` | Nhiễu hạt đầu ra chống banding (0..1) |
| `curvature` | `double` | `0.2` | Độ cong kính CRT (0 = phẳng) |
| `tint` | `Color` | trắng | Nhân vào màu cuối (xanh lá = phosphor cổ điển) |
| `brightness` | `double` | `1` | Nhân độ sáng cuối |
| `pageLoadAnimation` | `bool` | `true` | Ô hiện dần ~2s sau mount (widget); factory nhận `pageLoadProgress` 0..1 |
| `timeOffset` | `double?` | `null` | Pha khởi đầu (giây); null = random mỗi mount như bản gốc |
| `animate` | `bool` | `true` | Stop switch — tắt ticker, giữ phase |
| `program` / `assetKey` | — | null / vault path | Preload hoặc đổi vị trí .frag |

## Caveats

- **Cost per pixel cao:** `getColor` gọi `digit()` **10 lần** (1 chính +
  9 tap glow), mỗi `digit` = 1 `pattern` = 5 fbm = 15 lần sin-noise → ~150
  noise/pixel. `chromaticAberration ≠ 0` nhân thêm ×3 (default 0 skip
  branch). Fullscreen trên Android tầm trung: **chưa đo**. Máy yếu: giảm
  bằng `animate: false` khi tĩnh, hoặc bỏ chromatic aberration.
- Opaque, không có mode transparent — bản gốc composite trên đen. Muốn
  overlay lên nền khác thì dùng ShaderMask/BlendMode ở tầng app.
- Mouse-follow/ripple của bản web KHÔNG port (xem Port notes) — không có
  prop tương ứng.
- `curvature` > 0 kéo UV ra ngoài [0,1] ở mép → viền ngoài lặp pattern mờ
  thay vì đen tuyệt đối (giống bản gốc, pattern tự tắt ngoài biên ô).
- Mặc định mỗi mount một pha random (`timeOffset` null) — thumbnail/test
  cần ổn định thì truyền số cố định.
- Cần `FragmentProgram` (Flutter 3.10+; vault tạo trên 3.44.5). Widget
  render trống 1 frame đầu khi program đang load.
- **License gốc:** MIT + Commons Clause (react-bits) — dùng trong
  app/product thoải mái, KHÔNG được bán/redistribute bản thân component
  (kể cả bản port).

## Changelog

- **1.0.0** (2026-08-19) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `FaultyTerminal` vào project này.

**Context**
- Chức năng: nền terminal CRT glitch (port react-bits "FaultyTerminal") —
  grid digit sáng theo noise, scanline, xé dòng, kính cong. FragmentProgram
  + file `faulty_terminal.frag` đi kèm. Factory `createFaultyTerminalShader`
  trả `ui.Shader` cho ShaderMask; widget `FaultyTerminal` fill nền, opaque.
- Public API: xem bảng API trong README.
- Portability: folder_with_assets — copy cả folder `faulty_terminal/`
  (1 dart + 1 frag), import duy nhất `faulty_terminal.dart`, VÀ khai báo
  `.frag` trong pubspec `shaders:` (xem Install).
- Deps: không có pub package — Flutter SDK only.

**Việc cần làm**
1. Copy folder `faulty_terminal/` vào thư mục widget của project đích.
2. Thêm path `.frag` vào pubspec `shaders:` (path thật sau khi copy) và
   truyền `assetKey` nếu khác path mặc định trong `faulty_terminal.dart`.
3. Nền màn hình: đặt `FaultyTerminal()` dưới cùng Stack (opaque). Carrier
   khác: `ShaderMask` + `createFaultyTerminalShader`.

**Việc cần adapt theo project đích**
- `tint` sang palette project (xanh lá = phosphor, hổ phách `0xFFFFB000` =
  terminal cổ); `curvature: 0` nếu muốn phẳng.
- Carrier nhỏ: tăng `scale` (§9.1).
- Màn hình tĩnh: `animate: false` (+ `timeOffset` cố định nếu cần frame
  ổn định).

**Rào (constraints)**
- KHÔNG sửa logic shader/dart bên trong. Chỉ đổi qua params.
- KHÔNG đổi thứ tự uniform trong `.frag` — Dart set theo index.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
