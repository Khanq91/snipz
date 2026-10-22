---
id: coucou_mochi
title: Coucou Mochi
kind: composite
tags: [mascot, animation, canvas, audio, interaction, study]

paint_source: painter
carriers_verified: []
carriers_failed: []
scale_aware: false

portability: folder_with_assets
entry: coucou_mochi.dart
files:
  - coucou_mochi.dart: "entry, public API"
  - _audio.dart: "required by coucou_mochi.dart"
  - _engine.dart: "required by coucou_mochi.dart"
  - _painter.dart: "required by coucou_mochi.dart"
  - _skins.dart: "required by coucou_mochi.dart"
  - _greeting.dart: "required by coucou_mochi.dart"
  - _scenes.dart: "required by coucou_mochi.dart"
  - _upload.dart: "required by coucou_mochi.dart"
  - _upload_painter.dart: "required by coucou_mochi.dart"
  - _scene_math.dart: "required by _greeting.dart"
vendored_from: null
assets_required: [lib/components/coucou_mochi/audio/]
shaders_required: []

deps:
  audioplayers: ^6.8.1

origin: adapted
source: https://github.com/Louis-CFM/coucou
author: "Louis Raillé"
license: "Source code MIT; character design and sounds reserved; private local study only"

created: 2026-10-02
created_flutter: 3.44.5
created_dart: 3.12.2
created_deps:
  audioplayers: 6.8.1
platforms_initial: [android]

version: 1.2.0
latest_known_good: null
last_verified: null
status: null
preview: null
---

# Coucou Mochi

A procedural Flutter Canvas study of Coucou's tiny companion. It rebuilds the squircle body, moving eyes, state badges, blinks, greetings, emotes, particles, mailbox morph, and interaction sounds from the upstream behavior and geometry. `sample(t)` stays deterministic for still frames and the gallery scrubber.

## Private research and asset rights

