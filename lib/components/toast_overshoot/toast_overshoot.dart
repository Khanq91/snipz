/// ToastOvershoot
/// Origin: reimplemented — kinetics "Toast Overshoot" (Interaction & Input),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/widgets.dart';

/// Status pill that slides up from 140% below its rest position, overshoots,
/// settles, then auto-hides. Change [pushId] to (re)show it; retriggering
/// while visible just restarts the auto-hide timer, like the original.
class ToastOvershoot extends StatefulWidget {
  const ToastOvershoot({
    super.key,
    this.pushId = 0,
    this.message = 'Changes saved',
    this.autoHideDuration = const Duration(milliseconds: 2200),
    this.initiallyVisible = false,
    this.backgroundColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.textColor = const Color(0xFFEDE9E0),
    this.dotColor = const Color(0xFF4CD08A),
    this.onDismissed,
    this.animate = true,
  });

  /// Change this value to show the toast. Zero is reserved for "no request".
  final int pushId;

  final String message;
  final Duration autoHideDuration;

  /// Renders the toast already settled on mount. Primarily for previews and
  /// state boards; it stays until a [pushId] change starts a real cycle.
  final bool initiallyVisible;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color dotColor;
  final VoidCallback? onDismissed;

  /// False disables motion and the auto-hide timer.
  final bool animate;

  @override
  State<ToastOvershoot> createState() => _ToastOvershootState();
}

class _ToastOvershootState extends State<ToastOvershoot>
    with SingleTickerProviderStateMixin {
  // --spring variant of the original toast: cubic-bezier(0.18, 1.25, 0.4, 1).
  static const Curve _overshoot = Cubic(0.18, 1.25, 0.4, 1);

  late final AnimationController _life = AnimationController(
    vsync: this,
    duration: widget.autoHideDuration,
  );
  late bool _visible = widget.initiallyVisible || widget.pushId != 0;

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  @override
  void initState() {
    super.initState();
    _life.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _visible = false);
        widget.onDismissed?.call();
      }
    });
    if (widget.pushId != 0 && widget.animate) _life.forward(from: 0);
  }

  @override
  void didUpdateWidget(ToastOvershoot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _life.duration = widget.autoHideDuration;
    if (oldWidget.pushId != widget.pushId && widget.pushId != 0) {
      setState(() => _visible = true);
      if (widget.animate) _life.forward(from: 0);
    }
    if (oldWidget.animate && !widget.animate) _life.stop();
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Implicit animations retarget from the current value with the same
    // curve — exactly the CSS transition semantics of the original,
    // including interrupted show/hide cycles.
    final Duration slideDuration = _motionEnabled
        ? const Duration(milliseconds: 550)
        : Duration.zero;
    final Duration fadeDuration = _motionEnabled
        ? const Duration(milliseconds: 300)
        : Duration.zero;

    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 1.4),
      duration: slideDuration,
      curve: _overshoot,
      child: AnimatedScale(
        scale: _visible ? 1 : 0.9,
        duration: slideDuration,
        curve: _overshoot,
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: fadeDuration,
          curve: Curves.ease,
          child: Semantics(
            liveRegion: true,
            label: widget.message,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
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
                        fontSize: 13,
                        height: 1.45,
                        color: widget.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
