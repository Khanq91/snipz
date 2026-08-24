/// TypingIndicator
/// Origin: reimplemented — kinetics "Typing Indicator" (Feedback & State),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Chat "typing…" indicator: a bubble with one squared corner holding three
/// dots. Each dot loops a 1.2s ease-in-out bounce — lifted 7px and brightened
/// at the 30% mark, resting low and dim otherwise — staggered 0.16s apart so
/// the bounce travels left to right.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    super.key,
    this.dotCount = 3,
    this.dotSize = 9,
    this.gap = 7,
    this.bounceHeight = 7,
    this.dotColor = const Color(0xFFA8A6A0),
    this.bubbleColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.showBubble = true,
    this.period = 1.2,
    this.stagger = 0.16,
    this.animate = true,
    this.frozenAt,
  }) : assert(dotCount >= 1);

  final int dotCount;
  final double dotSize;

  /// Horizontal gap between dots.
  final double gap;

  /// Peak lift of a dot in logical px (7px in the original).
  final double bounceHeight;

  final Color dotColor;

  /// Bubble chrome; ignored when [showBubble] is false (dots only — for
  /// embedding in your own message bubble).
  final Color bubbleColor;
  final Color borderColor;
  final bool showBubble;

  /// Seconds per bounce cycle (1.2s in the original).
  final double period;

  /// Per-dot delay (0.16s in the original).
  final double stagger;

  /// False freezes the ticker (viewer freeze button / reduced motion).
  final bool animate;

  /// Non-null renders exactly one deterministic frame at t seconds — no
  /// ticker (thumbnails, golden tests).
  final double? frozenAt;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
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
  void didUpdateWidget(TypingIndicator old) {
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

  /// Keyframes: 0% rest → 30% lifted/bright → 60% rest → 100% rest, each
  /// segment eased in-out. Returns (lift 0..1, opacity).
  (double, double) _sample(double t, int i) {
    final double p = widget.period;
    double local = (t - i * widget.stagger) % p;
    if (local < 0) local += p;
    final double u = local / p;
    double lift = 0;
    if (u < 0.3) {
      lift = Curves.easeInOut.transform(u / 0.3);
    } else if (u < 0.6) {
      lift = 1 - Curves.easeInOut.transform((u - 0.3) / 0.3);
    }
    return (lift, 0.4 + 0.6 * lift);
  }

  @override
  Widget build(BuildContext context) {
    final Widget dots = ValueListenableBuilder<double>(
      valueListenable: _t,
      builder: (context, live, _) {
        final double t = widget.frozenAt ?? live;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < widget.dotCount; i++) ...<Widget>[
              if (i > 0) SizedBox(width: widget.gap),
              _dot(t, i),
            ],
          ],
        );
      },
    );
    if (!widget.showBubble) return dots;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: widget.bubbleColor,
        border: Border.all(color: widget.borderColor),
        // 18px corners, squared (5px) bottom-left — chat tail side.
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(5),
        ),
      ),
      child: dots,
    );
  }

  Widget _dot(double t, int i) {
    final (double lift, double opacity) = _sample(t, i);
    return Transform.translate(
      offset: Offset(0, -widget.bounceHeight * lift),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: widget.dotSize,
          height: widget.dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.dotColor,
          ),
        ),
      ),
    );
  }
}
