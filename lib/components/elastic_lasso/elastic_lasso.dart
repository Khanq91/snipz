/// ElasticLasso
/// Origin: reimplemented — kinetics "Elastic Lasso" (Interaction & Input),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/widgets.dart';

/// Miniature drag-to-select surface: dragging stretches a translucent amber
/// lasso rectangle from its origin; dots inside it spring larger and turn
/// amber. The selection is live during the drag and stays after release; the
/// next drag re-evaluates it.
class ElasticLasso extends StatefulWidget {
  const ElasticLasso({
    super.key,
    this.width = 210,
    this.height = 112,
    this.dotPositions = const <Offset>[
      Offset(22, 24),
      Offset(78, 65),
      Offset(132, 29),
      Offset(174, 73),
      Offset(45, 83),
    ],
    this.initialSelection = const <int>{},
    this.borderColor = const Color(0xFF2A2A2E),
    this.dotColor = const Color(0xFF6E6C68),
    this.selectedColor = const Color(0xFFFF8A00),
    this.onSelectionChanged,
    this.animate = true,
  });

  final double width;
  final double height;

  /// Top-left corners of the 12px dots, like the original's absolute layout.
  final List<Offset> dotPositions;
  final Set<int> initialSelection;
  final Color borderColor;
  final Color dotColor;

  /// Lasso border + selected dots; the fill is this at 10% alpha.
  final Color selectedColor;
  final ValueChanged<Set<int>>? onSelectionChanged;

  /// False applies selection changes immediately.
  final bool animate;

  @override
  State<ElasticLasso> createState() => _ElasticLassoState();
}

class _ElasticLassoState extends State<ElasticLasso> {
  static const Curve _spring = Cubic(0.34, 1.56, 0.64, 1);
  static const double _dotSize = 12;

  Offset? _start;
  Offset? _current;
  late Set<int> _selected = Set<int>.of(widget.initialSelection);

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  Offset _clamp(Offset p) => Offset(
    p.dx.clamp(0, widget.width),
    p.dy.clamp(0, widget.height),
  );

  void _drag(Offset local) {
    final Offset point = _clamp(local);
    _current = point;
    final Rect box = Rect.fromPoints(_start!, point);
    // A dot counts when its center lies inside the rectangle — the
    // original's offsetLeft + 6 test.
    final Set<int> next = <int>{
      for (int i = 0; i < widget.dotPositions.length; i++)
        if (box.contains(widget.dotPositions[i] + const Offset(6, 6))) i,
    };
    final bool changed = !_setEquals(next, _selected);
    _selected = next;
    setState(() {});
    if (changed) widget.onSelectionChanged?.call(Set<int>.of(next));
  }

  void _end() {
    if (_start == null) return;
    setState(() {
      _start = null;
      _current = null;
    });
  }

  static bool _setEquals(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  Widget build(BuildContext context) {
    final Duration springDuration = _motionEnabled
        ? const Duration(milliseconds: 300)
        : Duration.zero;
    final Rect? box = _start == null
        ? null
        : Rect.fromPoints(_start!, _current ?? _start!);

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        _start = _clamp(e.localPosition);
        _drag(e.localPosition);
      },
      onPointerMove: (e) {
        if (_start != null) _drag(e.localPosition);
      },
      onPointerUp: (_) => _end(),
      onPointerCancel: (_) => _end(),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          border: Border.all(color: widget.borderColor),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            for (int i = 0; i < widget.dotPositions.length; i++)
              Positioned(
                left: widget.dotPositions[i].dx,
                top: widget.dotPositions[i].dy,
                child: AnimatedScale(
                  scale: _selected.contains(i) ? 1.45 : 1,
                  duration: springDuration,
                  curve: _spring,
                  child: AnimatedContainer(
                    duration: springDuration,
                    curve: _spring,
                    width: _dotSize,
                    height: _dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selected.contains(i)
                          ? widget.selectedColor
                          : widget.dotColor,
                    ),
                  ),
                ),
              ),
            if (box != null)
              Positioned(
                left: box.left,
                top: box.top,
                width: box.width,
                height: box.height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.selectedColor.withValues(alpha: 0.1),
                    border: Border.all(color: widget.selectedColor),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
