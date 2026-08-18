/// ElasticSlider
/// Origin: reimplemented — dựng lại "Elastic Slider" của react-bits
/// (motion/react) bằng Flutter thuần: track kéo giãn đàn hồi khi drag quá
/// biên, icon hai đầu bị đẩy theo, spring-back khi thả.
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Elastic range slider: dragging past either end stretches the track
/// (sigmoid-decayed overflow, capped at [maxOverflow] px) and pushes the
/// icon on that side; releasing springs everything back. The whole control
/// grows slightly while touched. Value flows out via [onChanged].
class ElasticSlider extends StatefulWidget {
  const ElasticSlider({
    super.key,
    this.initialValue = 50,
    this.minValue = 0,
    this.maxValue = 100,
    this.isStepped = false,
    this.stepSize = 1,
    this.leftIcon,
    this.rightIcon,
    this.onChanged,
    this.onChangeEnd,
    this.showValueLabel = true,
    this.trackColor = const Color(0xFF9CA3AF),
    this.fillColor = const Color(0xFF6B7280),
    this.iconColor = const Color(0xFF9CA3AF),
    this.labelStyle,
    this.maxOverflow = 50,
  }) : assert(maxValue > minValue, 'maxValue must be > minValue'),
       assert(stepSize > 0, 'stepSize must be > 0');

  /// Start value (original `defaultValue`). The widget owns its state after
  /// that; listen via [onChanged].
  final double initialValue;

  /// Range start (original `startingValue`).
  final double minValue;

  final double maxValue;

  /// Snap [stepSize] increments while dragging.
  final bool isStepped;

  final double stepSize;

  /// Widgets at either end (original defaults are "-" / "+" text).
  final Widget? leftIcon;
  final Widget? rightIcon;

  /// Fired on every value change while dragging.
  final ValueChanged<double>? onChanged;

  /// Fired once on release.
  final ValueChanged<double>? onChangeEnd;

  /// Rounded current value under the track (original always shows it).
  final bool showValueLabel;

  final Color trackColor;
  final Color fillColor;

  /// Default color for the fallback -/+ icons and the value label.
  final Color iconColor;

  /// Style for the value label; merged over a small default.
  final TextStyle? labelStyle;

  /// Max elastic overflow in logical px (original MAX_OVERFLOW = 50).
  final double maxOverflow;

  @override
  State<ElasticSlider> createState() => ElasticSliderState();
}

