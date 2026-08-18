/// SpectrumSweep
/// Origin: original — written for the Snipz vault
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Default palette — vivid spectrum.
const List<ui.Color> spectrumSweepColors = [
  ui.Color(0xFFFF1744),
  ui.Color(0xFFFF9100),
  ui.Color(0xFFFFEA00),
  ui.Color(0xFF00E676),
  ui.Color(0xFF00B0FF),
  ui.Color(0xFF651FFF),
  ui.Color(0xFFD500F9),
];

/// Creates a seamless angular spectrum sweep (§2.3 shader contract: the
/// factory IS the component — `ShaderMask` + `BlendMode.srcIn` puts it on any
/// carrier, text included, with zero extra files).
///
/// [scale] is detail density (§9.1): how many full color cycles fit around
/// the circle, rounded to a whole number so the seam never shows. [rotation]
/// spins the sweep around the center of [bounds], in radians.
ui.Shader createSpectrumSweepShader(
  ui.Rect bounds, {
  double scale = 1.0,
  double rotation = 0,
  List<ui.Color>? colors,
}) {
  final List<ui.Color> palette = colors ?? spectrumSweepColors;
  final int cycles = scale.round().clamp(1, 6);
  final List<ui.Color> ring = [
    for (int c = 0; c < cycles; c++) ...palette,
    palette.first,
  ];
  final List<double> stops = [
    for (int i = 0; i < ring.length; i++) i / (ring.length - 1),
  ];
  return ui.Gradient.sweep(
    bounds.center,
    ring,
    stops,
    ui.TileMode.clamp,
    0,
    2 * math.pi,
    _rotationAboutCenter(rotation, bounds.center),
  );
}

/// Column-major 4x4 for T(center) * Rz(radians) * T(-center) — rotates the
/// sweep around the rect center without pulling in a matrix package.
Float64List _rotationAboutCenter(double radians, ui.Offset center) {
  final double c = math.cos(radians);
  final double s = math.sin(radians);
  final double tx = center.dx - c * center.dx + s * center.dy;
  final double ty = center.dy - s * center.dx - c * center.dy;
  return Float64List.fromList([
    c, s, 0, 0, //
    -s, c, 0, 0, //
    0, 0, 1, 0, //
    tx, ty, 0, 1,
  ]);
}

/// Convenience wrapper that fills its bounds with the sweep. The factory
/// above is the primary API — use the widget when you just need a filled box.
class SpectrumSweep extends StatelessWidget {
  const SpectrumSweep({
    super.key,
    this.scale = 1.0,
    this.rotation = 0,
    this.colors,
  });

  /// Whole color cycles around the circle (§9.1); see the factory doc.
  final double scale;

  /// Radians; animate it externally for a spinning sweep.
  final double rotation;

  final List<ui.Color>? colors;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SweepFillPainter(
        scale: scale,
        rotation: rotation,
        colors: colors,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SweepFillPainter extends CustomPainter {
  const _SweepFillPainter({
    required this.scale,
    required this.rotation,
    required this.colors,
  });

  final double scale;
  final double rotation;
  final List<ui.Color>? colors;

  @override
  void paint(Canvas canvas, Size size) {
    final ui.Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = createSpectrumSweepShader(
          rect,
          scale: scale,
          rotation: rotation,
          colors: colors,
        ),
    );
  }

  @override
  bool shouldRepaint(_SweepFillPainter oldDelegate) =>
      oldDelegate.scale != scale ||
      oldDelegate.rotation != rotation ||
      oldDelegate.colors != colors;
}
