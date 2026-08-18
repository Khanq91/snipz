// Demo/usage example for GradientText. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'gradient_text.dart';

final ComponentDemo gradientTextDemo = ComponentDemo(
  id: 'gradient_text',
  builder: (context) => const _GradientTextShowcase(),
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
