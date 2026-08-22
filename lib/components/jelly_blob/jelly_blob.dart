/// Jelly Blob
/// Origin: adapted — port of mortspace/feral-blob (MIT), a pokeable SVG
/// jelly-blob mascot for React, redrawn with CustomPainter on a pure-time
/// engine (no motion/framer dependency — springs are closed-form).
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '_engine.dart';
import '_geom.dart';
import '_painter.dart';
import '_palette.dart';

export '_engine.dart';
export '_geom.dart';
export '_painter.dart';
export '_palette.dart';
export '_speech.dart';

/// A playful, pokeable jelly-blob mascot. Seven moods reshape the face and
/// body (`sad` melts the silhouette, `happy` hops with squash-and-stretch,
/// `sideEye` glances sideways, `password` shuts its eyes and looks away);
/// underneath it idles with a slow physics-y slosh, random-but-seeded blinks
/// and little arm fidgets. Drive [gaze], [nod] and [mouth] from a form and
/// it reads along as the user types.
///
/// Poking it squashes it; six pokes in quick succession make it shake and
/// fire [onOverpoke] — wire that to a [JellyBlobSpeech] so it can protest.
///
/// The engine underneath ([JellyBlobEngine]) is a pure function of time —
/// pass [frozenAt] for a deterministic still frame (thumbnails, tests,
/// state boards; see [jellyMoodPoses] for a readable instant per mood).
class JellyBlobMascot extends StatefulWidget {
  const JellyBlobMascot({
    super.key,
    this.size = 240,
    this.mood = JellyBlobMood.neutral,
    this.palette = JellyBlobPalette.violet,
    this.happyEyes = JellyHappyEyes.star,
    this.gaze = Offset.zero,
    this.gazeIntensity,
    this.mouth,
    this.nod = false,
    this.pokeable = true,
    this.onOverpoke,
    this.animate = true,
    this.frozenAt,
    this.seed = 0,
  });

  /// Render width in logical pixels; height follows the 900:720 design box.
  final double size;

  /// Face and body expression. Changes spring smoothly from wherever the
  /// blob currently is.
  final JellyBlobMood mood;

  /// Colors. [JellyBlobPalette.violet] is the upstream skin; mint/coral/gold
  /// presets are hand-mixed, or bring your own.
  final JellyBlobPalette palette;

  /// Happy-mood eyes: sparkly stars (default) or closed `^_^` arcs.
  final JellyHappyEyes happyEyes;

  /// Nudges where the blob looks, in viewBox units (x -16..18, y -10..10) —
  /// e.g. glance at a field with `Offset(18, -8)`.
  final Offset gaze;

  /// How far the body leans along with the gaze (0..1). Defaults to a value
  /// derived from the gaze distance.
  final double? gazeIntensity;

  /// Override the mouth with an open talking shape; flip between
  /// [JellyTalkMouth.open]/[JellyTalkMouth.wide] per keystroke for a
  /// "talking along as you type" effect. Null uses the mood's mouth.
  final JellyTalkMouth? mouth;

  /// Subtle talking wobble for host-driven moments (typing into a watched
  /// field).
  final bool nod;

  /// Whether the widget handles taps itself (poke squash + overpoke). Set
  /// false and wrap it in your own GestureDetector if the host owns input.
  final bool pokeable;

  /// Fired when the blob is poked past its patience (6 pokes within 2.5 s).
  /// The blob also shakes itself. Firing resets the tally.
  final VoidCallback? onOverpoke;

  /// Stop the internal ticker from outside (the frame freezes where it is).
  final bool animate;

  /// Freeze the render at this many seconds into [mood]. The engine being
  /// pure in time, the image is reproducible to the pixel with no animation
  /// loop.
  final double? frozenAt;

  /// Varies the blink rhythm, arm fidget and arm rest pose between
  /// instances; same seed = same animation, frame for frame.
  final int seed;

  @override
  State<JellyBlobMascot> createState() => _JellyBlobMascotState();
}

