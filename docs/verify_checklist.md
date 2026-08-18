# Checklist kiểm tra Phase 3 → 5

> Mỗi mục ghi rõ: cách kiểm + kết quả kỳ vọng. Phần **[máy]** đã được
> script/test tự động cover (chạy `flutter test` + `dart tools/validate.dart`
> là đủ); phần **[tay]** cần bạn thao tác trên máy Android thật.

## Chạy nhanh toàn bộ phần [máy]

```
flutter analyze          # 0 issue
flutter test             # 30 test pass
dart tools/validate.dart # OK — 13 component(s)
flutter build apk --debug
```

---

## Phase 3 — Carrier switcher

- [ ] **[máy]** `flutter test test/carrier_switcher_test.dart` — 5 test pass:
  - Seed shader (`spectrum_sweep`) áp lên card / button / text / border mà
    `carrierBuilders` rỗng (chỉ dùng factory §2.3).
  - Chip `Text` không render carrier text cho tới khi tap (§9.2).
  - Carrier trong `carriers_failed` → chip disabled + tooltip đúng lý do.
  - Paint không shader hóa (widget/painter) → text/icon/border disabled,
    shape carrier (card/button/divider) vẫn nhúng được.
- [ ] **[tay]** Mở app → `Spectrum Sweep` → tab Preview:
  - Hàng chip scroll ngang, không wrap: Fullscreen | Card | Button | Text |
    Border | Icon | Divider.
  - Thấy đủ 3 trạng thái chip: bình thường (fullscreen/card/button/text),
    mờ-tap-được (border/divider), disabled (icon — giữ/tap chip hiện tooltip
    lý do).
  - Tap Card/Button/Text: sweep quay mượt trong từng shape; Text chỉ bắt đầu
    vẽ khi tap.
- [ ] **[tay]** Mở `Gradient Waves` / `Dither` / `Pixel Blast` (GLSL): tap
  Card/Button/Text — shader động chạy trong shape, không crash, không giật
  nặng.
- [ ] **[tay]** Mở `Aurora Stack` (paint dạng widget): Card/Button/Divider
  nhúng được; Text/Icon/Border disabled + tooltip giải thích.

## Phase 4 — Metadata & compat

- [ ] **[máy]** `flutter test test/compat_test.dart` — 8 test pass (đủ 4 luật
  quyết định #11 + stale runtime).
- [ ] **[máy]** `flutter test test/phase4_test.dart` — 6 test pass:
  - Sửa Test History thành `fail` → badge 🔴 và bị filter 🟢 Compat loại.
  - Đổi target version trong Settings → badge đổi theo (🟢 → 🟡).
  - Component 3 file hiện badge vàng `folder (3)`; single-file hiện `single`.
  - `last_verified` 8 tháng trước → 🟡 stale.
  - Favorite lưu qua store (JSON trong Hive), filter ★ hoạt động.
  - Search theo title/tag.
- [ ] **[tay]** Gallery: mỗi tile có badge compat (🟢🟡🔴) + badge chi phí tái
  dụng; tap badge compat hiện tooltip lý do.
- [ ] **[tay]** Settings (icon bánh răng): dropdown Target Flutter version,
  default ghi `(default)`; đổi version → quay lại gallery badge đổi màu;
  **kill app mở lại** → lựa chọn còn nguyên (Hive).
- [ ] **[tay]** Đánh dấu ★ vài component, kill app mở lại → còn nguyên.

## Phase 5 — Hoàn thiện

- [ ] **[máy]** `flutter test test/phase5_test.dart` — 5 test pass:
  - Share block đủ: deps snippet, danh sách file, dòng import, key
    `assets:`/`shaders:` tách riêng, scale hint, link GitHub.
  - Single-file: không có tab Files; Code lazy (chỉ đọc
    `assets/sources/<id>.json` khi mở tab).
  - Multi-file: tab Files liệt kê file + vai trò; tap file → nhảy sang tab
    Code đúng file.
  - Toggle checkerboard hoạt động.
- [ ] **[máy]** Pre-commit hook chặn frontmatter sai — đã test thật: sửa
  `status: verified` → `stale`, commit bị chặn với thông báo validate.
  Kiểm lại bất kỳ lúc nào:
  ```
  git config core.hooksPath   # phải in ra: hooks
  ```
  (Clone mới phải chạy lại `git config core.hooksPath hooks`.)
- [ ] **[tay]** Detail bất kỳ → nút Share: share sheet Android mở, block
  paste-ready đúng nội dung, có link
  `https://github.com/Khanq91/snipz/tree/main/lib/components/<id>`.
- [ ] **[tay]** Tab Code: monospace, scroll ngang được, đổi file bằng chip.
- [ ] **[tay]** Toggle checkerboard trên `Glass Card` (carrier) và một
  effect (`Blur Text`) — thấy nền ca-rô sau component.
- [ ] **[tay]** **Perf (§12 Phase 5):** scroll gallery 13 component bằng
  DevTools → Performance overlay / frame chart, không tụt frame kéo dài
  (đo bằng DevTools, không đo bằng cảm giác). Thumbnail ngoài viewport bị
  dispose (animation dừng) — kéo xuống rồi kéo lên, demo animate lại từ đầu
  là đúng hành vi.
- [ ] **[tay]** Xoay ngang / dark mode hệ thống: gallery + detail không vỡ
  layout.

## Ghi chú còn lại (không thuộc phase nào)

- `carriers_verified` của các component còn `[]` (trừ spectrum_sweep):
  tap thử từng carrier trong app rồi cập nhật frontmatter + chạy
  `dart tools/build_index.dart` (hoặc dùng `dart tools/verify.dart <id>`
  khi verify version mới).
- CI (`build-apk.yml`) đã chạy analyze + test + validate trên mỗi push —
  push lên GitHub và xem Actions xanh là phần [máy] được xác nhận lần nữa
  trên Linux + Flutter 3.44.5.
