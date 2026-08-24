/// SignalBars
/// Origin: reimplemented — kinetics "Signal Bars" (Feedback & State),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// "Connecting" signal-strength indicator: bars of increasing height whose
/// green fill fades in left-to-right in sequence, holds, then clears and
/// repeats — a device searching for signal. 2.4s ease-in-out loop, bars
/// staggered 0.18s (original keyframes: 0%→12% in, hold to 70%, out by 82%).
class SignalBars extends StatefulWidget {
  const SignalBars({
    super.key,
    this.heights = const <double>[0.32, 0.55, 0.78, 1.0],
    this.height = 56,
    this.barWidth = 14,
    this.gap = 6,
    this.radius = 4,
    this.barColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.fillColor = const Color(0xFF4CD08A),
    this.period = 2.4,
    this.stagger = 0.18,
    this.animate = true,
    this.frozenAt,
  });

  /// Height of each bar as a fraction of [height], left to right.
  final List<double> heights;

  /// Height of the tallest possible bar (the row's height).
  final double height;

  final double barWidth;
  final double gap;
  final double radius;

  /// Empty bar background.
  final Color barColor;
  final Color borderColor;

  /// The "lit" overlay (kinetics success green).
  final Color fillColor;

  /// Seconds per cycle (2.4s in the original).
  final double period;

  /// Per-bar delay (0.18s in the original).
  final double stagger;

  /// False freezes the ticker (viewer freeze button / reduced motion).
  final bool animate;

  /// Non-null renders exactly one deterministic frame at t seconds — no
  /// ticker (thumbnails, golden tests).
  final double? frozenAt;

  @override
  State<SignalBars> createState() => _SignalBarsState();
}

class _SignalBarsState extends State<SignalBars>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker =
        createTicker((elapsed) => _t.value = elapsed.inMicroseconds / 1e6);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(SignalBars old) {
    super.didUpdateWidget(old);
    _syncTicker();
  }

  void _syncTicker() {
    final bool reduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bool run = widget.animate && widget.frozenAt == null && !reduced;
    if (run && !_ticker.isActive) {
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  /// Fill opacity for bar i: 0% → 12% rise, hold to 70%, gone by 82%.
  double _fill(double t, int i) {
    final double p = widget.period;
    double local = (t - i * widget.stagger) % p;
    if (local < 0) local += p;
    final double u = local / p;
    if (u < 0.12) return Curves.easeInOut.transform(u / 0.12);
    if (u < 0.70) return 1;
    if (u < 0.82) return 1 - Curves.easeInOut.transform((u - 0.70) / 0.12);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _t,
      builder: (context, live, _) {
        final double t = widget.frozenAt ?? live;
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (int i = 0; i < widget.heights.length; i++) ...<Widget>[
                if (i > 0) SizedBox(width: widget.gap),
                _bar(t, i),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _bar(double t, int i) {
    return Container(
      width: widget.barWidth,
      height: widget.height * widget.heights[i],
      decoration: BoxDecoration(
        color: widget.barColor,
        border: Border.all(color: widget.borderColor),
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      // The lit overlay covers the bar's interior, inside the border.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius - 1),
        child: ColoredBox(
          color: widget.fillColor.withValues(alpha: _fill(t, i)),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
