// Demo/usage example for LikeBurst.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'like_burst.dart';

final ComponentDemo likeBurstDemo = ComponentDemo(
  id: 'like_burst',
  builder: (context) => const _LikeShowcase(),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'unliked',
      label: 'Unliked',
      builder: (context) => const _Stage(
        child: LikeBurst(liked: false, onChanged: null, animate: false),
      ),
    ),
    DemoVariant(
      id: 'liked',
      label: 'Liked',
      builder: (context) => const _Stage(
        child: LikeBurst(liked: true, onChanged: null, animate: false),
      ),
    ),
  ],
);

class _LikeShowcase extends StatefulWidget {
  const _LikeShowcase();

  @override
  State<_LikeShowcase> createState() => _LikeShowcaseState();
}

class _LikeShowcaseState extends State<_LikeShowcase> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    return _Stage(
      child: LikeBurst(
        liked: _liked,
        onChanged: (liked) => setState(() => _liked = liked),
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
