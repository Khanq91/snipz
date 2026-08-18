// Demo/usage example for PixelBlast. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'pixel_blast.dart';

final ComponentDemo pixelBlastDemo = ComponentDemo(
  id: 'pixel_blast',
  // Tap anywhere: ripple rings light the pixels up. Transparent by default,
  // so the demo supplies the dark backdrop a host app would have.
  builder: (context) => const ColoredBox(
    color: Color(0xFF060010),
    child: PixelBlast(),
  ),
  // Grid thumbnails must not run tickers (§9.2) — frozen frame.
  thumbnailBuilder: (context) => const ColoredBox(
    color: Color(0xFF060010),
    child: PixelBlast(animate: false, enableRipples: false),
  ),
  // No hand-built carriers: this paint satisfies the §2.3 shader contract
  // (createPixelBlastShader returns a real ui.Shader for ShaderMask), so
  // carrier composition is the host's job — see the README example.
);
