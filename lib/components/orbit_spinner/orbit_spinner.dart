/// OrbitSpinner
/// Origin: reimplemented — kinetics "Orbit Spinner" (Feedback & State),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Dual-arc loading ring: a half circle of accent color over a muted track,
/// rotating on a tight 0.8s linear loop (CSS `border-top/right-color` +
/// `rotate(1turn)` in the original). Pure paint — no layout tricks.
class OrbitSpinner extends StatefulWidget {
  const OrbitSpinner({
    super.key,
    this.size = 44,
    this.strokeWidth = 4,
    this.color = const Color(0xFFFF8A00),
    this.trackColor = const Color(0xFF232326),
    this.period = 0.8,
    this.animate = true,
    this.frozenAt,
  });

  /// Outer diameter.
  final double size;

  final double strokeWidth;

  /// The rotating half-arc (kinetics amber).
  final Color color;

  /// The full ring behind it.
  final Color trackColor;

  /// Seconds per revolution (0.8s in the original).
  final double period;

  /// False freezes the ticker (viewer freeze button / reduced motion).
  final bool animate;

  /// Non-null renders exactly one deterministic frame at t seconds — no
  /// ticker (thumbnails, golden tests).
  final double? frozenAt;

  @override
  State<OrbitSpinner> createState() => _OrbitSpinnerState();
}

class _OrbitSpinnerState extends State<OrbitSpinner>
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
  void didUpdateWidget(OrbitSpinner old) {
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
      builder: (context, t, _) => CustomPaint(
        painter: _OrbitPainter(
          t: widget.frozenAt ?? t,
          color: widget.color,
          trackColor: widget.trackColor,
          strokeWidth: widget.strokeWidth,
          period: widget.period,
          repaint: widget.frozenAt == null ? _t : null,
        ),
        size: Size.square(widget.size),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required this.t,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.period,
    super.repaint,
  });

  final double t;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final double period;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Rect arcRect = rect.deflate(strokeWidth / 2);
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawArc(arcRect, 0, math.pi * 2, false, stroke..color = trackColor);

    // CSS border-top + border-right of a round element = a contiguous half
    // ring; the seams sit on the 45° diagonals.
    final double angle = (t % period) / period * math.pi * 2;
    canvas.drawArc(
      arcRect,
      angle - math.pi * 3 / 4,
      math.pi,
      false,
      stroke..color = color,
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.t != t ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth ||
      old.period != period;
}
