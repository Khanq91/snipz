/// BouncingBall
/// Origin: reimplemented — kinetics "Bouncing Ball" (Surface & Motion),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A ball that bounces with squash-and-stretch over a synced ellipse shadow.
///
/// Both keyframe tracks of the source run on the same one-second
/// `cubic-bezier(0.7, 0, 0.3, 1)` clock: the ball travels translateY
/// -54 → 0 while squashing (scaleY 1.05 → 0.8, scaleX 1 → 1.15), and the
/// shadow scales 0.5 → 1 while darkening 0.25 → 0.5.
class BouncingBall extends StatefulWidget {
  const BouncingBall({
    super.key,
    this.width = 80,
    this.height = 110,
    this.ballSize = 34,
    this.color = const Color(0xFFFF8A00),
    this.deepColor = const Color(0xFFB36200),
    this.shadowColor = const Color(0xFF000000),
    this.bounceHeight = 54,
    this.shadowWidth = 38,
    this.shadowHeight = 9,
    this.ballBottom = 14,
    this.shadowBottom = 8,
    this.period = 1,
    this.animate = true,
    this.frozenAt,
  }) : assert(width > 0),
       assert(height > 0),
       assert(ballSize > 0),
       assert(bounceHeight >= 0),
       assert(shadowWidth > 0),
       assert(shadowHeight > 0),
       assert(period > 0);

  /// Stage size (80 × 110 in the source).
  final double width;
  final double height;

  final double ballSize;

  /// Highlight of the ball's off-center radial gradient.
  final Color color;

  /// Outer stop of the ball's gradient.
  final Color deepColor;

  final Color shadowColor;

  /// Peak height of the bounce in logical pixels.
  final double bounceHeight;

  /// Unscaled shadow ellipse size.
  final double shadowWidth;
  final double shadowHeight;

  /// Distance from the stage bottom to the ball / shadow rest positions.
  final double ballBottom;
  final double shadowBottom;

  /// Seconds per bounce.
  final double period;

  /// Whether the live ticker may run.
  final bool animate;

  /// Renders the deterministic frame at this time in seconds without running
  /// the ticker. Useful for thumbnails and golden tests.
  final double? frozenAt;

  @override
  State<BouncingBall> createState() => _BouncingBallState();
}

class _BouncingBallState extends State<BouncingBall>
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
  void didUpdateWidget(BouncingBall oldWidget) {
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
          painter: _BouncingBallPainter(
            frame: _sampleBounce(widget.frozenAt ?? liveTime, widget.period),
            ballSize: widget.ballSize,
            color: widget.color,
            deepColor: widget.deepColor,
            shadowColor: widget.shadowColor,
            bounceHeight: widget.bounceHeight,
            shadowWidth: widget.shadowWidth,
            shadowHeight: widget.shadowHeight,
            ballBottom: widget.ballBottom,
            shadowBottom: widget.shadowBottom,
          ),
          child: SizedBox(width: widget.width, height: widget.height),
        );
      },
    );
  }
}

class _BounceFrame {
  const _BounceFrame({
    required this.drop,
    required this.scaleX,
    required this.scaleY,
    required this.shadowScale,
    required this.shadowOpacity,
  });

  /// 0 at the top of the flight, 1 on the ground.
  final double drop;
  final double scaleX;
  final double scaleY;
  final double shadowScale;
  final double shadowOpacity;
}

/// Both source keyframe tracks share the clock and the bezier; the easing
/// restarts on each 0→50 / 50→100 leg.
_BounceFrame _sampleBounce(double time, double period) {
  const Curve fall = Cubic(0.7, 0, 0.3, 1);
  double local = time % period;
  if (local < 0) local += period;
  final double phase = local / period;
  final double u = phase <= 0.5
      ? fall.transform(phase * 2)
      : 1 - fall.transform((phase - 0.5) * 2);
  return _BounceFrame(
    drop: u,
    scaleX: _lerp(1, 1.15, u),
    scaleY: _lerp(1.05, 0.8, u),
    shadowScale: _lerp(0.5, 1, u),
    shadowOpacity: _lerp(0.25, 0.5, u),
  );
}

double _lerp(double begin, double end, double amount) =>
    begin + (end - begin) * amount;

class _BouncingBallPainter extends CustomPainter {
  const _BouncingBallPainter({
    required this.frame,
    required this.ballSize,
    required this.color,
    required this.deepColor,
    required this.shadowColor,
    required this.bounceHeight,
    required this.shadowWidth,
    required this.shadowHeight,
    required this.ballBottom,
    required this.shadowBottom,
  });

  final _BounceFrame frame;
  final double ballSize;
  final Color color;
  final Color deepColor;
  final Color shadowColor;
  final double bounceHeight;
  final double shadowWidth;
  final double shadowHeight;
  final double ballBottom;
  final double shadowBottom;

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;

    // Shadow ellipse, centered like the CSS 50%-origin scale.
    final Offset shadowCenter = Offset(
      centerX,
      size.height - shadowBottom - shadowHeight / 2,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: shadowCenter,
        width: shadowWidth * frame.shadowScale,
        height: shadowHeight * frame.shadowScale,
      ),
      Paint()..color = shadowColor.withValues(alpha: frame.shadowOpacity),
    );

    // Ball: translateY then centered squash (CSS default 50% 50% origin).
    final double restCenterY = size.height - ballBottom - ballSize / 2;
    final Offset ballCenter = Offset(
      centerX,
      restCenterY - bounceHeight * (1 - frame.drop),
    );
    final Rect ballRect = Rect.fromCenter(
      center: ballCenter,
      width: ballSize * frame.scaleX,
      height: ballSize * frame.scaleY,
    );
    // radial-gradient(circle at 35% 30%, color, deepColor) — the gradient
    // deforms with the squash, like a CSS background under transform.
    final Offset focus = Offset(
      ballRect.left + ballRect.width * 0.35,
      ballRect.top + ballRect.height * 0.30,
    );
    canvas.drawOval(
      ballRect,
      Paint()
        ..shader = ui.Gradient.radial(
          focus,
          // circle extent: farthest corner of the box from the 35%/30% focus.
          math
              .sqrt(
                math.pow(ballRect.width * 0.65, 2) +
                    math.pow(ballRect.height * 0.70, 2),
              )
              .toDouble(),
          <Color>[color, deepColor],
        ),
    );
  }

  @override
  bool shouldRepaint(_BouncingBallPainter oldDelegate) =>
      oldDelegate.frame.drop != frame.drop ||
      oldDelegate.frame.shadowScale != frame.shadowScale ||
      oldDelegate.ballSize != ballSize ||
      oldDelegate.color != color ||
      oldDelegate.deepColor != deepColor ||
      oldDelegate.shadowColor != shadowColor ||
      oldDelegate.bounceHeight != bounceHeight ||
      oldDelegate.shadowWidth != shadowWidth ||
      oldDelegate.shadowHeight != shadowHeight ||
      oldDelegate.ballBottom != ballBottom ||
      oldDelegate.shadowBottom != shadowBottom;
}
