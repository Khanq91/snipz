// Demo/usage example for ExpandingSearch.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'expanding_search.dart';

final ComponentDemo expandingSearchDemo = ComponentDemo(
  id: 'expanding_search',
  builder: (context) => const _SearchShowcase(),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'collapsed',
      label: 'Collapsed',
      builder: (context) => const _Stage(
        child: ExpandingSearch(expanded: false, animate: false),
      ),
    ),
    DemoVariant(
      id: 'expanded',
      label: 'Expanded',
      builder: (context) => const _Stage(
        child: ExpandingSearch(expanded: true, animate: false),
      ),
    ),
  ],
);

/// Tap the pill to focus and expand; tapping the empty stage around it
/// unfocuses, collapsing the field again.
class _SearchShowcase extends StatelessWidget {
  const _SearchShowcase();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: const _Stage(child: ExpandingSearch()),
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
