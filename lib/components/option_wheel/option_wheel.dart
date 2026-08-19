/// OptionWheel
/// Origin: adapted — port "OptionWheel" của react-bits, giữ nguyên toán layout
/// vòng cung + exponential smoothing
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Which edge the wheel hugs (text anchors to that edge and curls toward it).
enum OptionWheelSide { left, right }

/// Vertical option picker where the entries sit on a circular arc: drag (or
/// tap an entry, or scroll on desktop) to spin; the wheel eases toward its
/// target with frame-rate-independent exponential smoothing and snaps to the
/// nearest entry on release.
///
/// The arc radius keeps the arc length between neighbors equal to one row
/// height, so [tilt] controls how tightly the list curls; [curve] scales how
/// deep entries retreat toward the anchored edge.
class OptionWheel extends StatefulWidget {
  const OptionWheel({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.onChanged,
    this.onTick,
    this.textColor = const Color(0xFFA6A6A6),
    this.activeColor = const Color(0xFFFFFFFF),
    this.side = OptionWheelSide.left,
    this.fontSize = 48,
    this.spacing = 1.4,
    this.curve = 1,
    this.tilt = 6,
    this.blur = 2,
    this.fade = 0.25,
    this.minOpacity = 0.05,
    this.smoothing = const Duration(milliseconds: 200),
    this.inset = 80,
    this.loop = false,
    this.draggable = true,
    this.textStyle,
  }) : assert(items.length > 0, 'items must not be empty');

  final List<String> items;
  final int initialIndex;
  final void Function(int index, String item)? onChanged;

  /// Fires on every selection change, throttled to 70 ms — hook haptics or a
  /// click sound here (the web original played an `Audio` tick).
  final VoidCallback? onTick;

  final Color textColor;
  final Color activeColor;
  final OptionWheelSide side;
  final double fontSize;

  /// Row height = [fontSize] × [spacing].
  final double spacing;

  /// Depth multiplier of the horizontal curl (0 = straight column).
  final double curve;

  /// Degrees between neighboring entries on the arc.
  final double tilt;

  /// Blur sigma per row of distance from the selection (0 = off; blur costs a
  /// saveLayer per visible entry).
  final double blur;

  /// Opacity lost per row of distance.
  final double fade;

  final double minOpacity;

  /// Time constant of the easing toward the target.
  final Duration smoothing;

  /// Distance from the anchored edge to the resting text position.
  final double inset;

  final bool loop;
  final bool draggable;

  /// Base style; color/weight/size are still driven by the wheel.
  final TextStyle? textStyle;

  @override
  State<OptionWheel> createState() => OptionWheelState();
}

