// Demo/usage example for SpeedDialFab.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'speed_dial_fab.dart';

final ComponentDemo speedDialFabDemo = ComponentDemo(
  id: 'speed_dial_fab',
  builder: (context) => const _Stage(child: SpeedDialFab()),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'closed',
      label: 'Closed',
      builder: (context) => const _Stage(child: SpeedDialFab(animate: false)),
    ),
    DemoVariant(
      id: 'open',
      label: 'Open',
      builder: (context) => const _Stage(
        child: SpeedDialFab(initiallyOpen: true, animate: false),
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
