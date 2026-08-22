// Demo/usage example for CalmWelcomeScreen. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'calm_welcome.dart';

final ComponentDemo calmWelcomeDemo = ComponentDemo(
  id: 'calm_welcome',
  builder: (context) => CalmWelcomeScreen(
    onNext: () => _toast(context, 'onNext'),
    onLogin: () => _toast(context, 'onLogin'),
  ),
  thumbnailBuilder: (context) =>
      _still(const CalmWelcomeScreen(animate: false)),
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
