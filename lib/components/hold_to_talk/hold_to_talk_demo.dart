// Demo/usage example for HoldToTalk.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'hold_to_talk.dart';

final ComponentDemo holdToTalkDemo = ComponentDemo(
  id: 'hold_to_talk',
  builder: (context) => const _Stage(child: HoldToTalk()),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'idle',
      label: 'Idle',
      builder: (context) => const _Stage(
        child: HoldToTalk(pinnedPhase: HoldToTalkPhase.idle, animate: false),
      ),
    ),
    DemoVariant(
      id: 'live',
      label: 'Live',
      builder: (context) => const _Stage(
        child: HoldToTalk(pinnedPhase: HoldToTalkPhase.live, animate: false),
      ),
    ),
    DemoVariant(
      id: 'sent',
      label: 'Sent',
      builder: (context) => const _Stage(
        child: HoldToTalk(pinnedPhase: HoldToTalkPhase.sent, animate: false),
      ),
    ),
  ],
);

/// Dark stage matching the kinetics palette (graphite #0e0e10).
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
