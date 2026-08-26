// Demo/usage example for NeonGlowPulse. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'neon_glow_pulse.dart';

final ComponentDemo neonGlowPulseDemo = ComponentDemo(
  id: 'neon_glow_pulse',
  builder: (context) => const _Stage(child: NeonGlowPulse()),
  // Frozen at the bright half of the cycle — no ticker in the gallery grid.
  thumbnailBuilder: (context) =>
      const _Stage(child: NeonGlowPulse(frozenAt: 1)),
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
