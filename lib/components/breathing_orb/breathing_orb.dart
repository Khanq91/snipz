/// BreathingOrb
/// Origin: reimplemented — kinetics "Breathing Orb" (Surface & Motion),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A radial-gradient orb that gently inflates while its amber glow expands.
///
/// The 5s loop reproduces the original 0/50/100% CSS keyframes: scale
/// 0.9 → 1.08 → 0.9, with the glow interpolating in sync.
class BreathingOrb extends StatefulWidget {
  const BreathingOrb({
    super.key,
    this.size = 96,
    this.color = const Color(0xFFFF8A00),
    this.deepColor = const Color(0xFFB36200),
    this.glowColor = const Color(0xFFFF8A00),
    this.minScale = 0.9,
    this.maxScale = 1.08,
    this.minGlowBlur = 20,
    this.maxGlowBlur = 48,
    this.minGlowSpread = 0,
    this.maxGlowSpread = 8,
    this.minGlowOpacity = 0.35,
    this.maxGlowOpacity = 0.55,
    this.period = 5,
    this.animate = true,
    this.frozenAt,
    this.child,
  }) : assert(size > 0),
       assert(minScale >= 0),
       assert(maxScale >= minScale),
       assert(minGlowBlur >= 0),
       assert(maxGlowBlur >= minGlowBlur),
       assert(minGlowOpacity >= 0 && minGlowOpacity <= 1),
       assert(maxGlowOpacity >= 0 && maxGlowOpacity <= 1),
       assert(period > 0);

  final double size;
  final Color color;
  final Color deepColor;
  final Color glowColor;
  final double minScale;
  final double maxScale;
  final double minGlowBlur;
  final double maxGlowBlur;
  final double minGlowSpread;
  final double maxGlowSpread;
  final double minGlowOpacity;
  final double maxGlowOpacity;

  /// Seconds per complete inhale-and-exhale cycle.
  final double period;

  /// Whether the live ticker may run.
  final bool animate;

  /// Renders the deterministic frame at this time in seconds without running
  /// the ticker. Useful for thumbnails and golden tests.
  final double? frozenAt;

  /// Content centered in the orb. Null preserves the source label, `breathe`.
  final Widget? child;

  @override
  State<BreathingOrb> createState() => _BreathingOrbState();
}

class _BreathingOrbState extends State<BreathingOrb>
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
  void didUpdateWidget(BreathingOrb oldWidget) {
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
        final _BreathingOrbFrame frame = _sampleBreathingOrb(
          time: widget.frozenAt ?? liveTime,
          period: widget.period,
          minScale: widget.minScale,
          maxScale: widget.maxScale,
          minGlowBlur: widget.minGlowBlur,
          maxGlowBlur: widget.maxGlowBlur,
          minGlowSpread: widget.minGlowSpread,
          maxGlowSpread: widget.maxGlowSpread,
          minGlowOpacity: widget.minGlowOpacity,
          maxGlowOpacity: widget.maxGlowOpacity,
        );
        return Transform.scale(
          scale: frame.scale,
          child: SizedBox.square(
            dimension: widget.size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(0, -0.1),
                  radius: math.sqrt(0.5 * 0.5 + 0.55 * 0.55),
                  colors: <Color>[widget.color, widget.deepColor],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: widget.glowColor.withValues(
                      alpha: frame.glowOpacity,
                    ),
                    blurRadius: frame.glowBlur,
                    spreadRadius: frame.glowSpread,
                  ),
                ],
              ),
              child: Center(child: widget.child ?? _defaultLabel),
            ),
          ),
        );
      },
    );
  }
}

const Widget _defaultLabel = Text(
  'breathe',
  style: TextStyle(
    color: Color(0xFF0E0E10),
    fontFamily: 'monospace',
    fontSize: 11,
    fontWeight: FontWeight.w600,
  ),
);

class _BreathingOrbFrame {
  const _BreathingOrbFrame({
    required this.scale,
    required this.glowBlur,
    required this.glowSpread,
    required this.glowOpacity,
  });

  final double scale;
  final double glowBlur;
  final double glowSpread;
  final double glowOpacity;
}

_BreathingOrbFrame _sampleBreathingOrb({
  required double time,
  required double period,
  required double minScale,
  required double maxScale,
  required double minGlowBlur,
  required double maxGlowBlur,
  required double minGlowSpread,
  required double maxGlowSpread,
  required double minGlowOpacity,
  required double maxGlowOpacity,
}) {
  final double amount = _sampleEaseInOutBreath(time, period);
  return _BreathingOrbFrame(
    scale: _lerp(minScale, maxScale, amount),
    glowBlur: _lerp(minGlowBlur, maxGlowBlur, amount),
    glowSpread: _lerp(minGlowSpread, maxGlowSpread, amount),
    glowOpacity: _lerp(minGlowOpacity, maxGlowOpacity, amount),
  );
}

/// CSS applies `ease-in-out` independently to the 0→50 and 50→100 segments.
double _sampleEaseInOutBreath(double time, double period) {
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
