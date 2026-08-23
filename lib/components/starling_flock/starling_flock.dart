/// StarlingFlock
/// Origin: reimplemented — port of the "timeline refresh starlings" example
/// from anime.js v4 (juliangarnier/anime,
/// examples/timeline-refresh-starlings): thousands of dots ease toward
/// random points inside a target circle that itself wanders, breathes and
/// resizes — reading as a starling murmuration.
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A murmuration of dots: each bird glides (inOut, ~3s) to a fresh random
/// point inside an invisible circle whose center and radius keep drifting.
/// Fully autonomous; fills the box it is given.
class StarlingFlock extends StatefulWidget {
  const StarlingFlock({
    super.key,
    this.count = 1200,
    this.backgroundColor = const Color(0xFFF6F4F2),
    this.colors,
    this.dotRadius = 1.7,
    this.seed = 7,
    this.animate = true,
    this.frozenAt,
  });

  /// Number of birds. Upstream runs 2500 on desktop; 1200 keeps a phone at
  /// 60fps with headroom.
  final int count;

  /// Painted behind the flock. Use [Colors.transparent] to overlay.
  final Color backgroundColor;

  /// Bird colors, picked per bird by the seeded PRNG. Null uses the upstream
  /// ramp: dark warm browns, hsl(15..25, 60%, 10..18%).
  final List<Color>? colors;

  final double dotRadius;

  /// PRNG seed — same seed, same murmuration, every run.
  final int seed;

  /// False freezes the ticker (viewer freeze button / reduced motion).
  final bool animate;

  /// Non-null renders exactly one deterministic frame at t seconds — no
  /// ticker (thumbnails, golden tests).
  final double? frozenAt;

  @override
  State<StarlingFlock> createState() => _StarlingFlockState();
}

