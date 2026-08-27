// Demo/usage example for MarqueeReveal. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'marquee_reveal.dart';

final ComponentDemo marqueeRevealDemo = ComponentDemo(
  id: 'marquee_reveal',
  builder: (context) => _Stage(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MarqueeReveal(),
        const SizedBox(height: 12),
        const Text(
          'hold to pause',
          style: TextStyle(
            color: Color(0xFF6E6C68),
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
      ],
    ),
  ),
  // Deterministic mid-scroll frame — no ticker in the gallery grid.
  thumbnailBuilder: (context) => _Stage(child: MarqueeReveal(frozenAt: 0.75)),
  // sample(t): freeze in the detail stage becomes a time scrubber.
  scrubBuilder: (context, t) => _Stage(child: MarqueeReveal(frozenAt: t)),
  scrubDuration: 6, // one label-set pass (period 6)
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
