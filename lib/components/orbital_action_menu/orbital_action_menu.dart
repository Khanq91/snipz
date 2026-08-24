/// OrbitalActionMenu
/// Origin: reimplemented — kinetics "Orbital Action Menu" (Interaction & Input),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/widgets.dart';

/// Compact radial menu: four tiny actions start stacked behind an amber +
/// core, then spring outward in cardinal directions (N/E/S/W) while the core
/// rotates 45° and shrinks slightly. Web hover maps to touch: tap the core
/// to toggle, tap an action to fire it (and close).
class OrbitalActionMenu extends StatefulWidget {
  const OrbitalActionMenu({
    super.key,
    this.actions = const <String>['✦', '↗', '⌁', '⌘'],
    this.onAction,
    this.initiallyOpen = false,
    this.orbitRadius = 48,
    this.coreSize = 46,
    this.actionSize = 31,
    this.coreColor = const Color(0xFFFF8A00),
    this.coreIconColor = const Color(0xFF0E0E10),
    this.actionColor = const Color(0xFF232326),
    this.actionBorderColor = const Color(0xFF2A2A2E),
    this.actionIconColor = const Color(0xFFA8A6A0),
    this.onOpenChanged,
    this.animate = true,
  });

  /// Glyphs in N, E, S, W order; extras beyond four are ignored.
  final List<String> actions;
  final ValueChanged<int>? onAction;
  final bool initiallyOpen;
  final double orbitRadius;
  final double coreSize;
  final double actionSize;
  final Color coreColor;
  final Color coreIconColor;
  final Color actionColor;
  final Color actionBorderColor;
  final Color actionIconColor;
  final ValueChanged<bool>? onOpenChanged;

  /// False applies state changes immediately.
  final bool animate;

  @override
  State<OrbitalActionMenu> createState() => _OrbitalActionMenuState();
}

class _OrbitalActionMenuState extends State<OrbitalActionMenu> {
  static const Curve _spring = Cubic(0.34, 1.56, 0.64, 1);
  // Unit vectors of the four cardinal slots: N, E, S, W.
  static const List<Offset> _directions = <Offset>[
    Offset(0, -1),
    Offset(1, 0),
    Offset(0, 1),
    Offset(-1, 0),
  ];

  late bool _open = widget.initiallyOpen;

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  void _toggle() {
    setState(() => _open = !_open);
    widget.onOpenChanged?.call(_open);
  }

  void _fire(int i) {
    widget.onAction?.call(i);
    if (_open) _toggle();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> actions = widget.actions.take(4).toList();
    return SizedBox(
      width: 126,
      height: 126,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          for (int i = 0; i < actions.length; i++) _action(i, actions[i]),
          _core(),
        ],
      ),
    );
  }

  Widget _action(int i, String glyph) {
    final Duration moveDuration = _motionEnabled
        ? const Duration(milliseconds: 460)
        : Duration.zero;
    final Duration fadeDuration = _motionEnabled
        ? const Duration(milliseconds: 200)
        : Duration.zero;
    final Offset target = _open
        ? _directions[i] * widget.orbitRadius
        : Offset.zero;

    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(end: target),
      duration: moveDuration,
      curve: _spring,
      builder: (context, offset, child) =>
          Transform.translate(offset: offset, child: child),
      child: AnimatedOpacity(
        opacity: _open ? 1 : 0,
        duration: fadeDuration,
        curve: Curves.ease,
        child: Semantics(
          button: true,
          label: glyph,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _open ? () => _fire(i) : null,
            child: Container(
              width: widget.actionSize,
              height: widget.actionSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.actionColor,
                border: Border.all(color: widget.actionBorderColor),
              ),
              child: Text(
                glyph,
                style: TextStyle(
                  fontSize: 14,
                  height: 1,
                  color: widget.actionIconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _core() {
    final Duration coreDuration = _motionEnabled
        ? const Duration(milliseconds: 420)
        : Duration.zero;
    return Semantics(
      button: true,
      expanded: _open,
      label: 'Open actions',
      onTap: _toggle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        // rotate(45deg) scale(0.88) in one transform, one spring.
        child: AnimatedRotation(
          turns: _open ? 45 / 360 : 0,
          duration: coreDuration,
          curve: _spring,
          child: AnimatedScale(
            scale: _open ? 0.88 : 1,
            duration: coreDuration,
            curve: _spring,
            child: Container(
              width: widget.coreSize,
              height: widget.coreSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.coreColor,
              ),
              child: Text(
                '+',
                style: TextStyle(
                  fontSize: 27,
                  height: 1,
                  color: widget.coreIconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
