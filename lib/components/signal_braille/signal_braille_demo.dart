// Demo/usage example for SignalBraille.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'signal_braille.dart';

final ComponentDemo signalBrailleDemo = ComponentDemo(
  id: 'signal_braille',
  builder: (context) => const _Stage(child: SignalBraille()),
  thumbnailBuilder: (context) =>
      const _Stage(child: SignalBraille(frozenAt: 0.8)),
  // sample(t): freeze in the detail stage becomes a time scrubber.
  scrubBuilder: (context, t) => _Stage(child: SignalBraille(frozenAt: t)),
  scrubDuration: 2.1, // one cycle (period 2.1)
  variants: <DemoVariant>[
    for (final (String id, String label, double time)
        in <(String, String, double)>[
          ('phase-a', 'Phase A', 0.1),
          ('phase-b', 'Phase B', 0.8),
          ('phase-c', 'Phase C', 1.5),
        ])
      DemoVariant(
        id: id,
        label: label,
        builder: (context) => const _Stage(child: SignalBraille()),
        frozenBuilder: (context) =>
            _Stage(child: SignalBraille(frozenAt: time)),
      ),
  ],
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