class _StarlingFlockState extends State<StarlingFlock>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);
  _FlockEngine? _engine;

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
  void didUpdateWidget(StarlingFlock old) {
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
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final Size size = constraints.biggest;
          _engine ??= _FlockEngine(count: widget.count, seed: widget.seed);
          return ValueListenableBuilder<double>(
            valueListenable: _t,
            builder: (context, t, _) {
              // upstream seeks 20s in so the flock starts settled
              _engine!.advanceTo((widget.frozenAt ?? t) + 20, size);
              return CustomPaint(
                size: size,
                painter: _FlockPainter(
                  engine: _engine!,
                  backgroundColor: widget.backgroundColor,
                  colors: widget.colors,
                  dotRadius: widget.dotRadius,
                  repaint: _t,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Deterministic murmuration simulation — no wall clock, all randomness from
/// a seeded LCG keyed by (seed, bird, cycle), so any absolute time can be
/// reproduced by advancing from zero.
class _FlockEngine {
  _FlockEngine({required this.count, required this.seed}) {
    _fromX = Float32List(count);
    _fromY = Float32List(count);
    _toX = Float32List(count);
    _toY = Float32List(count);
    _start = Float64List(count);
    _dur = Float64List(count);
    _cycle = Int32List(count);
    _posBuf = Float32List(count * 2);
    // staggered first take-off: i * (3000/count) * 1.125 ms
    for (int i = 0; i < count; i++) {
      _start[i] = i * (3.0 / count) * 1.125;
      _dur[i] = 0; // zero-length "cycle 0" — resolves on first advance
      _cycle[i] = 0;
    }
  }

  final int count;
  final int seed;

  static const int _buckets = 6;

  late final Float32List _fromX, _fromY, _toX, _toY;
  late final Float64List _start, _dur;
  late final Int32List _cycle;
  late final Float32List _posBuf;
  double _lastT = -1;
  Size _size = Size.zero;
  bool _initialized = false;

  Float32List get positions => _posBuf;

  /// Bucket b = birds [b·count/6, (b+1)·count/6) — bird index does not
  /// correlate with screen position, so range buckets look fully mixed and
  /// let the painter draw zero-copy sublist views.
  (int, int) bucketRange(int b) => (
        (b * count) ~/ _buckets,
        ((b + 1) * count) ~/ _buckets,
      );

  /// Deterministic uniform [0,1) from (seed, a, b).
  double _rand01(int a, int b) {
    int h = seed ^ (a * 0x9E3779B1) ^ (b * 0x85EBCA77);
    h = (h ^ (h >> 15)) * 0x2C1B3C6D & 0xFFFFFFFF;
    h = (h ^ (h >> 12)) * 0x297A2D39 & 0xFFFFFFFF;
    h ^= h >> 15;
    return h / 0x100000000;
  }

  double _lerpRand(int a, int b, double lo, double hi) =>
      lo + (hi - lo) * _rand01(a, b);

  static double _inOutPow(double p, double n) {
    if (p <= 0) return 0;
    if (p >= 1) return 1;
    return p < .5
        ? math.pow(2 * p, n) / 2
        : 1 - math.pow(2 - 2 * p, n) / 2;
  }

  /// Wandering target circle — the upstream chained tweens, closed form.
  /// Returns (cx, cy, r) at time t.
  (double, double, double) _target(double t) {
    final double ex = _size.width * .26, ey = _size.height * .26;
    // x: chained 2.8s tweens between seeded randoms, ease inOut(1.3)
    final int kx = (t / 2.8).floor();
    final double exs = _inOutPow(t / 2.8 - kx, 1.3);
    double cx = _lerpRand(kx, 101, -ex, ex) * (1 - exs) +
        _lerpRand(kx + 1, 101, -ex, ex) * exs;
    cx += math.sin(t * 1000 * .0007) * ex * .65;
    // y: 1.8s
    final int ky = (t / 1.8).floor();
    final double eys = _inOutPow(t / 1.8 - ky, 1.3);
    double cy = _lerpRand(ky, 202, -ey, ey) * (1 - eys) +
        _lerpRand(ky + 1, 202, -ey, ey) * eys;
    cy += math.cos(t * 1000 * .00012) * ey * .65;
    // r: 1.25s between ex*[.05,.5]
    final int kr = (t / 1.25).floor();
    final double ers = _inOutPow(t / 1.25 - kr, 1.3);
    final double r = _lerpRand(kr, 303, ex * .05, ex * .5) * (1 - ers) +
        _lerpRand(kr + 1, 303, ex * .05, ex * .5) * ers;
    return (cx, cy, r);
  }

  void advanceTo(double t, Size size) {
    _size = size;
    if (!_initialized) {
      _initialized = true;
      for (int i = 0; i < count; i++) {
        _fromX[i] = 0;
        _fromY[i] = 0;
        _toX[i] = 0;
        _toY[i] = 0;
      }
    }
    if (t == _lastT) return;
    for (int i = 0; i < count; i++) {
      // resolve finished glide cycles up to t
      while (_start[i] + _dur[i] <= t) {
        final double endT = _start[i] + _dur[i];
        _fromX[i] = _toX[i];
        _fromY[i] = _toY[i];
        _start[i] = endT;
        _cycle[i]++;
        final int k = _cycle[i];
        _dur[i] = 3.0 + _lerpRand(i, k * 7 + 1, -.1, .1);
        final (double cx, double cy, double r) = _target(endT);
        final double theta = _rand01(i, k * 7 + 2) * math.pi * 2;
        final double rad = r * math.sqrt(_rand01(i, k * 7 + 3));
        _toX[i] = (cx + math.cos(theta) * rad).toDouble();
        _toY[i] = (cy + math.sin(theta) * rad).toDouble();
        if (_dur[i] <= 0) break; // safety, never expected
      }
      final double p =
          _dur[i] <= 0 ? 1 : ((t - _start[i]) / _dur[i]).clamp(0.0, 1.0);
      final double e = _inOutPow(p, 1.5);
      _posBuf[i * 2] = _fromX[i] + (_toX[i] - _fromX[i]) * e;
      _posBuf[i * 2 + 1] = _fromY[i] + (_toY[i] - _fromY[i]) * e;
    }
    _lastT = t;
  }

  /// Upstream ramp: hsl(15..25, 60%, 10..18%), keyed per bucket.
  Color bucketColor(int b, List<Color>? palette) {
    if (palette != null && palette.isNotEmpty) {
      return palette[b % palette.length];
    }
    final double h = 15 + 10 * _rand01(b, 404);
    final double l = .10 + .08 * _rand01(b, 505);
    return HSLColor.fromAHSL(1, h, .6, l).toColor();
  }
}

class _FlockPainter extends CustomPainter {
  _FlockPainter({
    required this.engine,
    required this.backgroundColor,
    required this.colors,
    required this.dotRadius,
    super.repaint,
  });

  final _FlockEngine engine;
  final Color backgroundColor;
  final List<Color>? colors;
  final double dotRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundColor.a > 0) {
      canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    }
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final Float32List pos = engine.positions;
    // one drawRawPoints per color bucket — 6 draw calls for the whole flock
    for (int b = 0; b < _FlockEngine._buckets; b++) {
      final (int lo, int hi) = engine.bucketRange(b);
      if (hi <= lo) continue;
      canvas.drawRawPoints(
        PointMode.points,
        Float32List.sublistView(pos, lo * 2, hi * 2),
        Paint()
          ..color = engine.bucketColor(b, colors)
          ..strokeWidth = dotRadius * 2
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FlockPainter old) =>
      old.engine != engine ||
      old.backgroundColor != backgroundColor ||
      old.colors != colors ||
      old.dotRadius != dotRadius;
}
