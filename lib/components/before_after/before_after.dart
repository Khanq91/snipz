/// BeforeAfterSlider
/// Origin: reimplemented — kinetics "Before / After" (Surface & Motion),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/widgets.dart';

/// A drag-to-compare wipe between two stacked layers.
///
/// Faithful to the source mechanics: the split follows the pointer 1:1 with
/// no easing, moves only while pressed (pointer capture, so the drag keeps
/// working outside the box), clamps to 0–100%, and starts at 50%. A 2px
/// divider and a 34px chevron handle track the split.
class BeforeAfterSlider extends StatefulWidget {
  const BeforeAfterSlider({
    super.key,
    this.before,
    this.after,
    this.width = 232,
    this.height = 122,
    this.initialFraction = 0.5,
    this.onChanged,
    this.borderRadius = 9,
    this.borderColor = const Color(0xFF2A2A2E),
    this.dividerColor = const Color(0xFFEDE9E0),
    this.dividerWidth = 2,
    this.handleSize = 34,
    this.handleColor = const Color(0xFFEDE9E0),
    this.handleIconColor = const Color(0xFF0E0E10),
    this.semanticsLabel = 'Compare',
  }) : assert(width > 0),
       assert(height > 0),
       assert(initialFraction >= 0 && initialFraction <= 1),
       assert(dividerWidth >= 0),
       assert(handleSize > 0);

  /// Bottom layer. Null renders the source's `BEFORE` placeholder.
  final Widget? before;

  /// Top layer, revealed left-of-split. Null renders the source's `AFTER`
  /// placeholder.
  final Widget? after;

  /// Box size (232 × 122 in the source).
  final double width;
  final double height;

  /// Starting split, 0–1 (source initializes at 50%).
  final double initialFraction;

  /// Reports the split fraction (0–1) on every drag update.
  final ValueChanged<double>? onChanged;

  final double borderRadius;
  final Color borderColor;
  final Color dividerColor;
  final double dividerWidth;
  final double handleSize;
  final Color handleColor;
  final Color handleIconColor;
  final String semanticsLabel;

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  late double _fraction = widget.initialFraction;

  void _updateFromPosition(Offset localPosition) {
    final double next = (localPosition.dx / widget.width)
        .clamp(0.0, 1.0)
        .toDouble();
    if (next == _fraction) return;
    setState(() => _fraction = next);
    widget.onChanged?.call(next);
  }

  void _nudge(double delta) {
    final double next = (_fraction + delta).clamp(0.0, 1.0).toDouble();
    if (next == _fraction) return;
    setState(() => _fraction = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final double splitX = widget.width * _fraction;

    return Semantics(
      slider: true,
      label: widget.semanticsLabel,
      value: '${(_fraction * 100).round()}%',
      increasedValue: '${((_fraction + 0.1).clamp(0.0, 1.0) * 100).round()}%',
      decreasedValue: '${((_fraction - 0.1).clamp(0.0, 1.0) * 100).round()}%',
      onIncrease: () => _nudge(0.1),
      onDecrease: () => _nudge(-0.1),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // pointerdown seeks immediately, pointermove follows while pressed —
        // exactly the source's dragging flag + setPointerCapture.
        onPanDown: (details) => _updateFromPosition(details.localPosition),
        onPanUpdate: (details) => _updateFromPosition(details.localPosition),
        child: Container(
          width: widget.width,
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: widget.borderColor),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              widget.before ?? const _CompareLayer(before: true),
              // clip-path: inset(0 (100-pct)% 0 0) — reveal left of the split.
              ClipRect(
                clipper: _LeftOfSplitClipper(fraction: _fraction),
                child: widget.after ?? const _CompareLayer(before: false),
              ),
              Positioned(
                left: splitX - widget.dividerWidth / 2,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: widget.dividerWidth,
                    color: widget.dividerColor,
                  ),
                ),
              ),
              Positioned(
                left: splitX - widget.handleSize / 2,
                top: (widget.height - widget.handleSize) / 2,
                child: IgnorePointer(
                  child: Container(
                    width: widget.handleSize,
                    height: widget.handleSize,
                    decoration: BoxDecoration(
                      color: widget.handleColor,
                      shape: BoxShape.circle,
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x80000000),
                          offset: Offset(0, 2),
                          blurRadius: 8,
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: CustomPaint(
                        size: const Size(18, 18),
                        painter: _ChevronsPainter(
                          color: widget.handleIconColor,
                        ),
                      ),
                    ),
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

class _LeftOfSplitClipper extends CustomClipper<Rect> {
  const _LeftOfSplitClipper({required this.fraction});

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftOfSplitClipper oldClipper) =>
      oldClipper.fraction != fraction;
}

/// The source's placeholder layers: 135deg gradients with a bold label.
class _CompareLayer extends StatelessWidget {
  const _CompareLayer({required this.before});

  final bool before;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: before
              ? const <Color>[Color(0xFF141417), Color(0xFF1A1A1D)]
              : const <Color>[Color(0xFFFF8A00), Color(0xFFB36200)],
        ),
      ),
      child: Center(
        child: Text(
          before ? 'BEFORE' : 'AFTER',
          style: TextStyle(
            color: before ? const Color(0xFFA8A6A0) : const Color(0xFF0E0E10),
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: 19 * 0.05,
          ),
        ),
      ),
    );
  }
}

/// The handle's inline SVG: two 2.2-stroke round-capped chevrons in a 24-unit
/// viewBox, rendered at 18px.
class _ChevronsPainter extends CustomPainter {
  const _ChevronsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double unit = size.width / 24;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * unit
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    canvas
      ..drawPath(
        Path()
          ..moveTo(9 * unit, 7 * unit)
          ..lineTo(4 * unit, 12 * unit)
          ..lineTo(9 * unit, 17 * unit),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(15 * unit, 7 * unit)
          ..lineTo(20 * unit, 12 * unit)
          ..lineTo(15 * unit, 17 * unit),
        paint,
      );
  }

  @override
  bool shouldRepaint(_ChevronsPainter oldDelegate) =>
      oldDelegate.color != color;
}
