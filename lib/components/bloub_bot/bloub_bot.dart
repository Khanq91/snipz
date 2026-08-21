/// Bloub Bot
/// Origin: adapted — port of jeremy-prt/bloub (MIT), an SVG recreation of
/// the x.ai bot avatar measured frame-by-frame off the reference video.
/// Deps: flutter only
/// Flutter: 3.47.1
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '_engine.dart';
import '_expressions.dart';
import '_painter.dart';
import '_skins.dart';
import '_states.dart';

export '_decor.dart';
export '_engine.dart';
export '_expressions.dart';
export '_eyefit.dart';
export '_face.dart';
export '_math.dart';
export '_painter.dart';
export '_profiles.dart';
export '_shape.dart';
export '_skins.dart';
export '_states.dart';
export '_svg.dart';

/// A morphing bot avatar: one filled shape that morphs between states, two
/// eyes that are REAL HOLES in the body, living on a sphere. Use it as an
/// AI-assistant mascot, a loading indicator, or an empty-state character.
///
/// The engine underneath ([BloubBotEngine]) is a pure function of time —
/// pass [frozenAt] for a deterministic still frame (thumbnails, tests,
/// state boards), or drive states live via [state].
///
/// Not a button: wrap it in a GestureDetector in the host app if it should
/// react to taps.
class BloubBot extends StatefulWidget {
  const BloubBot({
    super.key,
    this.size = 160,
    this.state = BloubBotState.idle,
    this.ink,
    this.paper,
    this.frozenAt,
    this.animate = true,
    this.expression,
    this.shape,
  });

  /// Side of the square the bot renders in, logical pixels.
  final double size;

  /// Current state. Changing it morphs — the widget dates the transition on
  /// its internal clock, so chained changes stay continuous.
  final BloubBotState state;

  /// Body color. Defaults to the upstream measured near-black (#0a0a0c).
  final Color? ink;

  /// The color BEHIND the widget. The eyes are holes backed by this color,
  /// so it should match the actual background for the "pierced" look.
  /// Defaults to `Theme.of(context).colorScheme.surface`.
  final Color? paper;

  /// Freeze the render at this many seconds into [state]. The engine being
  /// pure in time, the image is reproducible to the pixel with no animation
  /// loop. See [botStatePoses] for each state's most readable instant.
  final double? frozenAt;

  /// Stop the internal ticker from outside (the frame freezes where it is).
  final bool animate;

  /// Resting expression id ([kBotExpressions]: neutre, heureux, colere,
  /// triste…). Only the resting face wears it (`baseFace` states); changes
  /// glide. Null or unknown = the measured neutral.
  final String? expression;

  /// Customizer shape id ([kBotShapes]: cercle, galet, squircle, capsule,
  /// triangle, hexagone, nuage, goutte). Replaces the body only on resting
  /// (`baseBody`) states — elsewhere the silhouette IS the animation.
  /// Changes morph; the eye-offset table keeps the face inside the outline.
  final String? shape;

  @override
  State<BloubBot> createState() => _BloubBotState();
}

class _BloubBotState extends State<BloubBot>
    with SingleTickerProviderStateMixin {
  late final BloubBotEngine _engine = BloubBotEngine(
    initial: widget.state,
    shape: widget.shape == null ? null : botShapeById[widget.shape!]?.radii,
    expression:
        widget.expression == null ? null : botExpressionById[widget.expression!],
  );
  late final Ticker _ticker = createTicker(_tick);

  /// Scene clock, seconds. Delta is clamped so an app resumed from the
  /// background does not jump forward.
  double _clock = 0;
  Duration _last = Duration.zero;
  BotFrame? _frame;

  @override
  void initState() {
    super.initState();
    final double? frozen = widget.frozenAt;
    if (frozen != null) {
      _frame = _engine.sample(frozen);
    } else if (widget.animate) {
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final double dt =
        ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.064);
    _last = elapsed;
    _clock += dt;
    setState(() => _frame = _engine.sample(_clock));
  }

  @override
  void didUpdateWidget(BloubBot old) {
    super.didUpdateWidget(old);
    if (widget.state != old.state) {
      _engine.setState(widget.state, _clock);
    }
    if (widget.shape != old.shape) {
      // dated: the engine morphs to the new shape instead of jumping
      _engine.setShape(
          widget.shape == null ? null : botShapeById[widget.shape!]?.radii,
          _clock);
    }
    if (widget.expression != old.expression) {
      _engine.setExpression(
          widget.expression == null
              ? null
              : botExpressionById[widget.expression!],
          _clock);
    }
    final double? frozen = widget.frozenAt;
    if (frozen != null) {
      if (_ticker.isActive) _ticker.stop();
      _frame = _engine.sample(frozen);
    } else {
      if (widget.animate && !_ticker.isActive) {
        _last = Duration.zero;
        _ticker.start();
      } else if (!widget.animate && _ticker.isActive) {
        _ticker.stop();
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BotFrame frame = _frame ?? _engine.sample(widget.frozenAt ?? 0);
    return CustomPaint(
      size: Size.square(widget.size),
      painter: BloubBotPainter(
        frame: frame,
        ink: widget.ink ?? const Color(0xFF0A0A0C),
        paper: widget.paper ?? Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
