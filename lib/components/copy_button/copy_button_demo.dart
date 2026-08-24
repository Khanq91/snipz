// Demo/usage example for CopyButton.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'copy_button.dart';

final ComponentDemo copyButtonDemo = ComponentDemo(
  id: 'copy_button',
  // Same payload as the original card (`data-copy="spring(320, 24)"`).
  builder: (context) => const _Stage(
    child: CopyButton(value: 'spring(320, 24)'),
  ),
);

/// Dark stage matching the kinetics palette (graphite #0e0e10).
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
