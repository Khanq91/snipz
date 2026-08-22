// Demo/usage example for CalmBreathScreen. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'calm_breath.dart';

final ComponentDemo calmBreathDemo = ComponentDemo(
  id: 'calm_breath',
  builder: (context) => CalmBreathScreen(
    onNext: () => _toast(context, 'onNext'),
  ),
  thumbnailBuilder: (context) => _still(const CalmBreathScreen(animate: false)),
  variants: [
    DemoVariant(
      id: 'mint',
      label: 'mint',
      builder: (context) =>
          CalmBreathScreen(onNext: () => _toast(context, 'onNext')),
      frozenBuilder: (context) =>
          _still(const CalmBreathScreen(animate: false)),
    ),
    DemoVariant(
      id: 'ocean',
      label: 'ocean',
      builder: (context) => CalmBreathScreen(
          startWithOcean: true, onNext: () => _toast(context, 'onNext')),
      frozenBuilder: (context) => _still(
          const CalmBreathScreen(startWithOcean: true, animate: false)),
    ),
  ],
);

// Render the settled screen at its 390x844 design size and scale it into
// whatever tile the gallery gives us — screens are not tile-sized layouts.
Widget _still(Widget screen) => FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(width: 390, height: 844, child: screen),
    );

void _toast(BuildContext context, String s) =>
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(s), duration: const Duration(milliseconds: 700)));
