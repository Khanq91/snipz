// Demo/usage example for CalmPaywallScreen. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'calm_paywall.dart';

final ComponentDemo calmPaywallDemo = ComponentDemo(
  id: 'calm_paywall',
  builder: (context) => CalmPaywallScreen(
    onStart: () => _toast(context, 'onStart'),
    onRestore: () => _toast(context, 'onRestore'),
  ),
  thumbnailBuilder: (context) =>
      _still(const CalmPaywallScreen(animate: false)),
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
