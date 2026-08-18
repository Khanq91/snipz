/// GradientText
/// Origin: reimplemented — dựng lại "Gradient Text" của react-bits (CSS
/// animated background-clip gradient → ShaderMask + ui.Gradient.linear).
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Gradient axis (original `direction`). Diagonal slides horizontally only,
/// like the original (avoids interference patterns).
enum GradientTextDirection { horizontal, vertical, diagonal }

const List<ui.Color> _defaultGradientTextColors = <ui.Color>[
  ui.Color(0xFF5227FF),
  ui.Color(0xFFFF9FFC),
  ui.Color(0xFFB497CF),
];

/// Shader factory: the animated gradient as a real [ui.Shader], usable with
/// `ShaderMask`/`Paint.shader` on anything, not just text. Mirrors the CSS
/// setup: gradient image spans 300% of [bounds] along the axis (first color
/// repeated at the end for a seamless loop), and [progress] 0..1 slides it
/// one full background-position cycle (0% -> 100%). Values beyond 1 keep
/// sliding seamlessly (tile mode repeated) — that is the non-yoyo loop.
ui.Shader createGradientTextShader(
  ui.Rect bounds, {
  List<ui.Color> colors = _defaultGradientTextColors,
  double progress = 0,
  GradientTextDirection direction = GradientTextDirection.horizontal,
}) {
  final List<ui.Color> loop = <ui.Color>[...colors, colors.first];
  final List<double> stops = <double>[
    for (int i = 0; i < loop.length; i++) i / (loop.length - 1),
  ];

  final ui.Offset from = bounds.topLeft;
  late final ui.Offset to;
  double dx = 0;
  double dy = 0;
  switch (direction) {
    case GradientTextDirection.horizontal:
      to = from + ui.Offset(3 * bounds.width, 0);
      dx = -2 * bounds.width * progress;
    case GradientTextDirection.vertical:
      to = from + ui.Offset(0, 3 * bounds.height);
      dy = -2 * bounds.height * progress;
    case GradientTextDirection.diagonal:
      to = from + ui.Offset(3 * bounds.width, 3 * bounds.height);
      dx = -2 * bounds.width * progress; // horizontal slide only (original)
  }

  final Float64List matrix = Float64List(16)
    ..[0] = 1
    ..[5] = 1
    ..[10] = 1
    ..[15] = 1
    ..[12] = dx
    ..[13] = dy;
  return ui.Gradient.linear(from, to, loop, stops, ui.TileMode.repeated, matrix);
}

/// Animated gradient clipped to [child]'s alpha (usually a [Text]) — the
/// Flutter equivalent of CSS `background-clip: text`. With [showBorder] the
/// same gradient also runs around a rounded pill behind the child.
class GradientText extends StatefulWidget {
  const GradientText({
    super.key,
    required this.child,
    this.colors = _defaultGradientTextColors,
    this.animationSpeed = 8,
    this.direction = GradientTextDirection.horizontal,
    this.yoyo = true,
    this.animate = true,
    this.showBorder = false,
    this.borderRadius = 20,
    this.borderWidth = 1,
    this.borderFillColor = const ui.Color(0xFF000000),
    this.padding,
  });

  /// Content the gradient is masked to. Any opaque-colored text works — the
  /// mask replaces color and keeps alpha.
  final Widget child;

  /// Gradient stops; the first color is repeated at the end automatically.
  final List<ui.Color> colors;

  /// Seconds per background-position sweep (original default 8).
  final double animationSpeed;

  final GradientTextDirection direction;

  /// `true` sweeps 0 -> 100% -> 0 (original default); `false` slides forward
  /// forever, seamlessly.
  final bool yoyo;

  /// External stop switch: `false` halts the ticker (gradient freezes at the
  /// current phase); resuming continues from it.
  final bool animate;

  /// Draws the animated gradient as a [borderWidth] ring around a
  /// [borderFillColor] pill behind the child (original `showBorder`).
  final bool showBorder;

  /// Pill corner radius (original 1.25rem = 20).
  final double borderRadius;

  final double borderWidth;

  /// Fill inside the border ring (original: black).
  final ui.Color borderFillColor;

  /// Content padding; defaults to 8×4 when [showBorder], zero otherwise
  /// (matches the original's `py-1 px-2`).
  final EdgeInsetsGeometry? padding;

  @override
  State<GradientText> createState() => _GradientTextState();
}

class _GradientTextState extends State<GradientText>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _elapsed = ValueNotifier<double>(0);
  double _timeBase = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.animate) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    _elapsed.value = _timeBase + elapsed.inMicroseconds / 1e6;
  }

  @override
  void didUpdateWidget(GradientText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.animate && _ticker.isActive) {
      _timeBase = _elapsed.value;
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  double _progress(double elapsed) {
    final double s = widget.animationSpeed;
    if (s <= 0) {
      return 0;
    }
    if (widget.yoyo) {
      final double cycle = elapsed % (2 * s);
      return cycle < s ? cycle / s : 2 - cycle / s;
    }
    return elapsed / s;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _elapsed,
      builder: (context, elapsed, _) {
        final double p = _progress(elapsed);
        final Widget masked = ShaderMask(
          blendMode: ui.BlendMode.srcIn,
          shaderCallback: (bounds) => createGradientTextShader(
            bounds,
            colors: widget.colors,
            progress: p,
            direction: widget.direction,
          ),
          child: widget.child,
        );
        if (!widget.showBorder) {
          return masked;
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _GradientBorderPainter(
                    progress: p,
                    colors: widget.colors,
                    direction: widget.direction,
                    borderWidth: widget.borderWidth,
                    fillColor: widget.borderFillColor,
                    borderRadius: widget.borderRadius,
                  ),
                ),
              ),
              Padding(
                padding: widget.padding ??
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: masked,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Gradient underlay + inset fill = a gradient ring, same construction as
/// the original (gradient layer behind, near-full-size dark box on top).
class _GradientBorderPainter extends CustomPainter {
  _GradientBorderPainter({
    required this.progress,
    required this.colors,
    required this.direction,
    required this.borderWidth,
    required this.fillColor,
    required this.borderRadius,
  });

  final double progress;
  final List<ui.Color> colors;
  final GradientTextDirection direction;
  final double borderWidth;
  final ui.Color fillColor;
  final double borderRadius;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final ui.Rect rect = ui.Offset.zero & size;
    canvas.drawRect(
      rect,
      ui.Paint()
        ..shader = createGradientTextShader(
          rect,
          colors: colors,
          progress: progress,
          direction: direction,
        ),
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        rect.deflate(borderWidth),
        ui.Radius.circular(borderRadius - borderWidth),
      ),
      ui.Paint()..color = fillColor,
    );
  }

  @override
  bool shouldRepaint(_GradientBorderPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.colors != colors ||
      oldDelegate.direction != direction ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.borderRadius != borderRadius;
}
