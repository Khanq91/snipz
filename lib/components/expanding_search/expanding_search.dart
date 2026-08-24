/// ExpandingSearch
/// Origin: reimplemented — kinetics "Expanding Search" (Interaction & Input),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/material.dart';

/// Pill-shaped search field that sits collapsed at just its icon and glides
/// open when the field gains focus (only the width animates; the icon stays
/// pinned left, the input is clipped while collapsed). Tapping anywhere on
/// the pill focuses the field; losing focus collapses it.
class ExpandingSearch extends StatefulWidget {
  const ExpandingSearch({
    super.key,
    this.collapsedWidth = 56,
    this.expandedWidth = 230,
    this.hintText = 'Search…',
    this.expanded,
    this.textController,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.backgroundColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.focusBorderColor = const Color(0xFFFF8A00),
    this.iconColor = const Color(0xFFA8A6A0),
    this.textColor = const Color(0xFFEDE9E0),
    this.hintColor = const Color(0xFF6E6C68),
    this.animate = true,
  }) : assert(expandedWidth >= collapsedWidth);

  final double collapsedWidth;
  final double expandedWidth;
  final String hintText;

  /// Null (default): expansion follows focus. Non-null pins the state —
  /// mainly for previews and state boards.
  final bool? expanded;
  final TextEditingController? textController;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Color backgroundColor;
  final Color borderColor;
  final Color focusBorderColor;
  final Color iconColor;
  final Color textColor;
  final Color hintColor;

  /// False applies state changes immediately.
  final bool animate;

  @override
  State<ExpandingSearch> createState() => _ExpandingSearchState();
}

class _ExpandingSearchState extends State<ExpandingSearch> {
  // --glide of the original design system.
  static const Curve _glide = Cubic(0.16, 1, 0.3, 1);

  FocusNode? _internalNode;

  FocusNode get _node => widget.focusNode ?? (_internalNode ??= FocusNode());

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(ExpandingSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalNode)?.removeListener(_onFocusChanged);
      _node.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocusChanged);
    _internalNode?.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final bool focused = _node.hasFocus;
    final bool expanded = widget.expanded ?? focused;
    final Duration widthDuration = _motionEnabled
        ? const Duration(milliseconds: 400)
        : Duration.zero;
    final Duration borderDuration = _motionEnabled
        ? const Duration(milliseconds: 300)
        : Duration.zero;
    // Border 1px each side + horizontal padding 14 each side.
    final double contentWidth = widget.expandedWidth - 30;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _node.requestFocus,
      // Outer container glides the width, inner one fades the border color —
      // the original's two independent transitions.
      child: AnimatedContainer(
        duration: widthDuration,
        curve: _glide,
        width: expanded ? widget.expandedWidth : widget.collapsedWidth,
        child: AnimatedContainer(
          duration: borderDuration,
          curve: Curves.ease,
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: Border.all(
              color: focused ? widget.focusBorderColor : widget.borderColor,
            ),
            borderRadius: BorderRadius.circular(100),
          ),
          // The row keeps its expanded layout at all times; the pill just
          // clips it while collapsed (the original's overflow: hidden).
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: contentWidth,
            maxWidth: contentWidth,
            child: Row(
              children: <Widget>[
                CustomPaint(
                  size: const Size.square(18),
                  painter: _SearchGlyphPainter(widget.iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: widget.textController,
                    focusNode: _node,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    textInputAction: TextInputAction.search,
                    cursorColor: widget.focusBorderColor,
                    style: TextStyle(fontSize: 14, color: widget.textColor),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: widget.hintColor,
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
}

/// The 24-viewBox search glyph (circle r7 at 11,11 + handle 21,21→16.5,16.5).
class _SearchGlyphPainter extends CustomPainter {
  const _SearchGlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(const Offset(11, 11), 7, paint);
    canvas.drawLine(const Offset(21, 21), const Offset(16.5, 16.5), paint);
  }

  @override
  bool shouldRepaint(_SearchGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}
