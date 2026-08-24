/// TabPillGlide
/// Origin: reimplemented — kinetics "Tab Pill Glide" (Interaction & Input),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/widgets.dart';

/// Segmented tab control where an accent pill glides (left AND width) to the
/// active tab while the label colors crossfade. Controlled: the parent owns
/// [index] and rebuilds in [onChanged].
class TabPillGlide extends StatelessWidget {
  const TabPillGlide({
    super.key,
    this.tabs = const <String>['Plan', 'Build', 'Ship'],
    required this.index,
    required this.onChanged,
    this.backgroundColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.pillColor = const Color(0xFFFF8A00),
    this.labelColor = const Color(0xFFA8A6A0),
    this.activeLabelColor = const Color(0xFF0E0E10),
    this.animate = true,
  }) : assert(tabs.length > 0),
       assert(index >= 0 && index < tabs.length);

  final List<String> tabs;
  final int index;
  final ValueChanged<int>? onChanged;
  final Color backgroundColor;
  final Color borderColor;
  final Color pillColor;
  final Color labelColor;
  final Color activeLabelColor;

  /// False applies state changes immediately.
  final bool animate;

  // Container padding, gap and button padding of the original demo.
  static const double _framePadding = 5;
  static const double _gap = 4;
  static const EdgeInsets _buttonPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 7,
  );
  static const TextStyle _labelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  // cubic-bezier(0.65, 0, 0.35, 1) — the glide of both left and width.
  static const Curve _glide = Cubic(0.65, 0, 0.35, 1);

  @override
  Widget build(BuildContext context) {
    final bool motion =
        animate && !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    final Duration glideDuration = motion
        ? const Duration(milliseconds: 400)
        : Duration.zero;
    final Duration colorDuration = motion
        ? const Duration(milliseconds: 300)
        : Duration.zero;

    // The original JS measures the target button (offsetLeft/offsetWidth)
    // before moving the pill; here the same numbers come from TextPainter so
    // pill and labels always agree.
    final TextScaler scaler =
        MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;
    final List<double> widths = <double>[
      for (final String tab in tabs)
        _measure(tab, scaler) + _buttonPadding.horizontal,
    ];
    double pillLeft = _framePadding;
    for (int i = 0; i < index; i++) {
      pillLeft += widths[i] + _gap;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Stack(
        children: <Widget>[
          AnimatedPositioned(
            duration: glideDuration,
            curve: _glide,
            left: pillLeft,
            top: _framePadding,
            bottom: _framePadding,
            width: widths[index],
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(_framePadding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < tabs.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: _gap),
                  _tab(i, glideDuration: colorDuration),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(int i, {required Duration glideDuration}) {
    final bool active = i == index;
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(i),
        child: Padding(
          padding: _buttonPadding,
          child: AnimatedDefaultTextStyle(
            duration: glideDuration,
            curve: Curves.ease,
            style: _labelStyle.copyWith(
              color: active ? activeLabelColor : labelColor,
            ),
            child: Text(tabs[i]),
          ),
        ),
      ),
    );
  }

  double _measure(String text, TextScaler scaler) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: _labelStyle),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final double width = painter.width;
    painter.dispose();
    return width;
  }
}
