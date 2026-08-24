// Demo/usage example for ContextualDock.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'contextual_dock.dart';

final ComponentDemo contextualDockDemo = ComponentDemo(
  id: 'contextual_dock',
  builder: (context) => const _Stage(child: ContextualDock()),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'rest',
      label: 'At rest',
      builder: (context) =>
          const _Stage(child: ContextualDock(animate: false)),
    ),
    DemoVariant(
      id: 'focused',
      label: 'Center focused',
      builder: (context) => const _Stage(
        child: ContextualDock(focusedIndex: 2, animate: false),
      ),
    ),
  ],
);

/// Dark stage matching the kinetics palette (graphite #0e0e10). Extra height
/// so the raised icons have room.
class _Stage extends StatelessWidget {
  const _Stage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0E0E10),
      child: Center(
        child: Padding(padding: const EdgeInsets.only(top: 24), child: child),
      ),
    );
  }
}