class _JellyBlobMascotState extends State<JellyBlobMascot>
    with SingleTickerProviderStateMixin {
  late JellyBlobEngine _engine;
  late final Ticker _ticker;
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);
  double _t = 0;
  double _lastElapsed = 0;

  // poke tally (clock-dated, so no wall clock enters the component)
  int _pokes = 0;
  double _lastPokeT = -1e9;

  @override
  void initState() {
    super.initState();
    _engine = _buildEngine();
    _ticker = createTicker((elapsed) {
      final double e = elapsed.inMicroseconds / 1e6;
      // clamp dt so an app resume doesn't teleport every animation
      final double dt = (e - _lastElapsed).clamp(0.0, .064);
      _lastElapsed = e;
      _t += dt;
      _engine.sample(_t);
      _repaint.value++;
    });
  }

  /// Fresh engine already settled in the widget's current props: initial
  /// events are dated 10 s in the past so every spring is at rest.
  JellyBlobEngine _buildEngine() {
    final JellyBlobEngine e = JellyBlobEngine(
      mood: widget.mood,
      happyEyes: widget.happyEyes,
      seed: widget.seed,
    );
    const double past = -10;
    if (widget.gaze != Offset.zero || widget.gazeIntensity != null) {
      e.setGaze(widget.gaze.dx, widget.gaze.dy, widget.gazeIntensity, past);
    }
    if (widget.mouth != null) e.setTalk(widget.mouth, past);
    if (widget.nod) e.setNod(true, past);
    return e;
  }

  bool get _reduce => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  double? get _stillAt =>
      widget.frozenAt ?? (_reduce ? jellyMoodPoses[widget.mood] : null);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  void _syncTicker() {
    final bool live = widget.animate && _stillAt == null;
    if (live && !_ticker.isActive) {
      _lastElapsed = 0; // Ticker.start() restarts its elapsed from zero
      _ticker.start();
    } else if (!live && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void didUpdateWidget(JellyBlobMascot old) {
    super.didUpdateWidget(old);
    if (widget.seed != old.seed) {
      _engine = _buildEngine();
    } else {
      if (widget.mood != old.mood) _engine.setMood(widget.mood, _t);
      if (widget.happyEyes != old.happyEyes) {
        _engine.setHappyEyes(widget.happyEyes, _t);
      }
      if (widget.gaze != old.gaze ||
          widget.gazeIntensity != old.gazeIntensity) {
        _engine.setGaze(
            widget.gaze.dx, widget.gaze.dy, widget.gazeIntensity, _t);
      }
      if (widget.mouth != old.mouth) _engine.setTalk(widget.mouth, _t);
      if (widget.nod != old.nod) _engine.setNod(widget.nod, _t);
    }
    _syncTicker();
    if (!_ticker.isActive) _repaint.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _engine.boop(_t);
    if (_t - _lastPokeT > 2.5) _pokes = 0; // patience window
    _lastPokeT = _t;
    _pokes++;
    if (_pokes >= 6) {
      _pokes = 0;
      _engine.shake(_t);
      widget.onOverpoke?.call();
    }
    _repaint.value++;
  }

  @override
  Widget build(BuildContext context) {
    final double? still = _stillAt;
    final JellyFrame frame;
    if (still != null) {
      frame = _buildEngine().sample(still);
    } else {
      frame = _engine.sample(_t);
    }
    Widget child = CustomPaint(
      size: Size(widget.size,
          widget.size * kJellyViewBox.height / kJellyViewBox.width),
      isComplex: true,
      painter: JellyBlobPainter(
        frame: frame,
        palette: widget.palette,
        repaint: still == null ? _repaint : null,
      ),
    );
    if (widget.pokeable && still == null && !_reduce) {
      child = GestureDetector(
        onTapDown: _onTapDown,
        behavior: HitTestBehavior.opaque,
        child: child,
      );
    }
    return Semantics(
      label: 'Jelly blob mascot, ${widget.mood.name}',
      image: true,
      child: child,
    );
  }
}
