/// AdditiveCreature
/// Origin: reimplemented — port of the "additive creature" example from
/// anime.js v4 (juliangarnier/anime, examples/additive-creature): a 13×13
/// stack of glowing dots that trails the pointer as one comet-like creature,
/// pulses in waves and wanders on its own when idle. The original relies on
/// anime's `composition: 'blend'`; here each dot runs a cascaded exponential
/// pursuit of a per-dot-delayed cursor, which produces the same look.
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A glowing dot-swarm "creature" that follows the finger and breathes in
/// pulse waves. Fills the box it is given; drag anywhere to lead it, release
/// and after 1.5s it resumes wandering by itself.
class AdditiveCreature extends StatefulWidget {
  const AdditiveCreature({
    super.key,
    this.rows = 13,
    this.color = const Color(0xFFE8442E),
    this.backgroundColor = const Color(0xFF190D08),
    this.dotRadius = 5.0,
    this.interactive = true,
    this.animate = true,
    this.frozenAt,
  });

  /// Grid side; the creature is rows×rows dots stacked on one point.
  final int rows;

  /// Creature tint. Its hue/saturation drive the light-core → dark-halo ramp
  /// (the upstream hsl(4, 70%, 80%→20%)).
  final Color color;

  /// Painted behind the creature. Use [Colors.transparent] to overlay.
  final Color backgroundColor;

  /// Radius of a scale-1 dot in logical px (dots run ×2 core to ×5 halo).
  final double dotRadius;

  /// False ignores touch — the creature only wanders on its own.
  final bool interactive;

  /// False freezes the ticker (viewer freeze button / reduced motion).
  final bool animate;

  /// Non-null renders exactly one deterministic frame at t seconds — no
  /// ticker (thumbnails, golden tests).
  final double? frozenAt;

  @override
  State<AdditiveCreature> createState() => _AdditiveCreatureState();
}

class _AdditiveCreatureState extends State<AdditiveCreature>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);
  _CreatureEngine? _engine;

  // manual-drag state (live only — the engine itself stays pure in t)
  Offset? _drag;
  double _resumeAutoAt = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    _t.value = elapsed.inMicroseconds / 1e6;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(AdditiveCreature old) {
    super.didUpdateWidget(old);
    if (old.rows != widget.rows || old.frozenAt != widget.frozenAt) {
      _engine = null;
    }
    _syncTicker();
  }

  void _syncTicker() {
    final bool reduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bool run = widget.animate && widget.frozenAt == null && !reduced;
    if (run && !_ticker.isActive) {
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  void _onPanDown(Offset local, Size size) {
    if (!widget.interactive) return;
    _drag = local - size.center(Offset.zero);
  }

  void _onPanEnd() {
    _drag = null;
    _resumeAutoAt = _t.value + 1.5;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size size = constraints.biggest;
        _engine ??= _CreatureEngine(
          rows: widget.rows,
          seedTime: widget.frozenAt ?? 0,
        );
        final Widget paint = ValueListenableBuilder<double>(
          valueListenable: _t,
          builder: (context, t, _) {
            final double now = widget.frozenAt ?? t;
            final bool auto = _drag == null && now >= _resumeAutoAt;
            if (widget.frozenAt != null) {
              // warm start 2s back so the frozen frame carries a real trail
              _engine!.advanceTo(now - 2, size, null);
            }
            _engine!.advanceTo(now, size, auto ? null : _drag);
            return CustomPaint(
              size: size,
              painter: _CreaturePainter(
                engine: _engine!,
                color: widget.color,
                backgroundColor: widget.backgroundColor,
                dotRadius: widget.dotRadius,
                repaint: _t,
              ),
            );
          },
        );
        if (!widget.interactive) return paint;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => _onPanDown(d.localPosition, size),
          onPanUpdate: (d) => _onPanDown(d.localPosition, size),
          onPanEnd: (_) => _onPanEnd(),
          onPanCancel: _onPanEnd,
          child: paint,
        );
      },
    );
  }
}

