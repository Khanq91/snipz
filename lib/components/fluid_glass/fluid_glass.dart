/// FluidGlass
/// Origin: reimplemented — dựng lại ý tưởng "FluidGlass" của react-bits
/// (three.js + GLB + MeshTransmissionMaterial) bằng RawMagnifier 2D thuần
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Shape/behavior of the glass, mirroring the three modes of the original.
enum FluidGlassMode {
  /// Circular lens that follows the finger.
  lens,

  /// Rounded-square lens that follows the finger.
  cube,

  /// Glass bar pinned to the bottom edge (navbar); does not follow touch.
  bar,
}

/// A "liquid glass" magnifier floating over arbitrary [child] content: a
/// circular lens / rounded cube glides after the finger (exponential damp,
/// the `easing.damp3(…, 0.15)` feel of the original), or a glass bar sits
/// pinned to the bottom. The glass genuinely magnifies what is beneath it
/// ([RawMagnifier]) and gets a procedural rim highlight + sheen.
///
/// Honest scope note: the web original refracts a real 3D GLB mesh through
/// `MeshTransmissionMaterial`. This is a 2D look-alike of its lens demo —
/// uniform magnification, no true edge refraction.
class FluidGlass extends StatefulWidget {
  const FluidGlass({
    super.key,
    required this.child,
    this.mode = FluidGlassMode.lens,
    this.lensSize = 140,
    this.magnification = 1.25,
    this.smoothing = 0.15,
    this.barHeight = 56,
    this.barMargin = 12,
    this.barWidthFactor = 0.92,
    this.barChild,
    this.shadow = true,
    this.rimOpacity = 1,
  })  : assert(lensSize > 0),
        assert(magnification > 0),
        assert(barWidthFactor > 0 && barWidthFactor <= 1);

  /// Content under the glass. Stays fully interactive (the glass layer is
  /// pointer-transparent).
  final Widget child;

  final FluidGlassMode mode;

  /// Lens diameter (also the cube side).
  final double lensSize;

  /// Scale of the content seen through the glass.
  final double magnification;

  /// Time constant (seconds) of the glide toward the finger; 0 = snap.
  final double smoothing;

  // Bar mode geometry.
  final double barHeight;
  final double barMargin;
  final double barWidthFactor;

  /// Content shown inside the bar (nav row of the original). Interactive.
  final Widget? barChild;

  /// Soft drop shadow under the glass.
  final bool shadow;

  /// 0..1 fade of the rim/sheen highlights (0 = bare magnifier).
  final double rimOpacity;

  @override
  State<FluidGlass> createState() => _FluidGlassState();
}

