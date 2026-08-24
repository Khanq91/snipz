// Demo/usage example for HoldToConfirm.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'hold_to_confirm.dart';

final ComponentDemo holdToConfirmDemo = ComponentDemo(
  id: 'hold_to_confirm',
  builder: (context) => const _HoldShowcase(),
);

class _HoldShowcase extends StatefulWidget {
  const _HoldShowcase();

  @override
  State<_HoldShowcase> createState() => _HoldShowcaseState();
}

class _HoldShowcaseState extends State<_HoldShowcase> {
  int _confirmed = 0;

  @override
  Widget build(BuildContext context) {
    return _Stage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          HoldToConfirm(onConfirm: () => setState(() => _confirmed++)),
          const SizedBox(height: 18),
          Text(
            _confirmed == 0 ? 'Press and hold 800ms' : 'Confirmed ×$_confirmed',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6E6C68)),
          ),
        ],
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
