/// WaveLoader
/// Origin: reimplemented — kinetics "Wave Loader" (Surface & Motion),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Four amber dots bouncing in a phase-offset wave.
///
/// The original uses a 1.1s CSS ease-in-out keyframe: each dot rests at
/// opacity 0.4 at 0%, 60%, and 100%, and reaches -12px / opacity 1 at 30%.
/// Successive dots start 0.12s apart.
class WaveLoader extends StatefulWidget {
  const WaveLoader({
    super.key,
    this.dotCount = 4,
    this.dotSize = 11,
    this.gap = 7,
    this.bounceHeight = 12,
    this.color = const Color(0xFFFF8A00),
    this.restOpacity = 0.4,
    this.period = 1.1,
    this.stagger = 0.12,
    this.animate = true,
    this.frozenAt,
  }) : assert(dotCount >= 1),
       assert(dotSize > 0),
       assert(gap >= 0),
       assert(bounceHeight >= 0),
       assert(restOpacity >= 0 && restOpacity <= 1),
       assert(period > 0),
       assert(stagger >= 0);

  /// Number of dots. The live kinetics demo contains four.
  final int dotCount;

  final double dotSize;

  /// Horizontal space between dots.
  final double gap;

  /// Peak upward translation in logical pixels.
  final double bounceHeight;

  final Color color;

  /// Opacity while a dot rests at the bottom of its bounce.
  final double restOpacity;

  /// Seconds per dot cycle.
  final double period;

  /// Positive start delay between neighboring dots, in seconds.
  final double stagger;

  /// Whether the live ticker may run.
  final bool animate;

  /// Renders the deterministic frame at this time in seconds without running
  /// the ticker. Useful for thumbnails and golden tests.
  final double? frozenAt;

  @override
  State<WaveLoader> createState() => _WaveLoaderState();
}

class _WaveLoaderState extends State<WaveLoader>
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
  void didUpdateWidget(WaveLoader oldWidget) {
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
        final double time = widget.frozenAt ?? liveTime;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int index = 0; index < widget.dotCount; index++) ...<Widget>[
              if (index > 0) SizedBox(width: widget.gap),
              _buildDot(time, index),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDot(double time, int index) {
    final _WaveDotFrame frame = _sampleWaveDot(
      time: time,
      index: index,
      period: widget.period,
      stagger: widget.stagger,
      bounceHeight: widget.bounceHeight,
      restOpacity: widget.restOpacity,
    );
    return Transform.translate(
      offset: Offset(0, frame.translateY),
      child: Opacity(
        opacity: frame.opacity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(dimension: widget.dotSize),
        ),
      ),
    );
  }
}

class _WaveDotFrame {
  const _WaveDotFrame({required this.translateY, required this.opacity});

  final double translateY;
  final double opacity;
}

/// Pure CSS-keyframe equivalent. The easing restarts at each keyframe
/// interval, matching `animation-timing-function: ease-in-out`.
_WaveDotFrame _sampleWaveDot({
  required double time,
  required int index,
  required double period,
  required double stagger,
  required double bounceHeight,
  required double restOpacity,
}) {
  double local = (time - index * stagger) % period;
  if (local < 0) local += period;
  final double phase = local / period;

  double peak = 0;
  if (phase < 0.3) {
    peak = Curves.easeInOut.transform(phase / 0.3);
  } else if (phase < 0.6) {
    peak = 1 - Curves.easeInOut.transform((phase - 0.3) / 0.3);
  }

  return _WaveDotFrame(
    translateY: -bounceHeight * peak,
    opacity: restOpacity + (1 - restOpacity) * peak,
  );
}
