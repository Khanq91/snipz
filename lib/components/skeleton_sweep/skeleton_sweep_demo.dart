// Demo/usage example for SkeletonSweep. Exempt from portability rules; this
// is also the copy-paste usage reference.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'skeleton_sweep.dart';

final ComponentDemo skeletonSweepDemo = ComponentDemo(
  id: 'skeleton_sweep',
  builder: (context) => const ColoredBox(
    color: Color(0xFF0E0E10),
    child: Center(child: SizedBox(width: 220, child: SkeletonSweep())),
  ),
  thumbnailBuilder: (context) => const ColoredBox(
    color: Color(0xFF0E0E10),
    child: Center(
      child: SizedBox(width: 220, child: SkeletonSweep(frozenAt: 0.56)),
    ),
  ),
);
