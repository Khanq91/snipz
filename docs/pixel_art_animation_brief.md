# Pixel-art animation brief — PixelWalker + PullRevealRefresh

Tài liệu handoff cho việc **thiết kế thêm animation / art mới** (mascot mới,
scene mới, chỉnh chuyển động mượt mà – dễ thương hơn) trên hệ pixel-art của
Snipz. Đưa doc này + bộ file ở mục 1 cho Claude Design (hoặc bất kỳ agent
thiết kế nào) là đủ ngữ cảnh để làm việc, không cần đọc thêm repo.

---

## 1. Bộ file cần và đủ

### Lõi (bắt buộc)

| File | Vai trò |
|---|---|
| `lib/components/pixel_walker/pixel_walker.dart` | **Toàn bộ engine art**: format sprite ma trận ký tự, 6 bộ frame mascot, painter dither/parallax, mọi hằng số animation. Art mới sinh ra ở đây. |
| `lib/components/pixel_walker/README.md` | API contract, spec parallax, caveats, changelog (ghi các quyết định thiết kế đã chốt). |
| `docs/pixel_art_animation_brief.md` | Chính doc này — bản đồ animation + ràng buộc + núm vặn. |

### Ngữ cảnh interaction (cần nếu design đụng tới cảm giác kéo/nhả)

| File | Vai trò |
|---|---|
| `lib/components/pull_reveal_refresh/pull_reveal_refresh.dart` | Vật lý header: lực cản kéo, settle/collapse, state machine — nguồn của `progress`/`isRefreshing`. |
| `lib/components/pull_reveal_refresh/README.md` | Contract + caveats (physics, translate-not-relayout). |
| `lib/components/pull_reveal_refresh/pull_reveal_refresh_demo.dart` | Wiring chuẩn 2 component + số đo thật đang dùng (trigger 110 / max 190, màu nền từng scene). |

### Tham khảo thêm (không bắt buộc)

- `lib/components/pixel_walker/pixel_walker_demo.dart` — playground các param,
  danh sách 6 mascot.
- `assets/sources/pixel_walker.json`, `assets/sources/pull_reveal_refresh.json`
  — file **generated** (README + full source gói trong 1 JSON, app dùng để xem
  source). Tiện làm "1 file duy nhất" đưa cho agent, nhưng là bản snapshot:
  sửa code thì phải regenerate, **không sửa tay**.
- `CLAUDE.md` — luật repo nếu design dẫn tới sửa code (bump version...).

---

## 2. Kiến trúc: 2 tầng, nối bằng 2 giá trị

```
Tay kéo → PullRevealRefresh (extent px, state machine, settle/collapse)
              │
              ├─ status.progress (0→1 so với ngưỡng) ──→ PixelWalker.progress  (cảnh hiện dần)
              └─ status.isRefreshing (bool)           ──→ PixelWalker.walking   (bước + parallax trôi)
```

- `PullRevealRefresh` không vẽ gì — chỉ quyết định header cao bao nhiêu px và
  đang ở mode nào. `headerBuilder` được gọi lại **mỗi frame** extent đổi.
- `PixelWalker` nhận đúng 2 giá trị đó và tự lo 100% phần nhìn thấy.
- Lúc **đang kéo** mascot chưa bước (`walking` chỉ bật khi `refreshing`);
  `progress` clamp ở 1 nên kéo lố chỉ giãn header, cảnh không đổi thêm.

Wiring chuẩn (demo):

```dart
PullRevealRefresh(
  onRefresh: _load,
  triggerExtent: 110,
  maxExtent: 190,
  headerBuilder: (context, status) => PixelWalker(
    progress: status.progress,
    walking: status.isRefreshing,
    backgroundColor: bg,
  ),
  child: ListView(
    physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
    ...
  ),
)
```

---

## 3. Tầng 1 — PullRevealRefresh (motion của header)

File: `pull_reveal_refresh.dart` (~316 dòng, single file).

**State machine** (contract public, không đổi luồng):
`idle → dragging → armed → refreshing → settling → idle`.

**Driver**: một `AnimationController.unbounded` tên `_extent` — vừa nhận giá
trị kéo tay trực tiếp, vừa chạy 2 animation lúc nhả.

