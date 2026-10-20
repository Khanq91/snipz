---
# --- IDENTITY ---
id: depth_page_transition
title: Depth Page Transition
kind: effect
tags: [navigation, transition, push, pop, slide, fade, depth]

# --- TAXONOMY (§2) ---
paint_source: none
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: single_file
entry: depth_page_transition.dart
files:
  - depth_page_transition.dart: "entry, public API"
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: original
source: null
author: "Khang"
license: null

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: 2026-10-20
created_flutter: 3.44.5
created_dart: 3.12.2
created_deps: []
platforms_initial: [android]

# --- COMPONENT VERSION ---
version: 1.0.0

# --- DERIVED (computed from Test History by verify.dart, do not hand-edit) ---
latest_known_good: 3.44.5
last_verified: 2026-10-20
status: verified

preview: null
---

# Depth Page Transition

Muzicz page motion packaged as a standalone Flutter effect. A pushed page slides
from the right and fades in; its predecessor moves left, shrinks, rounds, dims
and blurs. Pop reveals the retained previous page while the foreground exits right.
Use for Navigator page pushes, not bottom-navigation tab changes.

## Install / Reuse

Copy `depth_page_transition.dart`. Flutter SDK only; no assets or app state.

```dart
ThemeData(
  pageTransitionsTheme: PageTransitionsTheme(builders: {
    for (final platform in TargetPlatform.values)
      platform: const DepthPageTransitionsBuilder(),
  }),
);
// Both routes should use MaterialPageRoute for secondaryAnimation coordination.
Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DetailPage()));
```

For custom routes, use `DepthPageTransition` inside transitionsBuilder and pass
both animation and secondaryAnimation. Set push duration 450ms and pop 350ms.
Wrap the previous route too so its depth animation can run.

## API

| Param | Type | Default | Meaning |
|---|---|---|---|
| animation | Animation<double> | required | Incoming/outgoing route progress |
| secondaryAnimation | Animation<double> | required | Route above this page |
| child | Widget | required | Full page content |
| blur | double | 12 | Background blur radius |
| radius | double | 32 | Transitional corner radius |
| dim | double | 0.4 | Background black overlay opacity |

## Caveats

- Honors MediaQuery.disableAnimations. Native iOS edge-swipe and Android
  predictive-back gestures are not implemented by this builder; normal Back works.
- Blur incurs an offscreen render during movement; set blur to 0 for cheaper motion.
- The gallery demo uses an isolated nested Navigator; it does not change Snipz routing.
- Live Push / Pop, static thumbnail, frozen variant and timeline scrub are included.

## Changelog

- **1.0.0** (2026-10-20) — port from Muzicz; reusable push/pop motion.

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|
| 2026-10-20 | 3.44.5 | 3.12.2 | — | windows | pass_warning | Flutter widget tests: push/pop, retained background, reduced motion, isolated demo, thumbnail and scrub passed; analyzer clean. No Android device visual review yet. |

## AI Integration Prompt

Copy the single entry file and configure DepthPageTransitionsBuilder in the target
ThemeData.pageTransitionsTheme. Apply it to full page routes only. Retain the target
app navigation/state and customize blur, radius and dim through parameters.