/// Pure-in-time simulation. Everything the painter reads is a deterministic
/// function of the advanced-to time (given the same drag input trail);
/// auto-wander, pulse schedule and per-dot params contain no wall clock and
/// no unseeded randomness.
class _CreatureEngine {
  _CreatureEngine({required this.rows, double seedTime = 0}) {
    final double c = (rows - 1) / 2;
    final double maxD = math.sqrt(2) * c;
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < rows; col++) {
        final double d = math.sqrt(
            (col - c) * (col - c) + (row - c) * (row - c));
        final double nd = maxD == 0 ? 0 : d / maxD;
        _dist.add(d);
        // upstream staggers, all "from: center":
        // scale [2..5] inQuad, opacity [1..0.1] linear,
        // lightness [80..20], glow [8..1], z-order center-on-top
        _scale.add(2 + 3 * nd * nd);
        _opacity.add(1 - .9 * nd);
        _lightness.add(.80 - .60 * nd);
        _glow.add(8 - 7 * nd);
        // follow delay 40ms/cell, duration 750+120 inQuad — the pursuit lag
        _delay.add(.040 * d);
        _tau.add((0.75 + 1.02 * nd * nd) / 3.5);
      }
    }
    // paint order: faint big halo dots first, bright core last
    _order = List<int>.generate(rows * rows, (i) => i)
      ..sort((a, b) => _dist[b].compareTo(_dist[a]));
    _lastT = seedTime;
    _historyT = seedTime;
  }

  final int rows;

  // per-dot static params
  final List<double> _dist = [];
  final List<double> _scale = [];
  final List<double> _opacity = [];
  final List<double> _lightness = [];
  final List<double> _glow = [];
  final List<double> _delay = [];
  final List<double> _tau = [];
  late final List<int> _order;

  // per-dot filter state (cascade of two one-pole filters)
  List<double>? _v1x, _v1y, _v2x, _v2y;

  // cursor history ring for per-dot delayed targets (~400ms deep)
  static const int _histLen = 32;
  static const double _histStep = .016;
  final List<Offset> _hist = List<Offset>.filled(_histLen, Offset.zero);
  int _histHead = 0;
  double _historyT = 0;

  double _lastT = 0;
  Size _size = Size.zero;

  int get count => rows * rows;
  List<double> get scaleOf => _scale;
  List<double> get opacityOf => _opacity;
  List<double> get lightnessOf => _lightness;
  List<double> get glowOf => _glow;
  List<int> get paintOrder => _order;
  double get time => _lastT;

  double dotX(int i) => _v2x![i];
  double dotY(int i) => _v2y![i];

  /// Pulse wave factor 0..1 for dot i at time t — every 3s of auto motion a
  /// wave leaves the center 1.65s in (upstream delay stagger 90ms/cell,
  /// start 1650, up 150ms, settle 600ms inOutQuad).
  double pulse(int i, double t) {
    final double local = (t % 3.0) - 1.65 - .090 * _dist[i];
    if (local <= 0) return 0;
    if (local < .150) return local / .150;
    if (local < .750) {
      final double p = (local - .150) / .600;
      // inOutQuad down
      final double e =
          p < .5 ? 2 * p * p : 1 - math.pow(-2 * p + 2, 2) / 2;
      return 1 - e;
    }
    return 0;
  }

  /// Auto-wander cursor path — the upstream autoMove timeline, closed form.
  Offset autoCursor(double t) {
    final double hw = _size.width / 2, hh = _size.height / 2;
    final double ms = t * 1000;
    final double xt = _alternate(ms / 3000);
    final double x = (2 * _inOutExpo(xt) - 1) * .45 * hw +
        math.sin(ms * .0007) * .5 * hw;
    final double yt = _alternate(ms / 1000);
    final double y = (2 * _inOutQuad(yt) - 1) * .45 * hh +
        math.cos(ms * .00012) * .5 * hh;
    return Offset(x, y);
  }

  static double _alternate(double cycles) {
    final double m = cycles % 2;
    return m < 1 ? m : 2 - m;
  }

  static double _inOutExpo(double p) {
    if (p <= 0 || p >= 1) return p.clamp(0, 1).toDouble();
    return p < .5
        ? math.pow(2, 20 * p - 10) / 2
        : (2 - math.pow(2, -20 * p + 10)) / 2;
  }

  static double _inOutQuad(double p) =>
      p < .5 ? 2 * p * p : 1 - math.pow(-2 * p + 2, 2) / 2;

  Offset _delayedCursor(double delay) {
    final int back = (delay / _histStep).round().clamp(0, _histLen - 1);
    return _hist[(_histHead - back + _histLen * 4) % _histLen];
  }

  /// Advance the simulation to absolute time [t]. [drag] non-null pins the
  /// cursor to that point (manual lead), null follows the auto path.
  void advanceTo(double t, Size size, Offset? drag) {
    _size = size;
    if (_v1x == null) {
      final Offset start = drag ?? autoCursor(t);
      _v1x = List<double>.filled(count, start.dx);
      _v1y = List<double>.filled(count, start.dy);
      _v2x = List<double>.filled(count, start.dx);
      _v2y = List<double>.filled(count, start.dy);
      for (int k = 0; k < _histLen; k++) {
        _hist[k] = start;
      }
      _lastT = t;
      _historyT = t;
      return;
    }
    if (t <= _lastT) return;
    double now = _lastT;
    // clamp long gaps (app resume) so we never grind through minutes
    if (t - now > 2.0) {
      now = t - 2.0;
      _historyT = now;
    }
    while (now < t) {
      final double dt = math.min(.032, t - now);
      now += dt;
      final Offset cursor = drag ?? autoCursor(now);
      while (_historyT + _histStep <= now) {
        _historyT += _histStep;
        _histHead = (_histHead + 1) % _histLen;
        _hist[_histHead] = cursor;
      }
      for (int i = 0; i < count; i++) {
        final Offset target = _delayedCursor(_delay[i]);
        final double k = 1 - math.exp(-dt / _tau[i]);
        _v1x![i] += (target.dx - _v1x![i]) * k;
        _v1y![i] += (target.dy - _v1y![i]) * k;
        _v2x![i] += (_v1x![i] - _v2x![i]) * k;
        _v2y![i] += (_v1y![i] - _v2y![i]) * k;
      }
    }
    _lastT = t;
  }
}

