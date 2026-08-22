// Demo/usage example for CalmMoodScreen. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'calm_mood.dart';

final ComponentDemo calmMoodDemo = ComponentDemo(
  id: 'calm_mood',
  builder: (context) => CalmMoodScreen(
    onNext: () => _toast(context, 'onNext'),
    onChanged: (v) => _toast(
        context, kCalmMoodLabels[(v * 6).round().clamp(0, 6)]),
  ),
  thumbnailBuilder: (context) => _still(const CalmMoodScreen(animate: false)),
  variants: [
    for (final (double v, String label) in const [
      (0.0, 'unpleasant'),
      (0.5, 'neutral'),
      (1.0, 'pleasant'),
    ])
      DemoVariant(
        id: label,
        label: label,
        builder: (context) => CalmMoodScreen(initialValue: v),
        frozenBuilder: (context) =>
            _still(CalmMoodScreen(initialValue: v, animate: false)),
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
