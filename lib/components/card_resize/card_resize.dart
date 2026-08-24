/// CardResize
/// Origin: reimplemented — kinetics "Card Resize" (Interaction & Input),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/widgets.dart';

/// Card that springs between two fixed heights on tap. Only the height
/// animates (single overshooting cubic); the secondary text fades in with a
/// small delay so it never lingers during the collapse.
class CardResize extends StatefulWidget {
  const CardResize({
    super.key,
    this.title = 'Tap to expand',
    this.extra =
        'Spring-driven height with a single cubic-bezier that mimics '
        'critically damped motion.',
    this.width = 220,
    this.collapsedHeight = 64,
    this.expandedHeight = 124,
    this.initiallyExpanded = false,
    this.backgroundColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.titleColor = const Color(0xFFEDE9E0),
    this.extraColor = const Color(0xFFA8A6A0),
    this.borderRadius = 9,
    this.onChanged,
    this.animate = true,
  }) : assert(expandedHeight >= collapsedHeight);

  final String title;

  /// Secondary text revealed while expanded.
  final String extra;
  final double width;
  final double collapsedHeight;
  final double expandedHeight;
  final bool initiallyExpanded;
  final Color backgroundColor;
  final Color borderColor;
  final Color titleColor;
  final Color extraColor;
  final double borderRadius;
  final ValueChanged<bool>? onChanged;

  /// False applies state changes immediately.
  final bool animate;

  @override
  State<CardResize> createState() => _CardResizeState();
}

class _CardResizeState extends State<CardResize> {
  // --spring of the original design system.
  static const Curve _spring = Cubic(0.34, 1.56, 0.64, 1);

  late bool _expanded = widget.initiallyExpanded;

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  void _toggle() {
    setState(() => _expanded = !_expanded);
    widget.onChanged?.call(_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final Duration heightDuration = _motionEnabled
        ? const Duration(milliseconds: 500)
        : Duration.zero;
    // 400ms with a 0.25 interval = the original 0.1s delay + 0.3s ease fade.
    final Duration fadeDuration = _motionEnabled
        ? const Duration(milliseconds: 400)
        : Duration.zero;

    return Semantics(
      button: true,
      expanded: _expanded,
      onTap: _toggle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: AnimatedContainer(
          duration: heightDuration,
          curve: _spring,
          width: widget.width,
          height: _expanded ? widget.expandedHeight : widget.collapsedHeight,
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: Border.all(color: widget.borderColor),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          // Content keeps its intrinsic height; the card clips it while the
          // height spring runs (the original's overflow: hidden).
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minHeight: 0,
            maxHeight: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    color: widget.titleColor,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedOpacity(
                  opacity: _expanded ? 1 : 0,
                  duration: fadeDuration,
                  curve: const Interval(0.25, 1, curve: Curves.ease),
                  child: Text(
                    widget.extra,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: widget.extraColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