This component includes local copies of Coucou's 28 WAV effects and recreates the Mochi character design, expressions, and motion. Coucou's [`LICENSE-ASSETS.md`](https://github.com/Louis-CFM/coucou/blob/main/LICENSE-ASSETS.md) says the MIT license covers its source code; the Mochi character and sounds remain reserved to Louis Raillé. The user approved keeping this copy in Snipz for private local research; that approval is not a license from the rights holder. Do not publish or distribute this component, its assets, or an app containing them, and do not use them commercially without written permission from the rights holder.

The root `pubspec.yaml` has a local-study exception for the audio package and WAV directory. Remove that dependency, asset-directory entry, registry entry, this folder, and the `SESSION.yaml` addition together if this study is removed. The WAVs are not relicensed by this project.

## Install

Keep this folder, including `audio/`, together. Add the following to the host project's `pubspec.yaml`:

```yaml
dependencies:
  audioplayers: ^6.8.1

flutter:
  assets:
    - lib/components/coucou_mochi/audio/
```

The widget uses Flutter SDK APIs and `audioplayers` 6.8.1. WAVs are loaded into `AudioPool`s on first use through an empty-prefix `AudioCache`: the asset keys above already start at the bundle root. Playback never blocks drawing; a failed pool is removed so a later request can retry.

## API

| API | Type / default | Purpose |
| --- | --- | --- |
| `CoucouMochi.size` | `double`, `220` | Drawing width; height is 1.28× width. |
| `state` | `CoucouMochiState`, `idle` | Idle, working, thinking, searching, approval, question, error, finished, rate limit, sleeping, or dizzy pose. |
| `skin` | `CoucouMochiSkin`, `original` | Original Mochi, `nekoPudding` (Neko Pudding), or `cloud` (Mây Bông). Applies to the body, accessories and mailbox; also available on `CoucouMochiScene` and the painters. |
| `controller` | `CoucouMochiController?`, `null` | `greet()`, `emote(...)`, `stopEmote()`, and `gulp()` commands. The owner disposes it. |
| `frozenAt` | `double?`, `null` | Render one deterministic frame at the given time in seconds, without a ticker. |
| `animate` | `bool`, `true` | Run the `Ticker`; `TickerMode` still pauses it. |
| `interactive` | `bool`, `true` | Enable tap, long-press, gaze, and hover reactions. Three quick taps make Mochi dizzy; long-press triggers love. |
| `soundEnabled` / `volume` | `bool` / `double`, `true` / `0.12` | Enable WAV playback and set volume from 0 to 1. |
| `greetingOnStart` | `bool`, `false` | Play the small peek wave on mount; use the launch scene for the full opening sequence. |
| `morph` | `double`, `0` | Morph body from Mochi (`0`) to mailbox (`1`). |
| `backgroundColor` | `Color`, `#080A10` | Fill the component canvas behind Mochi. |
| `onSound` / `onDizzy` | callbacks, `null` | Observe requested sound names and the three-tap dizzy event. |
| `isMini` / `miniColor` | `bool` / `Color`, `false` / `#3E86E0` | Solid-color mini companion with larger eyes, mini badges, autonomous gaze and breathing. |
| `permanentEmote` / `behaviorSeed` | `CoucouMochiEmote?` / `int`, `null` / `41` | Repeating mini happy/annoyed/wink/love behavior; vary the seed between companions. |
| `initialEmote` | `CoucouMochiEmote?`, `null` | Silent declarative emote on mount, including frozen previews and minis. Changing it starts a new emote; use the controller to replay the same value. |
| `emoteLoop` / `musicBpm` | `bool` / `double`, `false` / `100` | Options for `initialEmote`. Loop is supported only for chill/music; BPM is finite and between 40 and 240. |
| `CoucouMochiEngine.sample(t)` | `CoucouMochiFrame` | Pure, deterministic frame model; `CoucouMochiPainter` draws a sampled frame. Both helpers are exported from the entry file. |

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:snipz/components/coucou_mochi/coucou_mochi.dart';

class MochiPreview extends StatefulWidget {
  const MochiPreview({super.key});

  @override
  State<MochiPreview> createState() => _MochiPreviewState();
}

class _MochiPreviewState extends State<MochiPreview> {
  final CoucouMochiController _mochi = CoucouMochiController();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoucouMochi(
            controller: _mochi,
            state: CoucouMochiState.working,
            onDizzy: () => debugPrint('Mochi is dizzy'),
          ),
          TextButton(onPressed: _mochi.greet, child: const Text('Greet')),
          TextButton(
            onPressed: () => _mochi.emote(CoucouMochiEmote.happy),
            child: const Text('Happy'),
          ),
          TextButton(onPressed: _mochi.gulp, child: const Text('Gulp')),
        ],
      );

  @override
  void dispose() {
    _mochi.dispose();
    super.dispose();
  }
}
```

The standalone `_engine.dart` and `_painter.dart` contain the time-addressable motion model and renderer. Sound assets and the `audioplayers` package are kept at the widget boundary. The controller's `gulp()` first morphs a normal body into a mailbox if needed; the lower-level engine's `gulp(t)` only performs the original swallow, leaving morph control to its caller.

## Character skins

The showcase's **Skin** dropdown selects Mochi, Neko Pudding or Mây Bông.
Changing the selection remounts the preview with a new controller and resets
the state, emote, loop, mailbox and active scene. The sound preference stays
unchanged. The reload button restarts the selected skin.

- **Neko Pudding** has a custard body, caramel cap, pink ears, curved tail and
  a small cat muzzle. Ears and tail react to the displayed expression and pose.
- **Mây Bông** has a scalloped cloud silhouette, cool soft shading and small
  weather accents driven by the displayed expression.
- **Mochi** keeps the original appearance and animation behavior.

All skins support the same eleven states, twelve emotes, tap/hold/gaze,
greeting, mini companions, mailbox/gulp and full launch/upload scenes. Skin
details share the existing animation clock: freezing, scrubbing and pausing
also freeze their motion. No image assets, packages or sounds were added.
Mini colors act as accents on the new skins, preserving their identity.
The viewer's Freeze/scrub controls keep the selected skin. The live preview
is paused while the deterministic frame is shown; Resume restores its
previous scene and interaction state.

```dart
CoucouMochi(
  skin: CoucouMochiSkin.nekoPudding,
  controller: controller,
);

