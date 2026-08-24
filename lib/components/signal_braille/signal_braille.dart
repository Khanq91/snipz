/// SignalBraille
/// Origin: reimplemented — kinetics "Signal Braille" (Feedback & State),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A six-dot, Braille-inspired machine-status matrix. The dots switch among
/// dark, amber and blue in three discrete phases instead of spinning or
/// bouncing, with a quiet status label below.
class SignalBraille extends StatefulWidget {
  const SignalBraille({
    super.key,
    this.label = 'READY',
    this.dotSize = 18,
    this.gap = 9,
    this.labelGap = 3,
    this.labelSize = 16,
    this.idleColor = const Color(0xFF232326),
    this.activeColor = const Color(0xFFFF8A00),
    this.signalColor = const Color(0xFF5B8DEF),
    this.labelColor = const Color(0xFFEDE9E0),
    this.animate = true,
    this.frozenAt,
  });

  final String label;
  final double dotSize;
  final double gap;
  final double labelGap;
  final double labelSize;
  final Color idleColor;
  final Color activeColor;
  final Color signalColor;
  final Color labelColor;

  /// False freezes the current frame and stops the ticker.
  final bool animate;

  /// Renders exactly one deterministic frame at t seconds, without a ticker.
  final double? frozenAt;

  @override
  State<SignalBraille> createState() => _SignalBrailleState();
}

class _SignalBrailleState extends State<SignalBraille>
    with SingleTickerProviderStateMixin {
  static const double _period = 2.1;
  static const List<double> _delays = <double>[0, -0.7, -1.4, -0.7, 0, -1.4];

  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(
      (elapsed) => _time.value = elapsed.inMicroseconds / 1e6,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(SignalBraille oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  void _syncTicker() {
    final bool reduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bool shouldRun =
        widget.animate && widget.frozenAt == null && !reduced;
    if (shouldRun && !_ticker.isActive) {
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  Color _colorAt(double time, int index) {
    double local = (time - _delays[index]) % _period;
    if (local < 0) local += _period;
    final double phase = local / _period;
    if (phase < 0.33) return widget.idleColor;
    if (phase < 0.66) return widget.activeColor;
    return widget.signalColor;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _time,
      builder: (context, liveTime, _) {
        final double time = widget.frozenAt ?? liveTime;
        return Semantics(
          label: '${widget.label} status signal',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int row = 0; row < 3; row++) ...<Widget>[
                if (row > 0) SizedBox(height: widget.gap),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (int column = 0; column < 2; column++) ...<Widget>[
                      if (column > 0) SizedBox(width: widget.gap),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _colorAt(time, row * 2 + column),
                        ),
                        child: SizedBox.square(dimension: widget.dotSize),
                      ),
                    ],
                  ],
                ),
              ],
              SizedBox(height: widget.labelGap),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.labelColor,
                  fontSize: widget.labelSize,
                  fontWeight: FontWeight.w700,
                  height: 1.55,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
