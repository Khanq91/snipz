/// FireflySwarm
/// Origin: reimplemented — port of the "additive fireflies" example from
/// anime.js v4 (juliangarnier/anime, examples/additive-fireflies): hundreds
/// of colored particles buzz around a ring centered on the pointer; pressing
/// widens the ring and the swarm scatters out. The original's 250ms retarget
/// + `composition: 'blend'` is emulated with per-particle exponential
/// pursuit of freshly rolled rim points.
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A swarm of fireflies orbiting the finger. Touch to gather them, hold to
/// scatter the ring wide, release and they drift after an auto-wandering
/// point. Fills the box it is given.
class FireflySwarm extends StatefulWidget {
  const FireflySwarm({
    super.key,
    this.count = 225,
    this.colors = const <Color>[
      Color(0xFFFF4B4B),
      Color(0xFFFF8B6A),
      Color(0xFFFFA24B),
    ],
    this.backgroundColor = const Color(0xFF120D0B),
    this.dotRadius = 3.2,
    this.ringRadius = 64,
    this.interactive = true,
    this.showRing = true,
    this.seed = 3,
    this.animate = true,
    this.frozenAt,
  });

  /// Number of fireflies (upstream: 15² = 225).
  final int count;

  /// Firefly tints, assigned per particle by the seeded PRNG.
  final List<Color> colors;

  /// Painted behind the swarm. Use [Colors.transparent] to overlay.
  final Color backgroundColor;

  /// Base radius of one firefly (each runs a ×0.6..×1.5 personal scale).
  final double dotRadius;

  /// Resting ring radius the swarm orbits; holding a touch widens it ×2.5.
  final double ringRadius;

  /// False ignores touch — the swarm only follows the auto-wander point.
  final bool interactive;

  /// Faint circle marking the pointer (the upstream cursor disc).
  final bool showRing;

  /// PRNG seed — same seed, same buzz.
  final int seed;

  /// False freezes the ticker (viewer freeze button / reduced motion).
  final bool animate;

  /// Non-null renders exactly one deterministic frame at t seconds — no
  /// ticker (thumbnails, golden tests).
  final double? frozenAt;

  @override
  State<FireflySwarm> createState() => _FireflySwarmState();
}

class _FireflySwarmState extends State<FireflySwarm>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);
  _SwarmEngine? _engine;

  Offset? _touch;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(
        (elapsed) => _t.value = elapsed.inMicroseconds / 1e6);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(FireflySwarm old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count || old.seed != widget.seed) _engine = null;
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size size = constraints.biggest;
        _engine ??= _SwarmEngine(
          count: widget.count,
          seed: widget.seed,
          ringRadius: widget.ringRadius,
        );
        final Widget paint = ValueListenableBuilder<double>(
          valueListenable: _t,
          builder: (context, t, _) {
            final double now = widget.frozenAt ?? t;
            if (widget.frozenAt != null) {
              // warm start 2s back so the frozen swarm sits mid-buzz
              _engine!.advanceTo(now - 2, size, null, false);
            }
            _engine!.advanceTo(
              now,
              size,
              _touch == null
                  ? null
                  : _touch! - size.center(Offset.zero),
              _down,
            );
            return CustomPaint(
              size: size,
              painter: _SwarmPainter(
                engine: _engine!,
                colors: widget.colors,
                backgroundColor: widget.backgroundColor,
                dotRadius: widget.dotRadius,
                showRing: widget.showRing,
                repaint: _t,
              ),
            );
          },
        );
        if (!widget.interactive) return paint;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) {
            _touch = d.localPosition;
            _down = true;
          },
          onPanUpdate: (d) => _touch = d.localPosition,
          onPanEnd: (_) {
            _touch = null;
            _down = false;
          },
          onPanCancel: () {
            _touch = null;
            _down = false;
          },
          child: paint,
        );
      },
    );
  }
}

/// Deterministic swarm simulation — seeded PRNG, fixed-step integration,
/// no wall clock. Reproducible from t=0 for any frozen time.
class _SwarmEngine {
  _SwarmEngine({
    required this.count,
    required this.seed,
    required this.ringRadius,
  }) {
    _px = List<double>.filled(count, 0);
    _py = List<double>.filled(count, 0);
    _vx = List<double>.filled(count, 0);
    _vy = List<double>.filled(count, 0);
    _scale = List<double>.filled(count, 1);
    for (int i = 0; i < count; i++) {
      _phase.add(_rand01(i, -1));
      _tau.add(.28 + .30 * _rand01(i, -2));
      _tint.add(_rand01(i, -3));
    }
  }

  final int count;
  final int seed;
  final double ringRadius;

  late final List<double> _px, _py, _vx, _vy, _scale;
  final List<double> _phase = [];
  final List<double> _tau = [];
  final List<double> _tint = [];

  double _lastT = -1;
  Size _size = Size.zero;
  bool _init = false;

  // pointer state the painter reads
  double pointerX = 0, pointerY = 0;
  double ringR = 0;
  double pressGlow = 0; // 0 idle → 1 held down