**Lực cản đàn hồi** (`_onPulled`):

```dart
final room = (1 - _extent.value / maxExtent).clamp(0.0, 1.0);
_setExtent(_extent.value + delta * (0.25 + 0.75 * room));
// đầu hành trình ăn ~100% delta, sát trần maxExtent chỉ còn 25%
```

**Haptic**: `HapticFeedback.mediumImpact()` đúng khoảnh khắc extent vượt
`triggerExtent` (chuyển sang armed), tắt được qua `hapticOnArm`.

**Hai animation nhả tay**:

| Animation | Khi nào | Đích | Duration | Curve |
|---|---|---|---|---|
| settle | nhả lúc armed | `triggerExtent` | `settleDuration` = 200ms | `easeOutCubic` (hard-code) |
| collapse | refresh xong / nhả non | 0 | `collapseDuration` = 320ms | `collapseCurve` = `easeOutCubic` |

Collapse dùng `.orCancel` — người dùng kéo tiếp giữa chừng sẽ cướp quyền êm,
không giật.

**Render**: header là `Positioned` cao đúng `extent` trong `Stack`; nội dung
list chỉ bị `Transform.translate` xuống (không relayout). Hệ quả: nền phía
sau phải cùng màu app (caveat trong README).

**Input**: `NotificationListener<ScrollNotification>` — nhánh chính cho
`ClampingScrollPhysics` (Android, đọc `OverscrollNotification` âm), nhánh
fallback cho `BouncingScrollPhysics` (iOS, đọc `metrics.pixels` âm, có thể
giật nhẹ 1 nhịp lúc nhả).

---

## 4. Tầng 2 — PixelWalker (toàn bộ animation pixel)

File: `pixel_walker.dart` (~978 dòng, single file, không asset — 100%
procedural).

### 4.1. Đồng hồ và repaint

- `Ticker` chỉ chạy khi `walking == true`; thời gian tích lũy qua `_timeBase`
  nên tắt/bật walking đi tiếp đúng pha, không giật về 0.
- `walking: false` = **không ticker, 0 frame/giây** — bất biến cần giữ (cảnh
  tĩnh nhúng lâu dài trong tree, thumbnail).
- Repaint qua `ChangeNotifier` truyền vào `CustomPainter(repaint:)`, không
  `setState` mỗi frame.
- Mọi tốc độ nhân `t = _timeSec * speed`.

### 4.2. Reveal theo progress — 2 đường cong, có chủ đích

```dart
final reveal = progress.clamp(0.0, 1.0);          // TUYẾN TÍNH → độ trồi mascot
final eased  = Curves.easeOutCubic.transform(reveal); // → mật độ dither + alpha mọi layer
```

Mascot trồi theo `reveal` tuyến tính để **chân chạm đất đúng lúc
progress = 1** — tự thân là chỉ báo "đủ ngưỡng refresh" (quyết định đã chốt,
changelog 1.0.1 — giữ nguyên khi redesign).

### 4.3. Lưới pixel

```dart
cell       = 3.0 * scale;      // ô dither nền
spriteCell = cell * 2;         // ô mascot
feetY      = size.height - cell;
skylineBaseY = feetY - spriteH * 0.9 + (1 - eased) * 3 * cell;
// đáy skyline ngang tầm đầu mascot; cả cảnh lún 3 ô khi chưa hiện đủ
```

Mọi thứ vẽ bằng `canvas.drawRawPoints(PointMode.points, Float32List, paint)`
với `strokeCap: square`, `strokeWidth = cell` — mỗi điểm là một ô vuông. Đó
là toàn bộ "chất pixel". Buffer `_PointSink` tái dùng giữa các frame —
**không cấp phát trong `paint()`**.

### 4.4. Chu kỳ bước của mascot (trái tim của độ dễ thương)

```dart
fi   = walking && frameCount > 1 ? (t * 7).floor() % frameCount : 0;  // 7 bước frame/giây
lean = walking && fi.isOdd ? (fi % 4 == 1 ? 0.09 : -0.09) : 0.0;      // ±0.09 rad (~5.2°)
bob  = walking && fi.isOdd ? -spriteCell * 0.35 : 0.0;                // nhấc người ~2px
rise = (1 - reveal) * (spriteH + spriteCell);                          // trồi từ mép dưới
// translate(size.width/2, feetY + rise + bob) rồi rotate(lean), vẽ frame
```

