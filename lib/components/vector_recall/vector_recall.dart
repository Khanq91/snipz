/// VectorRecall
/// Origin: reimplemented — kinetics "Vector Recall" (Feedback & State),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Semantic search over an embedding space, as a 5.6s looping state
/// animation: faint points scatter around a bright query node, a thin ring
/// sweeps outward, the nearest points (the "hits") brighten and drift a
/// third of the way toward the query while the rest stay dim, and a status
/// readout cross-fades from "querying…" to a cosine score as they land.
class VectorRecall extends StatefulWidget {
  const VectorRecall({
    super.key,
    this.width = 214,
    this.height = 132,
    this.points = const <(Offset, bool)>[
      (Offset(-62, -30), false),
      (Offset(54, -34), false),
      (Offset(-46, 28), false),
      (Offset(-30, -18), true),
      (Offset(34, 14), true),
      (Offset(8, -34), true),
      (Offset(66, 24), false),
    ],
    this.queryText = 'querying…',
    this.matchText = '0.94 · match',
    this.accentColor = const Color(0xFFFF8A00),
    this.queryColor = const Color(0xFFEDE9E0),
    this.pointColor = const Color(0xFF6E6C68),
    this.borderColor = const Color(0xFF2A2A2E),
    this.backgroundColors = const <Color>[Color(0xFF1B1B1F), Color(0xFF232326)],
    this.animate = true,
    this.frozenAt,
  });

  final double width;
  final double height;

  /// Embedding points as (offset from center, isHit). Hits are pulled toward
  /// the query; the i-th hit is staggered i * 0.1s like the original.
  final List<(Offset, bool)> points;

  /// Status readout before / after the matches land.
  final String queryText;
  final String matchText;

  /// Hit points, sweep ring and score color (kinetics amber).
  final Color accentColor;

  /// Query node (bright) and its glow.
  final Color queryColor;

  /// Non-hit points.
  final Color pointColor;

  final Color borderColor;

  /// Radial backdrop, inner → outer.
  final List<Color> backgroundColors;

  /// False freezes the ticker (viewer freeze button / reduced motion).
  final bool animate;

  /// Non-null renders exactly one deterministic frame at t seconds — no
  /// ticker (thumbnails, golden tests).
  final double? frozenAt;

  @override
  State<VectorRecall> createState() => _VectorRecallState();
}

