// Demo/usage example for DitherWaves. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'dither.dart';

final ComponentDemo ditherDemo = ComponentDemo(
  id: 'dither',
  builder: (context) => const _DitherShowcase(),
  // Static frame for the gallery grid — no ticker per tile (§8.3).
  thumbnailBuilder: (context) => const DitherWaves(animate: false),
);

/// Fullscreen animated waves with foreground content — the standard
/// "retro background" use. The widget is opaque (composites over black),
/// so it goes at the bottom of a Stack.
class _DitherShowcase extends StatelessWidget {
  const _DitherShowcase();

  @override
  Widget build(BuildContext context) {
    return DitherWaves(
      // Original defaults: gray waves, 4 levels, 2px cells.
      waveColor: const Color(0xFF808080),
      colorNum: 4,
      pixelSize: 2,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            Text(
              'Dither',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Bayer 8×8 over Perlin fbm waves',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
