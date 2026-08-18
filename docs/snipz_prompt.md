# PROMPT BÀN GIAO — Snipz (Flutter Component Vault)

> Spec **v3**. Paste toàn bộ file này vào session Claude Code mới.
> v3 = v2 + chốt toàn bộ mâu thuẫn đã được review, + chốt platform target là Android/mobile.

---

## 0. VAI TRÒ & CÁCH LÀM VIỆC

Bạn là Flutter engineer implement một dev-tool cá nhân từ spec dưới đây.

**Cách làm việc mong đợi:**
- Đọc hết spec trước khi viết dòng code đầu tiên. Nêu assumption và điểm mâu thuẫn (nếu có) TRƯỚC khi implement.
- Làm theo phase. Kết thúc mỗi phase phải chạy được và verify được, rồi mới sang phase sau.
- Ưu tiên code tối thiểu giải quyết đúng vấn đề. Không thêm abstraction cho code dùng một lần, không thêm "flexibility" không được yêu cầu.
- Không cần hỏi xác nhận từng bước nhỏ. Chỉ dừng khi spec thực sự thiếu thông tin hoặc tự mâu thuẫn.
- Trả lời bằng tiếng Việt. Code + comment trong code bằng tiếng Anh, trừ note giải thích thì tiếng Việt.

### 0.1 Bối cảnh repo

Project **trống**, vừa `flutter create`, chưa có gì. Đây là greenfield, KHÔNG phải migrate.
Máy dev chạy Flutter **3.44.5**; CI đang pin **3.38.9** (mặc định template) → nâng cho khớp ở Phase 0.

### 0.2 Các quyết định đã chốt sau review v2 — KHÔNG mở lại

