/// GradientShimmerText
/// Origin: reimplemented — kinetics "Gradient Shimmer Text" (Surface &
///   Motion), https://github.com/ckissi/kinetics — thông số + hành vi quan
///   sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Display text filled by a dim/bright/dim gradient that sweeps through it
/// forever.
///
/// Mirrors the original: a 100deg linear gradient (dim 30%, accent 50%,
/// dim 70%) sized 200% of the text, clipped to the glyphs, with
/// `background-position` animated over a three-second linear loop.
class GradientShimmerText extends StatefulWidget {
  const GradientShimmerText({
    super.key,
    this.text = 'KINETIC',
    this.style,
    this.dimColor = const Color(0xFF6E6C68),
    this.highlightColor = const Color(0xFFFF8A00),
    this.angleDegrees = 100,
    this.period = 3,
    this.animate = true,
    this.frozenAt,
  }) : assert(period > 0);

  final String text;

  /// Merged over the source style (w900, 40px, -0.02em tracking). The fill
  /// color always comes from the gradient.
  final TextStyle? style;

  final Color dimColor;
  final Color highlightColor;

  /// CSS gradient angle: 0 points up, 90 points right.
  final double angleDegrees;

  /// Seconds per complete sweep.
  final double period;

  /// Whether the live ticker may run.
  final bool animate;

  /// Renders the deterministic frame at this time in seconds without running
  /// the ticker. Useful for thumbnails and golden tests.
  final double? frozenAt;

  @override
  State<GradientShimmerText> createState() => _GradientShimmerTextState();
}

class _GradientShimmerTextState extends State<GradientShimmerText>
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
  void didUpdateWidget(GradientShimmerText oldWidget) {
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
    const TextStyle sourceStyle = TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w900,
      letterSpacing: 40 * -0.02,
      // The mask multiplies this color with the gradient — keep it opaque
      // white so the gradient shows unchanged.
      color: Color(0xFFFFFFFF),
    );
    final TextStyle effective = widget.style == null
        ? sourceStyle
        : sourceStyle
              .merge(widget.style)
              .copyWith(color: const Color(0xFFFFFFFF));

    return ValueListenableBuilder<double>(
      valueListenable: _time,
      builder: (context, liveTime, child) {
        final double phase = _sampleShimmerPhase(
          widget.frozenAt ?? liveTime,
          widget.period,
        );
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) => _createShimmerShader(
            bounds,
            phase: phase,
            dimColor: widget.dimColor,
            highlightColor: widget.highlightColor,
            angleDegrees: widget.angleDegrees,
          ),
          child: child,
        );
      },
      child: Text(widget.text, style: effective),
    );
  }
}

/// Linear phase 0→1 per cycle (CSS `linear` timing).
double _sampleShimmerPhase(double time, double period) {
  double local = time % period;
  if (local < 0) local += period;
  return local / period;
}

/// The animated `background-position: 0 → -200%` of a 200%-wide repeating
/// gradient: the tile slides exactly one tile width per cycle, so the loop
/// is seamless.
ui.Shader _createShimmerShader(
  Rect bounds, {
  required double phase,
  required Color dimColor,
  required Color highlightColor,
  required double angleDegrees,
}) {
  final double tile = bounds.width * 2;
  final double shift = phase * tile;
  // CSS angle: 0deg points up, 90deg points right. Sliding along the
  // gradient axis (not the x axis) keeps the shift period identical to the
  // tile period, so the repeat is exactly seamless.
  final double rad = angleDegrees * math.pi / 180;
  final ui.Offset axis = ui.Offset(math.sin(rad), -math.cos(rad));
  final ui.Offset center = bounds.center + axis * shift;
  final ui.Offset half = axis * (tile / 2);
  return ui.Gradient.linear(
    center - half,
    center + half,
    <Color>[dimColor, highlightColor, dimColor],
    const <double>[0.3, 0.5, 0.7],
    ui.TileMode.repeated,
  );
}
