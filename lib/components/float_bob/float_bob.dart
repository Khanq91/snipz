/// FloatBob
/// Origin: reimplemented — kinetics "Float Bob" (Surface & Motion),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A compact card that floats upward while its shadow drops and softens.
///
/// The 4s loop reproduces the original 0/50/100% ease-in-out keyframes.
class FloatBob extends StatefulWidget {
  const FloatBob({
    super.key,
    this.width = 150,
    this.height = 84,
    this.backgroundColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.borderRadius = 14,
    this.shadowColor = const Color(0xFF000000),
    this.lift = 12,
    this.restShadowOffset = 10,
    this.peakShadowOffset = 26,
    this.restShadowBlur = 20,
    this.peakShadowBlur = 30,
    this.restShadowSpread = -8,
    this.peakShadowSpread = -10,
    this.restShadowOpacity = 0.55,
    this.peakShadowOpacity = 0.45,
    this.period = 4,
    this.animate = true,
    this.frozenAt,
    this.child,
  }) : assert(width > 0),
       assert(height > 0),
       assert(borderRadius >= 0),
       assert(lift >= 0),
       assert(restShadowBlur >= 0),
       assert(peakShadowBlur >= 0),
       assert(restShadowOpacity >= 0 && restShadowOpacity <= 1),
       assert(peakShadowOpacity >= 0 && peakShadowOpacity <= 1),
       assert(period > 0);

  final double width;
  final double height;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final Color shadowColor;

  /// Peak upward translation in logical pixels.
  final double lift;

  final double restShadowOffset;
  final double peakShadowOffset;
  final double restShadowBlur;
  final double peakShadowBlur;
  final double restShadowSpread;
  final double peakShadowSpread;
  final double restShadowOpacity;
  final double peakShadowOpacity;

  /// Seconds per complete rise-and-settle cycle.
  final double period;

  /// Whether the live ticker may run.
  final bool animate;

  /// Renders the deterministic frame at this time in seconds without running
  /// the ticker. Useful for thumbnails and golden tests.
  final double? frozenAt;

  /// Content centered in the card. Null preserves the source label,
  /// `float(4s)`.
  final Widget? child;

  @override
  State<FloatBob> createState() => _FloatBobState();
}

class _FloatBobState extends State<FloatBob>
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
  void didUpdateWidget(FloatBob oldWidget) {
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
        final _FloatBobFrame frame = _sampleFloatBob(
          time: widget.frozenAt ?? liveTime,
          period: widget.period,
          lift: widget.lift,
          restShadowOffset: widget.restShadowOffset,
          peakShadowOffset: widget.peakShadowOffset,
          restShadowBlur: widget.restShadowBlur,
          peakShadowBlur: widget.peakShadowBlur,
          restShadowSpread: widget.restShadowSpread,
          peakShadowSpread: widget.peakShadowSpread,
          restShadowOpacity: widget.restShadowOpacity,
          peakShadowOpacity: widget.peakShadowOpacity,
        );
        return Transform.translate(
          offset: Offset(0, frame.translateY),
          child: Container(
            width: widget.width,
            height: widget.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              border: Border.all(color: widget.borderColor),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: widget.shadowColor.withValues(
                    alpha: frame.shadowOpacity,
                  ),
                  offset: Offset(0, frame.shadowOffset),
                  blurRadius: frame.shadowBlur,
                  spreadRadius: frame.shadowSpread,
                ),
              ],
            ),
            child: widget.child ?? _defaultLabel,
          ),
        );
      },
    );
  }
}

const Widget _defaultLabel = Text(
  'float(4s)',
  style: TextStyle(
    color: Color(0xFFA8A6A0),
    fontFamily: 'monospace',
    fontSize: 12,
  ),
);

class _FloatBobFrame {
  const _FloatBobFrame({
    required this.translateY,
    required this.shadowOffset,
    required this.shadowBlur,
    required this.shadowSpread,
    required this.shadowOpacity,
  });

  final double translateY;
  final double shadowOffset;
  final double shadowBlur;
  final double shadowSpread;
  final double shadowOpacity;
}

_FloatBobFrame _sampleFloatBob({
  required double time,
  required double period,
  required double lift,
  required double restShadowOffset,
  required double peakShadowOffset,
  required double restShadowBlur,
  required double peakShadowBlur,
  required double restShadowSpread,
  required double peakShadowSpread,
  required double restShadowOpacity,
  required double peakShadowOpacity,
}) {
  final double amount = _sampleEaseInOutBob(time, period);
  return _FloatBobFrame(
    translateY: -lift * amount,
    shadowOffset: _lerp(restShadowOffset, peakShadowOffset, amount),
    shadowBlur: _lerp(restShadowBlur, peakShadowBlur, amount),
    shadowSpread: _lerp(restShadowSpread, peakShadowSpread, amount),
    shadowOpacity: _lerp(restShadowOpacity, peakShadowOpacity, amount),
  );
}

/// CSS applies `ease-in-out` independently to the 0→50 and 50→100 segments.
double _sampleEaseInOutBob(double time, double period) {
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