const CoucouMochiScene(
  type: CoucouMochiSceneType.upload,
  skin: CoucouMochiSkin.cloud,
);
```

For hosts outside the showcase, changing `skin` changes appearance while
keeping the current animation clock. Use `key: ValueKey(skin)` when a full
restart is desired. The state board includes live/frozen skin, mini, launch
and upload examples.

## Five additional emotions

These are Snipz extensions to the ported engine, not additional upstream business states. Existing enum values and positional controller calls are unchanged.

| Emote | Default duration | Motion / effect |
| --- | --- | --- |
| `suspicious` | 2.4 s | Side gaze, asymmetric lids, delayed gentle tilt; silent. |
| `confused` | 2.8 s | Uneven eyes, head correction, double blink at 0.98/1.27 s; one vector question mark opposite the state badge. Silent unless `questionCue: true`. |
| `chill` | 6 s | Half-open eyes, upright 3.2 s breathing, gentle sway; silent, no Z particles. |
| `music` | 4 s | Alternating tilt, beat-driven bounce and small squash/stretch; up to four vector notes. Silent. |
| `shy` | 3 s | Continuous blush, sideways/downward gaze, slight contraction; silent, no hearts. |

```dart
controller.emote(CoucouMochiEmote.suspicious); // Existing call style.
controller.emote(CoucouMochiEmote.confused, questionCue: true);
controller.emote(CoucouMochiEmote.music, loop: true, bpm: 100);
controller.stopEmote(); // 0.6 s transition to the current state.

