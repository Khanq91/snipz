// Demo/usage example for GradientWaves. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:snipz/core/component_demo.dart';

import 'gradient_waves.dart';

final ComponentDemo gradientWavesDemo = ComponentDemo(
  id: 'gradient_waves',
  // Drag anywhere: camera parallax (the original's mouse hover). The widget
  // loads the FragmentProgram itself on first mount.
  builder: (context) => const GradientWaves(),
  // Grid thumbnails must not run tickers (§9.2) — frozen frame, no parallax,
  // low raymarch tier since it renders at tile size anyway.
  thumbnailBuilder: (context) => const GradientWaves(
    animate: false,
    touchParallax: false,
    detail: GradientWavesDetail.low,
  ),
  // No hand-built carriers: this paint satisfies the §2.3 shader contract
  // (createGradientWavesShader returns a real ui.Shader for ShaderMask), so
  // carrier composition is the host's job — see the README example.
);
