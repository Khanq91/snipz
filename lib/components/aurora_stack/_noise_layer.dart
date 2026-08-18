// Support file for AuroraStack — static film-grain overlay.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Static grain overlay to break up gradient banding. Deterministic (fixed
/// [seed]) and unanimated, so it costs one paint — not one per frame.
class AuroraNoiseOverlay extends StatelessWidget {
  const AuroraNoiseOverlay({
    super.key,
    this.opacity = 0.05,
    this.density = 1.0,
    this.seed = 7,
  });

  /// Grain visibility, keep subtle (0.03–0.08).
  final double opacity;

  /// Dots per area multiplier.
  final double density;

  /// Fixed seed keeps the pattern stable across rebuilds — no shimmer.
  final int seed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _NoisePainter(opacity: opacity, density: density, seed: seed),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  const _NoisePainter({
    required this.opacity,
    required this.density,
    required this.seed,
  });

  final double opacity;
  final double density;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final math.Random rng = math.Random(seed);
    final int count = (size.width * size.height / 700 * density).round();
    final Paint light = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: opacity);
    final Paint dark = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: opacity);
    for (int i = 0; i < count; i++) {
      final Offset p = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      );
      canvas.drawRect(p & const Size(1, 1), i.isEven ? light : dark);
    }
  }

  @override
  bool shouldRepaint(_NoisePainter oldDelegate) =>
      oldDelegate.opacity != opacity ||
      oldDelegate.density != density ||
      oldDelegate.seed != seed;
}