- `walking == false` → ép frame 0 (pose đứng), không đứng hình giữa bước.
- Frame count không cứng: painter lấy `frames.length` — **thêm frame là chu
  kỳ tự dài ra**, không phải sửa painter.
- Lean/bob là bậc thang (chỉ frame lẻ, giá trị cố định). Muốn mượt kiểu
  "lượn" thì thay bằng hàm liên tục theo `t` (vd `0.09 * sin(2π·t·3.5)`) —
  đổi cảm giác từ giật-pixel sang mềm; cân nhắc giữ chất retro.

### 4.5. Spec format sprite — contract cho artist

- Mỗi mascot = `PixelSprite(frames, palette)`:
  - `frames`: list các frame; mỗi frame là list dòng string; mỗi ký tự tra
    màu trong `palette`; `.` (hoặc ký tự lạ) = trong suốt.
  - Mọi dòng trong 1 frame dài bằng nhau; mọi frame cùng kích cỡ.
- **Quy ước động tác**: frame 0 = pose đứng; các frame sau là chu kỳ bước;
  **frame lẻ được painter tự cộng lean + bob** — đừng vẽ nghiêng sẵn trong
  data. Pattern hiện tại của cả 6 con: `[đứng, sải, đứng, thu]`.
- Kích cỡ hiện dùng: 12–18 cột × 10–11 hàng, palette 1–3 màu. Mascot vẽ bằng
  ô `spriteCell` (gấp đôi ô nền) nên đứng nổi trên cảnh.
- Sáu mascot có sẵn (đều trong `pixel_walker.dart`):

| Factory | Cỡ | Palette | Nét động riêng ở frame bước |
|---|---|---|---|
| `clawd({color})` | 12×10 | `X` | chỉ đảo 2 hàng chân |
| `miu({body, stripe})` | 16×11 | `X`,`S` | chóp đuôi `S` đổi chỗ từng frame → vẫy đuôi |
| `capy({body, dark, eye})` | 18×10 | `X`,`S`,`E` | chân đảo chéo, thân bất động (mặt đơ) |
| `duck({body, beak, eye})` | 14×10 | `X`,`B`,`E` | đuôi hất lên 1 hàng khi sải → lạch bạch |
| `crab({body, eyeWhite, eye})` | 16×10 | `X`,`W`,`E` | mỗi frame bước giơ hẳn 1 càng ngang mắt |
| `axolotl({body, accent, eye})` | 18×10 | `X`,`S`,`E` | mang rung 1 ô + đuôi cong lên/xuống |

Mascot mới = vẽ ma trận + palette mới, painter không đụng.

### 4.6. Parallax + thứ tự layer

Tốc độ (ô/giây, nhân `speed`), chậm → nhanh = xa → gần:

| Layer | Tốc độ | Ghi chú |
|---|---|---|
| Sao + trăng (nightCity) | 0 | neo màn hình; sao 2 tầng alpha 0.25/0.85; trăng khuyết = đĩa r3.6 trừ đĩa cắn r3.1, neo `width*0.78`, `baseY − 22 ô` |
| Núi (nightCity) | 2.2 | ridge chu kỳ 160 ô = max 5 đỉnh tam giác |
| Mây | 3.0 | 4 blob ellipse, chu kỳ 160 ô, vẽ thêm bản wrap để vào từ mép phải liền mạch |
| Toà nhà | 9.0 | chu kỳ ~96 ô; scroll dùng cả phần lẻ → trôi liên tục, vốn đã mượt |

Thứ tự vẽ `nightCity`: sao → trăng → núi → mây → **toà nhà (đè mây → chiều
sâu)** → mascot. `city`: skyline → mây → mascot.

### 4.7. Dither — hash deterministic + mật độ từng vùng

Mọi chấm quyết định bởi `_hash(x, y, seed) < density * eased` — hash 2D
deterministic (không `Random()` runtime) nên chấm "dính" vào toà nhà khi trôi
và `seed` tái lập được bố cục.

