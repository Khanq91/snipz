// Demo/usage example for LatticeSnap.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'lattice_snap.dart';

final ComponentDemo latticeSnapDemo = ComponentDemo(
  id: 'lattice_snap',
  builder: (context) => const _Stage(child: LatticeSnap()),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'first',
      label: 'First cell',
      builder: (context) => const _Stage(child: LatticeSnap(animate: false)),
    ),
    DemoVariant(
      id: 'last',
      label: 'Last cell',
      builder: (context) => const _Stage(
        child: LatticeSnap(
          initialColumn: 2,
          initialRow: 1,
          animate: false,
        ),
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
