// Demo/usage example for RadarPulse. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'radar_pulse.dart';

final ComponentDemo radarPulseDemo = ComponentDemo(
  id: 'radar_pulse',
  builder: (context) => const _Stage(child: RadarPulse()),
  // Three rings mid-flight at t = 1.2s — no ticker in the gallery grid.
  thumbnailBuilder: (context) => const _Stage(child: RadarPulse(frozenAt: 1.2)),
  // sample(t): freeze in the detail stage becomes a time scrubber.
  scrubBuilder: (context, t) => _Stage(child: RadarPulse(frozenAt: t)),
  scrubDuration: 2.4, // one ring flight, three staggered (period 2.4)
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
