// Support file for AuroraStack — drifting additive blobs.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Default aurora palette: electric blue, cyan, violet, mint.
const List<Color> auroraDefaultColors = [
  Color(0xFF3D5AFE),
  Color(0xFF00E5FF),
  Color(0xFF7C4DFF),
  Color(0xFF00E676),
];

class AuroraBlobPainter extends CustomPainter {
  const AuroraBlobPainter({
    required this.t,
    required this.scale,
    required this.colors,
    required this.background,
  });

  /// Animation phase, 0..1 (one full drift loop).
  final double t;
  final double scale;
  final List<Color> colors;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final Paint blob = Paint()..blendMode = BlendMode.plus;
    final double tau = 2 * math.pi;
    for (int i = 0; i < colors.length; i++) {
      final double phase = t * tau + i * (tau / colors.length);
      final Offset center = Offset(
        size.width * (0.5 + 0.32 * math.cos(phase + i * 0.9)),
        size.height * (0.5 + 0.30 * math.sin(phase * 0.8 + i * 1.7)),
      );
      final double radius =
          size.shortestSide * (0.42 + 0.10 * math.sin(phase * 1.3)) * scale;
      blob.shader = ui.Gradient.radial(center, radius, [
        colors[i].withValues(alpha: 0.55),
        colors[i].withValues(alpha: 0),
      ]);
      canvas.drawCircle(center, radius, blob);
    }
  }

  @override
  bool shouldRepaint(AuroraBlobPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.scale != scale ||
      oldDelegate.colors != colors ||
      oldDelegate.background != background;
}
