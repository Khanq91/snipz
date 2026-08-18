# PROMPT BÀN GIAO — Snipz Phase 2 (App viewer cơ bản)

> Paste toàn bộ file này vào session Claude Code mới, mở tại repo Snipz.

---

## 0. Việc đầu tiên, bắt buộc

Đọc **`docs/snipz_prompt.md`** (spec v3.1) từ đầu đến cuối trước khi viết dòng code nào. File này chỉ bàn giao *hiện trạng*, không thay thế spec. §0.2 của spec là các quyết định đã chốt — KHÔNG mở lại.

**Cách làm việc:** trả lời tiếng Việt; code + comment tiếng Anh. Làm theo phase, verify xong mới sang phase sau. Code tối thiểu, không thêm abstraction thừa. KHÔNG tự commit/push — cuối phase đưa commit message tiếng Anh để tôi tự push.

## 1. Hiện trạng: Phase 0 + Phase 1 ĐÃ XONG và đã verify

- Phase 0: chỉ còn `android/` (không có ios/web), CI pin Flutter 3.44.5, `analysis_options.yaml` strict (strict-casts/inference/raw-types + rules) — **`flutter analyze` phải luôn 0 issue**, smoke test trong `test/widget_test.dart`.
- Phase 1: toàn bộ xương sống + scripts đã chạy và pass đủ 9 kịch bản test âm tính (§0.4b). Trạng thái hiện tại: `validate: OK — 3 component(s), 0 warning(s)`, test 5/5, build APK debug pass.

### Cấu trúc đã có

```
lib/
├── main.dart                  # VẪN LÀ counter app mặc định — Phase 2 thay nó
├── core/
│   ├── models.dart            # pure Dart: enums (wire-value), ComponentMeta,
│   │                          #   ComponentIndex, ComponentSources, TestRecord
│   ├── component_demo.dart    # ComponentDemo {id, builder, thumbnailBuilder?,
│   │                          #   carrierBuilders (default {})}
│   └── index_loader.dart      # IndexLoader(AssetTextReader) — reader INJECT
├── registry.dart              # map id -> ComponentDemo, alphabet, script chèn
└── components/                # vault: glass_card, aurora_stack, spectrum_sweep
assets/index.json + assets/sources/<id>.json   # GENERATED, committed
tools/  new_component | verify | validate(--fix) | build_index | export
test/   widget_test.dart + index_loader_test.dart
```

### Quy ước đã chốt trong Phase 1 (tôn trọng, đừng viết lại)

1. **`IndexLoader` nhận reader inject** (`Future<String> Function(String assetPath)`). Phase 2 wire `rootBundle.loadString` làm reader ở composition root — KHÔNG gọi rootBundle chỗ khác, KHÔNG phá guarantee "startup đọc đúng 1 asset" (đã có unit test đếm số lần đọc trong `test/index_loader_test.dart` — phải giữ xanh).
2. `index.json` đã chứa cả `test_history` (parse sẵn từ README) → mọi data cho badge/filter Phase 4 đều ở startup read, không cần đọc gì thêm.
3. `sources/<id>.json` (`readme_body` + `files`) chỉ load **lazy** khi mở detail, qua `IndexLoader.loadSources(id)` (đã cache).
4. Frontmatter derived (`status`/`latest_known_good`/`last_verified`) **có thể null** khi component chưa verify lần nào — models đã xử lý, UI phải xử lý (hiện "untested/unknown", đừng crash).
5. 3 seed demo: `aurora_stack` có `thumbnailBuilder` với `animate: false`; `spectrum_sweep` expose `createSpectrumSweepShader(Rect bounds, {scale, rotation, colors})` — Phase 3 sẽ dùng cho carrier switcher, Phase 2 chưa đụng.
6. Sửa/thêm component xong phải chạy `dart tools/build_index.dart` (artifacts committed); `dart tools/validate.dart` phải pass — CI có step này. Component có dep pub mới thì dep đó phải được thêm cả vào pubspec app (code vault compile trong app).
7. Tools chạy từ repo root, output qua `stdout.writeln` (lint `avoid_print` đang bật), không dùng package `analyzer`.

