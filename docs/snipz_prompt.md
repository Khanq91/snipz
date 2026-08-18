# PROMPT BÀN GIAO — Snipz (Flutter Component Vault)

> Paste toàn bộ file này vào session Claude mới (khuyến nghị Claude Code) để bắt đầu implement.
> Version spec: v2 (đã gộp taxonomy paint/carrier + multi-file folder).

---

## 0. VAI TRÒ & CÁCH LÀM VIỆC

Bạn là Flutter engineer implement một dev-tool cá nhân từ spec dưới đây.

**Cách làm việc mong đợi:**
- Đọc hết spec trước khi viết dòng code đầu tiên. Nêu assumption và điểm mâu thuẫn (nếu có) TRƯỚC khi implement, không im lặng tự quyết.
- Làm theo phase. Kết thúc mỗi phase phải chạy được và verify được, rồi mới sang phase sau.
- Ưu tiên code tối thiểu giải quyết đúng vấn đề. Không thêm abstraction cho code dùng một lần, không thêm "flexibility" không được yêu cầu.
- Không cần hỏi xác nhận từng bước nhỏ. Cứ làm theo spec, chỉ dừng khi spec thực sự thiếu thông tin hoặc tự mâu thuẫn.
- Trả lời bằng tiếng Việt. Code + comment trong code bằng tiếng Anh, trừ note giải thích thì tiếng Việt.

---

## 1. MỤC TIÊU SẢN PHẨM

Tôi sưu tầm component / background / animation / effect Flutter từ trên mạng và muốn quản lý chúng có hệ thống để tái sử dụng.

**Điểm cốt lõi phải hiểu đúng:**

> Sản phẩm thật là **cái repo**. App Flutter chỉ là **mục lục có hình** (visual index).

Tôi KHÔNG copy code từ trong app. Tôi browse app để nhớ mình có gì và nó trông thế nào, rồi tự mở folder trong project lấy mang đi. Toàn bộ giá trị nằm ở chỗ mỗi folder component là một **gói bàn giao tự đủ** (self-contained handoff package).

**Giả định thiết kế trung tâm: 6 tháng sau tôi không nhớ gì cả.** Mọi quyết định phải kiểm chứng được bằng script, không dựa vào việc tôi nhớ hay tôi kỷ luật. Comment sẽ rot (tôi sửa code, quên sửa comment). Vì vậy: cái gì quan trọng thì phải có script verify, không chỉ có comment.

**Hệ quả thiết kế:**
- KHÔNG làm knobs/tweak param runtime (trừ ngoại lệ ở mục 8.4). Tôi tweak ở project đích.
- KHÔNG làm plugin system / thêm component lúc runtime. Dart không compile runtime. Đây là dev-time tool: paste file → chạy script → hot restart.
- Render preview bằng **widget thật**, không dùng screenshot tĩnh. Đây là lý do tồn tại của app — nó không được phép hiển thị sai so với code.

---

## 2. TAXONOMY — ĐỌC KỸ, ĐÂY LÀ PHẦN DỄ HIỂU SAI NHẤT

### 2.1 `background` KHÔNG phải một category

Nó là **paint source**. Còn text / button / card là **carrier** (thứ nhận paint). Đây là hai trục độc lập, không phải một danh sách phẳng:

- **Paint** (nguồn hình): gradient mesh, aurora, noise, particle, fragment shader, animated blob
- **Carrier** (thứ nhận paint): `fullscreen`, `card`, `button`, `text`, `border`, `icon`, `divider`
- **Effect** (trục 3, bọc lên bất kỳ combo nào): glow, blur, glass, grain

Một paint đẹp có thể phủ 6 carrier → một component sưu tầm được sinh ra 6 lần giá trị. Đó là lý do trục này tồn tại.

### 2.2 Paint nào với tới được carrier nào

| Paint dạng | Với tới carrier | Cơ chế |
|---|---|---|
| `Shader` (gradient / `FragmentShader` GLSL) | **Tất cả**, kể cả `text` | `ShaderMask` + `BlendMode.srcIn` |
| `CustomPainter` | Hình khối dễ; `text` khó | `ClipPath` cho shape; text cần `saveLayer` + `BlendMode.dstIn` |
| Widget tree (Stack blob động) | Hình khối OK; `text` đắt | Clip cho shape; text phải capture layer |

