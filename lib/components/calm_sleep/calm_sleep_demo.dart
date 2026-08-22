// Demo/usage example for CalmSleepScreen. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'calm_sleep.dart';

final ComponentDemo calmSleepDemo = ComponentDemo(
  id: 'calm_sleep',
  builder: (context) => CalmSleepScreen(
    onNext: () => _toast(context, 'onNext'),
  ),
  thumbnailBuilder: (context) => _still(const CalmSleepScreen(animate: false)),
  variants: [
    for (final (int mins, String label, String headline) in const [
      (192, 'restless', 'A slim crescent'),
      (384, 'okay', 'Nearly a full moon'),
      (480, 'full', 'A full moon night'),
    ])
      DemoVariant(
        id: label,
        label: label,
        builder: (context) =>
            CalmSleepScreen(sleptMinutes: mins, headline: headline),
        frozenBuilder: (context) => _still(CalmSleepScreen(
            sleptMinutes: mins, headline: headline, animate: false)),
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
