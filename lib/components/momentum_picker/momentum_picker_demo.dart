// Demo/usage example for MomentumPicker.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'momentum_picker.dart';

final ComponentDemo momentumPickerDemo = ComponentDemo(
  id: 'momentum_picker',
  builder: (context) => const _PickerShowcase(),
  variants: <DemoVariant>[
    for (int i = 0; i < 3; i++)
      DemoVariant(
        id: 'option-$i',
        label: const <String>['Airy', 'Balanced', 'Dense'][i],
        builder: (context) => _Stage(
          child: MomentumPicker(index: i, onChanged: null, animate: false),
        ),
      ),
  ],
);

/// Swipe vertically for detents, or tap a row directly — same state as the
/// original's wheel/keys/click trio.
class _PickerShowcase extends StatefulWidget {
  const _PickerShowcase();

  @override
  State<_PickerShowcase> createState() => _PickerShowcaseState();
}

class _PickerShowcaseState extends State<_PickerShowcase> {
  int _index = 1;

  @override
  Widget build(BuildContext context) {
    return _Stage(
      child: MomentumPicker(
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
