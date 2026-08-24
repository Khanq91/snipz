// Demo/usage example for SwitchSpring.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'switch_spring.dart';

final ComponentDemo switchSpringDemo = ComponentDemo(
  id: 'switch_spring',
  builder: (context) => const _SwitchShowcase(),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'off',
      label: 'Off',
      builder: (context) =>
          const _Stage(child: SwitchSpring(value: false, onChanged: null)),
    ),
    DemoVariant(
      id: 'on',
      label: 'On',
      builder: (context) =>
          const _Stage(child: SwitchSpring(value: true, onChanged: null)),
    ),
  ],
);

class _SwitchShowcase extends StatefulWidget {
  const _SwitchShowcase();

  @override
  State<_SwitchShowcase> createState() => _SwitchShowcaseState();
}

class _SwitchShowcaseState extends State<_SwitchShowcase> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return _Stage(
      child: SwitchSpring(
        value: _value,
        onChanged: (value) => setState(() => _value = value),
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
