// Demo/usage example for EqualizerBars. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'equalizer_bars.dart';

final ComponentDemo equalizerBarsDemo = ComponentDemo(
  id: 'equalizer_bars',
  builder: (context) => _Stage(child: EqualizerBars()),
  // Deterministic phase mix — no ticker in the scrolling gallery grid.
  thumbnailBuilder: (context) =>
      _Stage(child: EqualizerBars(frozenAt: 0.25)),
);

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
