/// MarqueeReveal
/// Origin: reimplemented — kinetics "Marquee Reveal" (Surface & Motion),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A clipped card strip that scrolls forever and pauses under a finger.
///
/// The source loops five numbered cards (duplicated) through a 220 × 100
/// window over six linear seconds and pauses on hover
/// (`animation-play-state: paused`). Hover maps to press-and-hold here:
/// pointer down freezes the strip, release resumes it.
class MarqueeReveal extends StatefulWidget {
  const MarqueeReveal({
    super.key,
    this.labels = const <String>['01', '02', '03', '04', '05'],
    this.width = 220,
    this.height = 100,
    this.cardWidth = 80,
    this.cardHeight = 64,
    this.gap = 12,
    this.borderRadius = 14,
    this.cardRadius = 9,
    this.backgroundColor = const Color(0xFF141417),
    this.cardColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.labelStyle = const TextStyle(
      color: Color(0xFFA8A6A0),
      fontSize: 11,
      fontFamily: 'monospace',
    ),
    this.period = 6,
    this.pauseOnPress = true,
    this.animate = true,
    this.frozenAt,
  }) : assert(labels.length > 0),
       assert(width > 0),
       assert(height > 0),
       assert(cardWidth > 0),
       assert(cardHeight > 0),
       assert(gap >= 0),
       assert(period > 0);

  /// One scroll period's card labels; the strip repeats them seamlessly.
  final List<String> labels;

  /// Clip window size (220 × 100 in the source).
  final double width;
  final double height;

  final double cardWidth;
  final double cardHeight;
  final double gap;
  final double borderRadius;
  final double cardRadius;
  final Color backgroundColor;
  final Color cardColor;
  final Color borderColor;
  final TextStyle labelStyle;

  /// Seconds per full label cycle (CSS `6s linear infinite`).
  final double period;

  /// Press-and-hold pause — the touch mapping of the source's hover pause.
  final bool pauseOnPress;

  /// Whether the live ticker may run.
  final bool animate;

  /// Renders the deterministic frame at this time in seconds without running
  /// the ticker. Useful for thumbnails and golden tests.
  final double? frozenAt;

  @override
  State<MarqueeReveal> createState() => _MarqueeRevealState();
}

class _MarqueeRevealState extends State<MarqueeReveal>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  Duration? _lastTick;
  double _elapsedSeconds = 0;
  bool _pressed = false;

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
    // animation-play-state: paused — the clock holds, it does not rewind.
    if (!_pressed) {
      _elapsedSeconds += delta;
      _time.value = _elapsedSeconds;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(MarqueeReveal oldWidget) {
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

  void _setPressed(bool value) {
    if (!widget.pauseOnPress) return;
    _pressed = value;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // One full label set, gap included — the exact loop period. (The source
    // translates -50% of a track whose duplicated sets share one inner gap,
    // leaving a 6px seam every loop; the port scrolls the true period so the
    // loop is seamless.)
    final double setWidth =
        widget.labels.length * (widget.cardWidth + widget.gap);
    // Enough copies to cover the window at every shift in [0, setWidth).
    final int copies = (widget.width / setWidth).ceil() + 1;

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: Container(
        width: widget.width,
        height: widget.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: widget.borderColor),
        ),
        child: ValueListenableBuilder<double>(
          valueListenable: _time,
          builder: (context, liveTime, strip) {
            final double t = widget.frozenAt ?? liveTime;
            double shift = (t / widget.period) % 1 * setWidth;
            if (shift < 0) shift += setWidth;
            return OverflowBox(
              maxWidth: double.infinity,
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(-shift, 0),
                child: strip,
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int copy = 0; copy < copies; copy++)
                for (final String label in widget.labels) ...<Widget>[
                  _MarqueeCard(
                    label: label,
                    width: widget.cardWidth,
                    height: widget.cardHeight,
                    radius: widget.cardRadius,
                    color: widget.cardColor,
                    borderColor: widget.borderColor,
                    style: widget.labelStyle,
                  ),
                  SizedBox(width: widget.gap),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MarqueeCard extends StatelessWidget {
  const _MarqueeCard({
    required this.label,
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
    required this.borderColor,
    required this.style,
  });

  final String label;
  final double width;
  final double height;
  final double radius;
  final Color color;
  final Color borderColor;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: Text(label, style: style),
    );
  }
}
