// Demo/usage example for GradientText. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'gradient_text.dart';

final ComponentDemo gradientTextDemo = ComponentDemo(
  id: 'gradient_text',
  builder: (context) => const _GradientTextShowcase(),
  // Thumbnail: the real widgets frozen via `animate: false` (ticker never
  // starts, gradient stays at phase 0); FittedBox scales the fixed layout
  // down so the headline never wraps at tile size.
  thumbnailBuilder: (context) => const ColoredBox(
    color: Color(0xFF060010),
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              GradientText(
                animate: false,
                child: Text(
                  'Gradient Text',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 24),
              GradientText(
                animate: false,
                showBorder: true,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'bordered pill',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

/// Plain masked headline (the default), a bordered pill (original
/// `showBorder`), and a diagonal one-way loop — the three main configs.
class _GradientTextShowcase extends StatelessWidget {
  const _GradientTextShowcase();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const GradientText(
              child: Text(
                'Gradient Text',
                style: TextStyle(
                  color: Colors.white, // any opaque color; mask keeps alpha
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const GradientText(
              showBorder: true,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'bordered pill',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),
            GradientText(
              direction: GradientTextDirection.diagonal,
              yoyo: false, // endless forward slide
              animationSpeed: 4,
              colors: const <Color>[
                Color(0xFF40FFAA),
                Color(0xFF4079FF),
                Color(0xFF40FFAA),
              ],
              child: const Text(
                'diagonal, endless',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
