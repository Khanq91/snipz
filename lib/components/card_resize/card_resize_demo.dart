// Demo/usage example for CardResize.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'card_resize.dart';

final ComponentDemo cardResizeDemo = ComponentDemo(
  id: 'card_resize',
  builder: (context) => const _Stage(child: CardResize()),
  // Implicit animations render their end value on first build, so both
  // variants are naturally frozen frames.
  variants: <DemoVariant>[
    DemoVariant(
      id: 'collapsed',
      label: 'Collapsed',
      builder: (context) =>
          const _Stage(child: CardResize(animate: false)),
    ),
    DemoVariant(
      id: 'expanded',
      label: 'Expanded',
      builder: (context) => const _Stage(
        child: CardResize(initiallyExpanded: true, animate: false),
      ),
    ),
  ],
);

/// Dark stage matching the kinetics palette (graphite #0e0e10).
class _Stage extends StatelessWidget {
  const _Stage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0E0E10),
      child: Center(child: child),
    );
  }
}
