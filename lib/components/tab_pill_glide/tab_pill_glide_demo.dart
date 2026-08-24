// Demo/usage example for TabPillGlide.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'tab_pill_glide.dart';

final ComponentDemo tabPillGlideDemo = ComponentDemo(
  id: 'tab_pill_glide',
  builder: (context) => const _TabsShowcase(),
  // One entry per tab; implicit animations render their end value on first
  // build, so these are naturally frozen frames.
  variants: <DemoVariant>[
    for (int i = 0; i < 3; i++)
      DemoVariant(
        id: 'tab-$i',
        label: const <String>['Plan', 'Build', 'Ship'][i],
        builder: (context) => _Stage(
          child: TabPillGlide(index: i, onChanged: null, animate: false),
        ),
      ),
  ],
);

class _TabsShowcase extends StatefulWidget {
  const _TabsShowcase();

  @override
  State<_TabsShowcase> createState() => _TabsShowcaseState();
}

class _TabsShowcaseState extends State<_TabsShowcase> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return _Stage(
      child: TabPillGlide(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
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
