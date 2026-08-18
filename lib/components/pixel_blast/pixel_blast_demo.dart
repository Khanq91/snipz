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
  // No hand-built carriers: this paint satisfies the §2.3 shader contract.
  // One FragmentShader is reused and reconfigured per tick. transparent:false
  // gives shape carriers the dark backdrop the demo supplies by hand above.
  shader: CarrierShaderSpec(
    prepare: () async {
      final program = await loadPixelBlastProgram();
      final shader = program.fragmentShader();
      return CarrierShaderHandle(
        build: (bounds, scale, time) {
          configurePixelBlastShader(
            shader,
            bounds.size,
            time: time,
            scale: scale,
            transparent: false,
          );
          return shader;
        },
        dispose: shader.dispose,
      );
    },
  ),
);
