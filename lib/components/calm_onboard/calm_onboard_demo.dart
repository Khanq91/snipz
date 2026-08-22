// Demo/usage example for CalmOnboardScreen. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'calm_onboard.dart';

final ComponentDemo calmOnboardDemo = ComponentDemo(
  id: 'calm_onboard',
  builder: (context) => CalmOnboardScreen(
    onNext: () => _toast(context, 'onNext'),
  ),
  thumbnailBuilder: (context) =>
      _still(const CalmOnboardScreen(animate: false)),
  variants: [
    for (final (int page, String label) in const [
      (0, 'morning'),
      (1, 'midday'),
      (2, 'night'),
    ])
      DemoVariant(
        id: label,
        label: label,
        builder: (context) => CalmOnboardScreen(
          initialPage: page,
          onNext: () => _toast(context, 'onNext'),
        ),
        frozenBuilder: (context) =>
            _still(CalmOnboardScreen(initialPage: page, animate: false)),
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
