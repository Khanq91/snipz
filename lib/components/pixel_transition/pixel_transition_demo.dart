// Demo/usage example for PixelTransition. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'pixel_transition.dart';

final ComponentDemo pixelTransitionDemo = ComponentDemo(
  id: 'pixel_transition',
  builder: (context) => const _PixelTransitionShowcase(),
);

/// The original demo card ("This is a cat" -> "Meow!") rebuilt with a
/// gradient standing in for the cat photo — no assets in the vault.
class _PixelTransitionShowcase extends StatelessWidget {
  const _PixelTransitionShowcase();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 300,
              child: PixelTransition(
                pixelColor: const Color(0xFFB19EEF),
                firstChild: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFF5227FF), Color(0xFF060010)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'This is a cat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                secondChild: const ColoredBox(
                  color: Color(0xFF111111),
                  child: Center(
                    child: Text(
                      'Meow!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'tap the card',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
