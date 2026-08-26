/// SkeletonSweep
/// Origin: reimplemented — kinetics "Skeleton Sweep" (Surface & Motion),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Three rounded skeleton lines crossed by a 200%-wide shimmer gradient.
///
/// Width follows the parent. The live kinetics demo constrains it to 220px;
/// the final line is 60% as wide as the others.
class SkeletonSweep extends StatefulWidget {
  const SkeletonSweep({
    super.key,
    this.lineCount = 3,
    this.lineHeight = 12,
    this.gap = 11,
    this.lastLineFactor = 0.6,
    this.baseColor = const Color(0xFF232326),
    this.highlightColor = const Color(0xFF34343A),
    this.period = 1.4,
    this.animate = true,
    this.frozenAt,
  }) : assert(lineCount >= 1),
       assert(lineHeight > 0),
       assert(gap >= 0),
       assert(lastLineFactor > 0 && lastLineFactor <= 1),
       assert(period > 0);

  final int lineCount;
  final double lineHeight;
  final double gap;

  /// Width of the last line relative to the available parent width.
  final double lastLineFactor;

  final Color baseColor;
  final Color highlightColor;

  /// Seconds per complete sweep.
  final double period;

  /// Whether the live ticker may run.
  final bool animate;

  /// Renders the deterministic frame at this time in seconds without running
  /// the ticker. Useful for thumbnails and golden tests.
  final double? frozenAt;

  @override
  State<SkeletonSweep> createState() => _SkeletonSweepState();
}

class _SkeletonSweepState extends State<SkeletonSweep>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  Duration? _lastTick;
  double _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick);
  }

  void _handleTick(Duration elapsed) {
    final Duration previous = _lastTick ?? Duration.zero;
    _lastTick = elapsed;
    final double delta = ((elapsed - previous).inMicroseconds / 1000000)
        .clamp(0.0, 0.064)
        .toDouble();
    _elapsedSeconds += delta;
    _time.value = _elapsedSeconds;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(SkeletonSweep oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  void _syncTicker() {
    final bool reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bool shouldRun =
        widget.animate && widget.frozenAt == null && !reducedMotion;
    if (shouldRun && !_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
      _lastTick = null;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double height =
        widget.lineCount * widget.lineHeight +
        (widget.lineCount - 1) * widget.gap;
    return ValueListenableBuilder<double>(
      valueListenable: _time,
      builder: (context, liveTime, _) {
        final double time = widget.frozenAt ?? liveTime;
        return CustomPaint(
          painter: _SkeletonSweepPainter(
            progress: _sampleSweepProgress(time, widget.period),
            lineCount: widget.lineCount,
            lineHeight: widget.lineHeight,
            gap: widget.gap,
            lastLineFactor: widget.lastLineFactor,
            baseColor: widget.baseColor,
            highlightColor: widget.highlightColor,
          ),
          child: SizedBox(width: double.infinity, height: height),
        );
      },
    );
  }
}

/// Pure model for `background-position: 200% → -200%` with CSS ease-in-out.
double _sampleSweepProgress(double time, double period) {
  double local = time % period;
  if (local < 0) local += period;
  return Curves.easeInOut.transform(local / period);
}

class _SkeletonSweepPainter extends CustomPainter {
  const _SkeletonSweepPainter({
    required this.progress,
    required this.lineCount,
    required this.lineHeight,
    required this.gap,
    required this.lastLineFactor,
    required this.baseColor,
    required this.highlightColor,
  });

  final double progress;
  final int lineCount;
  final double lineHeight;
  final double gap;
  final double lastLineFactor;
  final Color baseColor;
  final Color highlightColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Radius radius = Radius.circular(lineHeight / 2);
    final double backgroundPosition = 200 - 400 * progress;

    for (int index = 0; index < lineCount; index++) {
      final bool short = index == lineCount - 1 && lineCount > 1;
      final double lineWidth = short ? size.width * lastLineFactor : size.width;
      final double gradientWidth = lineWidth * 2;

      // CSS background-position aligns equal percentages of the container and
      // the 200%-wide image: offset = (container - image) * position.
      final double gradientLeft =
          (lineWidth - gradientWidth) * backgroundPosition / 100;
      final double top = index * (lineHeight + gap);
      final ui.Shader shader = ui.Gradient.linear(
        Offset(gradientLeft, top),
        Offset(gradientLeft + gradientWidth, top),
        <Color>[baseColor, highlightColor, baseColor],
        const <double>[0.25, 0.5, 0.75],
      );
      final Paint paint = Paint()..shader = shader;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, top, lineWidth, lineHeight),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SkeletonSweepPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.lineCount != lineCount ||
      oldDelegate.lineHeight != lineHeight ||
      oldDelegate.gap != gap ||
      oldDelegate.lastLineFactor != lastLineFactor ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightColor != highlightColor;
}