  double get time => _lastT;
  double x(int i) => _px[i];
  double y(int i) => _py[i];
  double scaleOf(int i) => _scale[i];
  double tintOf(int i) => _tint[i];

  double _rand01(int a, int b) {
    int h = seed ^ (a * 0x9E3779B1) ^ (b * 0x85EBCA77);
    h = (h ^ (h >> 15)) * 0x2C1B3C6D & 0xFFFFFFFF;
    h = (h ^ (h >> 12)) * 0x297A2D39 & 0xFFFFFFFF;
    h ^= h >> 15;
    return h / 0x100000000;
  }

  /// Auto-wander pointer path — slow lissajous over ~60% of the box.
  Offset autoPointer(double t) {
    final double hw = _size.width * .30, hh = _size.height * .30;
    return Offset(
      math.sin(t * .61) * hw + math.sin(t * .173) * hw * .5,
      math.cos(t * .47) * hh + math.sin(t * .223) * hh * .5,
    );
  }

  void advanceTo(double t, Size size, Offset? touch, bool down) {
    _size = size;
    if (!_init) {
      _init = true;
      final Offset p0 = touch ?? autoPointer(t);
      for (int i = 0; i < count; i++) {
        final double a = _rand01(i, -4) * math.pi * 2;
        _px[i] = p0.dx + math.cos(a) * ringRadius;
        _py[i] = p0.dy + math.sin(a) * ringRadius;
        _vx[i] = _px[i];
        _vy[i] = _py[i];
      }
      pointerX = p0.dx;
      pointerY = p0.dy;
      ringR = ringRadius;
      _lastT = t;
      return;
    }
    if (t <= _lastT) return;
    double now = _lastT;
    if (t - now > 2.0) now = t - 2.0; // clamp resume gaps
    final double targetRing = down ? ringRadius * 2.5 : ringRadius;
    final double targetGlow = down ? 1 : 0;
    while (now < t) {
      final double dt = math.min(.032, t - now);
      now += dt;
      final Offset p = touch ?? autoPointer(now);
      final double kp = 1 - math.exp(-dt / .10);
      pointerX += (p.dx - pointerX) * kp;
      pointerY += (p.dy - pointerY) * kp;
      ringR += (targetRing - ringR) * (1 - math.exp(-dt / .18));
      pressGlow += (targetGlow - pressGlow) * (1 - math.exp(-dt / .12));
      for (int i = 0; i < count; i++) {
        // each firefly rerolls its rim target every 250ms, phase-shifted
        final int k = ((now / .25) + _phase[i]).floor();
        final double a = _rand01(i, k * 5 + 1) * math.pi * 2;
        final double tx = pointerX + math.cos(a) * ringR;
        final double ty = pointerY + math.sin(a) * ringR;
        final double kf = 1 - math.exp(-dt / _tau[i]);
        _vx[i] += (tx - _vx[i]) * kf;
        _vy[i] += (ty - _vy[i]) * kf;
        _px[i] += (_vx[i] - _px[i]) * kf;
        _py[i] += (_vy[i] - _py[i]) * kf;
        final double targetScale = .6 + .9 * _rand01(i, k * 5 + 2);
        _scale[i] += (targetScale - _scale[i]) * kf;
      }
    }
    _lastT = t;
  }
}

class _SwarmPainter extends CustomPainter {
  _SwarmPainter({
    required this.engine,
    required this.colors,
    required this.backgroundColor,
    required this.dotRadius,
    required this.showRing,
    super.repaint,
  });

  final _SwarmEngine engine;
  final List<Color> colors;
  final Color backgroundColor;
  final double dotRadius;
  final bool showRing;

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundColor.a > 0) {
      canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    }
    final Offset center = size.center(Offset.zero);
    canvas.save();
    canvas.translate(center.dx, center.dy);

    if (showRing) {
      final Offset p = Offset(engine.pointerX, engine.pointerY);
      final double g = engine.pressGlow;
      final double r = engine.ringR * (1 - .3 * g);
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..color =
              const Color(0xFFFFFFFF).withValues(alpha: .06 + .10 * g),
      );
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color =
              const Color(0xFFFFFFFF).withValues(alpha: .14 + .22 * g),
      );
    }

    final Paint glow = Paint();
    final Paint core = Paint();
    for (int i = 0; i < engine.count; i++) {
      final Color c =
          colors[(engine.tintOf(i) * colors.length).floor() % colors.length];
      final Offset pos = Offset(engine.x(i), engine.y(i));
      final double r = dotRadius * engine.scaleOf(i);
      glow.shader = RadialGradient(colors: <Color>[
        c.withValues(alpha: .5),
        c.withValues(alpha: 0),
      ]).createShader(Rect.fromCircle(center: pos, radius: r * 3));
      canvas.drawCircle(pos, r * 3, glow);
      core.color = c;
      canvas.drawCircle(pos, r, core);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SwarmPainter old) =>
      old.engine != engine ||
      old.colors != colors ||
      old.backgroundColor != backgroundColor ||
      old.dotRadius != dotRadius ||
      old.showRing != showRing;
}