class _CreaturePainter extends CustomPainter {
  _CreaturePainter({
    required this.engine,
    required this.color,
    required this.backgroundColor,
    required this.dotRadius,
    super.repaint,
  });

  final _CreatureEngine engine;
  final Color color;
  final Color backgroundColor;
  final double dotRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundColor.a > 0) {
      canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    }
    final Offset center = size.center(Offset.zero);
    final HSLColor hsl = HSLColor.fromColor(color);
    final double t = engine.time;
    final Paint glowPaint = Paint();
    final Paint corePaint = Paint();
    for (final int i in engine.paintOrder) {
      final double p = engine.pulse(i, t);
      final double scale =
          engine.scaleOf[i] + (5 - engine.scaleOf[i]) * p;
      final double opacity =
          (engine.opacityOf[i] + (1 - engine.opacityOf[i]) * p)
              .clamp(0.0, 1.0);
      final Offset pos =
          center + Offset(engine.dotX(i), engine.dotY(i));
      final double r = dotRadius * scale;
      final Color c = hsl
          .withLightness(engine.lightnessOf[i].clamp(0.0, 1.0))
          .toColor();
      // halo — radial gradient fade instead of css box-shadow blur
      final double glowR = r + engine.glowOf[i] * dotRadius * 1.6;
      glowPaint.shader = _radial(pos, glowR, c, opacity * .55);
      canvas.drawCircle(pos, glowR, glowPaint);
      corePaint.color = c.withValues(alpha: opacity);
      canvas.drawCircle(pos, r, corePaint);
    }
  }

  static Shader _radial(Offset c, double r, Color color, double alpha) {
    return RadialGradient(colors: [
      color.withValues(alpha: alpha),
      color.withValues(alpha: 0),
    ]).createShader(Rect.fromCircle(center: c, radius: r));
  }

  @override
  bool shouldRepaint(_CreaturePainter old) =>
      old.engine != engine ||
      old.color != color ||
      old.backgroundColor != backgroundColor ||
      old.dotRadius != dotRadius;
}
