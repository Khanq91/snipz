// Demo/usage example for SkeletonContent. Exempt from portability rules
// (§3.1.9); also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'skeleton_content.dart';

final ComponentDemo skeletonContentDemo = ComponentDemo(
  id: 'skeleton_content',
  builder: (context) => const _SkeletonContentShowcase(),
  // Frozen shimmer frame for the gallery grid — no ticker per tile.
  thumbnailBuilder: (context) => const _Stage(
    child: SkeletonContent(loaded: false, frozenAt: 0.35),
  ),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'loading',
      label: 'Loading',
      builder: (context) =>
          const _Stage(child: SkeletonContent(loaded: false)),
      frozenBuilder: (context) =>
          const _Stage(child: SkeletonContent(loaded: false, frozenAt: 0.35)),
    ),
    DemoVariant(
      id: 'loaded',
      label: 'Loaded',
      builder: (context) =>
          const _Stage(child: SkeletonContent(loaded: true)),
      frozenBuilder: (context) =>
          const _Stage(child: SkeletonContent(loaded: true, frozenAt: 0)),
    ),
  ],
);

/// Tap the card to toggle skeleton ↔ content, like the kinetics demo.
class _SkeletonContentShowcase extends StatefulWidget {
  const _SkeletonContentShowcase();

  @override
  State<_SkeletonContentShowcase> createState() =>
      _SkeletonContentShowcaseState();
}

class _SkeletonContentShowcaseState extends State<_SkeletonContentShowcase> {
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    return _Stage(
      child: SkeletonContent(
        loaded: _loaded,
        onTap: () => setState(() => _loaded = !_loaded),
      ),
    );
  }
}

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
