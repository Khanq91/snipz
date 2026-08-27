// Demo/usage example for OrbitSpinner. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'orbit_spinner.dart';

final ComponentDemo orbitSpinnerDemo = ComponentDemo(
  id: 'orbit_spinner',
  builder: (context) => const ColoredBox(
    color: Color(0xFF0E0E10),
    child: Center(child: OrbitSpinner()),
  ),
  // Frozen frame for the gallery grid — no ticker per tile.
  thumbnailBuilder: (context) => const ColoredBox(
    color: Color(0xFF0E0E10),
    child: Center(child: OrbitSpinner(size: 56, frozenAt: 0.3)),
  ),
  // sample(t): freeze in the detail stage becomes a time scrubber.
  scrubBuilder: (context, t) => ColoredBox(
    color: const Color(0xFF0E0E10),
    child: Center(child: OrbitSpinner(frozenAt: t)),
  ),
  scrubDuration: 1.6, // two revolutions (period 0.8)
);
