---
# --- IDENTITY ---
id: rate_limit_cooldown
title: Rate Limit Cooldown
kind: effect
tags: [rate-limit, tokens, cooldown, status, api, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: rate_limit_cooldown.dart
files:
  - rate_limit_cooldown.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Rate Limit Cooldown' (Feedback & State)"
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-24
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

# Rate Limit Cooldown

Token bucket rate-limiter thành animation trạng thái lặp 6.4s, dựng lại từ
kinetics "Rate Limit Cooldown": 5 pip amber bị "tiêu" nhanh trái → phải,
status lật từ `200 · ok` sang `429 · cooling` trong khi thanh cooldown cạn
dần, rồi pip được cấp lại từng cái trên nhịp chậm kèm overshoot 1.22×. Sự
bất đối xứng là điểm nhấn: tiêu thì tức thời, hồi thì đủng đỉnh.

## Port notes

- Effect gốc: "Rate Limit Cooldown", section **Feedback & State**, kinetics
  (`github.com/ckissi/kinetics`). Source: card trong `src/content/body.html`,
  style mục "47" trong `public/css/effects-b.css` (`.demo-ratelimit`),
  không có JS.
- Cơ chế gốc: **CSS keyframes 3 lớp đồng bộ** trên cùng chu kỳ 6.4s:
  `token-cycle` (linear, delay i×0.14s), `cooldown-sweep`
  (`cubic-bezier(0.4, 0, 0.2, 1)`), `state-ok`/`state-throttled`
  (ease-in-out). → Flutter: một ticker, mỗi lớp một track keyframe thuần
  theo `t` (`_kf`).
- Số liệu giữ nguyên: pip 15px amber glow 45%, keyframe
  0/4→9→52→62→70/100% (opacity 1→0.12→0.12→1(scale 1.22)→1); thanh 148×3
  gradient danger→amber scaleX 1→0 (8→62%); chữ 9px letterspacing 0.08em;
  card 214, padding 20/16/16, radius 14.
- Sai lệch nhỏ: glow của pip nội suy theo opacity thay vì switch cứng
  `box-shadow: none` tại keyframe (CSS nội suy shadow từng segment — khác
  biệt không nhận ra bằng mắt).
- Bỏ: font JetBrains Mono → font hệ thống (luật zero-asset);
  `color-mix()` → alpha trực tiếp.
- Theo quy ước sample(t): `frozenAt` + `animate`, tôn trọng
  `disableAnimations`. Ba pha có sẵn làm variants trong demo (ok / cooling
  / refill).

## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `rate_limit_cooldown/` folder (1 dart file(s), see `files`)
- **Import:** `import 'rate_limit_cooldown/rate_limit_cooldown.dart';` — one line
- **Or:** `dart tools/export.dart rate_limit_cooldown` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| `tokenCount` | `int` | `5` | Số pip trong bucket |
| `width` | `double` | `214` | Bề rộng card |
| `okText` | `String` | `'200 · ok'` | Nhãn trạng thái bình thường |
| `coolText` | `String` | `'429 · cooling'` | Nhãn khi throttled |
| `tokenColor` | `Color` | `#FF8A00` | Pip + nửa phải thanh cooldown |
| `okColor` | `Color` | `#4CD08A` | Màu nhãn ok |
| `dangerColor` | `Color` | `#FF5C5C` | Nhãn 429 + nửa trái thanh |
| `cardColor` | `Color` | `#232326` | Nền card |
| `borderColor` | `Color` | `#2A2A2E` | Viền card |
| `arcTrackColor` | `Color` | `#1A1A1D` | Nền thanh cooldown |
| `showCard` | `bool` | `true` | false = bỏ chrome card, chỉ nội dung |
| `animate` | `bool` | `true` | false = đứng im |
| `frozenAt` | `double?` | null | Render đúng 1 frame tại t giây, không ticker |

Mốc pha trong chu kỳ 6.4s (cho `frozenAt`): `0` ok đầy, `~2.5` throttled,
`~4.2` đang refill overshoot.

## Caveats

- Đây là **animation minh họa tự lặp**, không phải hiển thị trạng thái
  rate-limit thật — cần bản data-driven (số token thật, đếm ngược thật) thì
  yêu cầu bản mở rộng.
- Chu kỳ 6.4s là hằng trong source (`_period`) — đổi trực tiếp nếu cần,
  không expose param.
- Ticker chạy khi hiển thị — tắt bằng `animate: false` khi khuất (§9.2).
- Cost: chưa đo (5 pip + 1 gradient + 2 text mỗi frame).

## Changelog

- **1.0.0** (2026-08-24) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `RateLimitCooldown` vào project này.

**Context**
- Chức năng: animation token-bucket 6.4s — tiêu nhanh, 429, hồi chậm (port
  kinetics "Rate Limit Cooldown"). Minh họa, không data-driven.
- Public API: xem bảng API trong README. Class `RateLimitCooldown`.
- Portability: single_file — copy cả `rate_limit_cooldown/` (1 file), import duy nhất `rate_limit_cooldown.dart`.
- Deps: không có — Flutter SDK only (widgets layer, không cần Material).

**Việc cần làm**
1. Copy folder `rate_limit_cooldown/` vào <thư mục widget của project đích>.
2. Đặt vào docs/empty-state/landing về API — chỗ cần minh họa rate limit;
   đổi `okText`/`coolText` theo ngữ cảnh.

**Việc cần adapt theo project đích**
- Màu: 6 param màu có default palette tối kinetics — nền sáng đổi
  `cardColor`/`borderColor`/`arcTrackColor`.
- Cần gắn data thật: KHÔNG sửa keyframe bên trong — yêu cầu bản mở rộng.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
