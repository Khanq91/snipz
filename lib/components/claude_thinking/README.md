---
# --- IDENTITY ---
id: claude_thinking
title: Claude Thinking
kind: effect
tags: [text, shimmer, terminal, loader, animated, claude]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: claude_thinking.dart
files:
  - claude_thinking.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: https://github.com/theswerd/brainless (registry/brainless/claude/claude-thinking.tsx)
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-23
created_flutter: 3.44.0
created_dart: 3.12.0
created_deps: []
platforms_initial: [android]

# --- COMPONENT VERSION ---
version: 1.1.0

# --- DERIVED (computed from Test History by verify.dart, do not hand-edit) ---
latest_known_good: null
last_verified: null
status: null

preview: null
---

# Claude Thinking

Dòng "đang làm việc" của Claude Code CLI: một glyph asterisk nhấp nháy theo
chu kỳ capture thật (`· ✢ ✳ ✶ ✻ ✽ …`, 110ms/frame) cạnh một verb ngẫu hứng
("Thinking…", "Noodling…") màu terracotta với vệt sáng shimmer trượt ngang
(2.8s); mỗi lần đổi, verb mới tự gõ ra từng ký tự trái → phải (55ms/ký tự,
một chiều — không xoá lùi, không cursor). Bản rút gọn của `claude-thinking` từ brainless — bỏ đồng hồ giây,
token count và hint "esc to interrupt". Dùng làm loading indicator kiểu
terminal. Tôn trọng reduced-motion (đứng yên ở ✳, verb màu đặc).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `claude_thinking/` folder (1 dart file(s), see `files`)
- **Import:** `import 'claude_thinking/claude_thinking.dart';` — one line
- **Or:** `dart tools/export.dart claude_thinking` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `running` | `bool` | `true` | `false` render rỗng (như bản gốc return null) |
| `verbs` | `List<String>` | 7 verb gốc | Danh sách verb xoay vòng; 1 phần tử = chữ cố định |
| `baseColor` | `Color` | `0xFFCD694A` | Terracotta — màu glyph + chữ |
| `highlightColor` | `Color` | `0xFFE79475` | Màu vệt sáng shimmer |
| `fontSize` | `double` | `13` | Cỡ chữ (glyph box scale theo) |
| `fontFamily` | `String` | `'monospace'` | Font; default mono hệ thống |
| `glyphStyle` | `ClaudeThinkingGlyphStyle` | `text` | `painted` = vẽ glyph bằng CustomPainter, không bao giờ tofu |
| `animate` | `bool` | `true` | `false` đóng băng deterministic (✳ + verb đầu, màu đặc) |
| `glyphInterval` | `Duration` | `110ms` | Nhịp đổi glyph |
| `typeEffect` | `bool` | `true` | Verb mới gõ từng ký tự trái → phải (một chiều, không xoá lùi); `false` = swap tức thì |
| `typeCharInterval` | `Duration` | `55ms` | Nhịp gõ mỗi ký tự |
| `verbInterval` | `Duration` | `5200ms` | Nhịp đổi verb |
| `shimmerPeriod` | `Duration` | `2800ms` | Chu kỳ một lượt shimmer |

Ngoài widget còn export `createClaudeShimmerShader(bounds, {base, highlight,
progress})` — shader shimmer dùng được với `ShaderMask`/`Paint.shader` trên
nội dung bất kỳ.

## Caveats

- Glyph mặc định là ký tự Unicode Dingbats (U+2700 block) — đa số Android 8+
  render được qua Noto Sans Symbols, nhưng ROM vendor cắt font có thể ra ô
  tofu. Gặp trường hợp đó: đổi `glyphStyle: ClaudeThinkingGlyphStyle.painted`
  (một param, không cần font/asset).
- Shimmer nghỉ ở nửa sau mỗi chu kỳ 2.8s (vệt sáng quét qua rồi ngừng một
  nhịp) — đúng hành vi CSS gốc, không phải bug.
- Reduced-motion (`MediaQuery.disableAnimations`) tự dừng ticker và render
  tĩnh; không cần xử lý gì thêm ở phía dùng.

## Changelog

- **1.1.0** (2026-08-23) — verb tự gõ trái → phải khi đổi (text-type một
  chiều, không cursor); thêm `typeEffect` + `typeCharInterval`. Đồng thời ép
  glyph ✳ về text presentation (U+FE0E) — hết lỗi emoji xanh lá trên Android.
- **1.0.0** (2026-08-23) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `ClaudeThinking` vào project này.

**Context**
- Chức năng: loading indicator kiểu Claude Code CLI — glyph asterisk nhấp
  nháy + verb shimmer terracotta ("Thinking…"). Đặt ở nơi đang chờ tác vụ
  chạy; `running: false` để ẩn.
- Public API: xem bảng API trong README.
- Portability: single_file — copy cả `claude_thinking/` (1 file), import duy nhất `claude_thinking.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `claude_thinking/` vào <thư mục widget của project đích>.
2. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
