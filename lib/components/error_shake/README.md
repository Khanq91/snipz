---
# --- IDENTITY ---
id: error_shake
title: Error Shake
kind: composite
tags: [error, input, validation, shake, feedback, animated]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: error_shake.dart
files:
  - error_shake.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: reimplemented
source: "https://github.com/ckissi/kinetics — effect 'Error Shake' (Surface & Motion)"
author: "Khang"
license: MIT

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-08-26
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

# Error Shake

Error Shake is a controlled validation input that replays a short horizontal
shake for each rejected attempt. Its persistent message, transient border,
focus behavior, and semantics make `composite` a better classification than a
paint-only effect.

## Port notes

- Reimplemented in Flutter from the MIT-licensed Kinetics reference.
- The input in the demo is exactly 220 logical pixels wide.
- Horizontal keyframes are preserved exactly:
  `0: 0`, `10: -1`, `20: 2`, `30: -4`, `40: 4`, `50: -4`,
  `60: 4`, `70: -4`, `80: 2`, `90: -1`, `100: 0`.
- Every 10% keyframe interval independently uses
  `Cubic(.36, .07, .19, .97)`, matching CSS animation timing semantics. The
  complete timeline lasts 450 ms.
- The error-colored border appears only while the shake is running. It settles
  to the normal or focused color afterward while the validation message remains
  visible.
- The message layout appears with the invalid state and its opacity reveals or
  hides over 200 ms with `Curves.ease`.
- An initially invalid instance renders settled. Motion begins when the state
  changes from valid to invalid, or when `shakeTrigger` subsequently changes;
  restoring prevalidated state does not create unsolicited motion.
- `animate: false` stops an in-flight shake, resets translation to zero, and
  settles the controlled message immediately.

## Install

Copy `error_shake.dart` into the target project and import it. The entry uses
only Flutter and has no package-local imports, assets, shaders, or third-party
dependencies.

```dart
import 'path/to/error_shake.dart';
```

Copy the whole folder only when the catalog demo and documentation are also
useful. `error_shake_demo.dart` depends on Snipz's `ComponentDemo` registry and
is not part of the portable component API.

## Reuse

The parent owns validation. Keep `isInvalid` true for as long as the message
should remain visible, and increment any integer used as `shakeTrigger` for
every rejected submission. This allows repeated invalid submissions to replay
without briefly clearing the error.

```dart
int attempt = 0;
bool invalid = false;

ErrorShake(
  controller: emailController,
  focusNode: emailFocusNode,
  isInvalid: invalid,
  shakeTrigger: attempt,
  labelText: 'Email',
  errorMessage: 'Please enter your email.',
  onChanged: (value) {
    if (value.trim().isNotEmpty) {
      setState(() => invalid = false);
    }
  },
)

// Run for every rejected submit.
setState(() {
  invalid = true;
  attempt += 1;
});
```

If no text controller or focus node is supplied, Error Shake creates and
disposes its own. Caller-provided controllers and nodes remain caller-owned.

Use `ErrorShakeThumbnail` from the demo file for deterministic gallery capture.
It renders an invalid state with `animate: false` and starts no transition.

## API

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `isInvalid` | `bool` | required | Controls persistent error-message visibility. |
| `shakeTrigger` | `int` | required | Change on every rejected attempt to replay motion. |
| `errorMessage` | `String` | required | Visible validation message. |
| `controller` | `TextEditingController?` | `null` | Optional caller-owned text controller. |
| `focusNode` | `FocusNode?` | `null` | Optional caller-owned focus node. |
| `labelText` | `String?` | `null` | Material input label. |
| `hintText` | `String?` | `null` | Material input hint. |
| `semanticsLabel` | `String?` | `null` | Explicit spoken input label. |
| `errorSemanticsLabel` | `String?` | `null` | Spoken alternative to the visible error. |
| `onChanged` | `ValueChanged<String>?` | `null` | Text-change callback. |
| `onSubmitted` | `ValueChanged<String>?` | `null` | Keyboard-submit callback. |
| `onShakeComplete` | `VoidCallback?` | `null` | Called after completion, not cancellation. |
| `keyboardType` | `TextInputType?` | `null` | Input keyboard configuration. |
| `textInputAction` | `TextInputAction?` | `null` | Keyboard action configuration. |
| `autofillHints` | `Iterable<String>?` | `null` | Platform autofill hints. |
| `textCapitalization` | `TextCapitalization` | `none` | Keyboard capitalization behavior. |
| `enabled` | `bool` | `true` | Enables the input. |
| `readOnly` | `bool` | `false` | Makes the input read-only. |
| `obscureText` | `bool` | `false` | Obscures entered text. |
| `autocorrect` | `bool` | `true` | Enables autocorrection. |
| `enableSuggestions` | `bool` | `true` | Enables keyboard suggestions. |
| `animate` | `bool` | `true` | Runs motion; false immediately settles it. |
| `duration` | `Duration` | 450 ms | Complete shake timeline duration. |
| `messageDuration` | `Duration` | 200 ms | Message opacity transition duration. |
| `errorColor` | `Color?` | theme error | Active shake border and message color. |
| `borderColor` | `Color?` | theme outline variant | Resting border color. |
| `focusBorderColor` | `Color?` | theme primary | Resting focused border color. |
| `fillColor` | `Color?` | theme surface | Input fill color. |
| `textColor` | `Color?` | theme on-surface | Input text color. |
| `labelColor` | `Color?` | theme on-surface variant | Resting label color. |
| `borderRadius` | `double` | `12` | Input corner radius. |
| `borderWidth` | `double` | `1` | Input border width. |
| `contentPadding` | `EdgeInsetsGeometry` | horizontal 14, vertical 13 | Input padding. |
| `messageGap` | `double` | `6` | Space above the error message. |

## Accessibility

- The component retains native text-field editing, focus, keyboard, and
  autofill behavior.
- The validation copy is a live region while invalid. Use
  `errorSemanticsLabel` when spoken wording should differ from visible copy.
- Persistent text communicates invalid state without relying on red or motion.
- Connect `animate` to the application's reduced-motion policy.

## Caveats

- `shakeTrigger` is compared by value; assigning the same integer again does
  not replay the animation.
- A caller that supplies `controller` or `focusNode` must dispose it.
- The keyframe offsets are logical pixels and intentionally not scale-aware.
- The built-in field is single-line. For custom controls, multiline layouts, or
  non-text surfaces, use a dedicated shake-effect wrapper instead.
- `duration` and `messageDuration` are configurable for product integration;
  keep 450 ms and 200 ms respectively for source fidelity.

## Changelog

### 1.0.0 — 2026-08-26

- Initial Flutter reimplementation.
- Added controlled replay, transient error border, persistent message,
  reduced-motion settling, internal/external controller ownership, accessible
  labels, live demo, and deterministic thumbnail.

## Test History

- 2026-08-26 — Created against Flutter 3.44.5 / Dart 3.12.2. Verification has
  not yet populated the derived frontmatter fields; `status` remains `null`.

## AI Integration Prompt

```text
Integrate ErrorShake from error_shake.dart. Keep validation state in the parent:
isInvalid controls the persistent message, and shakeTrigger must change for each
rejected attempt. Preserve the 450 ms keyframe timeline and per-segment
Cubic(.36, .07, .19, .97) easing. Do not make the red border persistent; it is
active only during the shake. Pass animate: false when reduced motion is active.
If you provide a TextEditingController or FocusNode, retain and dispose it in the
owner. Provide meaningful semanticsLabel/errorSemanticsLabel values for the
specific field and error copy.
```