class _FluidGlassState extends State<FluidGlass>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  Offset? _pos;
  Offset? _target;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    final double dt = _lastElapsed == Duration.zero
        ? 1 / 60
        : math.min((elapsed - _lastElapsed).inMicroseconds / 1e6, 0.05);
    _lastElapsed = elapsed;
    final Offset pos = _pos ?? _target ?? Offset.zero;
    final Offset target = _target ?? pos;
    final double k = widget.smoothing <= 0
        ? 1
        : 1 - math.exp(-dt / widget.smoothing);
    Offset next = pos + (target - pos) * k;
    if ((target - next).distance < 0.3) {
      next = target;
      _ticker.stop();
      _lastElapsed = Duration.zero;
    }
    setState(() => _pos = next);
  }

  void _setTarget(Offset local, Size bounds) {
    if (widget.mode == FluidGlassMode.bar) {
      return;
    }
    _target = _clamp(local, bounds);
    if (widget.smoothing <= 0) {
      setState(() => _pos = _target);
      return;
    }
    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  /// Keep the whole lens inside the widget (the finger can leave it).
  Offset _clamp(Offset p, Size bounds) {
    final double half = widget.lensSize / 2;
    double clampAxis(double v, double extent) => extent <= widget.lensSize
        ? extent / 2
        : v.clamp(half, extent - half);
    return Offset(clampAxis(p.dx, bounds.width), clampAxis(p.dy, bounds.height));
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size bounds = Size(constraints.maxWidth, constraints.maxHeight);
        final bool bar = widget.mode == FluidGlassMode.bar;

        final Size glassSize = bar
            ? Size(bounds.width * widget.barWidthFactor, widget.barHeight)
            : Size.square(widget.lensSize);
        final Offset center = bar
            ? Offset(
                bounds.width / 2,
                bounds.height - widget.barMargin - widget.barHeight / 2,
              )
            : (_pos ??= _clamp(bounds.center(Offset.zero), bounds));

        final ShapeBorder shape = switch (widget.mode) {
          FluidGlassMode.lens => const CircleBorder(),
          FluidGlassMode.cube => RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.lensSize * 0.24),
            ),
          FluidGlassMode.bar => const StadiumBorder(),
        };

        final Rect glassRect = Rect.fromCenter(
          center: center,
          width: glassSize.width,
          height: glassSize.height,
        );

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) => _setTarget(e.localPosition, bounds),
          onPointerMove: (e) => _setTarget(e.localPosition, bounds),
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                widget.child,
                Positioned.fromRect(
                  rect: glassRect,
                  child: IgnorePointer(
                    child: RawMagnifier(
                      size: glassSize,
                      magnificationScale: widget.magnification,
                      decoration: MagnifierDecoration(shape: shape),
                    ),
                  ),
                ),
                if (widget.rimOpacity > 0 || widget.shadow)
                  Positioned.fromRect(
                    rect: glassRect,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _GlassRimPainter(
                          shape: shape,
                          rimOpacity: widget.rimOpacity.clamp(0.0, 1.0),
                          shadow: widget.shadow,
                        ),
                      ),
                    ),
                  ),
                if (bar && widget.barChild != null)
                  Positioned.fromRect(
                    rect: glassRect,
                    child: Center(child: widget.barChild),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Procedural glass finish: a light-from-top-left rim stroke, an inner sheen
/// and a faint bottom shade — the 2D stand-ins for the transmission
/// material's fresnel edge.
class _GlassRimPainter extends CustomPainter {
  const _GlassRimPainter({
    required this.shape,
    required this.rimOpacity,
    required this.shadow,
  });

  final ShapeBorder shape;
  final double rimOpacity;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Path path = shape.getOuterPath(rect);

    if (shadow) {
      // Drop shadow clipped to OUTSIDE the glass: painted under the lens it
      // would be captured by the magnifier and darken the magnified view.
      final Path outside = Path()
        ..addRect(rect.inflate(48))
        ..addPath(path, Offset.zero)
        ..fillType = PathFillType.evenOdd;
      canvas.save();
      canvas.clipPath(outside);
      canvas.drawPath(
        path.shift(const Offset(0, 8)),
        Paint()
          ..color = const Color(0x40000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.restore();
    }
    if (rimOpacity <= 0) {
      return;
    }
    final bool faded = rimOpacity < 1;
    if (faded) {
      canvas.saveLayer(
        rect.inflate(4),
        Paint()..color = Color.fromRGBO(0, 0, 0, rimOpacity),
      );
    }
    canvas.save();
    canvas.clipPath(path);
    // Sheen: bright spot toward the top-left, like a studio softbox.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.45, -0.55),
          radius: 1,
          colors: <Color>[Color(0x3DFFFFFF), Color(0x00FFFFFF)],
          stops: <double>[0, 0.75],
        ).createShader(rect),
    );
    // Faint shade pooling at the bottom of the glass.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: <Color>[Color(0x24000000), Color(0x00000000)],
          stops: <double>[0, 0.4],
        ).createShader(rect),
    );
    canvas.restore();

    // Rim: gradient stroke, bright where the light hits.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xB3FFFFFF),
            Color(0x1AFFFFFF),
            Color(0x66FFFFFF),
          ],
          stops: <double>[0, 0.55, 1],
        ).createShader(rect),
    );
    if (faded) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_GlassRimPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.rimOpacity != rimOpacity ||
      oldDelegate.shadow != shadow;
}
