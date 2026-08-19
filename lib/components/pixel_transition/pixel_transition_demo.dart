// Demo/usage example for PixelTransition. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'pixel_transition.dart';

final ComponentDemo pixelTransitionDemo = ComponentDemo(
  id: 'pixel_transition',
  builder: (context) => const _PixelTransitionShowcase(),
  // Grid thumbnails must not run tickers (§9.2): static mock of the card
  // frozen MID-WIPE — a hand-picked 7x7 pixel pattern over the first child.
  thumbnailBuilder: (context) => const _PixelTransitionThumb(),
);

/// Static stand-in for the gallery tile: the demo card with the pixel-grid
/// wipe frozen about halfway (fixed pseudo-random pattern, no controller).
class _PixelTransitionThumb extends StatelessWidget {
  const _PixelTransitionThumb();

  // 7x7 snapshot of a random stagger ~55% through the covering sweep
  // ('x' = wipe cell painted). Hand-scattered so it reads as random.
  static const List<String> _pattern = <String>[
    'x.xx..x',
    '.x..xx.',
    'xx.x..x',
    '.x.xx..',
    'x..x.xx',
    '.xx..x.',
    'x.x.xx.',
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            width: 300,
            height: 300,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // Same first child as the interactive demo card.
                const DecoratedBox(
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
                // Frozen wipe cells.
                Column(
                  children: <Widget>[
                    for (final String row in _pattern)
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            for (int c = 0; c < row.length; c++)
                              Expanded(
                                child: ColoredBox(
                                  color: row[c] == 'x'
                                      ? const Color(0xFFB19EEF)
                                      : const Color(0x00000000),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
