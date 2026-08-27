// Demo/usage example for SignalBars. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'signal_bars.dart';

final ComponentDemo signalBarsDemo = ComponentDemo(
  id: 'signal_bars',
  builder: (context) => const ColoredBox(
    color: Color(0xFF0E0E10),
    child: Center(child: SignalBars()),
  ),
  // Frozen with the first bars lit — no ticker per gallery tile.
  thumbnailBuilder: (context) => const ColoredBox(
    color: Color(0xFF0E0E10),
    child: Center(child: SignalBars(frozenAt: 0.9)),
  ),
  // sample(t): freeze in the detail stage becomes a time scrubber.
  scrubBuilder: (context, t) => ColoredBox(
    color: const Color(0xFF0E0E10),
    child: Center(child: SignalBars(frozenAt: t)),
  ),
  scrubDuration: 2.4, // one cycle, bars staggered inside (period 2.4)
);
