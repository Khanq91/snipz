/// SwitchSpring
/// Origin: reimplemented — kinetics "Switch Spring" (Feedback & State),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/widgets.dart';

/// Controlled toggle whose knob overshoots as it crosses the track.
class SwitchSpring extends StatelessWidget {
  const SwitchSpring({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 54,
    this.height = 30,
    this.padding = 4,
    this.knobSize = 22,
    this.offTrackColor = const Color(0xFF232326),
    this.onTrackColor = const Color(0xFFB36200),
    this.borderColor = const Color(0xFF2A2A2E),
    this.onBorderColor = const Color(0xFFFF8A00),
    this.offKnobColor = const Color(0xFFA8A6A0),
    this.onKnobColor = const Color(0xFF0E0E10),
    this.animate = true,
  }) : assert(width >= knobSize + padding * 2),
       assert(height >= knobSize + padding * 2);

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double width;
  final double height;
  final double padding;
  final double knobSize;
  final Color offTrackColor;
  final Color onTrackColor;
  final Color borderColor;
  final Color onBorderColor;
  final Color offKnobColor;
  final Color onKnobColor;

  /// False applies state changes immediately.
  final bool animate;

  static const Curve _spring = Cubic(0.34, 1.56, 0.64, 1);

  @override
  Widget build(BuildContext context) {
    final bool enabled = onChanged != null;
    final Duration colorDuration = animate
        ? const Duration(milliseconds: 300)
        : Duration.zero;
    final Duration slideDuration = animate
        ? const Duration(milliseconds: 400)
        : Duration.zero;
    final double travel = width - knobSize - padding * 2;

    return Semantics(
      button: true,
      enabled: enabled,
      toggled: value,
      onTap: enabled ? () => onChanged!(!value) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: colorDuration,
          curve: Curves.ease,
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: value ? onTrackColor : offTrackColor,
            border: Border.all(color: value ? onBorderColor : borderColor),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Stack(
            children: <Widget>[
              AnimatedPositioned(
                duration: slideDuration,
                curve: _spring,
                left: padding + (value ? travel : 0),
                top: (height - knobSize) / 2,
                child: AnimatedContainer(
                  duration: colorDuration,
                  curve: Curves.ease,
                  width: knobSize,
                  height: knobSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? onKnobColor : offKnobColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
