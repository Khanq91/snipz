/// ContextualDock
/// Origin: reimplemented — kinetics "Contextual Dock" (Interaction & Input),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/widgets.dart';

/// Icon dock with a discrete focus field: the pressed icon rises and
/// enlarges, its immediate neighbours get exactly half the lift — three
/// tiers, not a continuous falloff. Web hover maps to touch: press/drag
/// along the bar moves the focus, release settles the dock (and taps the
/// focused icon).
class ContextualDock extends StatefulWidget {
  const ContextualDock({
    super.key,
    this.icons = const <String>['◇', '◒', '✳', '◈', '⌁'],
    this.onPressed,
    this.focusedIndex,
    this.backgroundColor = const Color(0xCC232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.buttonColor = const Color(0xFF141417),
    this.iconColor = const Color(0xFFA8A6A0),
    this.focusColor = const Color(0xFFFF8A00),
    this.focusIconColor = const Color(0xFF0E0E10),
    this.animate = true,
  });

  final List<String> icons;
  final ValueChanged<int>? onPressed;

  /// Pins the focused icon (previews/state boards). Null = pointer-driven.
  final int? focusedIndex;

  /// card-2 at 80% like the original color-mix.
  final Color backgroundColor;
  final Color borderColor;
  final Color buttonColor;
  final Color iconColor;
  final Color focusColor;
  final Color focusIconColor;

  /// False applies state changes immediately.
  final bool animate;

  @override
  State<ContextualDock> createState() => _ContextualDockState();
}

class _ContextualDockState extends State<ContextualDock> {
  static const Curve _spring = Cubic(0.34, 1.56, 0.64, 1);

  // Original geometry: 31px buttons, gap 7, padding 13px 15px.
  static const double _button = 31;
  static const double _gap = 7;
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 13,
  );

  int? _pressed;

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  int? get _focused => widget.focusedIndex ?? _pressed;

  int? _indexAt(Offset local) {
    final double x = local.dx - _padding.left;
    final int i = (x / (_button + _gap)).floor();
    if (i < 0 || i >= widget.icons.length) return null;
    // Only the button itself counts, not the gap after it.
    if (x - i * (_button + _gap) > _button) return null;
    return i;
  }

  void _update(Offset local) {
    final int? i = _indexAt(local);
    if (i != _pressed) setState(() => _pressed = i);
  }

  void _release({required bool tap}) {
    final int? i = _pressed;
    if (i == null) return;
    setState(() => _pressed = null);
    if (tap) widget.onPressed?.call(i);
  }

  @override
  Widget build(BuildContext context) {
    final Duration moveDuration = _motionEnabled
        ? const Duration(milliseconds: 300)
        : Duration.zero;
    final Duration colorDuration = _motionEnabled
        ? const Duration(milliseconds: 200)
        : Duration.zero;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => _update(e.localPosition),
      onPointerMove: (e) => _update(e.localPosition),
      onPointerUp: (_) => _release(tap: true),
      onPointerCancel: (_) => _release(tap: false),
      child: Container(
        padding: _padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          border: Border.all(color: widget.borderColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            for (int i = 0; i < widget.icons.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: _gap),
              _iconButton(i, moveDuration, colorDuration),
            ],
          ],
        ),
      ),
    );
  }

  Widget _iconButton(int i, Duration moveDuration, Duration colorDuration) {
    final int? focused = _focused;
    // Three tiers: the focused icon, its direct neighbours, everyone else.
    final double lift;
    final double scale;
    if (focused == i) {
      lift = -14;
      scale = 1.34;
    } else if (focused != null && (i - focused).abs() == 1) {
      lift = -7;
      scale = 1.13;
    } else {
      lift = 0;
      scale = 1;
    }
    final bool hot = focused == i;

    return Semantics(
      button: true,
      label: widget.icons[i],
      child: AnimatedContainer(
        duration: moveDuration,
        curve: _spring,
        transform: Matrix4.translationValues(0, lift, 0)..scaleByDouble(scale, scale, 1, 1),
        transformAlignment: Alignment.center,
        child: AnimatedContainer(
          duration: colorDuration,
          curve: Curves.ease,
          width: _button,
          height: _button,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hot ? widget.focusColor : widget.buttonColor,
            border: Border.all(color: widget.borderColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedDefaultTextStyle(
            duration: colorDuration,
            curve: Curves.ease,
            style: TextStyle(
              fontSize: 14,
              height: 1,
              color: hot ? widget.focusIconColor : widget.iconColor,
            ),
            child: Text(widget.icons[i]),
          ),
        ),
      ),
    );
  }
}
