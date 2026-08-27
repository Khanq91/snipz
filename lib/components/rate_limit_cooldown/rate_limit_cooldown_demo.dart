// Demo/usage example for RateLimitCooldown. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'rate_limit_cooldown.dart';

final ComponentDemo rateLimitCooldownDemo = ComponentDemo(
  id: 'rate_limit_cooldown',
  builder: (context) => const _Stage(child: RateLimitCooldown()),
  // Frozen mid-cooldown for the gallery grid — no ticker per tile.
  thumbnailBuilder: (context) =>
      const _Stage(child: RateLimitCooldown(frozenAt: 2.5)),
  // sample(t): freeze in the detail stage becomes a time scrubber.
  scrubBuilder: (context, t) => _Stage(child: RateLimitCooldown(frozenAt: t)),
  scrubDuration: 6.4, // request-limit-cooldown-recover cycle (period 6.4)
  // The three phases of the 6.4s cycle, as deterministic frames.
  variants: <DemoVariant>[
    DemoVariant(
      id: 'ok',
      label: '200 · ok',
      builder: (context) => const _Stage(child: RateLimitCooldown()),
      frozenBuilder: (context) =>
          const _Stage(child: RateLimitCooldown(frozenAt: 0)),
    ),
    DemoVariant(
      id: 'cooling',
      label: '429 · cooling',
      builder: (context) => const _Stage(child: RateLimitCooldown()),
      frozenBuilder: (context) =>
          const _Stage(child: RateLimitCooldown(frozenAt: 2.5)),
    ),
    DemoVariant(
      id: 'refill',
      label: 'Refill',
      builder: (context) => const _Stage(child: RateLimitCooldown()),
      frozenBuilder: (context) =>
          const _Stage(child: RateLimitCooldown(frozenAt: 4.2)),
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
