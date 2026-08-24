/// LatticeSnap
/// Origin: reimplemented — kinetics "Lattice Snap" (Interaction & Input),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:ui' as ui show PathMetric;

import 'package:flutter/widgets.dart';

/// Magnetic 3×2 lattice: while dragging, the amber tile tracks the pointer
/// with a short 80ms trail and the cell under it lights up; on release it
/// springs onto that cell. The grid itself never reflows.
class LatticeSnap extends StatefulWidget {
  const LatticeSnap({
    super.key,
    this.columns = 3,
    this.rows = 2,
    this.width = 200,
    this.height = 118,
    this.gap = 8,
    this.initialColumn = 0,
    this.initialRow = 0,
    this.cellBorderColor = const Color(0xFF34322F),
    this.cellColor = const Color(0x8C232326),
    this.tileColor = const Color(0xFFFF8A00),
    this.onSnapped,
    this.animate = true,
  }) : assert(columns > 0 && rows > 0);

  final int columns;
  final int rows;
  final double width;
  final double height;
  final double gap;
  final int initialColumn;
  final int initialRow;

  /// Dashed rest-cell border (line mixed toward bone-faint).
  final Color cellBorderColor;

  /// card-2 at 55% like the original color-mix.
  final Color cellColor;

  /// Center of the tile's radial gradient; hot cells derive from it too.
  final Color tileColor;

  /// Fired when the tile lands on a cell: (column, row).
  final void Function(int column, int row)? onSnapped;

  /// False applies snaps immediately.
  final bool animate;

  @override
  State<LatticeSnap> createState() => _LatticeSnapState();
}

class _LatticeSnapState extends State<LatticeSnap> {
  static const Curve _spring = Cubic(0.34, 1.56, 0.64, 1);

  late int _col = widget.initialColumn.clamp(0, widget.columns - 1);
  late int _row = widget.initialRow.clamp(0, widget.rows - 1);
  bool _dragging = false;
  Offset _dragTopLeft = Offset.zero;
  int? _hotCell;

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  double get _cellWidth =>
      (widget.width - (widget.columns - 1) * widget.gap) / widget.columns;
  double get _cellHeight =>
      (widget.height - (widget.rows - 1) * widget.gap) / widget.rows;

  Offset _cellOrigin(int c, int r) => Offset(
    c * (_cellWidth + widget.gap),
    r * (_cellHeight + widget.gap),
  );

  (int, int) _cellAt(Offset p) => (
    ((p.dx / widget.width) * widget.columns)
        .floor()
        .clamp(0, widget.columns - 1),
    ((p.dy / widget.height) * widget.rows).floor().clamp(0, widget.rows - 1),
  );

  Rect get _tileRect => Rect.fromLTWH(
    _dragging ? _dragTopLeft.dx : _cellOrigin(_col, _row).dx,
    _dragging ? _dragTopLeft.dy : _cellOrigin(_col, _row).dy,
    _cellWidth,
    _cellHeight,
  );

  void _down(Offset local) {
    if (!_tileRect.contains(local)) return;
    setState(() => _dragging = true);
    _follow(local);
  }

  void _follow(Offset local) {
    if (!_dragging) return;
    final double x = (local.dx - _cellWidth / 2).clamp(
      0.0,
      widget.width - _cellWidth,
    );
    final double y = (local.dy - _cellHeight / 2).clamp(
      0.0,
      widget.height - _cellHeight,
    );
    final (int c, int r) = _cellAt(local);
    setState(() {
      _dragTopLeft = Offset(x, y);
      _hotCell = r * widget.columns + c;
    });
  }

  void _release(Offset local) {
    if (!_dragging) return;
    final (int c, int r) = _cellAt(local);
    setState(() {
      _dragging = false;
      _hotCell = null;
      _col = c;
      _row = r;
    });
    widget.onSnapped?.call(c, r);
  }

  @override
  Widget build(BuildContext context) {
    final Duration snapDuration = !_motionEnabled
        ? Duration.zero
        : _dragging
        ? const Duration(milliseconds: 80)
        : const Duration(milliseconds: 500);
    final Rect tile = _tileRect;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => _down(e.localPosition),
      onPointerMove: (e) => _follow(e.localPosition),
      onPointerUp: (e) => _release(e.localPosition),
      onPointerCancel: (e) => _release(e.localPosition),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            for (int r = 0; r < widget.rows; r++)
              for (int c = 0; c < widget.columns; c++) _cell(c, r),
            AnimatedPositioned(
              duration: snapDuration,
              curve: _spring,
              left: tile.left,
              top: tile.top,
              width: _cellWidth,
              height: _cellHeight,
              child: AnimatedScale(
                scale: _dragging ? 1.06 : 1,
                duration: _motionEnabled
                    ? const Duration(milliseconds: 300)
                    : Duration.zero,
                curve: _spring,
                child: Semantics(
                  label: 'Drag tile onto a cell',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: RadialGradient(
                        center: const Alignment(-0.4, -0.6),
                        radius: 1.2,
                        colors: <Color>[
                          const Color(0xFFFFD08A),
                          widget.tileColor,
                          const Color(0xFFB36200),
                        ],
                        stops: const <double>[0, 0.46, 1],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, _dragging ? 0.45 : 0.35),
                          offset: Offset(0, _dragging ? 14 : 8),
                          blurRadius: _dragging ? 28 : 18,
                        ),
                        if (_dragging)
                          BoxShadow(
                            color: widget.tileColor.withValues(alpha: 0.18),
                            spreadRadius: 4,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(int c, int r) {
    final bool hot = _hotCell == r * widget.columns + c;
    final Offset origin = _cellOrigin(c, r);
    return Positioned(
      left: origin.dx,
      top: origin.dy,
      width: _cellWidth,
      height: _cellHeight,
      child: AnimatedContainer(
        duration: _motionEnabled
            ? const Duration(milliseconds: 250)
            : Duration.zero,
        curve: Curves.ease,
        decoration: BoxDecoration(
          color: hot
              ? widget.tileColor.withValues(alpha: 0.08)
              : widget.cellColor,
          borderRadius: BorderRadius.circular(10),
          border: hot
              ? Border.all(color: widget.tileColor.withValues(alpha: 0.55))
              : null,
        ),
        child: hot
            ? null
            : CustomPaint(
                painter: _DashedBorderPainter(widget.cellBorderColor),
              ),
      ),
    );
  }
}

/// 1px dashed rounded border of the resting cells.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path border = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.5),
          const Radius.circular(10),
        ),
      );
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    const double dash = 4;
    for (final ui.PathMetric metric in border.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          paint,
        );
        distance += dash * 2;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
