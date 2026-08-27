// Demo/usage example for FlipGrid. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'package:snipz/core/component_demo.dart';

import 'flip_grid.dart';

final ComponentDemo flipGridDemo = ComponentDemo(
  id: 'flip_grid',
  builder: (context) => const FlipGrid(),
  // Resting grid — interaction-driven component, static thumbnail.
  thumbnailBuilder: (context) => const FlipGrid(frozenAt: 0),
  variants: [
    DemoVariant(
      id: 'no-spin',
      label: 'No spin',
      builder: (context) => const FlipGrid(spinOnShuffle: false),
      frozenBuilder: (context) =>
          const FlipGrid(spinOnShuffle: false, frozenAt: 0),
    ),
    DemoVariant(
      id: 'dense',
      label: 'Dense (20)',
      builder: (context) => const FlipGrid(itemCount: 20, staggerAmount: 0.3),
      frozenBuilder: (context) => const FlipGrid(itemCount: 20, frozenAt: 0),
    ),
  ],
);
