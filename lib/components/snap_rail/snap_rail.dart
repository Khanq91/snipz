/// SnapRail
/// Origin: reimplemented — kinetics "Snap Rail" (Interaction & Input),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Segmented rail whose translucent amber pill springs between EQUAL cells —
/// the pill is always one column wide, never sized to the text. Web hover
/// preview maps to touch selection: tap an option and the pill snaps to it.
/// Controlled: the parent owns [index] and rebuilds in [onChanged].
class SnapRail extends StatelessWidget {
  const SnapRail({
    super.key,
    this.labels = const <String>['Day', 'Week', 'Month'],
    required this.index,
    required this.onChanged,
    this.width = 240,
    this.height = 44,
    this.backgroundColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.labelColor = const Color(0xFFA8A6A0),
    this.accentColor = const Color(0xFFFF8A00),
    this.animate = true,
  }) : assert(labels.length > 0),
       assert(index >= 0 && index < labels.length);

  final List<String> labels;
  final int index;
  final ValueChanged<int>? onChanged;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color borderColor;
  final Color labelColor;

  /// Pill (16% fill, 50% border) and the active label.
  final Color accentColor;

  /// False applies state changes immediately.
  final bool animate;

  static const Curve _spring = Cubic(0.34, 1.56, 0.64, 1);
  static const double _padding = 4;

  @override
  Widget build(BuildContext context) {
    final bool motion =
        animate && !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    final Duration snapDuration = motion
        ? const Duration(milliseconds: 450)
        : Duration.zero;
    final Duration colorDuration = motion
        ? const Duration(milliseconds: 250)
        : Duration.zero;
    // Equal columns of the inner track (width minus border and padding).
    final double trackWidth = width - 2 - _padding * 2;
    final double cellWidth = trackWidth / labels.length;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Stack(
        children: <Widget>[
          // The spring overshoots by ~10% of the travel. Past the end cells
          // the outer edge stops at the wall while the inner edge keeps
          // going, so the pill squashes against the end and rebounds instead
          // of poking out of the rounded rail.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: index.toDouble()),
            duration: snapDuration,
            curve: _spring,
            builder: (BuildContext context, double cell, Widget? child) {
              final double x = cell * cellWidth;
              final double left = math.max(x, 0.0);
              final double right = math.min(x + cellWidth, trackWidth);
              return Positioned(
                left: left,
                top: 0,
                bottom: 0,
                width: math.max(right - left, 0.0),
                child: child!,
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.16),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Row(
            children: <Widget>[
              for (int i = 0; i < labels.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onChanged == null ? null : () => onChanged!(i),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: colorDuration,
                          curve: Curves.ease,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1,
                            color: i == index ? accentColor : labelColor,
                          ),
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
