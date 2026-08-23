/// LineDrawing
/// Origin: reimplemented — port of the "svg line drawing" example from
/// anime.js v4 (juliangarnier/anime, examples/svg-line-drawing): concentric
/// circles (or a curtain of vertical lines) whose strokes draw themselves as
/// travelling segments, each on its own staggered 10s loop, tinting from
/// green to red as they sweep. All closed-form in t.
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Which upstream plate to draw.
enum LineDrawingVariant { circles, lines }

/// Self-drawing strokes: every circle (or vertical line) carries a segment
/// of paint that grows, travels along the path and dissolves, staggered
/// across the set so the whole plate keeps breathing. Fills its box.
class LineDrawing extends StatefulWidget {
  const LineDrawing({
    super.key,
    this.variant = LineDrawingVariant.circles,
    this.count,
    this.colorFrom = const Color(0xFFA4FF4F),
    this.colorTo = const Color(0xFFFF4B4B),
    this.backgroundColor = const Color(0xFF161514),
    this.strokeWidth,
    this.seed = 9,
    this.animate = true,
    this.frozenAt,
  });

  final LineDrawingVariant variant;

  /// Element count; null = 28 circles / 44 lines (upstream: 50 / 100).
  final int? count;

  /// Segment tint at the start of each loop…
  final Color colorFrom;

  /// …and at the end (loops close on a zero-length segment, so the snap
  /// back to [colorFrom] is invisible).
  final Color colorTo;

  /// Painted behind. Use [Colors.transparent] to overlay.
  final Color backgroundColor;

  /// Stroke width; null scales with the box (upstream 10px at 1100px).
  final double? strokeWidth;

  /// PRNG seed — same seed, same choreography.
  final int seed;

  /// False freezes the ticker (viewer freeze button / reduced motion).
  final bool animate;

  /// Non-null renders exactly one deterministic frame at t seconds — no
  /// ticker (thumbnails, golden tests).
  final double? frozenAt;

  @override
  State<LineDrawing> createState() => _LineDrawingState();
}

class _LineDrawingState extends State<LineDrawing>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);

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
  void didUpdateWidget(LineDrawing old) {
    super.didUpdateWidget(old);
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
    return ValueListenableBuilder<double>(
      valueListenable: _t,
      builder: (context, t, _) {
        // the expanding child is load-bearing: a childless CustomPaint has
        // preferred size zero and collapses under loose stage constraints
        return CustomPaint(
          painter: _LineDrawingPainter(
            // pre-roll so the plate is mid-dance immediately
            t: (widget.frozenAt ?? t) + 9,
            variant: widget.variant,
            count: widget.count ??
                (widget.variant == LineDrawingVariant.circles ? 28 : 44),
            colorFrom: widget.colorFrom,
            colorTo: widget.colorTo,
            backgroundColor: widget.backgroundColor,
            strokeWidth: widget.strokeWidth,
            seed: widget.seed,
            repaint: widget.frozenAt == null ? _t : null,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _LineDrawingPainter extends CustomPainter {
  _LineDrawingPainter({
    required this.t,
    required this.variant,
    required this.count,
    required this.colorFrom,
    required this.colorTo,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.seed,
    super.repaint,
  });

  final double t;
  final LineDrawingVariant variant;
  final int count;
  final Color colorFrom;
  final Color colorTo;
  final Color backgroundColor;
  final double? strokeWidth;
  final int seed;

  static const double _loop = 10; // upstream duration 10s
  static const double _spread = 8; // stagger [0, 8000ms]

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

  /// Draw-range [a,b] of element [i] at loop-phase [p] 0..1 — the upstream
  /// two-segment keyframes with per-element seeded values, ease inOut(4).
  (double, double) _range(int i, double p) {
    if (variant == LineDrawingVariant.circles) {
      final double v0 = _lerpRand(i, 1, -1, -.5);
      final double m0 = _lerpRand(i, 2, 0, .25);
      final double m1 = _lerpRand(i, 3, .5, .75);
      final double v1 = _lerpRand(i, 4, 1, 1.5);
      if (p < .5) {
        final double e = _inOutPow(p / .5, 4);
        return (v0 + (m0 - v0) * e, v0 + (m1 - v0) * e);
      }
      final double e = _inOutPow((p - .5) / .5, 4);
      return (m0 + (v1 - m0) * e, m1 + (v1 - m1) * e);
    } else {
      final double l = _lerpRand(i, 5, .05, .45);
      if (p < .5) {
        final double e = _inOutPow(p / .5, 4);
        return (.5 - l * e, .5 + l * e);
      }
      final double e = _inOutPow((p - .5) / .5, 4);
      return (.5 - l * (1 - e), .5 + l * (1 - e));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundColor.a > 0) {
      canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    }
    final double scaleRef = math.min(size.width, size.height);
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth ?? math.max(2, scaleRef * .009);

    for (int i = 0; i < count; i++) {
      final double start =
          count <= 1 ? 0 : _spread * i / (count - 1);
      final double local = t - start;
      if (local < 0) continue;
      final double p = (local % _loop) / _loop;
      final (double a, double b) = _range(i, p);
      if (b - a <= 1e-4) continue;
      stroke.color = Color.lerp(colorFrom, colorTo, p)!;

      if (variant == LineDrawingVariant.circles) {
        final double maxR = scaleRef * .46;
        final double r = maxR * (i + 1) / count;
        final Rect rect =
            Rect.fromCircle(center: size.center(Offset.zero), radius: r);
        final double sweep = math.min(b - a, 1.0) * 2 * math.pi;
        final double from = (a % 1) * 2 * math.pi - math.pi / 2;
        canvas.drawArc(rect, from, sweep, false, stroke);
      } else {
        final double margin = size.width * .05;
        final double x = count <= 1
            ? size.width / 2
            : margin + (size.width - 2 * margin) * i / (count - 1);
        final double top = size.height * .05;
        final double len = size.height * .90;
        final double ya = top + len * a.clamp(0.0, 1.0);
        final double yb = top + len * b.clamp(0.0, 1.0);
        if (yb - ya > .5) {
          canvas.drawLine(Offset(x, ya), Offset(x, yb), stroke);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_LineDrawingPainter old) =>
      old.t != t ||
      old.variant != variant ||
      old.count != count ||
      old.colorFrom != colorFrom ||
      old.colorTo != colorTo ||
      old.backgroundColor != backgroundColor ||
      old.strokeWidth != strokeWidth ||
      old.seed != seed;
}