class OptionWheelState extends State<OptionWheel>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late double _pos = widget.initialIndex.toDouble();
  late double _target = widget.initialIndex.toDouble();
  late int _selected = widget.initialIndex;
  Duration _lastElapsed = Duration.zero;
  double? _dragStartTarget;
  double _dragStartY = 0;
  DateTime _lastTickAt = DateTime.fromMillisecondsSinceEpoch(0);

  double get _rowH => math.max(widget.fontSize * widget.spacing, 1);

  int get _count => widget.items.length;

  /// Currently selected index.
  int get selected => _selected;

  /// Spin to [index] (shortest way around when [OptionWheel.loop]).
  void select(int index) {
    final int n = _count;
    double d = index - (((_target % n) + n) % n);
    if (widget.loop && n > 1) {
      if (d > n / 2) {
        d -= n;
      } else if (d < -n / 2) {
        d += n;
      }
    }
    _applyTarget(_target + d, snap: true);
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onFrame);
  }

  void _onFrame(Duration elapsed) {
    final double dt = _lastElapsed == Duration.zero
        ? 1 / 60
        : math.min((elapsed - _lastElapsed).inMicroseconds / 1e6, 0.05);
    _lastElapsed = elapsed;
    final double tau =
        math.max(widget.smoothing.inMilliseconds, 1).toDouble() / 1000;
    final double k = 1 - math.exp(-dt / tau);
    double next = _pos + (_target - _pos) * k;
    final bool settled = (_target - next).abs() < 0.001;
    if (settled) {
      next = _target;
      _ticker.stop();
      _lastElapsed = Duration.zero;
    }
    setState(() => _pos = next);
  }

  void _wake() {
    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  void _applyTarget(double value, {required bool snap}) {
    double v = value;
    if (!widget.loop) {
      v = v.clamp(0.0, math.max(_count - 1, 0).toDouble());
    }
    if (snap) {
      v = v.roundToDouble();
    }
    _target = v;
    final int idx = ((v.round() % _count) + _count) % _count;
    if (idx != _selected) {
      _selected = idx;
      widget.onChanged?.call(idx, widget.items[idx]);
      final DateTime now = DateTime.now();
      if (now.difference(_lastTickAt).inMilliseconds >= 70) {
        _lastTickAt = now;
        widget.onTick?.call();
      }
    }
    _wake();
  }

  void _onDragStart(DragStartDetails d) {
    if (!widget.draggable) {
      return;
    }
    _dragStartTarget = _target;
    _dragStartY = d.localPosition.dy;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final double? start = _dragStartTarget;
    if (start == null) {
      return;
    }
    final double dy = d.localPosition.dy - _dragStartY;
    _applyTarget(start - dy / _rowH, snap: false);
  }

  void _onDragEnd() {
    if (_dragStartTarget == null) {
      return;
    }
    _dragStartTarget = null;
    _applyTarget(_target, snap: true);
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }
    final double step = (event.scrollDelta.dy / _rowH).clamp(-1.0, 1.0);
    _applyTarget(_target + step, snap: true);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool right = widget.side == OptionWheelSide.right;
    final double mirror = right ? -1 : 1;
    final double tiltRad = widget.tilt * math.pi / 180;
    final double radius = tiltRad > 0.0005 ? _rowH / tiltRad : 0;

    return Listener(
      onPointerSignal: _onPointerSignal,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: _onDragStart,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: (_) => _onDragEnd(),
        onVerticalDragCancel: _onDragEnd,
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double centerY = constraints.maxHeight / 2;
              final List<Widget> children = <Widget>[];
              for (int i = 0; i < _count; i++) {
                double d = i - _pos;
                if (widget.loop && _count > 1) {
                  d = ((d % _count) + _count) % _count;
                  if (d > _count / 2) {
                    d -= _count;
                  }
                }
                final double dist = d.abs();
                double x = 0;
                double y = d * _rowH;
                double rot = 0;
                if (radius > 0) {
                  final double ang =
                      (d * tiltRad).clamp(-math.pi / 2, math.pi / 2);
                  y = radius * math.sin(ang);
                  x = -mirror * radius * (1 - math.cos(ang)) * widget.curve;
                  rot = mirror * ang;
                }
                final double opacity = math
                    .max(widget.minOpacity, 1 - dist * widget.fade)
                    .clamp(0.0, 1.0);
                // Skip entries eased fully out — no layout, no saveLayer.
                if (opacity <= widget.minOpacity &&
                    dist * _rowH > constraints.maxHeight) {
                  continue;
                }
                children.add(
                  _buildItem(
                    index: i,
                    x: x,
                    top: centerY + y - widget.fontSize / 2,
                    rot: rot,
                    dist: dist,
                    opacity: opacity,
                    right: right,
                  ),
                );
              }
              return Stack(clipBehavior: Clip.none, children: children);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    required int index,
    required double x,
    required double top,
    required double rot,
    required double dist,
    required double opacity,
    required bool right,
  }) {
    final double p = math.max(0, 1 - math.min(dist, 1)).toDouble();
    final bool isSelected = index == _selected;
    final TextStyle base = widget.textStyle ?? const TextStyle();
    Widget item = Text(
      widget.items[index],
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      style: base.copyWith(
        fontSize: widget.fontSize,
        height: 1,
        color: Color.lerp(widget.textColor, widget.activeColor, p),
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.w200,
      ),
    );
    final double sigma = dist * widget.blur;
    if (sigma > 0.05) {
      item = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.decal,
        ),
        child: item,
      );
    }
    item = Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: rot,
        alignment: right ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => select(index),
          child: item,
        ),
      ),
    );
    return Positioned(
      top: top,
      left: right ? null : widget.inset + x,
      right: right ? widget.inset - x : null,
      height: widget.fontSize,
      child: item,
    );
  }
}
