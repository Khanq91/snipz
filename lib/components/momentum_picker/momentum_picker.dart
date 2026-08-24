/// MomentumPicker
/// Origin: reimplemented — kinetics "Momentum Picker" (Interaction & Input),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/widgets.dart';

/// Tactile vertical picker: options roll behind a fixed amber highlight one
/// detent at a time with a weighted overshoot; peripheral rows dim and
/// shrink to imply cylindrical depth. Web wheel input maps to touch — a
/// vertical swipe steps detents (one per row-height of travel) and taps
/// select directly. Controlled: the parent owns [index].
class MomentumPicker extends StatefulWidget {
  const MomentumPicker({
    super.key,
    this.options = const <String>['Airy', 'Balanced', 'Dense'],
    required this.index,
    required this.onChanged,
    this.width = 208,
    this.height = 122,
    this.backgroundColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.textColor = const Color(0xFFEDE9E0),
    this.accentColor = const Color(0xFFFF8A00),
    this.readoutColor = const Color(0xFF6E6C68),
    this.animate = true,
  }) : assert(options.length > 0),
       assert(index >= 0 && index < options.length);

  final List<String> options;
  final int index;
  final ValueChanged<int>? onChanged;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  /// Focus pill (8% fill, 46% border) and the active label.
  final Color accentColor;
  final Color readoutColor;

  /// False applies state changes immediately.
  final bool animate;

  @override
  State<MomentumPicker> createState() => _MomentumPickerState();
}

class _MomentumPickerState extends State<MomentumPicker> {
  static const Curve _spring = Cubic(0.34, 1.56, 0.64, 1);
  // Original geometry: 38px rows, focus band 37px from the top.
  static const double _row = 38;
  static const double _focusTop = 37;

  double _dragAccum = 0;

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  void _select(int next) {
    final int clamped = next.clamp(0, widget.options.length - 1);
    if (clamped != widget.index) widget.onChanged?.call(clamped);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (widget.onChanged == null) return;
    _dragAccum -= details.delta.dy;
    // One detent per row-height of travel — the swipe analogue of the
    // original's one-step-per-wheel-burst lock.
    while (_dragAccum >= _row) {
      _dragAccum -= _row;
      _select(widget.index + 1);
    }
    while (_dragAccum <= -_row) {
      _dragAccum += _row;
      _select(widget.index - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Duration rollDuration = _motionEnabled
        ? const Duration(milliseconds: 580)
        : Duration.zero;
    final Duration scaleDuration = _motionEnabled
        ? const Duration(milliseconds: 500)
        : Duration.zero;
    final Duration fadeDuration = _motionEnabled
        ? const Duration(milliseconds: 350)
        : Duration.zero;
    final Duration colorDuration = _motionEnabled
        ? const Duration(milliseconds: 250)
        : Duration.zero;
    final String readout =
        '${widget.options[widget.index].toUpperCase()} · '
        '0${widget.index + 1}';

    return Semantics(
      label: 'Picker: ${widget.options[widget.index]}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: (_) => _dragAccum = 0,
        onVerticalDragCancel: () => _dragAccum = 0,
        child: Container(
          width: widget.width,
          height: widget.height,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: Border.all(color: widget.borderColor),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            children: <Widget>[
              // Fixed focus band behind the rolling track.
              Positioned(
                top: _focusTop,
                left: 10,
                right: 10,
                height: _row,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.08),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.46),
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: rollDuration,
                curve: _spring,
                top: _focusTop - widget.index * _row,
                left: 10,
                right: 10,
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < widget.options.length; i++)
                      _rowItem(
                        i,
                        scaleDuration: scaleDuration,
                        fadeDuration: fadeDuration,
                        colorDuration: colorDuration,
                      ),
                  ],
                ),
              ),
              _fade(top: true),
              _fade(top: false),
              Positioned(
                right: 10,
                bottom: 5,
                child: Text(
                  readout,
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 0.4,
                    color: widget.readoutColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowItem(
    int i, {
    required Duration scaleDuration,
    required Duration fadeDuration,
    required Duration colorDuration,
  }) {
    final bool active = i == widget.index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onChanged == null ? null : () => _select(i),
      child: SizedBox(
        height: _row,
        child: Center(
          child: AnimatedOpacity(
            opacity: active ? 1 : 0.28,
            duration: fadeDuration,
            curve: Curves.ease,
            child: AnimatedScale(
              scale: active ? 1 : 0.88,
              duration: scaleDuration,
              curve: _spring,
              child: AnimatedDefaultTextStyle(
                duration: colorDuration,
                curve: Curves.ease,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? widget.accentColor : widget.textColor,
                ),
                child: Text(widget.options[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 35px card-colored fades implying the cylinder's poles.
  Widget _fade({required bool top}) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      height: 35,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: top ? Alignment.topCenter : Alignment.bottomCenter,
              end: top ? Alignment.bottomCenter : Alignment.topCenter,
              colors: <Color>[
                widget.backgroundColor,
                widget.backgroundColor.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
