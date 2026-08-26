// Demo/usage example for ConfettiBurst. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'confetti_burst.dart';

final ComponentDemo confettiBurstDemo = ComponentDemo(
  id: 'confetti_burst',
  builder: (context) => const _Stage(child: _ConfettiShowcase()),
  // Idle and ticker-free: gallery tiles never launch one-shot effects.
  thumbnailBuilder: (context) =>
      _Stage(child: ConfettiBurst(onPressed: null, animate: false)),
);

class _ConfettiShowcase extends StatefulWidget {
  const _ConfettiShowcase();

  @override
  State<_ConfettiShowcase> createState() => _ConfettiShowcaseState();
}

class _ConfettiShowcaseState extends State<_ConfettiShowcase> {
  int _bursts = 0;

  @override
  Widget build(BuildContext context) {
    return ConfettiBurst(
      onPressed: () => setState(() => _bursts++),
      child: Text(_bursts == 0 ? 'Celebrate' : 'Celebrate · $_bursts'),
    );
  }
}

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
