// Demo/usage example for GradientShimmerText. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'gradient_shimmer_text.dart';

final ComponentDemo gradientShimmerTextDemo = ComponentDemo(
  id: 'gradient_shimmer_text',
  builder: (context) => const _Stage(child: GradientShimmerText()),
  // frozenAt 0 parks the highlight mid-word — no ticker in the gallery grid.
  thumbnailBuilder: (context) =>
      const _Stage(child: GradientShimmerText(frozenAt: 0)),
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
