// Demo/usage example for ShimmerSkeleton. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'shimmer_skeleton.dart';

final ComponentDemo shimmerSkeletonDemo = ComponentDemo(
  id: 'shimmer_skeleton',
  builder: (context) => const ColoredBox(
    color: Color(0xFF0E0E10),
    child: Center(
      child: SizedBox(width: 230, child: ShimmerSkeleton()),
    ),
  ),
  // Frozen frame for the gallery grid — no ticker per tile.
  thumbnailBuilder: (context) => const ColoredBox(
    color: Color(0xFF0E0E10),
    child: Center(
      child: SizedBox(width: 230, child: ShimmerSkeleton(frozenAt: 0.5)),
    ),
  ),
);