class _VectorRecallState extends State<VectorRecall>
    with SingleTickerProviderStateMixin {
  /// One query → recall → release cycle (5.6s in the original).
  static const double _period = 5.6;
  static const Curve _glide = Cubic(0.16, 1, 0.3, 1);

  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker =
        createTicker((elapsed) => _t.value = elapsed.inMicroseconds / 1e6);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(VectorRecall old) {
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

  static double _kf(
    double u,
    List<double> pos,
    List<double> val,
    Curve curve,
  ) {
    if (u <= pos.first) return val.first;
    for (int i = 1; i < pos.length; i++) {
      if (u <= pos[i]) {
        final double span = pos[i] - pos[i - 1];
        final double p = span <= 0 ? 1 : (u - pos[i - 1]) / span;
        return val[i - 1] + (val[i] - val[i - 1]) * curve.transform(p);
      }
    }
    return val.last;
  }

  static double _local(double t, double delay) {
    double local = (t - delay) % _period;
    if (local < 0) local += _period;
    return local / _period;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _t,
      builder: (context, live, _) {
        final double t = widget.frozenAt ?? live;
        // score-match fades in with a 3px rise; score-query is its inverse
        // on slightly offset keyframes.
        final double queryOpacity = _kf(
            _local(t, 0),
            const <double>[0, .38, .48, .80, .92, 1],
            const <double>[1, 1, 0, 0, 1, 1],
            Curves.easeInOut);
        final double matchOpacity = _kf(
            _local(t, 0),
            const <double>[0, .38, .48, .80, .92, 1],
            const <double>[0, 0, 1, 1, 0, 0],
            Curves.easeInOut);
        TextStyle style(Color color) => TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.54,
              color: color,
            );
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(color: widget.borderColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: CustomPaint(
                    painter: _VectorPainter(
                      t: t,
                      points: widget.points,
                      accentColor: widget.accentColor,
                      queryColor: widget.queryColor,
                      pointColor: widget.pointColor,
                      backgroundColors: widget.backgroundColors,
                      repaint: widget.frozenAt == null ? _t : null,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  height: 11,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Opacity(
                        opacity: queryOpacity,
                        child: Text(widget.queryText,
                            style: style(widget.pointColor)),
                      ),
                      Opacity(
                        opacity: matchOpacity,
                        child: Transform.translate(
                          offset: Offset(0, 3 * (1 - matchOpacity)),
                          child: Text(widget.matchText,
                              style: style(widget.accentColor)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VectorPainter extends CustomPainter {
  _VectorPainter({
    required this.t,
    required this.points,
    required this.accentColor,
    required this.queryColor,
    required this.pointColor,
    required this.backgroundColors,
    super.repaint,
  });

  final double t;
  final List<(Offset, bool)> points;
  final Color accentColor;
  final Color queryColor;
  final Color pointColor;
  final List<Color> backgroundColors;

  static const Curve _glide = _VectorRecallState._glide;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);

    // Radial backdrop (the CSS 70%×90% ellipse, approximated circular).
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
            center, size.width * 0.45, backgroundColors),
    );

    // Two expanding rings, second delayed 0.55s. Diameter 8 → 104 on the
    // glide bezier; opacity rises to 0.75 by 12% and is gone at 46%.
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final double delay in const <double>[0, 0.55]) {
      final double u = _VectorRecallState._local(t, delay);
      final double d = _VectorRecallState._kf(
          u, const <double>[0, .46, 1], const <double>[8, 104, 104], _glide);
      final double opacity = _VectorRecallState._kf(
          u,
          const <double>[0, .12, .46, 1],
          const <double>[0, .75, 0, 0],
          _glide);
      if (opacity <= 0) continue;
      ringPaint.color =
          accentColor.withValues(alpha: 0.6 * opacity);
      canvas.drawCircle(center, d / 2, ringPaint);
    }

    // Points: hits pull to 34% of their offset between 24% and 48%, hold to
    // 76%, release by 100% — staggered 0.1s per hit. Others stay dim.
    int hitIndex = 0;
    final Paint dotPaint = Paint();
    for (final (Offset offset, bool hit) in points) {
      double factor = 1;
      double opacity = 0.35;
      double glow = 0;
      if (hit) {
        final double u = _VectorRecallState._local(t, hitIndex * 0.1);
        hitIndex++;
        const List<double> pos = <double>[0, .24, .48, .76, 1];
        factor = _VectorRecallState._kf(
            u, pos, const <double>[1, 1, .34, .34, 1], _glide);
        opacity = _VectorRecallState._kf(
            u, pos, const <double>[.35, .35, 1, 1, .35], _glide);
        glow = ((opacity - .35) / .65).clamp(0.0, 1.0);
      }
      final Offset p = center + offset * factor;
      final Color color = hit ? accentColor : pointColor;
      if (glow > 0) {
        dotPaint
          ..color = accentColor.withValues(alpha: 0.65 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(p, 5, dotPaint);
        dotPaint.maskFilter = null;
      }
      dotPaint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(p, 3, dotPaint);
    }

    // Query node with its soft glow.
    dotPaint
      ..color = queryColor.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawCircle(center, 6, dotPaint);
    dotPaint
      ..maskFilter = null
      ..color = queryColor;
    canvas.drawCircle(center, 4.5, dotPaint);
  }

  @override
  bool shouldRepaint(_VectorPainter old) =>
      old.t != t ||
      old.points != points ||
      old.accentColor != accentColor ||
      old.queryColor != queryColor ||
      old.pointColor != pointColor ||
      old.backgroundColors != backgroundColors;
}