| Vùng | Mật độ (city / night) |
|---|---|
| Antenna | 0.30 / 0.35 |
| Mép nóc toà (2 hàng) | 0.38 / 0.50 |
| Thân toà | 0.62 / 0.78 |
| Cửa sổ đèn (night) | xác suất 0.10 × eased, chỉ trong thân toà |
| Mây | `0.55·(1−r²) + 0.08` (đặc giữa, thưa mép), vẽ ở alpha 0.55 |
| Núi | mép ridge 0.60, thân 0.40, alpha 0.60 |

### 4.8. Sinh bố cục từ seed (`_rebuildLayout`)

LCG tự chế từ `seed`: skyline lặp {gap 3–8 đêm / 3–9 ngày, rộng 5–10 / 6–16,
cao 8–20 / 4–13} tới ~96 cột, mỗi toà 1 antenna cao 2–4 ô; núi 5 đỉnh (cao
12–24, slope 0.30–0.65) trên 160 ô; mây 4 blob (start `i·40 + rand 0–24`,
rộng 10–18, cao 3–5, lift 0–5 ô).

---

## 5. Bảng núm vặn cho redesign

**Độ mượt:**

| Núm | Hiện tại | Ở đâu (symbol) |
|---|---|---|
| Nhịp frame sprite | `(t * 7)` — 7 fps | `_paintSprite` |
| Lean / bob | ±0.09 rad / −0.35 ô, bậc thang frame lẻ | `_paintSprite` |
| Settle / collapse | 200ms / 320ms, easeOutCubic | params `PullRevealRefresh`; curve settle hard-code trong `_finishDrag` |
| Lực cản kéo | `0.25 + 0.75·room` | `_onPulled` |
| Tốc độ parallax | 9.0 / 3.0 / 2.2 | `_paintSkyline` / `_paintClouds` / `_paintMountains` |
| Reveal easing | easeOutCubic cho dither, tuyến tính cho mascot | `paint()` — giữ mascot tuyến tính |
| Tốc độ tổng | `speed` | param |

**Độ dễ thương:**

| Núm | Ý tưởng |
|---|---|
| Ma trận sprite | thêm frame (chớp mắt, ngoáy đuôi lúc đứng — hiện pose đứng chỉ 1 frame tĩnh), vẽ dáng mới |
| Palette mascot | thêm ký tự màu mới (má hồng, viền) — palette là map tùy ý |
| Bob/lean | tăng bob → nhún nhảy hơn (duck dựa hẳn vào cặp này) |
| Cửa sổ đèn | tăng 0.10 → phố ấm hơn; màu qua `windowColor` |
| Mây / sao / trăng | blob to-đặc hơn, mật độ sao, vị trí trăng |
| Haptic | mediumImpact → light/selection cho cảm giác nhẹ |

**Màu đang dùng** (từ demo — component chỉ nhận màu, không tự đoán):

| | city | nightCity |
|---|---|---|
| nền app | `#0E0D0B` | `#0A0D16` |
| skyline | `#B9B4AE` | `#93A1BE` |
| khác | mascot mặc định `#E8875C` | cửa sổ `#F2C069`, sao/trăng `#C7D3E6` |

---

## 6. Ràng buộc bất biến

1. **Single file** — mỗi component gói trong 1 file entry; không thêm dep
   ngoài Flutter SDK; **không asset** (cảnh phải 100% procedural).
2. **Không cấp phát trong `paint()`** — giữ pattern `_PointSink` +
   `drawRawPoints` (~1–2k điểm/frame ở 480px).
3. **`walking: false` = không ticker chạy** — nhiều chỗ nhúng cảnh tĩnh dựa
   vào bất biến này.
4. **Mascot trồi theo progress tuyến tính** — chân chạm đất = đủ ngưỡng
   (changelog 1.0.1).
5. **State machine PullRevealRefresh là contract public** — chỉnh cảm giác
   qua duration/curve/extent, không đổi luồng mode.
6. **Hash deterministic** — không `Random()` runtime, `seed` phải tái lập
   được bố cục.
7. Sửa code xong: bump `version` trong `pubspec.yaml` + version/changelog
   trong README component (luật `CLAUDE.md`); `assets/sources/*.json` là
   generated — regenerate bằng tool, không sửa tay.
