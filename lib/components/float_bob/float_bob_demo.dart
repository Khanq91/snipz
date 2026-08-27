// Demo/usage example for FloatBob. Exempt from portability rules; this is
// also the copy-paste usage reference.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'float_bob.dart';

final ComponentDemo floatBobDemo = ComponentDemo(
  id: 'float_bob',
  builder: (context) => const ColoredBox(
    color: Color(0xFF0E0E10),
    child: Center(
      child: SizedBox(height: 140, child: Center(child: FloatBob())),
    ),
  ),
  thumbnailBuilder: (context) => const ColoredBox(
    color: Color(0xFF0E0E10),
    child: Center(
      child: SizedBox(height: 140, child: Center(child: FloatBob(frozenAt: 2))),
    ),
  ),
  // sample(t): freeze in the detail stage becomes a time scrubber.
  scrubBuilder: (context, t) => ColoredBox(
    color: const Color(0xFF0E0E10),
    child: Center(child: SizedBox(height: 140, child: Center(child: FloatBob(frozenAt: t)))),
  ),
  scrubDuration: 4, // one bob cycle (period 4)
);