/// Public so a host can read/set the value via `GlobalKey<ElasticSliderState>`.
class ElasticSliderState extends State<ElasticSlider>
    with TickerProviderStateMixin {
  // Grow-on-touch: 0 -> 1 maps scale 1 -> 1.2, opacity 0.7 -> 1, height 6 -> 12.
  late final AnimationController _grow;
  late final CurvedAnimation _growCurve;

  // Icon pulse [1, 1.4, 1] when the drag first crosses an edge.
  late final AnimationController _pulse;
  late final Animation<double> _pulseScale;

  // Spring-back of the overflow on release (original: spring, bounce 0.5).
  late final AnimationController _spring;

  double _value = 0;
  double _overflow = 0; // decayed px, always >= 0
  int _region = 0; // -1 past left edge, 0 inside, 1 past right edge
  int _pulseSide = 0;
  bool _originRight = true; // stretch anchor: pointer left of center -> right

  double get value => _value;

  set value(double v) {
    setState(() => _value = _snap(v));
  }

  @override
  void initState() {
    super.initState();
    _value = _snap(widget.initialValue);
    _grow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _growCurve = CurvedAnimation(parent: _grow, curve: Curves.easeOut);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _pulseScale = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 1),
    ]).animate(_pulse);
    _spring = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() => _overflow = math.max(0, _spring.value));
      });
  }

  @override
  void dispose() {
    _grow.dispose();
    _growCurve.dispose();
    _pulse.dispose();
    _spring.dispose();
    super.dispose();
  }

  double _snap(double v) {
    double out = v;
    if (widget.isStepped) {
      out = (out / widget.stepSize).roundToDouble() * widget.stepSize;
    }
    return out.clamp(widget.minValue, widget.maxValue);
  }

  /// Sigmoid decay of the raw overshoot (original `decay`): approaches
  /// [max] asymptotically instead of tracking the finger 1:1.
  double _decay(double value, double max) {
    if (max == 0) {
      return 0;
    }
    final double entry = value / max;
    final double sigmoid = 2 * (1 / (1 + math.exp(-entry)) - 0.5);
    return sigmoid * max;
  }

  void _updateFromPointer(Offset local, double width) {
    final double range = widget.maxValue - widget.minValue;
    final double next = _snap(widget.minValue + (local.dx / width) * range);
    if (next != _value) {
      widget.onChanged?.call(next);
    }

    int region;
    double raw;
    if (local.dx < 0) {
      region = -1;
      raw = -local.dx;
    } else if (local.dx > width) {
      region = 1;
      raw = local.dx - width;
    } else {
      region = 0;
      raw = 0;
    }
    if (region != 0 && region != _pulseSide) {
      _pulseSide = region;
      _pulse.forward(from: 0);
    }
    setState(() {
      _value = next;
      _region = region;
      _overflow = _decay(raw, widget.maxOverflow);
      _originRight = local.dx < width / 2;
    });
  }

  void _onPointerDown(Offset local, double width) {
    _spring.stop();
    _grow.forward();
    _updateFromPointer(local, width);
  }

  void _onPointerUp() {
    _grow.reverse();
    _pulseSide = 0;
    // Underdamped spring (ζ ≈ 0.5) ~ the original's bounce: 0.5.
    _spring.value = _overflow;
    _spring.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 200, damping: 14),
        _overflow,
        0,
        0,
      ),
    );
    widget.onChangeEnd?.call(_value);
  }

  double get _fillFraction {
    final double range = widget.maxValue - widget.minValue;
    return range == 0 ? 0 : (_value - widget.minValue) / range;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle = TextStyle(
      color: widget.iconColor,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ).merge(widget.labelStyle);
    final Widget leftIcon =
        widget.leftIcon ?? Text('−', style: TextStyle(color: widget.iconColor));
    final Widget rightIcon =
        widget.rightIcon ??
        Text('+', style: TextStyle(color: widget.iconColor));

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_growCurve, _pulse]),
      builder: (context, _) {
        final double t = _growCurve.value;
        final double rowScale = 1 + 0.2 * t; // 1 -> 1.2
        final double trackHeight = 6 + 6 * t; // 6 -> 12
        final double opacity = 0.7 + 0.3 * t;

        Widget icon(int side, Widget child) {
          final double shift = _region == side ? side * _overflow / rowScale : 0;
          final double pulse = _pulseSide == side ? _pulseScale.value : 1.0;
          return Transform.translate(
            offset: Offset(shift, 0),
            child: Transform.scale(scale: pulse, child: child),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Transform.scale(
              scale: rowScale,
              child: Opacity(
                opacity: opacity,
                child: Row(
                  children: <Widget>[
                    icon(-1, leftIcon),
                    const SizedBox(width: 16),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double width = constraints.maxWidth;
                          return Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (e) =>
                                _onPointerDown(e.localPosition, width),
                            onPointerMove: (e) =>
                                _updateFromPointer(e.localPosition, width),
                            onPointerUp: (_) => _onPointerUp(),
                            onPointerCancel: (_) => _onPointerUp(),
                            child: SizedBox(
                              height: 44, // touch area (original py-4)
                              child: Center(
                                child: Transform(
                                  alignment: _originRight
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  transform: Matrix4.diagonal3Values(
                                    width == 0 ? 1 : 1 + _overflow / width,
                                    1 -
                                        0.2 *
                                            (_overflow / widget.maxOverflow)
                                                .clamp(0, 1),
                                    1,
                                  ),
                                  child: SizedBox(
                                    height: trackHeight,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: ColoredBox(
                                        color: widget.trackColor,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: FractionallySizedBox(
                                            widthFactor: _fillFraction,
                                            heightFactor: 1,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: widget.fillColor,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    icon(1, rightIcon),
                  ],
                ),
              ),
            ),
            if (widget.showValueLabel) ...<Widget>[
              const SizedBox(height: 4),
              Text('${_value.round()}', style: labelStyle),
            ],
          ],
        );
      },
    );
  }
}
