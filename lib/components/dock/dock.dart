/// Dock
/// Origin: reimplemented — dựng lại "Dock" của react-bits (motion/react
/// springs) bằng Ticker + tích phân lò xo thuần
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// One dock entry: an icon widget, a tooltip label and a tap callback.
class DockItemData {
  const DockItemData({required this.icon, required this.label, this.onPressed});

  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
}

/// macOS-style magnifying dock. Items swell toward [magnification] while the
/// finger is down, following the touch point (the web original follows mouse
/// hover); sizes settle through a spring (mass 0.1, stiffness 150, damping 12
/// — the original's constants). The pressed item shows its label above the
/// bar. Releasing over an item fires its [DockItemData.onPressed].
class Dock extends StatefulWidget {
  const Dock({
    super.key,
    required this.items,
    this.distance = 200,
    this.baseItemSize = 50,
    this.magnification = 70,
    this.panelHeight = 64,
    this.itemGap = 16,
    this.stiffness = 150,
    this.damping = 12,
    this.mass = 0.1,
    this.backgroundColor = Colors.transparent,
    this.itemColor = const Color(0xFF120F17),
    this.borderColor = const Color(0xFF404040),
    this.labelStyle,
  });

  final List<DockItemData> items;

  /// Influence radius of the touch point, logical px.
  final double distance;

  /// Resting item diameter.
  final double baseItemSize;

  /// Item diameter right under the touch point.
  final double magnification;

  /// Height of the bar the items rest in.
  final double panelHeight;

  /// Horizontal gap between items.
  final double itemGap;

  // Spring constants (motion/react `SpringOptions` of the original).
  final double stiffness;
  final double damping;
  final double mass;

  final Color backgroundColor;
  final Color itemColor;
  final Color borderColor;
  final TextStyle? labelStyle;

  @override
  State<Dock> createState() => _DockState();
}

class _DockState extends State<Dock> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late List<double> _sizes;
  late List<double> _velocities;
  Duration _lastTick = Duration.zero;

  /// Touch x relative to the panel's content row; null = no finger down.
  double? _pointerX;
  int _hoveredIndex = -1;

  static const double _panelPaddingX = 16;
  static const double _panelBottomPadding = 8;

  @override
  void initState() {
    super.initState();
    _sizes = List<double>.filled(widget.items.length, widget.baseItemSize);
    _velocities = List<double>.filled(widget.items.length, 0);
    _ticker = createTicker(_onTick);
  }

  @override
  void didUpdateWidget(Dock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != _sizes.length) {
      _sizes = List<double>.filled(widget.items.length, widget.baseItemSize);
      _velocities = List<double>.filled(widget.items.length, 0);
    }
  }

  double _targetSize(int index) {
    final double? px = _pointerX;
    if (px == null) {
      return widget.baseItemSize;
    }
    // Center of item [index] from the current (animated) sizes, so magnified
    // neighbors push centers apart exactly like the DOM layout does.
    double x = 0;
    for (int i = 0; i < index; i++) {
      x += _sizes[i] + widget.itemGap;
    }
    final double center = x + _sizes[index] / 2;
    final double d = (px - center).abs();
    if (d >= widget.distance) {
      return widget.baseItemSize;
    }
    final double t = 1 - d / widget.distance;
    return widget.baseItemSize +
        (widget.magnification - widget.baseItemSize) * t;
  }

  void _onTick(Duration elapsed) {
    double dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    dt = dt.clamp(0.0, 1 / 30);

    bool settled = true;
    for (int i = 0; i < _sizes.length; i++) {
      final double target = _targetSize(i);
      final double accel = (widget.stiffness * (target - _sizes[i]) -
              widget.damping * _velocities[i]) /
          widget.mass;
      _velocities[i] += accel * dt;
      _sizes[i] += _velocities[i] * dt;
      if ((target - _sizes[i]).abs() > 0.1 || _velocities[i].abs() > 0.1) {
        settled = false;
      } else {
        _sizes[i] = target;
        _velocities[i] = 0;
      }
    }
    setState(() {});
    if (settled && _pointerX == null) {
      _ticker.stop();
    }
  }

  void _wake() {
    if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  int _indexAt(double px) {
    double x = 0;
    for (int i = 0; i < _sizes.length; i++) {
      final double end = x + _sizes[i];
      if (px >= x - widget.itemGap / 2 && px <= end + widget.itemGap / 2) {
        return i;
      }
      x = end + widget.itemGap;
    }
    return -1;
  }

  void _updatePointer(Offset localToRow) {
    _pointerX = localToRow.dx;
    _hoveredIndex = _indexAt(localToRow.dx);
    _wake();
  }

  void _clearPointer({bool fire = false}) {
    if (fire && _hoveredIndex >= 0 && _hoveredIndex < widget.items.length) {
      widget.items[_hoveredIndex].onPressed?.call();
    }
    _pointerX = null;
    _hoveredIndex = -1;
    _wake();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double labelSpace = 36;
    final double height = widget.magnification + labelSpace;
    final TextStyle labelStyle = widget.labelStyle ??
        const TextStyle(color: Colors.white, fontSize: 12);

    // Label anchor: center x of the hovered item within the row.
    double labelCenter = 0;
    if (_hoveredIndex >= 0) {
      double x = 0;
      for (int i = 0; i < _hoveredIndex; i++) {
        x += _sizes[i] + widget.itemGap;
      }
      labelCenter = x + _sizes[_hoveredIndex] / 2;
    }

    return SizedBox(
      height: height,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => _updatePointer(_toRow(d.localPosition)),
          onPanUpdate: (d) => _updatePointer(_toRow(d.localPosition)),
          onPanEnd: (_) => _clearPointer(fire: true),
          onPanCancel: _clearPointer,
          child: Container(
            height: widget.panelHeight,
            padding: const EdgeInsets.symmetric(horizontal: _panelPaddingX),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.borderColor, width: 2),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    for (int i = 0; i < widget.items.length; i++) ...<Widget>[
                      if (i > 0) SizedBox(width: widget.itemGap),
                      _buildItem(i),
                    ],
                  ],
                ),
                if (_hoveredIndex >= 0)
                  Positioned(
                    left: labelCenter - 60,
                    width: 120,
                    bottom: widget.magnification + 12,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.itemColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: widget.borderColor),
                          ),
                          child: Text(
                            widget.items[_hoveredIndex].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: labelStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Gesture coordinates (panel-local) -> row-local x/y.
  Offset _toRow(Offset local) =>
      local - const Offset(_panelPaddingX, 0);

  Widget _buildItem(int i) {
    final double size = _sizes[i].clamp(1.0, double.infinity);
    return SizedBox(
      width: size,
      height: widget.panelHeight - _panelBottomPadding,
      child: OverflowBox(
        maxWidth: size,
        maxHeight: double.infinity,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: widget.items[i].onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: widget.itemColor,
              shape: BoxShape.circle,
              border: Border.all(color: widget.borderColor, width: 2),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: widget.items[i].icon),
          ),
        ),
      ),
    );
  }
}