// Deterministic thumbnail, also works with isMini: true.
const CoucouMochi(
  initialEmote: CoucouMochiEmote.shy,
  frozenAt: 1.65,
  soundEnabled: false,
);
```

`loop` defaults to false and is accepted only for chill/music. Other looping emotes, non-finite/out-of-range BPM, and invalid engine durations throw `ArgumentError`. `CoucouMochiEngine.triggerEmote(name, t, duration: ..., loop: ..., bpm: ...)` returns whether the request was accepted; `isEmoting(t)` reports activity and `stopEmote(t)` begins release. Existing calls can continue ignoring the return value. Explicit engine durations scale finite choreography; music's beat remains based on elapsed seconds and BPM.

New emotes enter from the displayed pose and release into the current state's live pose, preserving its body color and badge. Gaze and intentional blinks override ambient behavior while acting. A replacement starts from the current pose; greeting, gulp and dizzy take priority. State changes end emotes, and taps, hover, pointer movement or long press end looping emotes. A lower-priority emote requested during greeting/gulp/dizzy is ignored, including its sound cue. Loops have one entrance and a continuous clock; they do not restart at four/six seconds. `TickerMode`, `animate: false` and `frozenAt` pause that clock without catch-up on resume.

All five are silent by default. `questionCue: true` requests the existing question WAV once at accepted command start, respecting `soundEnabled` and `volume`. As before, `onSound` observes requested cues even while muted; frozen previews do not emit it. No WAV was added. BPM controls animation only: no playback, background music, audio analysis or player synchronization is implemented.

The demo provides five emote chips and five live/frozen variants, loop/stop controls and a BPM slider shown only for music. Controls scroll on short screens. Its 30-second scrub timeline gives each emote a six-second segment in priority order. Minis use `initialEmote` or controller commands for these extensions; `permanentEmote` retains its original mini behaviors.

## Launch and upload scenes

`CoucouMochiScene(type: CoucouMochiSceneType.launch, width: 640)` plays the original opening in a 640 by 150 reference space: grow, squint, dip, wave, tuck, badge, tint and collapse. The small `greet()` wave remains a separate command. Pointer hover holds the launch open; pointer exit collapses it. Without hover, collapse starts at 4.9 seconds.

`CoucouMochiScene(type: CoucouMochiSceneType.upload, width: 640)` plays the 640 by 176 file-follow, swallow, chew, shrink, progress and grow-back choreography. Drag to control the mailbox and release to drop; tap to replay the demonstration. This is a local visual preview, with no filesystem ingest, network upload or agent action. The host application can use `CoucouMochiUploadEngine.enter(t,x,y)`, `move(t,x,y)`, `drop(t, uploadDuration: ...)` and `sample(t)` for its own input and renderer. Coordinates use the reference space.

Both scenes support `frozenAt`, `soundEnabled`, `volume`, `onSound` and `onComplete`. Frozen previews are silent; scene and mascot cues follow the same paused animation clock. The gallery includes launch, upload and mini variants plus buttons in the main demo.

## Regression checks

`test/coucou_mochi_skins_test.dart` checks distinct deterministic renders at
normal/mini/mailbox sizes, launch/upload skin identity, tap/hold/dizzy/gulp,
pause behavior, and dropdown/reload resets across all scene modes.
`test/coucou_mochi_preview_test.dart` covers selected skins through the actual
viewer's Freeze, scrub, Resume and frozen deep links. To generate a local
visual atlas, set `MOCHI_SKINS_REVIEW=build/mochi_skins_review.png` before
running the skins test. The optional atlas uses the installed Windows Arial
font for labels.

`test/coucou_mochi_test.dart` covers the 28 actual bundle keys, dizzy recovery, mouth continuity, emote keyframes, particle staggering, hover/cue timing, interrupted greetings, pause behavior and gallery rendering. `test/fixtures/coucou_mochi_upstream.json` contains 12 launch and 13 upload frames executed from the local Coucou TypeScript reference at commit `8a5c263`; the tests compare the Flutter port against those independently generated values.

These automated checks do not certify physical Android speaker output or pixel-identical text rasterization. `latest_known_good` and platform verification fields remain unset until device verification.

`test/coucou_mochi_emotions_test.dart` adds keyframe, pose continuity, priority, finite/loop termination, seed replay, mute/cue, pause/resume, frozen-scrub and narrow/landscape demo coverage. It samples chill/music for 60 seconds at 60 FPS in normal and mini modes, checks the four-note bound, and reports sampling costs again one hour into the timeline. The ambient blink cache retains at most 32 scheduled entries; historical scrubs reconstruct the original seeded sequence when necessary. Music notes are evaluated from at most four beat indices without accumulating bursts.

For an optional visual review atlas on Windows, set `MOCHI_EMOTIONS_REVIEW` to a PNG path under `build/`, then run `flutter test test/coucou_mochi_emotions_test.dart`. The atlas uses the installed Arial font and shows all five emotes at 220 px, 80 px, mini size, and with the question-state badge. This rendering check and host-side timing diagnostics are not Android device verification.

## Caveats

- Reference motion, geometry and cues are ported from the local Coucou source. Blinks, ambient particles and mini behaviors use seeded randomness so gallery frames are reproducible; they do not reproduce a particular random run of the desktop app. Flutter and native/web text rasterization can differ. Platform windows and agent integrations remain outside this component.
- The mascot redraws each active frame and runs one `Ticker`; completed scenes stop theirs. Use `frozenAt` for thumbnails and static previews. Audio pools load on demand and retain up to three idle players per sound; active sounds may overlap.
- The package and bundled WAV folder make this component non-standalone without the install entries above. Keep asset paths relative to the project root.
- Character and sound rights remain reserved as described above, even for the locally copied files.

## Changelog

- `1.2.0` — added procedural Neko Pudding and Mây Bông skins across mascot, mini, mailbox, launch and upload; skin dropdown with preview reload, preserved mute preference and skin variants; added interaction and visual regression coverage.
- `1.1.0` — added suspicious/confused/chill/music/shy, continuous loop/stop transitions, BPM motion and bounded vector effects, frozen emote previews, responsive demo controls and regression coverage. No additional sounds or music playback.
- `1.0.1` — fixed audio asset resolution/retry, state entrances and recovery, swallow spring and eyes, emote keyframes, greeting interruption/cues, hover cooldown, particles and reference geometry; added the separate launch/upload scenes, mini behavior loops and upstream-frame regression checks.
- `1.0.0` — created the Flutter private-study port with procedural animation, interactive controls, gallery states, and local WAV playback.