**Kết luận thực tế:** paint nào biểu diễn được dưới dạng `Shader` thì có tính tái dụng cao nhất. Đây là tiêu chí khi tôi sưu tầm — gặp 2 background đẹp bằng nhau thì ưu tiên lưu cái viết bằng fragment shader.

### 2.3 Contract khuyến nghị cho paint dạng shader

Nếu paint biểu diễn được bằng `Shader`, file portable nên **expose factory trả về `Shader`** thay vì chỉ trả về Widget. Khi đó carrier dùng `ShaderMask` chuẩn của Flutter → **không cần bất kỳ file combinator nào**, vẫn giữ được 1 file, và tự động với tới mọi carrier.

Đừng cưỡng ép contract này lên paint dạng `CustomPainter`/widget tree. Không phải cái nào cũng shader hóa được. Thay vào đó khai báo trung thực ở frontmatter (`paint_source`, `carriers_verified`).

---

## 3. HỢP ĐỒNG PORTABILITY — ĐƠN VỊ LÀ **FOLDER**, KHÔNG PHẢI FILE

Có component đơn giản (1 file) và có component phức tạp kết hợp nhiều paint/animation (nhiều file). Cả hai đều phải tái dụng được. Vì vậy:

> **Đơn vị portability là folder.** Hành động tái dụng luôn là "copy cả folder", không bao giờ là "copy file nào và file nào".

### 3.1 Luật cứng

1. **Cấm relative import vượt ra khỏi folder của nó.** Trong cùng folder thì import nhau tự do.
2. Chỉ import `dart:*`, `package:flutter/*`, hoặc package pub đã khai báo trong frontmatter.
3. **Một entry file duy nhất, trùng tên folder** (`aurora_stack/aurora_stack.dart`), re-export mọi thứ public. Project đích chỉ cần import 1 dòng, dù folder có 8 file.
4. **File phụ prefix `_`** (`_noise_layer.dart`, `_blob_painter.dart`). Nhìn là biết "cái này không dùng riêng được".
5. **Không tham chiếu theme/constant/util của app này.** Style nhận qua constructor param có default value, hoặc lấy từ `Theme.of(context)`.
6. **Không global state, không DI, không Riverpod/GetIt/singleton bên trong.** Data vào qua param, event ra qua callback.
7. Tên public class tránh trùng lặp phổ biến (`GlassCard` chứ không phải `Card`).
8. **Không phụ thuộc asset ngoài.** Ưu tiên procedural / inline shader string. Nếu buộc phải có, khai báo `assets_required` và đặt `portability: folder_with_assets`.

### 3.2 Manifest — thứ thật sự cứu tôi khi không nhớ gì

Comment header một mình KHÔNG đủ, vì comment rot. Cần **manifest mà máy kiểm tra được** (mục 5.2, các field `portability` / `entry` / `files`).

`validate.dart` phải **dựng import graph thật từ code** rồi diff với manifest. Lệch → fail.
Đây là điểm mấu chốt của cả spec: **manifest không thể nói dối, vì nó bị verify chứ không phải được tin.**

Comment header vẫn giữ nhưng hạ cấp xuống "tiện khi mở file lẻ", không phải nguồn sự thật. Mỗi file phụ ghi 3 dòng: vai trò, được file nào require, có dùng độc lập được không.

### 3.3 File phụ hữu ích chung → dùng VENDORING

Sẽ có lúc `_noise_layer.dart` tự nó đủ hay để dùng ở component khác. Hai đường, và spec này chọn **một**:

| | Ưu | Nhược |
|---|---|---|
| **Vendoring** (nhân bản vào cả 2 folder) ✅ **CHỌN** | Mỗi folder tự đủ 100%, luật không vỡ | Fix bug phải fix 2 chỗ |
| `internal_deps` (folder A require folder B) ❌ | Không trùng code | Phá tính tự đủ, sinh dependency graph — đúng cái tôi đang muốn tránh |

Disk miễn phí; dependency graph mới là thứ khiến 6 tháng sau tôi không lấy được component ra. Khi vendor, ghi `vendored_from: <id>` vào frontmatter để biết mà đồng bộ khi cần. **Không implement cơ chế `internal_deps`.**

---

## 4. CẤU TRÚC REPO

