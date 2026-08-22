// Demo/usage example for CalmInsightsScreen. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'calm_insights.dart';

final ComponentDemo calmInsightsDemo = ComponentDemo(
  id: 'calm_insights',
  builder: (context) => CalmInsightsScreen(
    onNext: () => _toast(context, 'onNext'),
  ),
  thumbnailBuilder: (context) =>
      _still(const CalmInsightsScreen(animate: false)),
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
