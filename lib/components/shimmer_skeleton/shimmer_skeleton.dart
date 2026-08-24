/// ShimmerSkeleton
/// Origin: reimplemented — kinetics "Shimmer Skeleton" (Feedback & State),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Loading skeleton of stacked rounded bars with a soft highlight sweeping
/// across on a 1.5s linear loop. The CSS original slides a 280%-wide
/// gradient's background-position from 140% to -140%; here the same gradient
/// is painted with a per-frame x offset. Width follows the parent.
class ShimmerSkeleton extends StatefulWidget {
  const ShimmerSkeleton({
    super.key,
    this.lines = 3,
    this.lineHeight = 12,
    this.gap = 11,
    this.shortFactor = 0.6,
    this.baseColor = const Color(0xFF232326),
    this.highlightColor = const Color(0xFF2A2A2E),
    this.period = 1.5,
    this.animate = true,
    this.frozenAt,
  }) : assert(lines >= 1);

  /// Number of bars; the last one is [shortFactor] wide (paragraph tail).
  final int lines;

  final double lineHeight;

  /// Vertical gap between bars.
  final double gap;

  /// Width factor of the last bar (0.6 = 60% in the original).
  final double shortFactor;

  final Color baseColor;
  final Color highlightColor;

  /// Seconds per sweep (1.5s linear in the original).
  final double period;

  /// False freezes the ticker (viewer freeze button / reduced motion).
  final bool animate;

  /// Non-null renders exactly one deterministic frame at t seconds — no
  /// ticker (thumbnails, golden tests).
  final double? frozenAt;

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(ShimmerSkeleton old) {
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
    final double height =
        widget.lines * widget.lineHeight + (widget.lines - 1) * widget.gap;
    return ValueListenableBuilder<double>(
      valueListenable: _t,
      builder: (context, t, _) => CustomPaint(
        painter: _ShimmerPainter(
          t: widget.frozenAt ?? t,
          lines: widget.lines,
          lineHeight: widget.lineHeight,
          gap: widget.gap,
          shortFactor: widget.shortFactor,
          baseColor: widget.baseColor,
          highlightColor: widget.highlightColor,
          period: widget.period,
          repaint: widget.frozenAt == null ? _t : null,
        ),
        child: SizedBox(width: double.infinity, height: height),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({
    required this.t,
    required this.lines,
    required this.lineHeight,
    required this.gap,
    required this.shortFactor,
    required this.baseColor,
    required this.highlightColor,
    required this.period,
    super.repaint,
  });

  final double t;
  final int lines;
  final double lineHeight;
  final double gap;
  final double shortFactor;
  final Color baseColor;
  final Color highlightColor;
  final double period;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    // background-size 280%, background-position 140% → -140% linear.
    final double frac = (t % period) / period;
    final double pos = 140 - 280 * frac; // percent
    final double gradW = 2.8 * w;
    final double x0 = (w - gradW) * pos / 100;
    final ui.Shader shader = ui.Gradient.linear(
      Offset(x0, 0),
      Offset(x0 + gradW, 0),
      <Color>[baseColor, highlightColor, baseColor],
      const <double>[0, 0.2, 0.4],
    );
    final Paint paint = Paint()..shader = shader;
    final Radius radius = Radius.circular(lineHeight / 2);
    for (int i = 0; i < lines; i++) {
      final double lineW = i == lines - 1 && lines > 1 ? w * shortFactor : w;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, i * (lineHeight + gap), lineW, lineHeight),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) =>
      old.t != t ||
      old.lines != lines ||
      old.lineHeight != lineHeight ||
      old.gap != gap ||
      old.shortFactor != shortFactor ||
      old.baseColor != baseColor ||
      old.highlightColor != highlightColor ||
      old.period != period;
}