```
snipz/
├── lib/
│   ├── main.dart
│   ├── app/                    # router, theme, shell
│   ├── core/                   # models, frontmatter parser, compat resolver, carrier hosts
│   ├── features/
│   │   ├── gallery/            # grid, search, filter, badge
│   │   └── detail/             # preview stage, carrier switcher, code viewer, files tab, info
│   └── registry.dart           # barrel: map id -> ComponentDemo
├── components/                 # ★ TRÁI TIM CỦA PROJECT
│   ├── glass_card/                     # ví dụ single-file
│   │   ├── glass_card.dart             # entry, portable
│   │   ├── glass_card_demo.dart
│   │   └── README.md
│   └── aurora_stack/                   # ví dụ multi-file
│       ├── aurora_stack.dart           # entry, re-export
│       ├── _noise_layer.dart
│       ├── _blob_painter.dart
│       ├── aurora_stack_demo.dart
│       ├── README.md
│       └── preview.gif
├── assets/
│   └── index.json              # GENERATED — không sửa tay, xem mục 5.0
├── tools/
│   ├── new_component.dart
│   ├── verify.dart
│   ├── validate.dart
│   ├── build_index.dart
│   └── export.dart
└── pubspec.yaml
```

`components/` phải khai báo trong `pubspec.yaml` mục `assets:` để app đọc `.dart` và `.md` dưới dạng text qua `rootBundle` — dùng cho tab Code, tab Files và đọc README đầy đủ lúc mở detail.

---

## 5. README.md — SINGLE SOURCE OF TRUTH

Quyết định kiến trúc then chốt: **metadata chỉ tồn tại ở một chỗ duy nhất là frontmatter của README.md.** `demo.dart` chỉ cung cấp builder.

Lý do: metadata nằm 2 chỗ thì sau 50 component chắc chắn lệch.
Đánh đổi: MD sai cú pháp → app hỏng. Vì vậy `validate.dart` là bắt buộc, chạy trước commit.

### 5.0 Mỗi component có README RIÊNG — và app không parse trực tiếp chúng

**KHÔNG có file README tổng nào cả.** Mỗi folder component có `README.md` của riêng nó, chỉ nói về đúng component đó (~60–100 dòng). File không phình theo số lượng component; thêm component nghĩa là thêm file, không phải làm dài file cũ.

Nhưng app **không được** load bằng cách quét và parse N file README lúc khởi động. 100 component = 100 lần async asset read + 100 lần parse YAML trước khi gallery hiện được → startup ì, và lỗi parse ở component thứ 73 rất khó truy.

**Chiến lược load — implement ngay Phase 1, đừng để sau** (nó quyết định cách `core/` load dữ liệu; làm sau là phải viết lại lớp đó):

| Tầng dữ liệu | Nguồn | Khi nào đọc |
|---|---|---|
| Metadata mọi component (dựng gallery, search, filter, badge) | `assets/index.json` — **1 file duy nhất** | Lúc khởi động |
| Nội dung README đầy đủ (API, caveats, changelog, test history, AI prompt) | `components/<id>/README.md` | **Lazy** — chỉ khi mở detail của component đó |
| Source code từng file | `components/<id>/*.dart` | **Lazy** — chỉ khi mở tab Code / tab Files |

Quan hệ giữa hai thứ, phải nắm rõ:
- README từng component **vẫn là source of truth**.
- `index.json` là **artifact dẫn xuất**, sinh bằng `tools/build_index.dart` bằng cách gom frontmatter của mọi `components/*/README.md`. **Không bao giờ sửa tay.** Đầu file ghi rõ `"_generated": true` + timestamp. Gitignore hoặc commit kèm ghi chú là generated.

Đánh đổi: index có thể stale nếu quên regen. Chặn bằng `validate.dart` — check `index.json` khớp với các README thực tế, và validate đã nằm sẵn trong pre-commit hook.

### 5.1 Ba tầng thông tin, ba vòng đời khác nhau — KHÔNG được trộn

