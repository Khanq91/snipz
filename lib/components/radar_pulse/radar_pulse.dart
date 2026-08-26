/// RadarPulse
/// Origin: reimplemented — kinetics "Radar Pulse" (Surface & Motion),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A sonar ping: a glowing core dot with rings that expand and fade.
///
/// Reproduces the original numbers: three 24px rings with a 2px border,
/// scaling 0.4 → 4.2 while fading 0.9 → 0 on a 2.4s
/// `cubic-bezier(0, 0.4, 0.2, 1)` loop, launched 0.8s apart.
class RadarPulse extends StatefulWidget {
  const RadarPulse({
    super.key,
    this.size = 120,
    this.waveCount = 3,
    this.color = const Color(0xFFFF8A00),
    this.deepColor = const Color(0xFFB36200),
    this.coreSize = 16,
    this.waveBaseSize = 24,
    this.waveStrokeWidth = 2,
    this.startScale = 0.4,
    this.endScale = 4.2,
    this.startOpacity = 0.9,
    this.period = 2.4,
    this.animate = true,
    this.frozenAt,
  }) : assert(size > 0),
       assert(waveCount >= 1),
       assert(coreSize > 0),
       assert(waveBaseSize > 0),
       assert(waveStrokeWidth > 0),
       assert(endScale >= startScale),
       assert(startOpacity >= 0 && startOpacity <= 1),
       assert(period > 0);

  /// Square stage size (120px in the source).
  final double size;

  /// Rings in flight; each launches `period / waveCount` after the previous.
  final int waveCount;

  final Color color;

  /// Outer stop of the core's radial gradient.
  final Color deepColor;

  final double coreSize;

  /// Unscaled ring diameter.
  final double waveBaseSize;

  /// Unscaled ring border width; scales with the ring like a CSS transform.
  final double waveStrokeWidth;

  final double startScale;
  final double endScale;
  final double startOpacity;

  /// Seconds per ring flight.
  final double period;

  /// Whether the live ticker may run.
  final bool animate;

  /// Renders the deterministic frame at this time in seconds without running
  /// the ticker. Useful for thumbnails and golden tests.
  final double? frozenAt;

  @override
  State<RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<RadarPulse>
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
  void didUpdateWidget(RadarPulse oldWidget) {
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
    return ValueListenableBuilder<double>(
      valueListenable: _time,
      builder: (context, liveTime, _) {
        return CustomPaint(
          painter: _RadarPulsePainter(
            time: widget.frozenAt ?? liveTime,
            waveCount: widget.waveCount,
            color: widget.color,
            deepColor: widget.deepColor,
            coreSize: widget.coreSize,
            waveBaseSize: widget.waveBaseSize,
            waveStrokeWidth: widget.waveStrokeWidth,
            startScale: widget.startScale,
            endScale: widget.endScale,
            startOpacity: widget.startOpacity,
            period: widget.period,
          ),
          child: SizedBox.square(dimension: widget.size),
        );
      },
    );
  }
}

class _RadarPulsePainter extends CustomPainter {
  const _RadarPulsePainter({
    required this.time,
    required this.waveCount,
    required this.color,
    required this.deepColor,
    required this.coreSize,
    required this.waveBaseSize,
    required this.waveStrokeWidth,
    required this.startScale,
    required this.endScale,
    required this.startOpacity,
    required this.period,
  });

  static const Curve _ping = Cubic(0, 0.4, 0.2, 1);

  final double time;
  final int waveCount;
  final Color color;
  final Color deepColor;
  final double coreSize;
  final double waveBaseSize;
  final double waveStrokeWidth;
  final double startScale;
  final double endScale;
  final double startOpacity;
  final double period;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);

    // Rings, oldest first so the freshest paints on top.
    for (int index = 0; index < waveCount; index++) {
      final double delay = period * index / waveCount;
      double local = (time - delay) % period;
      if (local < 0) local += period;
      final double t = _ping.transform(local / period);
      final double scale = startScale + (endScale - startScale) * t;
      final double opacity = startOpacity * (1 - t);
      if (opacity <= 0) continue;
      canvas.drawCircle(
        center,
        waveBaseSize / 2 * scale,
        Paint()
          ..style = PaintingStyle.stroke
          // CSS scales the whole element, border width included.
          ..strokeWidth = waveStrokeWidth * scale
          ..color = color.withValues(alpha: opacity),
      );
    }

    // Core glow: box-shadow 0 0 14px at 50% alpha.
    canvas.drawCircle(
      center,
      coreSize / 2,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // Core dot: radial-gradient(circle, color, deepColor 70%).
    canvas.drawCircle(
      center,
      coreSize / 2,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          coreSize / 2,
          <Color>[color, deepColor],
          const <double>[0, 0.7],
        ),
    );
  }

  @override
  bool shouldRepaint(_RadarPulsePainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.waveCount != waveCount ||
      oldDelegate.color != color ||
      oldDelegate.deepColor != deepColor ||
      oldDelegate.coreSize != coreSize ||
      oldDelegate.waveBaseSize != waveBaseSize ||
      oldDelegate.waveStrokeWidth != waveStrokeWidth ||
      oldDelegate.startScale != startScale ||
      oldDelegate.endScale != endScale ||
      oldDelegate.startOpacity != startOpacity ||
      oldDelegate.period != period;
}
