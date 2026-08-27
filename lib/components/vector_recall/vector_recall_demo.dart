// Demo/usage example for VectorRecall. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'vector_recall.dart';

final ComponentDemo vectorRecallDemo = ComponentDemo(
  id: 'vector_recall',
  builder: (context) => const _Stage(child: VectorRecall()),
  // Frozen at the "match" phase for the gallery grid — no ticker per tile.
  thumbnailBuilder: (context) =>
      const _Stage(child: VectorRecall(frozenAt: 3.2)),
  // sample(t): freeze in the detail stage becomes a time scrubber.
  scrubBuilder: (context, t) => _Stage(child: VectorRecall(frozenAt: t)),
  scrubDuration: 5.6, // one recall cycle (period 5.6)
  variants: <DemoVariant>[
    DemoVariant(
      id: 'querying',
      label: 'Querying',
      builder: (context) => const _Stage(child: VectorRecall()),
      frozenBuilder: (context) =>
          const _Stage(child: VectorRecall(frozenAt: 1.0)),
    ),
    DemoVariant(
      id: 'match',
      label: 'Match',
      builder: (context) => const _Stage(child: VectorRecall()),
      frozenBuilder: (context) =>
          const _Stage(child: VectorRecall(frozenAt: 3.2)),
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
