// Demo/usage example for BeforeAfterSlider. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'before_after.dart';

final ComponentDemo beforeAfterDemo = ComponentDemo(
  id: 'before_after',
  builder: (context) => const _Stage(child: BeforeAfterSlider()),
  // No ticker at all — the resting 50% split is already deterministic.
  thumbnailBuilder: (context) => const _Stage(child: BeforeAfterSlider()),
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
