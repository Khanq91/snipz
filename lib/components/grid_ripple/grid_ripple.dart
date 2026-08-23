/// GridRipple
/// Origin: reimplemented — port of the "advanced grid staggering" example
/// from anime.js v4 (juliangarnier/anime, examples/advanced-grid-staggering):
/// a dot lattice with a cursor square that hops to random cells; every hop
/// squeezes the whole grid toward the cell, bounces it out scaled-up, and
/// settles — a ripple radiating from the cursor. Every frame here is a
/// closed-form function of elapsed time, so any moment can be frozen.
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A self-running dot-grid ripple: a cursor square glides between random
/// cells, each landing sends a squeeze-and-bounce wave through the lattice.
/// Fills the box it is given (the grid is centered, square).
class GridRipple extends StatefulWidget {
  const GridRipple({
    super.key,
    this.rows = 11,
    this.dotColor = const Color(0xFFEDEAE4),
    this.cursorColor = const Color(0xFFFF4B4B),
    this.backgroundColor = const Color(0xFF191817),
    this.seed = 11,
    this.animate = true,
    this.frozenAt,
  });

  /// Lattice side — rows × rows dots.
  final int rows;

  final Color dotColor;

  /// The hopping square outline.
  final Color cursorColor;

  /// Painted behind the grid. Use [Colors.transparent] to overlay.
  final Color backgroundColor;

  /// PRNG seed for the hop sequence — same seed, same choreography.
  final int seed;

  /// False freezes the ticker (viewer freeze button / reduced motion).
  final bool animate;

  /// Non-null renders exactly one deterministic frame at t seconds — no
  /// ticker (thumbnails, golden tests).
  final double? frozenAt;

  @override
  State<GridRipple> createState() => _GridRippleState();
}

class _GridRippleState extends State<GridRipple>
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
  void didUpdateWidget(GridRipple old) {
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
          painter: _GridRipplePainter(
            t: widget.frozenAt ?? t,
            rows: widget.rows,
            dotColor: widget.dotColor,
            cursorColor: widget.cursorColor,
            backgroundColor: widget.backgroundColor,
            seed: widget.seed,
            repaint: widget.frozenAt == null ? _t : null,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _GridRipplePainter extends CustomPainter {
  _GridRipplePainter({
    required this.t,
    required this.rows,
    required this.dotColor,
    required this.cursorColor,
    required this.backgroundColor,
    required this.seed,
    super.repaint,
  });

  final double t;
  final int rows;
  final Color dotColor;
  final Color cursorColor;
  final Color backgroundColor;
  final int seed;

  double _rand01(int a, int b) {
    int h = seed ^ (a * 0x9E3779B1) ^ (b * 0x85EBCA77);
    h = (h ^ (h >> 15)) * 0x2C1B3C6D & 0xFFFFFFFF;
    h = (h ^ (h >> 12)) * 0x297A2D39 & 0xFFFFFFFF;
    h ^= h >> 15;
    return h / 0x100000000;
  }

  /// Cell the cursor occupies during cycle k (never repeats back-to-back).
  (int, int) _cell(int k) {
    final int n = rows * rows;
    int idx = (_rand01(k, 17) * n).floor().clamp(0, n - 1);
    final int prev =
        k == 0 ? -1 : (_rand01(k - 1, 17) * n).floor().clamp(0, n - 1);
    if (idx == prev) idx = (idx + n ~/ 2 + 1) % n;
    return (idx % rows, idx ~/ rows); // (col, row)
  }

  static double _inOutQuad(double p) =>
      p < .5 ? 2 * p * p : 1 - math.pow(-2 * p + 2, 2) / 2;

  static double _outCirc(double p) =>
      math.sqrt((1 - (p - 1) * (p - 1)).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundColor.a > 0) {
      canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    }
    final double span = math.min(size.width, size.height) * .82;
    final double pitch = rows <= 1 ? span : span / (rows - 1);
    final Offset origin = size.center(Offset.zero) -
        Offset(span / 2, span / 2);

    // cycle timing — upstream: dot delay 50ms/cell + 1.3s of keyframes;
    // the cursor glide overlaps the settle (starts 1.5s before cycle end)
    final double maxDist = math.sqrt(2) * (rows - 1);
    final double cycle = .05 * maxDist + 1.3;
    final int k = (t / cycle).floor();
    final double s = t - k * cycle;

    final (int c0x, int c0y) = _cell(k);
    final (int c1x, int c1y) = _cell(k + 1);

    // ripple wave through the dots
    final Paint dotPaint = Paint()..color = dotColor;
    final double dotR = pitch * .16;
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < rows; col++) {
        final double dax = (col - c0x).toDouble();
        final double day = (row - c0y).toDouble();
        final double dist = math.sqrt(dax * dax + day * day);
        final double local = s - .05 * dist;
        double ox = 0, oy = 0, scale = 1;
        if (local > 0 && local < 1.3) {
          // keyframes: squeeze 200ms → bounce out ×2 500ms → settle 600ms
          const double pull = -.175, push = .125;
          if (local < .2) {
            final double e = _inOutQuad(local / .2);
            ox = pull * pitch * dax * e;
            oy = pull * pitch * day * e;
          } else if (local < .7) {
            final double e = _inOutQuad((local - .2) / .5);
            ox = pitch * dax * (pull + (push - pull) * e);
            oy = pitch * day * (pull + (push - pull) * e);
            scale = 1 + e;
          } else {
            final double e = _inOutQuad((local - .7) / .6);
            ox = push * pitch * dax * (1 - e);
            oy = push * pitch * day * (1 - e);
            scale = 2 - e;
          }
        }
        canvas.drawCircle(
          origin +
              Offset(col * pitch + ox, row * pitch + oy),
          dotR * scale,
          dotPaint,
        );
      }
    }

    // cursor square: pulse on landing, glide toward the next cell
    final double glideStart = cycle - 1.5;
    final double glideDur = .8 + .4 * _rand01(k, 23);
    double cx = c0x.toDouble(), cy = c0y.toDouble();
    if (s >= glideStart) {
      final double e =
          _outCirc(((s - glideStart) / glideDur).clamp(0.0, 1.0));
      cx += (c1x - c0x) * e;
      cy += (c1y - c0y) * e;
    }
    double cursorScale = 1;
    if (s < .2) {
      cursorScale = 1 + (.625 - 1) * _inOutQuad(s / .2);
    } else if (s < .4) {
      cursorScale = .625 + (1.125 - .625) * _inOutQuad((s - .2) / .2);
    } else if (s < .6) {
      cursorScale = 1.125 + (1 - 1.125) * _inOutQuad((s - .4) / .2);
    }
    final Offset cursorPos =
        origin + Offset(cx * pitch, cy * pitch);
    final double half = pitch * .5 * cursorScale;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: cursorPos, width: half * 2, height: half * 2),
        Radius.circular(pitch * .12),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, pitch * .07)
        ..color = cursorColor,
    );
  }

  @override
  bool shouldRepaint(_GridRipplePainter old) =>
      old.t != t ||
      old.rows != rows ||
      old.dotColor != dotColor ||
      old.cursorColor != cursorColor ||
      old.backgroundColor != backgroundColor ||
      old.seed != seed;
}