| Tầng | Nội dung | Vòng đời |
|---|---|---|
| **1. Creation snapshot** | Ngày tạo, Flutter/Dart version lúc tạo, deps đã resolve, nguồn gốc, platform thử ban đầu | **Bất biến.** Ghi một lần, không bao giờ sửa. Đây là dữ liệu khảo cổ — 2 năm sau tôi cần biết "cái này viết ở thời Flutter nào" để đoán tại sao nó vỡ. |
| **2. Component version** | Semver của **chính component** + changelog riêng | Tăng khi tôi tự sửa/nâng cấp. **Khác hoàn toàn với version Flutter đã test.** Không có tầng này thì không phân biệt được "chết vì Flutter mới" với "tôi đã tự fix và bản ở project X là bản cũ". |
| **3. Test history** | Bảng, mỗi dòng một lần verify | **Append-only.** Chỉ thêm dòng, không xóa/ghi đè. Lịch sử "từng vỡ ở 3.24 rồi fix ở 3.27" chính là thông tin giá trị nhất. |

### 5.2 Template README.md

```markdown
---
# --- IDENTITY (bắt buộc) ---
id: aurora_stack
title: Aurora Stack
kind: paint                  # paint | carrier | effect | composite
tags: [aurora, shader, animated]

# --- PAINT/CARRIER TAXONOMY (mục 2) ---
paint_source: shader         # shader | painter | widget | none
carriers_verified: [fullscreen, card, button, text]
carriers_failed:
  - icon: "chi tiết noise biến mất dưới 32px"
scale_aware: true            # component có nhận param scale/bounds hint hay không

# --- PORTABILITY (mục 3 — script verify, đừng gõ tay phần files) ---
portability: folder          # single_file | folder | folder_with_assets
entry: aurora_stack.dart
files:
  - aurora_stack.dart: "entry, re-export public API"
  - _noise_layer.dart: "required by entry"
  - _blob_painter.dart: "required by _noise_layer"
vendored_from: null          # id của component gốc nếu file phụ được nhân bản từ đó
assets_required: []

# --- ORIGIN (bắt buộc) ---
source: https://...
author: "Tên tác giả gốc"
license: MIT                 # hoặc unknown
adapted: true

# --- CREATION SNAPSHOT (bất biến, script tự điền) ---
created: 2026-08-17
created_flutter: 3.35.1
created_dart: 3.9.0
created_deps:                # LUÔN lấy từ pubspec.lock, KHÔNG lấy từ pubspec.yaml
  - blur: 4.0.1
platforms_initial: [android, ios]

# --- COMPONENT VERSION (tầng 2) ---
version: 1.1.0

# --- DERIVED (script tự tính từ Test History, đừng gõ tay) ---
latest_known_good: 3.35.1
last_verified: 2026-08-17
status: verified             # verified | stale | needs_patch | broken

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

Đây là mục tiết kiệm thời gian nhất trong cả file — snippet phải copy-paste được luôn, không phải "cần package blur".

## Reuse

- **Copy:** cả folder `aurora_stack/` (3 file dart, xem frontmatter `files`)
- **Import:** `import 'aurora_stack/aurora_stack.dart';` — chỉ cần 1 dòng
- **Hoặc:** `dart tools/export.dart aurora_stack` để lấy zip + block paste-ready

## API

| Param | Type | Default | Ý nghĩa |
|---|---|---|---|
| `scale` | `double` | `1.0` | Tỉ lệ chi tiết paint. Giảm khi dùng ở carrier nhỏ. |

## Carriers

Bảng ghi lại paint này đã áp lên carrier nào, kết quả thế nào. Chỉ ghi cái đã verify thật, không hứa suông.

| Carrier | Result | Note |
|---|---|---|
| fullscreen | pass | mặc định |
| card | pass | — |
| button | pass_warning | cần `scale: 0.3` nếu không thành vệt phẳng |
| text | pass | dùng ShaderMask + srcIn, đắt frame |
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
| 2026-08-17 | 3.35.1 | 3.9.0 | blur 4.0.1 | android, ios | pass | — |
| 2026-05-02 | 3.32.0 | 3.8.0 | blur 4.0.0 | android | needs_patch | `withOpacity` deprecated, xem changelog 1.1.0 |

**Result là 4 trạng thái, không phải pass/fail nhị phân:**
`pass` | `pass_warning` (có deprecation) | `needs_patch` (kèm mô tả patch) | `fail`

## AI Integration Prompt

<xem mục 7>
```

---

## 6. FILE DEMO — HAI CÔNG DỤNG

`<id>_demo.dart` không portable nên tự do dùng gì cũng được. Nó có **hai** nhiệm vụ, đừng bỏ nhiệm vụ thứ hai:

1. Cung cấp builder để app render preview/thumbnail.
2. Là **usage example tử tế** khi tôi copy component sang project khác — viết như code mẫu production, không phải scratchpad.

