/// VariableWeightText
/// Origin: reimplemented — kinetics "Variable Weight" (Surface & Motion),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/widgets.dart';

/// Display text that glides from feather-light to black while pressed.
///
/// The source is a `:hover` transition on a variable font: weight 200 → 800
/// and tracking 0.04em → -0.02em over 0.55s `cubic-bezier(0.16, 1, 0.3, 1)`,
/// with the color turning amber over 0.35s ease and a soft glow fading in
/// over 0.45s ease. Hover maps to press-and-hold: down engages, release
/// relaxes with the same curves.
///
/// The weight animates through `FontVariation('wght', …)`, which is smooth
/// wherever the resolved font has a weight axis (system Roboto on newer
/// Android); elsewhere the synced [FontWeight] fallback steps through the
/// nine static weights.
class VariableWeightText extends StatefulWidget {
  const VariableWeightText({
    super.key,
    this.text = 'MORPH',
    this.fontSize = 40,
    this.fontFamily,
    this.idleWeight = 200,
    this.engagedWeight = 800,
    this.idleTrackingEm = 0.04,
    this.engagedTrackingEm = -0.02,
    this.idleColor = const Color(0xFFEDE9E0),
    this.engagedColor = const Color(0xFFFF8A00),
    this.glowColor = const Color(0xFFFF8A00),
    this.glowBlur = 28,
    this.glowOpacity = 0.35,
    this.weightDuration = const Duration(milliseconds: 550),
    this.colorDuration = const Duration(milliseconds: 350),
    this.glowDuration = const Duration(milliseconds: 450),
    this.engaged,
    this.onEngagedChanged,
    this.animate = true,
  }) : assert(fontSize > 0),
       assert(idleWeight >= 1 && idleWeight <= 1000),
       assert(engagedWeight >= 1 && engagedWeight <= 1000),
       assert(glowBlur >= 0),
       assert(glowOpacity >= 0 && glowOpacity <= 1);

  final String text;
  final double fontSize;

  /// Null uses the default font. The source uses the Archivo variable font;
  /// supply a bundled variable font family here to reproduce it exactly.
  final String? fontFamily;

  /// `wght` axis values (200 → 800 in the source).
  final double idleWeight;
  final double engagedWeight;

  /// CSS letter-spacing in em, resolved against [fontSize].
  final double idleTrackingEm;
  final double engagedTrackingEm;

  final Color idleColor;
  final Color engagedColor;
  final Color glowColor;

  /// Engaged text-shadow: blur 28 at 35% alpha in the source.
  final double glowBlur;
  final double glowOpacity;

  /// Per-channel transition durations (0.55s / 0.35s / 0.45s in the source).
  final Duration weightDuration;
  final Duration colorDuration;
  final Duration glowDuration;

  /// Null lets press-and-hold drive the state; a value controls it
  /// externally and disables the gesture.
  final bool? engaged;

  /// Reports internal press state changes (ignored when [engaged] controls).
  final ValueChanged<bool>? onEngagedChanged;

  /// False snaps state changes instead of animating them.
  final bool animate;

  @override
  State<VariableWeightText> createState() => _VariableWeightTextState();
}

class _VariableWeightTextState extends State<VariableWeightText>
    with TickerProviderStateMixin {
  static const Curve _glide = Cubic(0.16, 1, 0.3, 1);

  late final AnimationController _weight;
  late final AnimationController _color;
  late final AnimationController _glow;
  late final Animation<double> _weightT;
  late final Animation<double> _colorT;
  late final Animation<double> _glowT;

  bool get _engagedNow => widget.engaged ?? _pressed;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    final double initial = (widget.engaged ?? false) ? 1 : 0;
    _weight = AnimationController(
      vsync: this,
      duration: widget.weightDuration,
      value: initial,
    );
    _color = AnimationController(
      vsync: this,
      duration: widget.colorDuration,
      value: initial,
    );
    _glow = AnimationController(
      vsync: this,
      duration: widget.glowDuration,
      value: initial,
    );
    // CSS restarts the easing on the way back, so the reverse leg plays the
    // flipped curve rather than retracing the forward one.
    _weightT = CurvedAnimation(
      parent: _weight,
      curve: _glide,
      reverseCurve: _glide.flipped,
    );
    _colorT = CurvedAnimation(
      parent: _color,
      curve: Curves.ease,
      reverseCurve: Curves.ease.flipped,
    );
    _glowT = CurvedAnimation(
      parent: _glow,
      curve: Curves.ease,
      reverseCurve: Curves.ease.flipped,
    );
  }

  @override
  void didUpdateWidget(VariableWeightText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _weight.duration = widget.weightDuration;
    _color.duration = widget.colorDuration;
    _glow.duration = widget.glowDuration;
    if (oldWidget.engaged != widget.engaged) {
      _drive(_engagedNow);
    }
  }

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  void _drive(bool engaged) {
    for (final AnimationController controller in <AnimationController>[
      _weight,
      _color,
      _glow,
    ]) {
      if (!_motionEnabled) {
        controller.value = engaged ? 1 : 0;
      } else if (engaged) {
        controller.forward();
      } else {
        controller.reverse();
      }
    }
  }

  void _setPressed(bool value) {
    if (widget.engaged != null || _pressed == value) return;
    _pressed = value;
    _drive(value);
    widget.onEngagedChanged?.call(value);
  }

  @override
  void dispose() {
    _weight.dispose();
    _color.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_weight, _color, _glow]),
          builder: (context, _) {
            final double wght = _lerp(
              widget.idleWeight,
              widget.engagedWeight,
              _weightT.value,
            );
            final double trackingEm = _lerp(
              widget.idleTrackingEm,
              widget.engagedTrackingEm,
              _weightT.value,
            );
            final Color color = Color.lerp(
              widget.idleColor,
              widget.engagedColor,
              _colorT.value,
            )!;
            final double glow = _glowT.value;
            return Text(
              widget.text,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontFamily: widget.fontFamily,
                color: color,
                letterSpacing: trackingEm * widget.fontSize,
                fontVariations: <FontVariation>[FontVariation('wght', wght)],
                // Static-weight fallback for fonts without a wght axis.
                fontWeight: _nearestFontWeight(wght),
                shadows: glow <= 0
                    ? null
                    : <Shadow>[
                        Shadow(
                          color: widget.glowColor.withValues(
                            alpha: widget.glowOpacity * glow,
                          ),
                          blurRadius: widget.glowBlur,
                        ),
                      ],
              ),
            );
          },
        ),
      ),
    );
  }
}

double _lerp(double begin, double end, double amount) =>
    begin + (end - begin) * amount;

FontWeight _nearestFontWeight(double wght) {
  final int index = (wght / 100).round().clamp(1, 9) - 1;
  return FontWeight.values[index];
}
