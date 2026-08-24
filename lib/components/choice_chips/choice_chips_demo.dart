// Demo/usage example for PopChips ("Choice Chips").

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'choice_chips.dart';

final ComponentDemo choiceChipsDemo = ComponentDemo(
  id: 'choice_chips',
  builder: (context) => const _ChipsShowcase(),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'none',
      label: 'None on',
      builder: (context) => const _Stage(
        child: PopChips(onChanged: null, animate: false),
      ),
    ),
    DemoVariant(
      id: 'one',
      label: 'Glide on',
      builder: (context) => const _Stage(
        child: PopChips(
          selected: <String>{'Glide'},
          onChanged: null,
          animate: false,
        ),
      ),
    ),
    DemoVariant(
      id: 'many',
      label: 'Multiple on',
      builder: (context) => const _Stage(
        child: PopChips(
          selected: <String>{'Spring', 'Bounce'},
          onChanged: null,
          animate: false,
        ),
      ),
    ),
  ],
);

class _ChipsShowcase extends StatefulWidget {
  const _ChipsShowcase();

  @override
  State<_ChipsShowcase> createState() => _ChipsShowcaseState();
}

class _ChipsShowcaseState extends State<_ChipsShowcase> {
  // Same initial state as the original demo (Glide starts on).
  Set<String> _selected = <String>{'Glide'};

  @override
  Widget build(BuildContext context) {
    return _Stage(
      child: SizedBox(
        width: 240,
        child: PopChips(
          selected: _selected,
          onChanged: (next) => setState(() => _selected = next),
        ),
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