| # | Vấn đề | Chốt |
|---|---|---|
| 1 | Inline fragment shader không tồn tại — `FragmentProgram` chỉ load từ asset `.frag`, khai báo ở key `shaders:` (KHÔNG phải `assets:`) | Seed Phase 1 dùng `ui.Gradient.sweep/linear` — trả `Shader` thật, thỏa contract §2.3, zero asset. GLSL để sau, khi có thì bắt buộc `portability: folder_with_assets` và khai báo ở `shaders_required` (field riêng, vì pubspec key khác) |
| 2 | App không đọc được Flutter version của máy lúc runtime (APK trên Android không có flutter CLI) | `build_index.dart` đóng dấu `_generated_flutter` / `_generated_dart` vào `index.json`. App cho user **chọn target version** (default = dấu này, lưu Hive). Cái cần so là Flutter của project sắp paste vào, không phải máy build index |
| 3 | `created_deps` vừa bất biến vừa bị dùng làm whitelist import | Tách: `created_deps` thuần khảo cổ (bất biến), thêm `deps` mutable — validate check `deps` |
| 4 | Freezed cần build_runner | Bỏ Freezed, viết model immutable tay + `fromJson` (~15 field). *Lưu ý: v2 chỉ cấm codegen CHO REGISTRY, không cấm toàn cục — đây không phải mâu thuẫn spec, chỉ là lựa chọn giảm setup* |
| 5 | `status: stale` là hàm của "hôm nay", không thể đóng băng vào index | `status` chỉ lưu `verified` / `needs_patch` / `broken` (kết quả lần verify cuối). `stale` do app tính runtime từ `last_verified` |
| 6 | Asset của Flutter không đệ quy → `- components/` không lấy subfolder | KHÔNG chèn từng dòng pubspec mỗi component. Thay bằng: `build_index.dart` sinh `assets/sources/<id>.json` chứa source text. pubspec chỉ cần **2 dòng cố định vĩnh viễn**. Xem §5.0 |
| 7 | Không script nào ghi block `files:` dù spec nói "đừng gõ tay" | `validate.dart --fix` rewrite block `files:` từ import graph thật |
| 8 | "Entry re-export mọi thứ public" không verify máy móc được | Đổi thành 2 luật kiểm được: (a) entry tồn tại + trùng tên folder + có ≥1 public symbol; (b) mọi `_*.dart` phải reachable từ entry trong import graph — không có file mồ côi |
| 9 | Diff manifest so cả chuỗi mô tả → giòn | Chỉ so **tập tên file**. Mô tả là free text, không so |
| 10 | `<id>_demo.dart` bị luật portability chặn | Miễn trừ khỏi luật portability. Không nằm trong `files:`. Vẫn check nó không import bậy ra ngoài repo |
| 11 | Badge compat thiếu luật so version | Khớp chính xác dòng Test History có Flutter == target version. Không có → so `latest_known_good`: `>= target` → 🟢, `< target` → 🟡 unknown-on-this-version. 🔴 chỉ khi có dòng `fail` ở version ≤ target và không có dòng `pass` nào ở version cao hơn |
| 12 | `flutter_markdown` đã bị Flutter team discontinue (30/4/2025) | Dùng `flutter_markdown_plus` (Foresight Mobile, bản kế nhiệm chính thức). Không cân nhắc lại |
| 13 | `index.json` gitignore hay commit? | **Commit.** CI build APK không chạy `build_index.dart`, thiếu file là vỡ build. Chặn stale bằng `validate.dart` trong CI |
| 14 | `registry.dart` relative-import ra ngoài `lib/` — rủi ro tooling | Đặt vault ở **`lib/components/`**, không ở root. Vì `components/` không còn cần là asset (xem #6), lợi ích duy nhất của root chỉ là thẩm mỹ thư mục — không đáng đổi lấy rủi ro analyzer/CI. Ranh giới "vault vs viewer" do `validate.dart` enforce, không do vị trí thư mục |
| 15 | `--files=n` nghĩa là gì | entry + (n−1) file `_part.dart` placeholder |
| 16 | `preview.gif` | Phục vụ người xem repo trên GitHub. App KHÔNG dùng (§1 bắt render widget thật). Hai đối tượng đọc khác nhau, không mâu thuẫn |

---

## 1. MỤC TIÊU SẢN PHẨM

Tôi sưu tầm component / background / animation / effect Flutter từ trên mạng và muốn quản lý chúng có hệ thống để tái sử dụng.

> Sản phẩm thật là **cái vault**. App Flutter chỉ là **mục lục có hình** (visual index).

Tôi KHÔNG copy code từ trong app. Tôi browse app để nhớ mình có gì và nó trông thế nào, rồi tự mở folder trong project lấy mang đi.

**Giả định thiết kế trung tâm: 6 tháng sau tôi không nhớ gì cả.** Mọi quyết định phải kiểm chứng được bằng script, không dựa vào việc tôi nhớ hay tôi kỷ luật. Comment sẽ rot. Cái gì quan trọng thì phải có script verify.

### 1.1 Platform target — ẢNH HƯỞNG NHIỀU QUYẾT ĐỊNH BÊN DƯỚI

**Android / mobile là chính.** iOS giữ lại nhưng không ưu tiên. Web/macOS/Linux/Windows: xoá folder ở Phase 0.

Hệ quả phải nắm:
- **Perf budget chặt hơn nhiều.** `saveLayer` và animated paint trên GPU mobile đắt hơn desktop đáng kể. §9.2 chuyển từ "nên làm" sang **bắt buộc**.
- **Grid 2 cột**, thumbnail nhỏ → bẫy scale (§9.1) lộ ra sớm và rõ hơn desktop. Đây là điểm tốt: nếu paint vẫn đẹp ở thumbnail mobile thì nó thật sự scale được.
- **App tách rời khỏi nơi viết code.** Tôi browse trên điện thoại, nhưng file thì lấy trên máy tính. → Cần affordance "gửi sang máy": share sheet gửi `id` + block paste-ready (§8.6). Cái này quan trọng hơn tab Code trên mobile.
- Carrier switcher: chip phải scroll ngang, không wrap.
- Tab Code: monospace nhỏ + scroll ngang. Chấp nhận khó đọc — nó chỉ để liếc 20 dòng quyết định "có đúng cái mình cần không".

**Hệ quả thiết kế chung:**
- KHÔNG làm knobs/tweak param runtime (trừ ngoại lệ §8.4).
- KHÔNG làm plugin system / thêm component lúc runtime. Dart không compile runtime. Đây là dev-time tool: paste file → chạy script → hot restart.
- Render preview bằng **widget thật**, không dùng screenshot tĩnh. App không được phép hiển thị sai so với code.

---

## 2. TAXONOMY — PHẦN DỄ HIỂU SAI NHẤT

### 2.1 `background` KHÔNG phải một category

Nó là **paint source**. Còn text / button / card là **carrier** (thứ nhận paint). Hai trục độc lập:

- **Paint** (nguồn hình): gradient mesh, aurora, noise, particle, animated blob
- **Carrier** (thứ nhận paint): `fullscreen`, `card`, `button`, `text`, `border`, `icon`, `divider`
- **Effect** (trục 3, bọc lên bất kỳ combo nào): glow, blur, glass, grain

Một paint đẹp có thể phủ 6 carrier → một component sưu tầm sinh ra 6 lần giá trị. Đó là lý do trục này tồn tại.

### 2.2 Paint nào với tới được carrier nào

| Paint dạng | Với tới carrier | Cơ chế |
|---|---|---|
| `Shader` (`ui.Gradient.*`, `ImageShader`, `FragmentProgram`) | **Tất cả**, kể cả `text` | `ShaderMask` + `BlendMode.srcIn` |
| `CustomPainter` | Hình khối dễ; `text` khó | `ClipPath` cho shape; text cần `saveLayer` + `BlendMode.dstIn` |
| Widget tree (Stack blob động) | Hình khối OK; `text` rất đắt | Clip cho shape; text phải capture layer |

**Kết luận:** paint nào biểu diễn được dưới dạng `Shader` thì tái dụng cao nhất. Tiêu chí khi sưu tầm: gặp 2 background đẹp bằng nhau thì ưu tiên cái shader hóa được.

### 2.3 Contract cho paint dạng shader

Nếu paint biểu diễn được bằng `Shader`, entry file nên **expose factory trả `Shader`** thay vì chỉ trả Widget. Khi đó carrier dùng `ShaderMask` chuẩn của Flutter → **không cần file combinator nào**, và tự động với tới mọi carrier.

Đừng cưỡng ép contract này lên `CustomPainter`/widget tree. Khai báo trung thực ở `paint_source` + `carriers_verified`.

**Cảnh báo GLSL** (quyết định #1): `FragmentProgram` chỉ load được từ file `.frag` khai báo ở key `shaders:` trong pubspec — không có cách inline GLSL string. Điều này phá tính tự đủ của folder, nên GLSL luôn là `portability: folder_with_assets`. Seed Phase 1 dùng `ui.Gradient.sweep`/`linear` để có `Shader` thật mà zero asset.

---

## 3. HỢP ĐỒNG PORTABILITY — ĐƠN VỊ LÀ **FOLDER**

Component đơn giản (1 file) và component phức tạp kết hợp nhiều paint/animation (nhiều file) đều phải tái dụng được. Vì vậy:

> **Đơn vị portability là folder.** Hành động tái dụng luôn là "copy cả folder", không bao giờ là "copy file nào và file nào".

### 3.1 Luật cứng

1. **Cấm relative import vượt ra khỏi folder của nó.** Trong cùng folder thì import nhau tự do.
2. Chỉ import `dart:*`, `package:flutter/*`, hoặc package pub đã khai báo ở frontmatter **`deps`** (không phải `created_deps`).
3. **Entry file trùng tên folder**, có ≥1 public symbol. Project đích chỉ import 1 dòng dù folder có 8 file.
4. **File phụ prefix `_`**, và **phải reachable từ entry** trong import graph. Không có file mồ côi.
5. **Không tham chiếu theme/constant/util của app này.** Style qua constructor param có default, hoặc `Theme.of(context)`.
6. **Không global state, không DI, không Riverpod/GetIt/singleton bên trong.** Data vào qua param, event ra qua callback.
7. Tên public class tránh trùng phổ biến (`GlassCard` chứ không `Card`).
8. **Không phụ thuộc asset ngoài.** Nếu buộc phải có: khai báo `assets_required` (key `assets:`) hoặc `shaders_required` (key `shaders:`) — **hai key pubspec khác nhau, đừng gộp** — và đặt `portability: folder_with_assets`.
9. `<id>_demo.dart` **miễn trừ** khỏi luật 1–8. Không nằm trong `files:`. Vẫn bị check không import bậy ra ngoài repo.

### 3.2 Manifest — thứ thật sự cứu tôi khi không nhớ gì

Comment header một mình KHÔNG đủ, vì comment rot. Cần **manifest mà máy kiểm tra được** (frontmatter `portability` / `entry` / `files`).

`validate.dart` **dựng import graph thật từ code** rồi diff **tập tên file** với manifest (không so chuỗi mô tả — free text, so sẽ giòn). Lệch → fail. `validate.dart --fix` rewrite block `files:` từ graph thật.

> **Đây là điểm mấu chốt của cả spec: manifest không thể nói dối, vì nó bị verify chứ không phải được tin.**

Comment header vẫn giữ nhưng hạ cấp xuống "tiện khi mở file lẻ", không phải nguồn sự thật.

### 3.3 File phụ hữu ích chung → dùng VENDORING

| | Ưu | Nhược |
|---|---|---|
| **Vendoring** (nhân bản vào cả 2 folder) ✅ **CHỌN** | Mỗi folder tự đủ 100% | Fix bug phải fix 2 chỗ |
| `internal_deps` (folder A require folder B) ❌ | Không trùng code | Phá tính tự đủ, sinh dependency graph — đúng cái đang muốn tránh |

Ghi `vendored_from: <id>` để biết mà đồng bộ. **Không implement cơ chế `internal_deps`.**

---

## 4. CẤU TRÚC REPO

```
snipz/
├── lib/
│   ├── main.dart
│   ├── app/                    # router, theme, shell
│   ├── core/                   # models, index loader, compat resolver, carrier hosts
│   ├── features/
│   │   ├── gallery/            # grid, search, filter, badge
│   │   └── detail/             # preview stage, carrier switcher, code/files/info tabs, share
│   ├── registry.dart           # barrel: map id -> ComponentDemo
│   └── components/             # ★ VAULT (trong lib/ — quyết định #14)
│       ├── glass_card/                 # ví dụ single-file
│       │   ├── glass_card.dart         # entry, portable
│       │   ├── glass_card_demo.dart
│       │   ├── README.md
│       │   └── preview.gif             # cho GitHub, app không dùng
│       └── aurora_stack/               # ví dụ multi-file
│           ├── aurora_stack.dart       # entry, re-export
│           ├── _noise_layer.dart
│           ├── _blob_painter.dart
│           ├── aurora_stack_demo.dart
│           └── README.md
├── assets/                     # TẤT CẢ đều GENERATED — không sửa tay
│   ├── index.json              # metadata mọi component, COMMIT vào git
│   └── sources/
│       └── <id>.json           # source text các file của component đó
├── tools/
│   ├── new_component.dart
│   ├── verify.dart
│   ├── validate.dart
│   ├── build_index.dart
│   └── export.dart
└── pubspec.yaml
```

**pubspec `assets:` chỉ cần 2 dòng, CỐ ĐỊNH VĨNH VIỄN:**
```yaml
assets:
  - assets/index.json
  - assets/sources/
```
Asset của Flutter không đệ quy, nhưng `assets/sources/*.json` là **con trực tiếp** nên hợp lệ. Thêm component KHÔNG bao giờ phải đụng pubspec. Đây là lý do chọn cách này thay vì chèn `- lib/components/<id>/` mỗi lần (quyết định #6).

---

## 5. README.md — SINGLE SOURCE OF TRUTH

Metadata **chỉ tồn tại ở frontmatter của README.md**. `demo.dart` chỉ cung cấp builder.
Lý do: metadata nằm 2 chỗ thì sau 50 component chắc chắn lệch.
Đánh đổi: MD sai cú pháp → app hỏng. Vì vậy `validate.dart` bắt buộc, chạy trước commit.

### 5.0 Mỗi component có README RIÊNG — app không parse trực tiếp chúng

**KHÔNG có file README tổng nào.** Mỗi folder có `README.md` của riêng nó (~60–100 dòng), chỉ nói về đúng component đó. Thêm component nghĩa là thêm file, không làm dài file cũ.

Nhưng app **không được** quét và parse N file README lúc khởi động. 100 component = 100 lần async read + 100 lần parse YAML trước khi gallery hiện → startup ì trên Android, và lỗi parse ở component thứ 73 rất khó truy.

**Chiến lược load — implement ngay Phase 1** (nó quyết định cách `core/` load dữ liệu; làm sau phải viết lại lớp đó):

| Tầng dữ liệu | Nguồn | Khi nào đọc |
|---|---|---|
| Metadata mọi component (gallery, search, filter, badge) | `assets/index.json` — **1 file duy nhất** | Lúc khởi động |
| README đầy đủ (API, caveats, changelog, test history, AI prompt) | Trường `readme_body` trong `assets/sources/<id>.json` | **Lazy** — khi mở detail |
| Source code từng file | Trường `files` trong `assets/sources/<id>.json` | **Lazy** — cùng lúc trên, khi mở detail |

Quan hệ, phải nắm rõ:
- `lib/components/*/README.md` và `*.dart` **là source of truth**.
- `assets/index.json` + `assets/sources/*.json` là **artifact dẫn xuất**, sinh bởi `build_index.dart`. **Không bao giờ sửa tay.** Đầu file ghi `"_generated": true` + timestamp + `_generated_flutter` / `_generated_dart`.
- **COMMIT cả hai vào git** (quyết định #13). CI build APK không chạy `build_index.dart`.

Đánh đổi: artifact có thể stale nếu quên regen. Chặn bằng check trong `validate.dart` + pre-commit hook + CI.

### 5.1 Ba tầng thông tin, ba vòng đời — KHÔNG được trộn

| Tầng | Nội dung | Vòng đời |
|---|---|---|
| **1. Creation snapshot** | Ngày tạo, Flutter/Dart version lúc tạo, `created_deps` đã resolve, nguồn gốc, platform thử ban đầu | **Bất biến.** Ghi một lần, không bao giờ sửa. Dữ liệu khảo cổ — 2 năm sau cần biết "cái này viết ở thời Flutter nào" để đoán tại sao nó vỡ. **KHÔNG dùng làm whitelist import** (quyết định #3) |
| **2. Component version** | Semver của **chính component** + changelog + `deps` hiện tại | Tăng khi tôi tự sửa/nâng cấp. **Khác hoàn toàn với version Flutter đã test.** Không có tầng này thì không phân biệt được "chết vì Flutter mới" với "tôi đã tự fix và bản ở project X là bản cũ" |
| **3. Test history** | Bảng, mỗi dòng một lần verify | **Append-only.** Chỉ thêm dòng, không xóa/ghi đè. Lịch sử "từng vỡ ở 3.24 rồi fix ở 3.27" là thông tin giá trị nhất |

### 5.2 Template README.md

```markdown
---
# --- IDENTITY (bắt buộc) ---
id: aurora_stack
title: Aurora Stack
kind: paint                  # paint | carrier | effect | composite
tags: [aurora, shader, animated]

# --- TAXONOMY (§2) ---
paint_source: shader         # shader | painter | widget | none
carriers_verified: [fullscreen, card, button, text]
carriers_failed:
  - icon: "chi tiết noise biến mất dưới 32px"
scale_aware: true

# --- PORTABILITY (§3 — block files do script ghi, đừng gõ tay) ---
portability: folder          # single_file | folder | folder_with_assets
entry: aurora_stack.dart
files:
  - aurora_stack.dart: "entry, public API"
  - _noise_layer.dart: "required by entry"
  - _blob_painter.dart: "required by _noise_layer"
vendored_from: null
assets_required: []          # khai báo ở pubspec key `assets:`
shaders_required: []         # khai báo ở pubspec key `shaders:` — KHÁC key, đừng gộp

# --- DEPS HIỆN TẠI (mutable — validate check CÁI NÀY) ---
deps:
  - blur: ^4.0.1

# --- ORIGIN (bắt buộc) ---
source: https://...
author: "Tên tác giả gốc"
license: MIT                 # hoặc unknown
adapted: true

# --- CREATION SNAPSHOT (bất biến, script tự điền, thuần khảo cổ) ---
created: 2026-08-17
created_flutter: 3.44.5
created_dart: 3.9.0
created_deps:                # LUÔN từ pubspec.lock, KHÔNG từ pubspec.yaml
  - blur: 4.0.1
platforms_initial: [android]

# --- COMPONENT VERSION ---
version: 1.1.0

# --- DERIVED (script tự tính từ Test History, đừng gõ tay) ---
latest_known_good: 3.44.5
last_verified: 2026-08-17
status: verified             # verified | needs_patch | broken
                             # KHÔNG có `stale` — app tính runtime từ last_verified (quyết định #5)

preview: preview.gif
---

# Aurora Stack

Mô tả 2-3 dòng: nó là gì, dùng khi nào, trông thế nào.

## Install

```yaml
# copy-paste thẳng vào pubspec.yaml
dependencies:
  blur: ^4.0.1
```

Mục tiết kiệm thời gian nhất trong cả file — snippet phải copy-paste được luôn.

## Reuse

- **Copy:** cả folder `aurora_stack/` (3 file dart, xem `files`)
- **Import:** `import 'aurora_stack/aurora_stack.dart';` — 1 dòng
- **Hoặc:** `dart tools/export.dart aurora_stack` → zip + block paste-ready

## API

| Param | Type | Default | Ý nghĩa |
|---|---|---|---|
| `scale` | `double` | `1.0` | Tỉ lệ chi tiết paint. Giảm khi dùng ở carrier nhỏ |

## Carriers

Chỉ ghi cái đã verify thật, không hứa suông.

| Carrier | Result | Note |
|---|---|---|
| fullscreen | pass | mặc định |
| card | pass | — |
| button | pass_warning | cần `scale: 0.3` nếu không thành vệt phẳng |
| text | pass | ShaderMask + srcIn, đắt frame trên mobile |
| icon | fail | quá nhỏ, mất chi tiết |

## Caveats

- Platform: ...
- Perf: ...
- Known issues: ...

## Changelog

- **1.1.0** (2026-08-17) — thêm param `scale`, verify carrier text
- **1.0.0** (2026-08-17) — import từ nguồn gốc

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|
| 2026-08-17 | 3.44.5 | 3.9.0 | blur 4.0.1 | android | pass | — |
| 2026-05-02 | 3.32.0 | 3.8.0 | blur 4.0.0 | android | needs_patch | `withOpacity` deprecated, xem changelog 1.1.0 |

**Result là 4 trạng thái, không phải pass/fail nhị phân:**
`pass` | `pass_warning` (có deprecation) | `needs_patch` (kèm mô tả patch) | `fail`

## AI Integration Prompt

<xem §7>
```

---

## 6. FILE DEMO — HAI CÔNG DỤNG

`<id>_demo.dart` không portable nên tự do. Nó có **hai** nhiệm vụ, đừng bỏ nhiệm vụ thứ hai:

1. Cung cấp builder để app render preview/thumbnail.
2. Là **usage example tử tế** khi tôi copy component sang project khác — viết như code mẫu production, không phải scratchpad.

```dart
final auroraStackDemo = ComponentDemo(
  id: 'aurora_stack',
  builder: (context) => ...,              // preview mặc định
  thumbnailBuilder: (context) => ...,     // optional, nếu preview chính quá nặng cho grid mobile
  carrierBuilders: {                      // optional, chỉ cho kind: paint
    Carrier.card: (context) => ...,
    Carrier.button: (context) => ...,
  },
);
```

Nếu paint tuân contract shader (§2.3) thì `carrierBuilders` để rỗng — app tự dựng carrier bằng `ShaderMask` từ factory shader mà entry expose. Đó là đường tốt hơn; `carrierBuilders` chỉ là fallback cho paint không shader hóa được.

Metadata **không** nằm trong file này.

---

## 7. KHỐI "AI INTEGRATION PROMPT" TRONG README

**Không phải** "hãy giải thích component này". Nó là **chỉ thị tích hợp** — thứ tôi paste vào Claude Code ở project đích để nó tự lắp vào.

Chuẩn hóa theo **một template dùng chung**, chỉ thay phần cụ thể. Mỗi component tự viết prompt kiểu tự do thì sau 30 cái không dùng được cái nào. `new_component.dart` sinh sẵn khung này.

```markdown
## AI Integration Prompt

Tích hợp component `AuroraStack` vào project này.

**Context**
- Chức năng: <1-2 dòng>
- Public API: <constructor params + ý nghĩa>
- Portability: folder — copy cả `aurora_stack/` (3 file), import duy nhất `aurora_stack.dart`
- Deps: <list>

**Việc cần làm**
1. Thêm vào pubspec.yaml: <snippet>
2. Copy cả folder `aurora_stack/` vào <thư mục widget của project đích>
3. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project
- `scale`: nếu dùng ở carrier nhỏ (button/icon), giảm scale — xem bảng Carriers
- State management: nối callback vào state layer của project
- Naming convention: đổi tên nếu project có convention khác

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling entry point (constructor params).
- KHÔNG tách entry file ra nhiều file "cho gọn". KHÔNG gộp các file `_*.dart` lại.
- KHÔNG bỏ bớt file — cả 3 đều required, xem `files`.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version project thấp hơn `latest_known_good` → đọc Test History trước.
```

---

## 8. APP VIEWER

### 8.1 Registry
Flutter không có reflection. Dùng **barrel file thủ công** `lib/registry.dart` (map `id` → `ComponentDemo`), do `new_component.dart` tự chèn. **Không build_runner/codegen cho registry** — setup nặng, không đáng cho ~100 component.

### 8.2 Target Flutter version (quyết định #2)
App **không đọc được** Flutter version của máy lúc runtime. Thay vào đó:
- `index.json` mang `_generated_flutter` (version của máy lúc build index)
- Settings có dropdown **"Target Flutter version"**, default = `_generated_flutter`, lưu Hive
- Mọi badge compat và filter so với **target này**

Lý do dropdown thay vì hardcode: cái tôi thực sự cần biết là "component này chạy được trên **project tôi sắp paste vào**", mà project đó có thể pin version khác máy build.

### 8.3 Gallery (mobile-first)
- **Grid 2 cột**, thumbnail nhỏ. Search theo title/tag; filter theo `kind` + `status` + `carriers_verified` + compat
- Load **duy nhất** `assets/index.json` lúc khởi động
- Favorite (Hive)
- Thumbnail render widget thật: `RepaintBoundary` + cache snapshot. Paint động **bắt buộc pause khi ra khỏi viewport** — trên Android đây không phải tối ưu, đây là điều kiện để app dùng được
- Không bao giờ render carrier `text` trong thumbnail (§9.2)

### 8.4 Hai loại badge — payoff bắt buộc

Metadata chỉ đáng viết nếu app **tự suy ra trạng thái**. Nếu chỉ để đọc bằng mắt thì sau 20 component tôi sẽ bỏ.

**Badge tương thích** — luật so version (quyết định #11):
1. Có dòng Test History với Flutter == target → dùng `result` của dòng đó
2. Không có → so `latest_known_good`: `>= target` → 🟢 ; `< target` → 🟡 unknown-on-this-version
3. 🔴 broken chỉ khi có dòng `fail` ở version ≤ target và **không** có dòng `pass` ở version cao hơn
4. 🟡 stale: `last_verified` quá 6 tháng so với **hôm nay** — tính runtime, không đọc từ index

**Badge chi phí tái dụng** (từ `portability`):
- 🟦 `single_file` — paste 10 giây
- 🟨 `folder (n files)`
- 🟥 `folder + assets`

Tôi cần quyết định được "hôm nay chỉ muốn cái nào paste 10 giây" **trước khi** mở detail.

### 8.5 Detail screen

**Preview stage theo `kind`:**
- `paint` → Carrier Switcher (bên dưới)
- `carrier` / `composite` → khung có padding, đổi light/dark/checkerboard
- `effect` → target mẫu để bọc lên, toggle on/off so sánh

**Carrier Switcher** (`kind: paint`): hàng chip **scroll ngang** (mobile, không wrap): `Fullscreen | Card | Button | Text | Border | Icon`.

> Meta-note cho người implement: cái này **mâu thuẫn có chủ ý** với "không làm knobs" ở §1. Knobs là tweak param — làm ở project đích được. Carrier switcher là **phát hiện khả năng tái dụng** — chỉ làm được ở đây, nơi có sẵn cả bộ carrier để so sánh. **Ngoại lệ chỉ áp dụng cho carrier switcher, không mở rộng sang knobs khác.**

Chip có 3 state: verified (bình thường) / failed (disabled + tooltip lý do từ `carriers_failed`) / untested (mờ, tap để thử).

**Tab Files**: cây file + vai trò (từ `files`), tap xem code. Single-file thì ẩn tab.
**Tab Code**: từ `assets/sources/<id>.json`. Monospace + scroll ngang. Giữ nhẹ.
**Tab Info**: render `readme_body` bằng `flutter_markdown_plus`.

Toggle chung: dark/light, checkerboard, (device frame optional trên mobile — màn hình đã nhỏ).

### 8.6 Share — quan trọng vì app ở trên điện thoại, code ở trên máy tính

Nút Share ở detail, gửi qua share sheet Android:
- `id` + tên component
- Block paste-ready (deps snippet, import statement, danh sách file cần copy, scale hint)
- Link tới file trên GitHub nếu repo có remote

Không có cái này thì tôi phải tự gõ lại tên component sang máy tính — đủ khó chịu để tôi ngừng dùng app.

### 8.7 Storage
Metadata là asset-time → **không cần DB**. Hive chỉ lưu state cá nhân: favorite, note, custom tag, recently viewed, target Flutter version.

---

## 9. HAI CÁI BẪY BẮT BUỘC XỬ LÝ

### 9.1 Scale — chỗ non-obvious nhất
Paint thiết kế cho fullscreen có chi tiết ở tỉ lệ fullscreen. Nhét vào button 48px thì noise/particle thành vệt màu phẳng, aurora thành cục xám. **Không phải lỗi kỹ thuật mà là lỗi thẩm mỹ.**

Hệ quả: file portable phải nhận param `scale` hoặc `bounds` hint **ngay từ khi tôi lưu component**. Không thì sau này phải sửa lõi. Field `scale_aware` track việc này; `validate.dart` warning (không fail) nếu `kind: paint` mà `scale_aware: false`.

Trên mobile grid 2 cột, bẫy này lộ ra ngay ở thumbnail — coi đó là lợi thế, không phải phiền toái.

### 9.2 Perf cliff — BẮT BUỘC trên mobile, không phải tùy chọn
Mask text lên paint động = `saveLayer` mỗi frame. Trên GPU Android tầm trung, vài cái cùng lúc là tụt frame thấy rõ.

- Carrier `text` **lazy tuyệt đối**: chỉ render khi tôi chủ động tap chip đó. Không bao giờ trong thumbnail.
- Paint động ngoài viewport phải **pause**, không chỉ ẩn.
- Thumbnail cache snapshot, không re-render mỗi lần scroll.
- Nếu component có animation controller, demo phải expose cách dừng — app không được để 20 controller chạy ngầm.

---

## 10. SCRIPTS (`tools/`) — PHASE 1, KHÔNG PHẢI PHASE 3

Đây là loại tính năng **chết vì ma sát tay**, không chết vì kỹ thuật. Không có script, tôi bỏ ngang sau 10 component.

### `new_component.dart <id> <kind> [--files=n]`
Sinh folder + skeleton (entry, demo, README) đã điền sẵn frontmatter (tự đọc `flutter --version` và `pubspec.lock`), sinh sẵn khung AI Integration Prompt, chèn entry vào `registry.dart`, **rồi tự gọi `build_index.dart`**.
`--files=n` = entry + (n−1) file `_part.dart` placeholder.

### `verify.dart <id>`
**Nguyên tắc cứng: KHÔNG BAO GIỜ gõ version bằng tay.**
Tự đọc `flutter --version` + `pubspec.lock`, append một dòng vào Test History, cập nhật `latest_known_good` / `last_verified` / `status`, **rồi tự gọi `build_index.dart`**. Tôi chỉ gõ `result` + `note`.

`pubspec.yaml` chứa range (`^1.2.0`) — **không phải sự thật**. Cái làm component vỡ là version đã resolve. Luôn snapshot từ `pubspec.lock`.

### `validate.dart [--fix]`
Script quan trọng nhất. Check:
1. **Import graph thật vs manifest** — parse import mọi file trong folder, dựng graph, diff **tập tên file** với `files`. Lệch → fail. `--fix` rewrite block `files:` từ graph
2. **Portability** — không relative import vượt folder; không import package ngoài `deps` (KHÔNG phải `created_deps`)
3. **Entry** — tồn tại + trùng tên folder + có ≥1 public symbol
4. **Không file mồ côi** — mọi `_*.dart` reachable từ entry
5. **Naming** — file phụ có prefix `_`; `<id>_demo.dart` miễn trừ luật portability nhưng vẫn check không import bậy ra ngoài repo
6. **Frontmatter schema** — field bắt buộc, enum `kind`/`status`/`result`/`portability`/carrier, format ngày. `status` KHÔNG được có giá trị `stale`
7. **Registry sync** — khớp folder thực tế
8. **Artifact sync** — `index.json` và `sources/*.json` khớp README + source thực tế. Stale → fail, gợi ý chạy `build_index.dart`
9. **Warning** (không fail) — `kind: paint` mà `scale_aware: false`

Exit code khác 0 nếu fail → pre-commit hook + CI.

### `build_index.dart`
Quét mọi `lib/components/*/README.md`, sinh:
- `assets/index.json` — gom frontmatter mọi component + `_generated: true` + timestamp + `_generated_flutter` / `_generated_dart`
- `assets/sources/<id>.json` — `readme_body` (phần dưới frontmatter) + map filename → source text

Artifact dẫn xuất, **không sửa tay**, **commit vào git**.
Frontmatter parse lỗi: báo rõ **id nào, dòng nào**, không nuốt lỗi rồi bỏ qua component.

### `export.dart <id>`
Ăn tiền hơn mọi comment. Xuất zip đúng folder + in block paste-ready: deps snippet, import statement, asset/shader cần khai báo (đúng key pubspec), caveat, scale hint. **Tôi không cần đọc hiểu gì, chỉ copy.**

---

## 11. TECH STACK

- Flutter 3.44.5, Dart 3
- **Riverpod** — state management
- **go_router** — routing. `CustomTransitionPage` fade cho mọi route (tránh scrim layer của `ZoomPageTransitionsBuilder` gây flash khi Scaffold background trong suốt)
- **Hive** — favorite/note/settings (JSON string)
- **KHÔNG Freezed** — model immutable viết tay + `fromJson` (~15 field, không đáng kéo build_runner vào)
- `yaml` — parse frontmatter (chỉ trong `tools/`, app đọc JSON)
- **`flutter_markdown_plus`** — render README. `flutter_markdown` gốc đã bị Flutter team discontinue; đây là bản kế nhiệm chính thức. Không cân nhắc lại

---

## 12. ROADMAP

**Phase 0 — Dọn project trống**
Xoá platform folder không dùng (giữ `android`, `ios`; bỏ web/macOS/linux/windows). Nâng CI pin 3.38.9 → 3.44.5. Thay `widget_test.dart` mặc định. `analysis_options.yaml` chế độ nghiêm (làm ngay khi chưa có code cũ phải sửa; thứ gì analyzer bắt được thì đừng viết lại trong `validate.dart`). Thêm step `dart tools/validate.dart` vào CI.
→ *Verify:* `flutter build apk --debug` pass; CI xanh.

**Phase 1 — Xương sống + scripts**
Model + index loader, pipeline `index.json` + `sources/*.json` (§5.0), `registry.dart`, 5 script, 3 seed (1 single-file, 1 multi-file, 1 paint dùng `ui.Gradient.sweep`).
→ *Verify:*
- `new_component.dart test_x paint` sinh skeleton + chèn registry + regen artifact
- `validate.dart` pass
- Xoá một dòng trong `files:` → validate **FAIL** (chứng minh import graph check chạy thật)
- Sửa tay `index.json` cho lệch README → validate **FAIL** (chứng minh artifact sync check chạy thật)
- Tạo file `_orphan.dart` không ai import → validate **FAIL**
- `validate.dart --fix` khôi phục đúng block `files:`
- `verify.dart test_x` append đúng dòng + regen
- `export.dart test_x` ra zip + block paste-ready

**Phase 2 — App viewer cơ bản**
Gallery grid 2 cột (load từ `index.json`) + thumbnail widget thật + detail preview stage theo `kind` + tab Info (lazy).
→ *Verify:* 3 seed hiện đúng thumbnail trên máy Android thật; mở detail render đúng; light/dark không lỗi. **Gallery chỉ đọc đúng 1 asset lúc khởi động** — assert số lần `rootBundle.loadString` trước khi grid render lần đầu.

**Phase 3 — Carrier switcher**
`ShaderMask` pipeline cho paint shader, `carrierBuilders` fallback, chip scroll ngang 3 state, lazy carrier `text`, `scale` wire vào switcher.
→ *Verify:* seed paint shader áp được lên card/button/text mà **không** cần viết `carrierBuilders`; chip `text` không render tới khi tap; chip `icon` disabled + tooltip lý do.

**Phase 4 — Metadata & compat**
Search, filter, 2 loại badge, dropdown target Flutter version, favorite.
→ *Verify:* sửa tay Test History thành `fail` → badge đổi 🔴 và bị lọc khỏi filter compat; đổi target version trong settings → badge đổi theo; component multi-file hiện 🟨 kèm số file đúng; component `last_verified` 8 tháng trước hiện 🟡 stale.

**Phase 5 — Hoàn thiện**
Tab Code + Files, share sheet (§8.6), checkerboard, pause paint ngoài viewport, pre-commit hook, seed 10 component thật.
→ *Verify:* scroll gallery 20+ component trên Android thật không tụt frame (đo bằng DevTools, không đo bằng cảm giác); commit với frontmatter sai bị chặn; share sheet ra đúng block paste-ready.

---

## 13. BẮT ĐẦU

1. Đọc hết spec. Nêu assumption + điểm nào thấy mâu thuẫn hoặc thiếu. **Lưu ý §0.2 là các quyết định đã chốt sau một vòng review — không mở lại, trừ khi phát hiện chúng sai về mặt kỹ thuật.**
2. Đề xuất kế hoạch Phase 0 + Phase 1 dạng `bước → cách verify`.
3. Chờ tôi ok, rồi implement.

Tên project: **Snipz**.