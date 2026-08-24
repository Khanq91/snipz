/// NotificationSlideIn
/// Origin: reimplemented — kinetics "Notification Slide-in" (Feedback & State),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/widgets.dart';

/// A pill banner that drops from the top edge, overshoots, settles, and then
/// dismisses itself after 2.2s. Increment [requestId] to show it; a retrigger
/// while visible only extends the timer (like the original — the pill does
/// not replay its drop). Motion follows CSS-transition semantics: the pill
/// always animates toward its current target with the same overshoot bezier,
/// entering and leaving alike.
class NotificationSlideIn extends StatefulWidget {
  const NotificationSlideIn({
    super.key,
    this.requestId = 0,
    this.message = 'New message received',
    this.width = 240,
    this.height = 130,
    this.top = 14,
    this.displayDuration = const Duration(milliseconds: 2200),
    this.backgroundColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.textColor = const Color(0xFFEDE9E0),
    this.dotColor = const Color(0xFF4CD08A),
    this.onDismissed,
    this.animate = true,
  });

  /// Change this value to show the banner. Reusing the current value is a
  /// no-op; increasing an integer is the simplest calling pattern.
  final int requestId;
  final String message;
  final double width;
  final double height;
  final double top;
  final Duration displayDuration;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color dotColor;
  final VoidCallback? onDismissed;

  /// False renders a requested notification as a stable visible state.
  final bool animate;

  @override
  State<NotificationSlideIn> createState() => _NotificationSlideInState();
}

class _NotificationSlideInState extends State<NotificationSlideIn>
    with SingleTickerProviderStateMixin {
  /// CSS: transform 0.55s cubic-bezier(0.18, 1.25, 0.4, 1), opacity 0.3s.
  static const Curve _drop = Cubic(0.18, 1.25, 0.4, 1);

  late final AnimationController _life;
  bool _shown = false;

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  @override
  void initState() {
    super.initState();
    _life = AnimationController(vsync: this, duration: widget.displayDuration)
      ..addStatusListener(_onLifeStatus);
    if (widget.requestId != 0) {
      _shown = true;
      if (widget.animate) _life.forward();
    }
  }

  @override
  void didUpdateWidget(NotificationSlideIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.displayDuration != widget.displayDuration) {
      _life.duration = widget.displayDuration;
    }
    if (oldWidget.requestId != widget.requestId) _show();
    if (oldWidget.animate && !widget.animate && _shown) _life.stop();
  }

  void _onLifeStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _dismiss();
  }

  /// Like the original click handler: (re)start the timer; the pill only
  /// animates in when it is not already on screen.
  void _show() {
    if (!_shown) setState(() => _shown = true);
    if (widget.animate) {
      _life.forward(from: 0);
    } else {
      _life
        ..stop()
        ..value = 0;
    }
  }

  void _dismiss() {
    if (!_shown) return;
    _life.stop();
    setState(() => _shown = false);
    // Without motion there is no exit transition to wait for.
    if (!_motionEnabled) widget.onDismissed?.call();
  }

  @override
  void dispose() {
    _life.removeStatusListener(_onLifeStatus);
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool motion = _motionEnabled;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRect(
        child: Stack(
          children: <Widget>[
            Positioned(
              top: widget.top,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                // -160% of the pill's own height, exactly the CSS transform.
                child: AnimatedSlide(
                  offset: _shown ? Offset.zero : const Offset(0, -1.6),
                  duration: motion
                      ? const Duration(milliseconds: 550)
                      : Duration.zero,
                  curve: _drop,
                  onEnd: () {
                    if (!_shown) widget.onDismissed?.call();
                  },
                  child: AnimatedOpacity(
                    opacity: _shown ? 1 : 0,
                    duration: motion
                        ? const Duration(milliseconds: 300)
                        : Duration.zero,
                    curve: Curves.ease,
                    child: Semantics(
                      liveRegion: true,
                      label: widget.message,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: widget.backgroundColor,
                          border: Border.all(color: widget.borderColor),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.dotColor,
                              ),
                              child: const SizedBox.square(dimension: 8),
                            ),
                            const SizedBox(width: 9),
                            Flexible(
                              child: Text(
                                widget.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: widget.textColor,
                                  fontSize: 13,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
