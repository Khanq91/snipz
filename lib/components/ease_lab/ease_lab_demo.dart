// Demo/usage example for EaseLab. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).
//
// The curves also work standalone, e.g.:
//   final wiggle = WiggleEase(wiggles: 8);
//   Tween<double>(begin: 0, end: 0.5).animate(
//     CurvedAnimation(parent: controller, curve: wiggle));  // rad, về lại 0

import 'package:snipz/core/component_demo.dart';

import 'ease_lab.dart';

final ComponentDemo easeLabDemo = ComponentDemo(
  id: 'ease_lab',
  builder: (context) => const EaseLab(),
  // Wiggle mid-swing — no ticker in the gallery grid.
  thumbnailBuilder: (context) => const EaseLab(frozenAt: 0.7),
  // sample(t): freeze in the detail stage becomes a time scrubber.
  scrubBuilder: (context, t) => EaseLab(frozenAt: t),
  scrubDuration: 3.1, // one period + hold
  variants: [
    DemoVariant(
      id: 'bounce',
      label: 'Bounce + Squash',
      builder: (context) => const EaseLab(initialEase: 'bounce'),
      frozenBuilder: (context) =>
          const EaseLab(initialEase: 'bounce', frozenAt: 0.55),
    ),
    DemoVariant(
      id: 'slowmo',
      label: 'Slow Mo',
      builder: (context) => const EaseLab(initialEase: 'slowmo'),
      frozenBuilder: (context) =>
          const EaseLab(initialEase: 'slowmo', frozenAt: 1.2),
    ),
    DemoVariant(
      id: 'expo',
      label: 'Expo Scale',
      builder: (context) => const EaseLab(initialEase: 'expo'),
      frozenBuilder: (context) =>
          const EaseLab(initialEase: 'expo', frozenAt: 1.0),
    ),
  ],
);
