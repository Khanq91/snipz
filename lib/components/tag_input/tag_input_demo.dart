// Demo/usage example for TagInput.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'tag_input.dart';

final ComponentDemo tagInputDemo = ComponentDemo(
  id: 'tag_input',
  builder: (context) => const _TagShowcase(),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'two',
      label: 'Two tags',
      builder: (context) => const _Stage(child: TagInput(animate: false)),
    ),
    DemoVariant(
      id: 'empty',
      label: 'Empty',
      builder: (context) => const _Stage(
        child: TagInput(initialTags: <String>[], animate: false),
      ),
    ),
  ],
);

class _TagShowcase extends StatelessWidget {
  const _TagShowcase();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: const _Stage(child: TagInput()),
    );
  }
}

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
