// Demo/usage example for OrbitalActionMenu.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'orbital_action_menu.dart';

final ComponentDemo orbitalActionMenuDemo = ComponentDemo(
  id: 'orbital_action_menu',
  builder: (context) => const _Stage(child: OrbitalActionMenu()),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'closed',
      label: 'Closed',
      builder: (context) =>
          const _Stage(child: OrbitalActionMenu(animate: false)),
    ),
    DemoVariant(
      id: 'open',
      label: 'Open',
      builder: (context) => const _Stage(
        child: OrbitalActionMenu(initiallyOpen: true, animate: false),
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
