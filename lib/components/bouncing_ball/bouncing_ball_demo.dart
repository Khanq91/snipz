// Demo/usage example for BouncingBall. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'bouncing_ball.dart';

final ComponentDemo bouncingBallDemo = ComponentDemo(
  id: 'bouncing_ball',
  builder: (context) => const _Stage(child: BouncingBall()),
  // Mid-fall frame at t = 0.25s — no ticker in the gallery grid.
  thumbnailBuilder: (context) =>
      const _Stage(child: BouncingBall(frozenAt: 0.25)),
  // sample(t): freeze in the detail stage becomes a time scrubber.
  scrubBuilder: (context, t) => _Stage(child: BouncingBall(frozenAt: t)),
  scrubDuration: 2, // two bounces (period 1)
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
