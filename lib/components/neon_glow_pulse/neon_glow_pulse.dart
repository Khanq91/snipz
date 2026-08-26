/// NeonGlowPulse
/// Origin: reimplemented — kinetics "Neon Glow Pulse" (Surface & Motion),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A neon pill whose halo breathes on a two-second ease-in-out loop.
///
/// Reproduces the original 0/50/100% keyframes: text-shadow blur 4 → 12
/// (plus a second 0 → 22 layer), outer box-shadow blur 6/spread -1 →
/// blur 18/spread 0, and an inset glow blur 6 → 12 at spread -2.
class NeonGlowPulse extends StatefulWidget {
  const NeonGlowPulse({
    super.key,
    this.color = const Color(0xFFFF8A00),
    this.borderRadius = 100,
    this.borderWidth = 1,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
    this.fontSize = 14,
    this.letterSpacingEm = 0.18,
    this.period = 2,
    this.animate = true,
    this.frozenAt,
    this.child,
  }) : assert(borderRadius >= 0),
       assert(borderWidth >= 0),
       assert(fontSize > 0),
       assert(period > 0);

  /// Accent used for text, border, and every glow layer.
  final Color color;

  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  /// Applied through [DefaultTextStyle] together with [letterSpacingEm].
  final double fontSize;

  /// CSS `letter-spacing: 0.18em`, resolved against [fontSize].
  final double letterSpacingEm;

  /// Seconds per glow cycle.
  final double period;

  /// Whether the live ticker may run.
  final bool animate;

  /// Renders the deterministic frame at this time in seconds without running
  /// the ticker. Useful for thumbnails and golden tests.
  final double? frozenAt;

  /// Content centered in the pill. Null preserves the source label, `ONLINE`.
  final Widget? child;

  @override
  State<NeonGlowPulse> createState() => _NeonGlowPulseState();
}

class _NeonGlowPulseState extends State<NeonGlowPulse>
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
  void didUpdateWidget(NeonGlowPulse oldWidget) {
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
      builder: (context, liveTime, child) {
        final double pump = _sampleNeonPump(
          widget.frozenAt ?? liveTime,
          widget.period,
        );
        return CustomPaint(
          painter: _NeonPillPainter(
            pump: pump,
            color: widget.color,
            borderRadius: widget.borderRadius,
            borderWidth: widget.borderWidth,
          ),
          child: Padding(
            padding: widget.padding,
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: widget.color,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                letterSpacing: widget.letterSpacingEm * widget.fontSize,
                shadows: <Shadow>[
                  Shadow(color: widget.color, blurRadius: _lerp(4, 12, pump)),
                  Shadow(
                    color: widget.color.withValues(alpha: pump),
                    blurRadius: _lerp(0, 22, pump),
                  ),
                ],
              ),
              child: child!,
            ),
          ),
        );
      },
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: widget.child ?? const Text('ONLINE'),
      ),
    );
  }
}

/// CSS applies `ease-in-out` independently to the 0→50 and 50→100 segments.
double _sampleNeonPump(double time, double period) {
  double local = time % period;
  if (local < 0) local += period;
  final double phase = local / period;
  if (phase <= 0.5) {
    return Curves.easeInOut.transform(phase * 2);
  }
  return 1 - Curves.easeInOut.transform((phase - 0.5) * 2);
}

double _lerp(double begin, double end, double amount) =>
    begin + (end - begin) * amount;

/// Border plus the two box-shadow layers of the source. Flutter has no inset
/// box-shadow, so the inner glow is approximated with a blurred stroke
/// clipped inside the pill.
class _NeonPillPainter extends CustomPainter {
  const _NeonPillPainter({
    required this.pump,
    required this.color,
    required this.borderRadius,
    required this.borderWidth,
  });

  final double pump;
  final Color color;
  final double borderRadius;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect pill = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    // Outer glow: blur 6/spread -1 → blur 18/spread 0, clipped outside the
    // border box like a CSS outset shadow.
    final double outerBlur = _lerp(6, 18, pump);
    final double outerSpread = _lerp(-1, 0, pump);
    canvas
      ..save()
      ..clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(pill.outerRect.inflate(outerBlur + 8)),
          Path()..addRRect(pill),
        ),
      )
      ..drawRRect(
        pill.inflate(outerSpread),
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, outerBlur / 2),
      )
      ..restore();

    // Inset glow: blur 6 → 12 at spread -2.
    final double insetBlur = _lerp(6, 12, pump);
    canvas
      ..save()
      ..clipRRect(pill)
      ..drawRRect(
        pill.deflate(-2 + insetBlur / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = insetBlur
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, insetBlur / 2),
      )
      ..restore();

    canvas.drawRRect(
      pill.deflate(borderWidth / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_NeonPillPainter oldDelegate) =>
      oldDelegate.pump != pump ||
      oldDelegate.color != color ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.borderWidth != borderWidth;
}
