/// StarBorderGlow
/// Origin: adapted — ported from react-bits "StarBorder" (Animations)
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Animated "shooting star" border: two soft radial-gradient glows slide
/// along the top and bottom edges of a rounded rect, fading out as they
/// travel, then reverse (CSS `linear infinite alternate`). The child sits on
/// a dark gradient button face; the glow shows through the vertical gap
/// controlled by [thickness].
///
/// This is a carrier, not a button — it has no tap handling. Wrap it in an
/// `InkWell`/`GestureDetector` in the host app if it should be tappable.
///
/// Named `StarBorderGlow` (not `StarBorder`) because Flutter's framework
/// already ships a `StarBorder` ShapeBorder.
class StarBorderGlow extends StatefulWidget {
  const StarBorderGlow({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.speed = const Duration(seconds: 6),
    this.thickness = 1,
    this.animate = true,
    this.borderRadius = 20,
    this.innerGradientColors = const [Color(0xFF000000), Color(0xFF111827)],
    this.innerBorderColor = const Color(0xFF1F2937),
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 26),
  });

  /// Content shown on the inner face.
  final Widget child;

  /// Color of the traveling glow.
  final Color color;

  /// Duration of one sweep (one keyframe pass); the animation alternates,
  /// so a full there-and-back cycle takes 2x this.
  final Duration speed;

  /// Vertical padding around the inner face — the visible border gap where
  /// the glow shows through (the original's `padding: {thickness}px 0`).
  final double thickness;

  /// External stop switch. When false the widget renders a single static
  /// frame (mid-cycle, so the glow is visible) and runs no ticker.
  final bool animate;

  /// Corner radius of both the outer clip and the inner face.
  final double borderRadius;

  /// Top-to-bottom gradient of the inner face
  /// (original: black -> tailwind gray-900).
  final List<Color> innerGradientColors;

  /// 1px border of the inner face (original: tailwind gray-800).
  final Color innerBorderColor;

  /// Padding around [child] inside the face.
  final EdgeInsetsGeometry padding;

  @override
  State<StarBorderGlow> createState() => _StarBorderGlowState();
}

class _StarBorderGlowState extends State<StarBorderGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.speed);
    if (widget.animate) {
      _controller.repeat(reverse: true);
    } else {
      // Static mode from the start: park mid-cycle so the glow is visible
      // (at t=0 both blobs sit outside the clip).
      _controller.value = 0.5;
    }
  }

  @override
  void didUpdateWidget(StarBorderGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed) {
      _controller.duration = widget.speed;
      if (_controller.isAnimating) _controller.repeat(reverse: true);
    }
    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop(); // freeze at current phase
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(widget.borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _StarGlowPainter(
                animation: _controller,
                color: widget.color,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: widget.thickness),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.innerGradientColors,
                ),
                border: Border.all(color: widget.innerBorderColor),
                borderRadius: radius,
              ),
              child: Padding(
                padding: widget.padding,
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the two traveling glows. Geometry is a direct translation of the
/// original CSS: each blob is a 300% x 50% element filled with
/// `radial-gradient(circle, color, transparent 10%)`. CSS sizes `circle` to
/// the farthest corner, so the glow dies at 10% of the blob's half-diagonal
/// — a tight falloff, which is what makes it read as a "star" streak.
class _StarGlowPainter extends CustomPainter {
  _StarGlowPainter({required this.animation, required this.color})
      : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final Paint _blobPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    if (w <= 0 || h <= 0) return;

    final double t = animation.value;
    // Keyframes fade opacity 1 -> 0; the elements also carry a static 0.7
    // (`opacity-70`). Both blobs share the same value.
    final double opacity = 0.7 * (1.0 - t);
    if (opacity <= 0.003) return;

    // Farthest-corner radius of the 3w x 0.5h blob.
    final double radius =
        math.sqrt(1.5 * w * 1.5 * w + 0.25 * h * 0.25 * h);

    // Bottom blob: right:-250% puts its center at x = 2w; it translates by
    // -100% of its own 3w width. bottom:-11px hugs the bottom edge.
    _paintBlob(
      canvas,
      size,
      Offset(2 * w - 3 * w * t, h + 11 - 0.25 * h),
      radius,
      opacity,
    );
    // Top blob: mirrored — starts left of the clip, travels right,
    // top:-10px hugs the top edge.
    _paintBlob(
      canvas,
      size,
      Offset(-w + 3 * w * t, -10 + 0.25 * h),
      radius,
      opacity,
    );
  }

  void _paintBlob(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    double opacity,
  ) {
    _blobPaint.shader = ui.Gradient.radial(
      center,
      radius,
      [
        color.withValues(alpha: opacity * color.a),
        color.withValues(alpha: 0),
      ],
      const [0.0, 0.1], // transparent at 10% — the original's tight falloff
    );
    canvas.drawRect(Offset.zero & size, _blobPaint);
  }

  @override
  bool shouldRepaint(_StarGlowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.animation != animation;
}