## 2. BẪY MÔI TRƯỜNG MÁY — đọc kỹ trước khi build

Máy có **2 SDK Flutter**:
- `D:\khang\data\flutterDev\flutter` — CŨ (rev 67323de), đang cấu hình trong Android Studio/IntelliJ
- `D:\khang\data\flutterDev\flutter_windows_3.44.5-stable\flutter` — 3.44.5, trên PATH (CLI dùng bản này)

IDE đang mở sẽ ghi đè `android/local.properties` và `.dart_tool/package_config.json` về SDK cũ → build CLI vỡ với lỗi lạ **bên trong framework** (`hitTestTransform` missing parameter ở semantics.dart = framework cũ + engine mới trộn nhau). Xử lý:
- **Luôn chạy `flutter pub get` ngay trước analyze/build CLI.**
- Nếu gặp đúng lỗi trên: đó là package_config bị IDE ghi đè, không phải lỗi code — pub get lại là hết.
- Nhắc tôi đổi SDK path trong IDE nếu thấy nó vẫn ghi đè.

## 3. Phase 2 — phạm vi (spec §12 + §8.3 + §8.5 + §11)

Gallery grid **2 cột** (mobile-first) + detail cơ bản:

1. **Deps mới** (chỉ thêm cái dùng ngay): `flutter_riverpod`, `go_router`, `flutter_markdown_plus` (KHÔNG phải `flutter_markdown` — đã bị discontinue, quyết định #12). Hive để Phase 4 (favorite/target version) — đừng thêm trước.
2. **App shell** (`lib/app/`): router go_router — mọi route dùng `CustomTransitionPage` fade (§11, tránh scrim flash), theme dark/light.
3. **Gallery** (`lib/features/gallery/`): load duy nhất `index.json` lúc khởi động qua `IndexLoader`; grid 2 cột thumbnail render **widget thật** từ `registry.dart` — ưu tiên `thumbnailBuilder` nếu có, bọc `RepaintBoundary`; KHÔNG bao giờ render carrier `text` trong thumbnail (§9.2).
4. **Detail** (`lib/features/detail/`): preview stage theo `kind` (§8.5 — `paint`: fullscreen preview, carrier switcher là Phase 3; `carrier`/`composite`: khung có padding + toggle light/dark; `effect`: target mẫu + toggle on/off); tab **Info** render `readme_body` bằng `flutter_markdown_plus`, load **lazy** qua `loadSources(id)`.
5. Thay `main.dart` counter bằng app thật; cập nhật `widget_test.dart` smoke test cho khớp (bơm app root, không exception — cẩn thận animation vô hạn với `pumpAndSettle`).

**KHÔNG làm ở Phase 2:** carrier switcher/ShaderMask (Phase 3), search/filter/badge/favorite/settings (Phase 4), tab Code/Files/share/pause-ngoài-viewport/pre-commit hook (Phase 5). Đừng làm trước "cho tiện".

### Verify Phase 2 (điều kiện kết thúc, theo spec)

- 3 seed hiện đúng thumbnail trên **máy Android thật** (nhờ tôi chạy và xác nhận bằng mắt — aurora thumbnail phải ĐỨNG YÊN vì `animate: false`).
- Mở detail render đúng theo `kind`; tab Info hiện README; light/dark không lỗi.
- **Gallery chỉ đọc đúng 1 asset lúc khởi động** — unit test đếm reader hiện có phải vẫn xanh; nếu thêm được assert/test ở tầng app càng tốt.
- `flutter analyze` 0 issue; `flutter test` pass; `dart tools/validate.dart` pass; `flutter build apk --debug` pass; CI xanh sau khi tôi push.

## 4. Bắt đầu

1. Đọc `docs/snipz_prompt.md` + lướt code hiện có (`lib/core/`, `lib/registry.dart`, 1 seed, `tools/validate.dart` phần header).
2. Nêu assumption/mâu thuẫn nếu phát hiện (chỉ dừng hỏi khi thật sự thiếu thông tin).
3. Đề xuất kế hoạch Phase 2 dạng `bước → cách verify`, chờ tôi OK rồi implement.
