// Demo/usage example for PixelCard. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'pixel_card.dart';

final ComponentDemo pixelCardDemo = ComponentDemo(
  id: 'pixel_card',
  builder: (context) => const _PixelCardShowcase(),
  // Grid thumbnails must not run tickers (§9.2): static mock of the blue
  // card frozen mid-appear (fixed-seed pixel field, no controller).
  thumbnailBuilder: (context) => const _PixelCardThumb(),
);

/// Two cards from the original demo page: press & hold fills the card with
/// shimmering pixels from the center out; release dissolves them.
class _PixelCardShowcase extends StatelessWidget {
  const _PixelCardShowcase();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: <Widget>[
            // Web default footprint (300x400) — PixelCard sizes from its
            // parent, so the SizedBox decides.
            SizedBox(
              width: 300,
              height: 400,
              child: PixelCard(
                variant: PixelCardVariant.blue,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Icon(Icons.ac_unit, color: Color(0xFFE0F2FE), size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Frost',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'press & hold',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 300,
              height: 220,
              child: PixelCard(
                variant: PixelCardVariant.pink,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Icon(Icons.favorite, color: Color(0xFFFDA4AF), size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Bloom',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'hold a card to reveal the pixels',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Static stand-in for the gallery tile: the blue card with its pixel field
/// frozen mid-appear — one fixed-seed paint, no ticker.
class _PixelCardThumb extends StatelessWidget {
  const _PixelCardThumb();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            width: 300,
            height: 400,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const CustomPaint(painter: _FrozenPixelFieldPainter()),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const <Widget>[
                      Icon(Icons.ac_unit, color: Color(0xFFE0F2FE), size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Frost',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

/// One-shot painter: blue-variant pixel grid as if the appear sweep is ~60%
/// through (center pixels shimmering, edge pixels still waiting). Painted
/// once, never repaints.
class _FrozenPixelFieldPainter extends CustomPainter {
  const _FrozenPixelFieldPainter();

  static const List<Color> _colors = <Color>[
    Color(0xFFE0F2FE),
    Color(0xFF7DD3FC),
    Color(0xFF0EA5E9),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final math.Random random = math.Random(7);
    final Paint paint = Paint();
    const double gap = 10; // blue variant gap
    final double reach = size.shortestSide * 0.75; // appear front radius
    for (double x = 0; x < size.width; x += gap) {
      for (double y = 0; y < size.height; y += gap) {
        final double dx = x - size.width / 2;
        final double dy = y - size.height / 2;
        final double distance = math.sqrt(dx * dx + dy * dy);
        // Jittered front, like the per-pixel counterStep randomness.
        if (distance > reach - random.nextDouble() * 60) {
          continue;
        }
        final double pixelSize = 0.5 + random.nextDouble() * 1.5;
        paint.color = _colors[random.nextInt(_colors.length)];
        canvas.drawRect(
          Rect.fromLTWH(x + 1 - pixelSize / 2, y + 1 - pixelSize / 2,
              pixelSize, pixelSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FrozenPixelFieldPainter oldDelegate) => false;
}
