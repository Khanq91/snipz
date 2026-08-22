// Demo/usage example for CalmClimbScreen. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'calm_climb.dart';

final ComponentDemo calmClimbDemo = ComponentDemo(
  id: 'calm_climb',
  builder: (context) => CalmClimbScreen(
    onNext: () => _toast(context, 'onNext'),
  ),
  thumbnailBuilder: (context) => _still(const CalmClimbScreen(animate: false)),
  variants: [
    for (final (double prog, int steps, String label, String headline)
        in const [
      (.25, 13250, 'base camp', 'A quarter up Everest'),
      (.5, 26500, 'halfway', 'Halfway up Everest'),
      (.85, 45050, 'the ridge', 'Nearly at the summit'),
    ])
      DemoVariant(
        id: label.replaceAll(' ', '_'),
        label: label,
        builder: (context) => CalmClimbScreen(
            progress: prog, steps: steps, headline: headline),
        frozenBuilder: (context) => _still(CalmClimbScreen(
            progress: prog,
            steps: steps,
            headline: headline,
            animate: false)),
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
