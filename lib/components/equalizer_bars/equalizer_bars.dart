/// EqualizerBars
/// Origin: reimplemented — kinetics "Equalizer Bars" (Surface & Motion),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Five phase-offset bars that pump between 25% and full height like a small
/// audio meter. The one-second ease-in-out loop is deterministic and can be
/// frozen at an exact elapsed time for thumbnails and golden tests.
class EqualizerBars extends StatefulWidget {
  const EqualizerBars({
    super.key,
    this.count = 5,
    this.height = 56,
    this.barWidth = 6,
    this.gap = 5,
    this.radius = 3,
    this.color = const Color(0xFFFF8A00),
    this.period = 1,
    this.phaseDelays = const <double>[0, -0.8, -0.4, -0.6, -0.2],
    this.animate = true,
    this.frozenAt,
  }) : assert(count > 0),
       assert(height > 0),
       assert(barWidth > 0),
       assert(gap >= 0),
       assert(radius >= 0),
       assert(period > 0),
       assert(phaseDelays.length > 0);

  final int count;
  final double height;
  final double barWidth;
  final double gap;
  final double radius;
  final Color color;

  /// Seconds per pump cycle (1s in the original).
  final double period;

  /// CSS animation delays in seconds. Negative values start partway through
  /// the cycle; values repeat when [count] exceeds this list's length.
  final List<double> phaseDelays;

  /// False freezes the internal ticker without scheduling further frames.
  final bool animate;

  /// Non-null renders exactly one deterministic frame at t seconds and never
  /// starts the ticker.
  final double? frozenAt;

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
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
    final double delta =
        ((elapsed - previous).inMicroseconds /
                Duration.microsecondsPerSecond)
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
  void didUpdateWidget(EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  void _syncTicker() {
    final bool reduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bool shouldRun =
        widget.animate && widget.frozenAt == null && !reduced;
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
      builder: (BuildContext context, double live, Widget? child) {
        final double t = widget.frozenAt ?? live;
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (int i = 0; i < widget.count; i++) ...<Widget>[
                if (i > 0) SizedBox(width: widget.gap),
                Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.diagonal3Values(
                    1,
                    _sampleEqualizerScale(
                      time: t,
                      index: i,
                      period: widget.period,
                      phaseDelays: widget.phaseDelays,
                    ),
                    1,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(widget.radius),
                    ),
                    child: SizedBox(
                      width: widget.barWidth,
                      height: widget.height,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Pure per-frame model. A negative CSS delay starts the animation
/// `-delay` seconds into its cycle; easing restarts for each keyframe leg.
double _sampleEqualizerScale({
  required double time,
  required int index,
  required double period,
  required List<double> phaseDelays,
}) {
  final double delay = phaseDelays[index % phaseDelays.length];
  double local = (time - delay) % period;
  if (local < 0) local += period;
  final double phase = local / period;
  final double pump = phase < 0.5
      ? Curves.easeInOut.transform(phase * 2)
      : 1 - Curves.easeInOut.transform((phase - 0.5) * 2);
  return 0.25 + 0.75 * pump;
}
