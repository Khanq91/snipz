/// ConfettiBurst
/// Origin: reimplemented — kinetics "Confetti Burst" (Surface & Motion),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Pill button that emits a deterministic 16-piece radial confetti burst on
/// every tap. Particles fly, spin, and fade for 900ms; rapid taps create
/// independent overlapping batches just like the source demo.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    required this.onPressed,
    this.child = const Text('Celebrate'),
    this.particleCount = 16,
    this.particleSize = 7,
    this.particleRadius = 2,
    this.colors = const <Color>[
      Color(0xFFFF8A00),
      Color(0xFF5B8DEF),
      Color(0xFF4CD08A),
      Color(0xFFEDE9E0),
    ],
    this.seed = 7,
    this.backgroundColor = const Color(0xFFFF8A00),
    this.foregroundColor = const Color(0xFF0E0E10),
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
    this.textStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    this.animate = true,
  }) : assert(particleCount > 0),
       assert(particleSize > 0),
       assert(particleRadius >= 0),
       assert(colors.length > 0);

  /// Called after the burst starts. Null disables taps.
  final VoidCallback? onPressed;

  /// Content centered inside the pill.
  final Widget child;

  final int particleCount;
  final double particleSize;
  final double particleRadius;

  /// Particle palette, assigned cyclically around the burst.
  final List<Color> colors;

  /// Seed for deterministic angle jitter, distance, and rotation.
  final int seed;

  final Color backgroundColor;
  final Color foregroundColor;
  final EdgeInsetsGeometry padding;
  final TextStyle textStyle;

  /// False disables the burst and applies press state changes immediately;
  /// [onPressed] still fires.
  final bool animate;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const Curve _glide = Cubic(0.16, 1, 0.3, 1);
  static const Curve _pressSpring = Cubic(0.34, 1.56, 0.64, 1);
  static const double _burstSeconds = 0.9;

  late final Ticker _ticker;
  final ValueNotifier<double> _clockSignal = ValueNotifier<double>(0);
  late math.Random _random = math.Random(widget.seed);
  final List<_ConfettiBatch> _bursts = <_ConfettiBatch>[];
  Duration? _lastTick;
  double _clock = 0;
  bool _pressed = false;

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

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
    _clock += delta;
    final int oldCount = _bursts.length;
    _bursts.removeWhere(
      (_ConfettiBatch batch) => _clock - batch.startedAt >= _burstSeconds,
    );
    _clockSignal.value = _clock;
    if (_bursts.length != oldCount && mounted) {
      setState(() {});
    }
    if (_bursts.isEmpty && _ticker.isActive) {
      _ticker.stop();
      _lastTick = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stopIfMotionDisabled();
  }

  @override
  void didUpdateWidget(ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) {
      _random = math.Random(widget.seed);
    }
    _stopIfMotionDisabled();
  }

  void _stopIfMotionDisabled() {
    if (!_motionEnabled) {
      if (_ticker.isActive) _ticker.stop();
      _lastTick = null;
      _bursts.clear();
    }
  }

  List<_ConfettiParticle> _createParticles() {
    return List<_ConfettiParticle>.generate(widget.particleCount, (int i) {
      final double angle =
          math.pi * 2 * i / widget.particleCount + _random.nextDouble() * 0.4;
      final double distance = 55 + _random.nextDouble() * 55;
      return _ConfettiParticle(
        target: Offset(math.cos(angle) * distance, math.sin(angle) * distance),
        rotation: _random.nextDouble() * math.pi * 2,
        color: widget.colors[i % widget.colors.length],
      );
    });
  }

  void _setPressed(bool value) {
    if (_pressed == value || widget.onPressed == null) return;
    setState(() => _pressed = value);
  }

  void _activate() {
    final VoidCallback? callback = widget.onPressed;
    if (callback == null) return;
    if (_motionEnabled) {
      setState(
        () => _bursts.add(
          _ConfettiBatch(startedAt: _clock, particles: _createParticles()),
        ),
      );
      if (!_ticker.isActive) {
        _lastTick = Duration.zero;
        _ticker.start();
      }
    }
    callback();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clockSignal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Duration pressDuration = _motionEnabled
        ? const Duration(milliseconds: 200)
        : Duration.zero;

    return Semantics(
      button: true,
      enabled: enabled,
      onTap: enabled ? _activate : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: enabled ? _activate : null,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            AnimatedScale(
              scale: _pressed ? 0.94 : 1,
              duration: pressDuration,
              curve: _pressSpring,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Padding(
                  padding: widget.padding,
                  child: IconTheme(
                    data: IconThemeData(color: widget.foregroundColor),
                    child: DefaultTextStyle.merge(
                      style: widget.textStyle.copyWith(
                        color: widget.foregroundColor,
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ConfettiPainter(
                    clock: _clockSignal,
                    bursts: List<_ConfettiBatch>.unmodifiable(_bursts),
                    particleSize: widget.particleSize,
                    particleRadius: widget.particleRadius,
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

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.target,
    required this.rotation,
    required this.color,
  });

  final Offset target;
  final double rotation;
  final Color color;
}

class _ConfettiBatch {
  const _ConfettiBatch({required this.startedAt, required this.particles});

  final double startedAt;
  final List<_ConfettiParticle> particles;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.clock,
    required this.bursts,
    required this.particleSize,
    required this.particleRadius,
  }) : super(repaint: clock);

  final ValueListenable<double> clock;
  final List<_ConfettiBatch> bursts;
  final double particleSize;
  final double particleRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (bursts.isEmpty) return;
    final Rect particleRect = Rect.fromCenter(
      center: Offset.zero,
      width: particleSize,
      height: particleSize,
    );
    final RRect particleShape = RRect.fromRectAndRadius(
      particleRect,
      Radius.circular(particleRadius),
    );
    final Offset origin = size.center(Offset.zero);
    final Paint paint = Paint();

    for (final _ConfettiBatch batch in bursts) {
      final double raw = ((clock.value - batch.startedAt) /
              _ConfettiBurstState._burstSeconds)
          .clamp(0.0, 1.0)
          .toDouble();
      if (raw >= 1) continue;
      final double t = _ConfettiBurstState._glide.transform(raw);
      for (final _ConfettiParticle particle in batch.particles) {
        paint.color = particle.color.withValues(alpha: 1 - t);
        final Offset position = origin + particle.target * t;
        canvas
          ..save()
          ..translate(position.dx, position.dy)
          ..rotate(particle.rotation * t)
          ..drawRRect(particleShape, paint)
          ..restore();
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.bursts != bursts ||
      oldDelegate.particleSize != particleSize ||
      oldDelegate.particleRadius != particleRadius;
}
