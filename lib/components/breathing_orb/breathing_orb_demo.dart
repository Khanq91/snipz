// Demo/usage example for BreathingOrb. Exempt from portability rules; this
// is also the copy-paste usage reference.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'breathing_orb.dart';

final ComponentDemo breathingOrbDemo = ComponentDemo(
  id: 'breathing_orb',
  builder: (context) => const ColoredBox(
    color: Color(0xFF0E0E10),
    child: Center(child: BreathingOrb()),
  ),
  thumbnailBuilder: (context) => const ColoredBox(
    color: Color(0xFF0E0E10),
    child: Center(child: BreathingOrb(frozenAt: 2.5)),
  ),
  // sample(t): freeze in the detail stage becomes a time scrubber.
  scrubBuilder: (context, t) => ColoredBox(
    color: const Color(0xFF0E0E10),
    child: Center(child: BreathingOrb(frozenAt: t)),
  ),
  scrubDuration: 5, // one breath cycle (period 5)
);
