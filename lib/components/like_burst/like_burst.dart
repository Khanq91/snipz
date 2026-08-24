/// LikeBurst
/// Origin: reimplemented — kinetics "Like Burst" (Interaction & Input),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Like button that pops its heart on every toggle and, when switching ON,
/// emits 8 particles on an even circle. Controlled: the parent owns [liked]
/// and rebuilds in [onChanged]; the shown number is `count + (liked ? 1 : 0)`.
class LikeBurst extends StatefulWidget {
  const LikeBurst({
    super.key,
    required this.liked,
    required this.onChanged,
    this.count = 128,
    this.backgroundColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.heartColor = const Color(0xFFA8A6A0),
    this.likedColor = const Color(0xFFFF8A00),
    this.countColor = const Color(0xFFA8A6A0),
    this.likedCountColor = const Color(0xFFEDE9E0),
    this.seed = 7,
    this.animate = true,
  });

  final bool liked;
  final ValueChanged<bool>? onChanged;

  /// Base count excluding the user's own like (the original demo's `128`).
  final int count;
  final Color backgroundColor;
  final Color borderColor;
  final Color heartColor;
  final Color likedColor;
  final Color countColor;
  final Color likedCountColor;

  /// Seed of the per-burst particle distances (deterministic — no wall-clock
  /// randomness in the paint path).
  final int seed;

  /// False disables pop and burst; states apply immediately.
  final bool animate;

  @override
  State<LikeBurst> createState() => _LikeBurstState();
}

class _LikeBurstState extends State<LikeBurst> with TickerProviderStateMixin {
  static const Curve _spring = Cubic(0.34, 1.56, 0.64, 1);

  // Button geometry of the original demo (border 1 + padding 18 + heart 22).
  static const double _heartSize = 22;
  static const Offset _heartCenter = Offset(1 + 18 + _heartSize / 2, 0);

  late final AnimationController _popHold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final math.Random _rng = math.Random(widget.seed);
  final List<Offset> _particles = <Offset>[];
  bool _popped = false;

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  @override
  void initState() {
    super.initState();
    _popHold.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _popped = false);
      }
    });
  }

  @override
  void didUpdateWidget(LikeBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.liked != widget.liked && _motionEnabled) {
      // The original pops on every toggle and bursts only when liking.
      setState(() => _popped = true);
      _popHold.forward(from: 0);
      if (widget.liked) {
        _particles
          ..clear()
          ..addAll(
            List<Offset>.generate(8, (i) {
              final double a = math.pi * 2 * i / 8;
              final double d = 22 + _rng.nextDouble() * 14;
              return Offset(math.cos(a) * d, math.sin(a) * d);
            }),
          );
        _burst.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _popHold.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onChanged != null;
    final Duration colorDuration = _motionEnabled
        ? const Duration(milliseconds: 200)
        : Duration.zero;
    final Duration popDuration = _motionEnabled
        ? const Duration(milliseconds: 300)
        : Duration.zero;

    return Semantics(
      button: true,
      enabled: enabled,
      toggled: widget.liked,
      onTap: enabled ? () => widget.onChanged!(!widget.liked) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => widget.onChanged!(!widget.liked) : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border: Border.all(color: widget.borderColor),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AnimatedScale(
                    scale: _popped ? 1.35 : 1,
                    duration: popDuration,
                    curve: _spring,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: widget.liked ? 1 : 0),
                      duration: colorDuration,
                      curve: Curves.ease,
                      builder: (context, t, _) => CustomPaint(
                        size: const Size.square(_heartSize),
                        painter: _HeartPainter(
                          strokeColor: Color.lerp(
                            widget.heartColor,
                            widget.likedColor,
                            t,
                          )!,
                          fillColor: widget.likedColor.withValues(alpha: t),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  AnimatedDefaultTextStyle(
                    duration: colorDuration,
                    curve: Curves.ease,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                      color: widget.liked
                          ? widget.likedCountColor
                          : widget.countColor,
                    ),
                    child: Text('${widget.count + (widget.liked ? 1 : 0)}'),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _BurstPainter(
                    progress: _burst,
                    particles: _particles,
                    color: widget.likedColor,
                    origin: _heartCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The ubiquitous 24-viewBox heart glyph, scaled to the given size.
class _HeartPainter extends CustomPainter {
  const _HeartPainter({required this.strokeColor, required this.fillColor});

  final Color strokeColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final Path path = Path()
      ..moveTo(12, 21.35)
      ..lineTo(10.55, 20.03)
      ..cubicTo(5.4, 15.36, 2, 12.28, 2, 8.5)
      ..cubicTo(2, 5.42, 4.42, 3, 7.5, 3)
      ..cubicTo(9.24, 3, 10.91, 3.81, 12, 5.09)
      ..cubicTo(13.09, 3.81, 14.76, 3, 16.5, 3)
      ..cubicTo(19.58, 3, 22, 5.42, 22, 8.5)
      ..cubicTo(22, 12.28, 18.6, 15.36, 13.45, 20.04)
      ..close();
    if (fillColor.a > 0) {
      canvas.drawPath(path, Paint()..color = fillColor);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = strokeColor,
    );
  }

  @override
  bool shouldRepaint(_HeartPainter oldDelegate) =>
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.fillColor != fillColor;
}

/// 6px dots flying from the heart center to their target offsets while
/// shrinking and fading — the original `like-fly` keyframes on --glide.
class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.progress,
    required this.particles,
    required this.color,
    required this.origin,
  }) : super(repaint: progress);

  static const Curve _glide = Cubic(0.16, 1, 0.3, 1);

  final Animation<double> progress;
  final List<Offset> particles;
  final Color color;

  /// dy 0 means the vertical center of the painted area.
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    final double raw = progress.value;
    if (particles.isEmpty || raw >= 1) return;
    final double t = _glide.transform(raw);
    final Offset center = Offset(origin.dx, size.height / 2 + origin.dy);
    final Paint paint = Paint()..color = color.withValues(alpha: 1 - t);
    for (final Offset target in particles) {
      canvas.drawCircle(center + target * t, 3 * (1 - t), paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.particles != particles || oldDelegate.color != color;
}
