// Demo/usage example for SnapRail.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'snap_rail.dart';

final ComponentDemo snapRailDemo = ComponentDemo(
  id: 'snap_rail',
  builder: (context) => const _RailShowcase(),
  variants: <DemoVariant>[
    for (int i = 0; i < 3; i++)
      DemoVariant(
        id: 'cell-$i',
        label: const <String>['Day', 'Week', 'Month'][i],
        builder: (context) => _Stage(
          child: SnapRail(index: i, onChanged: null, animate: false),
        ),
      ),
  ],
);

class _RailShowcase extends StatefulWidget {
  const _RailShowcase();

  @override
  State<_RailShowcase> createState() => _RailShowcaseState();
}

class _RailShowcaseState extends State<_RailShowcase> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return _Stage(
      child: SnapRail(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

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