Với component `kind: paint`, demo có thể cung cấp thêm builder theo từng carrier:

```dart
final auroraStackDemo = ComponentDemo(
  id: 'aurora_stack',
  builder: (context) => ...,              // preview mặc định
  thumbnailBuilder: (context) => ...,     // optional, nếu preview chính quá nặng
  carrierBuilders: {                      // optional, chỉ cho kind: paint
    Carrier.card: (context) => ...,
    Carrier.button: (context) => ...,
    Carrier.text: (context) => ...,
  },
);
```

Nếu paint tuân contract shader (mục 2.3) thì `carrierBuilders` có thể để rỗng — app tự dựng carrier bằng `ShaderMask` từ factory shader mà entry file expose. Đây là đường tốt hơn; `carrierBuilders` là fallback cho paint không shader hóa được.

Metadata **không** nằm trong file này.

---

## 7. KHỐI "AI INTEGRATION PROMPT" TRONG README

Đây là phần giá trị cao nhất và cũng dễ làm hỏng nhất.

**Nó KHÔNG phải** "hãy giải thích component này". Nó là **chỉ thị tích hợp** — thứ tôi paste vào Claude Code ở project đích để nó tự lắp component vào.

Phải chuẩn hóa theo **một template dùng chung cho mọi component**, chỉ thay phần cụ thể. Nếu mỗi component tự viết prompt kiểu tự do thì sau 30 cái sẽ không dùng được cái nào. `new_component.dart` sinh sẵn khung này.

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
- KHÔNG bỏ bớt file trong folder — cả 3 file đều required, xem frontmatter `files`.
- Nếu deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Nếu Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước khi chạy.
```

---

## 8. APP VIEWER

### 8.1 Registry
Flutter không có reflection. Dùng **barrel file thủ công** `registry.dart` (map `id` → `ComponentDemo`), do `new_component.dart` tự chèn. **Không dùng build_runner/codegen** — setup nặng, không đáng cho ~100 component.

### 8.2 Gallery
- Grid, search theo title/tag, filter theo `kind` + `status` + `carriers_verified`
- Filter đặc biệt: **"cái nào chạy được trên Flutter hiện tại của máy tôi"** — app đọc Flutter version của máy, đối chiếu Test History, lọc ra
- Favorite (Hive/SharedPreferences)
- Thumbnail render widget thật: bọc `RepaintBoundary`, cache snapshot; paint động phải **pause khi ra khỏi viewport** (không thì 50 animation cùng chạy sẽ tụt frame)

### 8.3 Hai loại badge — payoff bắt buộc

Metadata chỉ đáng viết nếu app **tự suy ra trạng thái** từ nó. Nếu chỉ để đọc bằng mắt thì sau 20 component tôi sẽ bỏ.

**Badge tương thích** (từ Test History):
- 🟢 `verified` — verify gần đây, tốt trên Flutter hiện tại
- 🟡 `stale` — quá 6 tháng chưa verify
- 🟠 `needs_patch` — chạy được nhưng cần sửa
- 🔴 `broken` — known-broken trên Flutter hiện tại

**Badge chi phí tái dụng** (từ `portability`):
- 🟦 `single_file` — paste 10 giây
- 🟨 `folder (n files)` — paste cả folder
- 🟥 `folder + assets` — cần copy asset nữa

Tôi cần quyết định được "hôm nay chỉ muốn cái nào paste 10 giây" **trước khi** mở detail.

### 8.4 Detail screen

**Preview stage khác nhau theo `kind`** (đây là lý do `kind` không chỉ dùng để filter):
- `paint` → xem mục Carrier Switcher bên dưới
- `carrier` / `composite` → khung có padding, đổi được light/dark/checkerboard
- `effect` → có target mẫu để bọc lên, toggle on/off để so sánh

**Carrier Switcher** (cho `kind: paint`): một hàng chip `Fullscreen | Card | Button | Text | Border | Icon`. Tap để xem cùng một paint áp lên carrier khác.

> Lưu ý cho người implement: cái này **mâu thuẫn với quyết định "không làm knobs"** ở mục 1, và đó là có chủ ý. Knobs là tweak param — làm ở project đích được. Carrier switcher là **phát hiện khả năng tái dụng** — chỉ làm được ở đây, nơi có sẵn cả bộ carrier để so sánh. Ngoại lệ này chỉ áp dụng cho carrier switcher, không mở rộng sang các knobs khác.

Chip carrier có state: verified (bình thường), failed (disabled + tooltip lý do từ `carriers_failed`), untested (mờ, tap để thử).

**Tab Files**: cây file kèm vai trò (từ frontmatter `files`), tap xem code từng file. Với single-file thì tab này ẩn.

**Tab Code**: đọc file qua `rootBundle`, syntax highlight. Giữ nhẹ — chỉ để xem nhanh quyết định "có đúng cái mình cần không", đỡ mở IDE.

**Tab Info**: render README (metadata, install, reuse, API, carriers, caveats, changelog, test history, AI prompt).

Toggle chung: dark/light, checkerboard (xem transparency), device frame.

### 8.5 Storage
Metadata là asset-time → **không cần DB**. Hive/SharedPreferences chỉ lưu state cá nhân: favorite, note, custom tag, recently viewed.

---

## 9. HAI CÁI BẪY BẮT BUỘC XỬ LÝ

### 9.1 Scale — chỗ non-obvious nhất
Paint thiết kế cho fullscreen có chi tiết ở tỉ lệ fullscreen. Nhét vào button 48px thì noise/particle biến thành một vệt màu phẳng, aurora thành cục xám. **Không phải lỗi kỹ thuật mà là lỗi thẩm mỹ.**

Hệ quả: file portable phải nhận param `scale` hoặc `bounds` hint **ngay từ khi tôi lưu component**. Nếu không, sau này muốn dùng lại phải sửa lõi component. Field `scale_aware` trong frontmatter track việc này; `validate.dart` cảnh báo (warning, không fail) nếu `kind: paint` mà `scale_aware: false`.

### 9.2 Perf cliff ở text + animated paint
Mask text lên paint động = `saveLayer` mỗi frame. 5 cái cùng lúc trong gallery là tụt frame.
→ Carrier `text` phải **lazy**: chỉ render khi tôi chủ động tap chip đó. Không bao giờ tự render carrier text trong thumbnail gallery.

---

## 10. SCRIPTS (`tools/`) — LÀM Ở PHASE 1, KHÔNG PHẢI PHASE 3

Đây là loại tính năng **chết vì ma sát tay**, không chết vì kỹ thuật. Nhiều file + frontmatter đúng cú pháp + prompt + bảng = quá nhiều thao tác. Không có script, tôi sẽ bỏ ngang sau 10 component.

### `new_component.dart <id> <kind> [--files=n]`
Sinh folder + skeleton (entry, demo, README) đã điền sẵn frontmatter (tự đọc `flutter --version` và `pubspec.lock`), sinh sẵn khung AI Integration Prompt, + tự chèn entry vào `registry.dart`.

### `verify.dart <id>`
**Nguyên tắc cứng: KHÔNG BAO GIỜ gõ version bằng tay.**
Script tự đọc `flutter --version` + `pubspec.lock`, append một dòng vào bảng Test History, rồi tự cập nhật `latest_known_good` / `last_verified` / `status`. Tôi chỉ gõ `result` + `note`.

Lưu ý: `pubspec.yaml` chứa range (`^1.2.0`) — **không phải sự thật**. Cái làm component vỡ là version đã resolve. Luôn snapshot từ `pubspec.lock`.

### `validate.dart`
Đây là script quan trọng nhất. Phải check:
1. **Import graph thật vs manifest** — parse import của mọi file trong folder, dựng graph, diff với frontmatter `files`. Lệch → fail. (mục 3.2)
2. **Portability** — không có relative import vượt ra ngoài folder; không import package ngoài `created_deps`
3. **Entry file** — tồn tại, trùng tên folder, re-export public API
4. **Naming** — file phụ có prefix `_`
5. **Frontmatter schema** — field bắt buộc, enum `kind`/`status`/`result`/`portability`/carrier names, format ngày
6. **Registry sync** — registry khớp folder thực tế (thiếu/thừa entry)
7. **Index sync** — `assets/index.json` khớp với frontmatter của mọi README thực tế. Stale → fail, kèm gợi ý chạy `build_index.dart`. (mục 5.0)
8. **Warning** — `kind: paint` mà `scale_aware: false`; component `stale` quá 6 tháng

Exit code khác 0 nếu fail, để dùng làm pre-commit hook.

### `build_index.dart`
Quét mọi `components/*/README.md`, gom frontmatter thành **một** file `assets/index.json` để app load lúc khởi động thay vì parse N file (mục 5.0).

- Đây là artifact **dẫn xuất**. README vẫn là source of truth.
- Ghi `"_generated": true` + timestamp ở đầu file để không ai sửa tay.
- Gọi tự động ở cuối `new_component.dart` và `verify.dart` — hai script này đều làm index stale, nên phải tự regen, không để tôi nhớ.
- Nếu frontmatter component nào parse lỗi: báo rõ **id nào, dòng nào**, không nuốt lỗi rồi bỏ qua component đó.

### `export.dart <id>`
Script này ăn tiền hơn mọi comment. Xuất zip đúng folder + in ra block paste-ready: deps cần thêm, import statement, asset cần copy, caveat, scale hint. **Tôi không cần đọc hiểu gì, chỉ copy.**

---

## 11. TECH STACK

- Flutter (version hiện tại của máy), Dart 3
- **Riverpod** — state management
- **go_router** — routing. Dùng `CustomTransitionPage` với fade cho mọi route (tránh scrim layer của `ZoomPageTransitionsBuilder` gây flash khi Scaffold background trong suốt)
- **Hive** — favorite/note (JSON string)
- **Freezed** — model
- `yaml` package cho frontmatter parser; `flutter_markdown` hoặc tương đương cho render README

---

## 12. ROADMAP

**Phase 1 — Xương sống + scripts**
Cấu trúc repo, model + frontmatter parser, **pipeline `index.json` (mục 5.0)**, `registry.dart`, 5 script trong `tools/`, 3 component seed (1 single-file, 1 multi-file, 1 paint dạng shader).
→ *Verify:*
- `dart tools/new_component.dart test_x paint` sinh đúng skeleton + chèn registry + **tự regen `index.json`**
- `dart tools/validate.dart` pass
- Cố tình xóa một dòng trong frontmatter `files` → validate phải FAIL (chứng minh import graph check hoạt động)
- Cố tình sửa tay `index.json` cho lệch README → validate phải FAIL (chứng minh index sync check hoạt động)
- `dart tools/verify.dart test_x` append đúng dòng vào bảng + regen index
- `dart tools/export.dart test_x` ra zip + block paste-ready

**Phase 2 — App viewer cơ bản**
Gallery grid (load từ `index.json`) + thumbnail widget thật + detail với preview stage theo `kind` + tab Info (lazy đọc README đầy đủ).
→ *Verify:* 3 seed hiện đúng thumbnail, mở detail render đúng, đổi light/dark không lỗi. **Gallery chỉ đọc đúng 1 asset lúc khởi động** — log/assert số lần `rootBundle.loadString` trước khi grid render đầu tiên.

**Phase 3 — Carrier switcher**
`ShaderMask` pipeline cho paint dạng shader, `carrierBuilders` fallback, chip carrier với 3 state, lazy carrier `text`, param `scale` wire vào switcher.
→ *Verify:* component paint shader áp được lên card/button/text mà KHÔNG cần viết `carrierBuilders`; chip `text` không render cho tới khi tap; chip `icon` disabled kèm tooltip lý do.

**Phase 4 — Metadata & compat**
Search, filter theo kind/tag/status/carrier, 2 loại badge, filter "chạy được trên Flutter hiện tại", favorite.
→ *Verify:* sửa tay một dòng Test History thành `fail` → badge đổi 🔴 và bị lọc khỏi filter compat; component multi-file hiện badge 🟨 kèm số file đúng.

**Phase 5 — Hoàn thiện**
Tab Code + syntax highlight, tab Files, checkerboard/device frame, pause paint ngoài viewport, pre-commit hook gọi `validate.dart`, seed 10 component thật.
→ *Verify:* scroll gallery 20+ component không tụt frame; commit với frontmatter sai bị chặn.

---

## 13. BẮT ĐẦU

1. Đọc hết spec. Nêu assumption + điểm nào thấy mâu thuẫn hoặc thiếu.
2. Đề xuất kế hoạch Phase 1 dạng `bước → cách verify`.
3. Chờ tôi ok kế hoạch, rồi implement Phase 1 trọn vẹn.

Tên project: **Snipz** (đổi nếu tôi nói khác).