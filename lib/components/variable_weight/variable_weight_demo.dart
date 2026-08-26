// Demo/usage example for VariableWeightText. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'variable_weight.dart';

final ComponentDemo variableWeightDemo = ComponentDemo(
  id: 'variable_weight',
  builder: (context) => const _Stage(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VariableWeightText(),
        SizedBox(height: 12),
        Text(
          'press and hold',
          style: TextStyle(
            color: Color(0xFF6E6C68),
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
      ],
    ),
  ),
  // Static engaged pose — no controllers running in the gallery grid.
  thumbnailBuilder: (context) =>
      const _Stage(child: VariableWeightText(engaged: true, animate: false)),
  variants: [
    DemoVariant(
      id: 'idle',
      label: 'Idle (200)',
      builder: (context) =>
          const _Stage(child: VariableWeightText(engaged: false)),
      frozenBuilder: (context) => const _Stage(
        child: VariableWeightText(engaged: false, animate: false),
      ),
    ),
    DemoVariant(
      id: 'engaged',
      label: 'Engaged (800)',
      builder: (context) =>
          const _Stage(child: VariableWeightText(engaged: true)),
      frozenBuilder: (context) => const _Stage(
        child: VariableWeightText(engaged: true, animate: false),
      ),
    ),
  ],
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
